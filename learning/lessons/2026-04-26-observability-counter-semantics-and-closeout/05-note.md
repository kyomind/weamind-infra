# 2026-04-26 Observability Counter Semantics and Closeout Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天的第一優先不是多做幾張 Grafana 圖，而是先判斷 App 4 的 counter 序列是否可信。
- 若今天證明問題主要落在多 worker 下的 metrics runtime，W7 可以先用 demo-grade 保守做法收尾，不需要在同一天硬補 production-grade multiprocess 支援。
- 今天要刻意分開三層：真實 webhook 流量、PromQL 對 counter 的解讀、以及 app runtime 如何暴露 metrics。

## Notes

### `message_text = 0` 在這個 app 是正常現象，不是異常訊號

- 這次 Grafana panel 裡 `message_text` 幾乎一直是 `0`，不能直接解讀成 metrics 壞掉。
- 對 WeaMind 目前的產品設計來說，主要互動路徑本來就是使用 rich menu 按鈕查天氣，而不是讓使用者手動輸入文字。
- 所以平常沒有 `message_text` event，本身是合理的產品行為；這一條序列維持接近 `0`，不應被當成這次 counter 問題的主證據。
- 更準確地說，這次真正可疑的不是 `message_text` 太低，而是 `postback` 在沒有真實夜間使用情境時，仍長時間維持明顯數值。

### 目前觀察到的異常，不像真實流量，更像 counter 序列失真

- 現在最不合理的現象是：Grafana 的 `Webhook Events (5m)` panel 在半夜也持續出現 `postback` 數值，而且很多點都落在 `20` 到 `30` 之間。
- 以 WeaMind 目前的使用情境看，這不太可能代表真實使用者在半夜持續用 rich menu 查天氣；尤其這種規模若是真的，應該會有更明顯的實際使用背景可對應。
- 因此第一輪判讀不應是「半夜真的有流量」，而是「**Prometheus / Grafana 正在對一條不可信的 counter 序列做換算**」。
- 目前最合理的推測是：`uvicorn --workers 2` 讓同一個 app endpoint 背後有多個 Python process，而 `app/line/metrics.py` 目前又使用預設 in-process `prometheus_client` registry，**沒有 multiprocess aggregation**。
- 在這種條件下，Prometheus scrape 到的 `/metrics` 內容可能在不同 worker 的 in-memory counter 之間跳動；`increase(line_webhook_events_total[5m])` 看到這種跳動時，可能把它誤判成 counter reset 後的新增流量，於是產生長時間持續存在的假數字。
- 所以今天要驗證的重點不是先調 panel，而是先確認：這條 `line_webhook_events_total` 對 Prometheus 來說，是否仍是一條可以被 `increase()` 正確解讀的單調遞增序列。

### Step 1 判斷的 Cluade 白話解說版

好，白話版：

#### 一句話版本

**你跑了兩個 worker，但 Prometheus 以為自己在看一個。**

#### 拆開來說

##### 場景設定

你的 LINE Bot Pod 裡其實跑了**兩個獨立的 Python 程式**（worker A 和 worker B），這是 `uvicorn --workers 2` 做的事。

每個 worker 自己記自己的帳：

- Worker A 的小本子：「我接過 21 個 postback」
- Worker B 的小本子：「我接過 3 個 postback」

**這兩本帳完全不互通**。因為 `prometheus_client` 預設是把 counter 存在 process 自己的記憶體裡，A 不知道 B 數到幾，B 也不知道 A 數到幾。

##### Prometheus 來抓資料的時候

Prometheus 每 15 秒來敲一次 `/metrics` 的門問：「現在數到幾了？」

但 Service 會**隨機**把這次的請求丟給其中一個 worker 去回答。所以 Prometheus 看到的數字是這樣：

```
10:00:00 → 問到 A → 「21」
10:00:15 → 問到 B → 「3」
10:00:30 → 問到 A → 「22」
10:00:45 → 問到 B → 「3」
10:01:00 → 問到 A → 「22」
10:01:15 → 問到 B → 「4」
```

**但 Prometheus 不知道有兩個 worker**。它以為這是同一個來源，看到數字 `21 → 3`，它的解讀是：「啊，這個程式重啟了，counter 從 0 開始重新計算，現在數到 3。」

##### 為什麼會憑空產生流量

Counter 的規則是：**只能往上加，不能往下減**。如果看到數字變小，唯一合理的解釋就是「程式重啟了」。

所以 Prometheus 看到 `21 → 3`，會這樣算：
- 「重啟前累積到 21」
- 「重啟後又數到 3」
- 「所以這段期間總共增加了 21 + 3 = 24」

這 24 是憑空生出來的，不是真的有 24 筆 webhook。

每次 Prometheus 在兩個 worker 之間「換邊」，就製造一次假的增量。半夜也會發生，因為換邊跟有沒有真實流量無關，只跟 scrape 間隔有關。

##### 為什麼 message_text 沒事、postback 在跳

| Event          | A 的小本子 | B 的小本子 | 結果                      |
| -------------- | ---------- | ---------- | ------------------------- |
| `postback`     | 21         | 3          | 兩邊差很大 → 換邊時跳很兇 |
| `message_text` | 0          | 0          | 兩邊都沒值 → 沒東西可跳   |

這也是為什麼你在圖上看到 `postback` 黃線到處飛、`message_text` 綠線一直貼地——**這個對比本身就是診斷證據**，不是巧合。

#### 標準解法為什麼叫 Multiprocess Mode

讓兩個 worker 把帳寫進**共用的小本子**（一個共享目錄），有個專門的人負責把兩本帳加起來再回答 Prometheus。這樣 Prometheus 拿到的永遠是 A+B 的總和，就不會跳了。

但你不做這個，因為 workers=1 直接消滅問題本身——只剩一個 worker，就沒有「換邊」的問題。

**GitHub Copilot 補充：更嚴謹一點的講法**

- 這不是單純一句「Service 隨機把請求打到不同 worker」就能完整描述的問題。
- 更準確地說，Prometheus 觀察到的 `line_webhook_events_total` 序列本身，已經不再是單一、穩定、單調遞增的 counter source。
- 當同一個 metrics endpoint 背後其實對應到多個彼此不共享 registry 的 Python process 時，Prometheus 看到的值就可能在不同 in-memory 狀態之間切換。
- 所以這裡不是 `increase()` 算錯，而是它對一條已失真的 counter 序列，做了符合規則、但不符合真實業務流量的換算。



## Flashcards

<!-- 待回填 -->
