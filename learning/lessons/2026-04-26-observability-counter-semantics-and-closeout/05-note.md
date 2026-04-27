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

### Pod 重啟後，Prometheus 怎麼面對時間連續性

- 先講最短版：**Prometheus 不會把舊 Pod 的 counter 直接接到新 Pod 上。** 舊 Pod 的 series 會停在最後一個樣本，新 Pod 則會以新的 series 身分重新開始。
- 也就是說，像 `instance=10.42.x.x:8000` 這種帶有 Pod IP 的 target，一旦 Pod 被 rollout 換掉，對 Prometheus 來說通常就是「舊 series 結束、新 series 出現」，而不是同一條線被無縫延續。
- 所以如果你直接看帶 `instance` 這種易變 label 的單條 raw counter，Pod 重啟本來就會破壞那條線的連續性。這不是 Prometheus 壞掉，而是 workload identity 本來就變了。
- 真正在實務上要保的，通常不是「某一顆 Pod 的單條 counter 永遠連續」，而是**服務層或工作負載層的觀察連續性**。這通常是靠 query 聚合來做到，例如：

```promql
sum by (event_type) (increase(line_webhook_events_total[5m]))
```

- 這種 query 的意思不是去硬接某一條 Pod series，而是把同一段時間內、屬於這個服務的多條 series 一起納入計算，再做較高層的觀察。
- 也因此，Prometheus 對 Pod 重啟的處理方式比較像：
	- 保留舊 Pod 的歷史樣本
	- 讓舊 series 停止更新並進入 stale
	- 對新 Pod 開始記新的 series
	- 查詢時再由 PromQL 決定要如何聚合、忽略哪些易變 label、以及怎麼處理 counter reset
- 所以如果問題是「Prometheus 怎麼保時間連續性」，更準確的答案是：**它保的是歷史資料與可查詢性，不是替你把 Pod identity 無縫縫合。真正的連續性通常是在 query / aggregation 這一層建立的。**
- 這也順手解釋了為什麼我們今天會一直避免過度盯著單條 Pod raw counter：那一層對 debug 很有用，但它本來就不是最終想要維持的 product / service-level 觀察面。

### 可以把 Prometheus 理解成盡量忠實記錄樣本，但服務語意問題常出在 query 層

- 這一輪追問的核心很重要：Prometheus 比較像是在盡量保留「每次 scrape 當下實際觀察到了什麼」，而不是保證你最後查出來的每條線都天然對應到想看的業務語意。
- 所以比較穩的切法是把它分成兩層：
	- 資料收集層：Prometheus 盡量忠實記下每次 scrape 拿到的樣本
	- 查詢與解讀層：PromQL、aggregation、label 選擇與 metric 模型，決定這些樣本最後會被解讀成什麼服務指標
- 換句話說，Prometheus 原始記錄可能是真的，但如果我們把不該拼在一起的 series 拼在一起、忽略了 identity 會變、或把不適合做 `increase()` 的序列拿去換算，最後得到的業務解讀仍然可能失真。
- 這也是為什麼這次問題不能簡化成「Prometheus 記錯資料」；更準確地說，是：**Prometheus 記下了它真的看到的樣本，但我們原本對這些樣本能否被當成穩定 counter source 的假設不成立。**
- 若要再口語一點，可以記成：**Prometheus 比較像誠實的記錄員；真正容易出錯的地方，常常不是它記了什麼，而是我們後來怎麼把那些資料解讀成服務指標。**

### 為什麼手動按了 6 次，但 `increase()` 的峰值只有 4

- 這題最重要的先釐清一句：`increase()` 不是在「數事件本身」，而是在**根據 scrape 到的離散樣本，估算某個時間窗內 counter 增加了多少**。
- 所以 raw counter 和 `increase()` 其實在回答不同問題：
	- raw counter：最後累積到多少
	- `increase()[1m]` / `increase()[5m]`：某個時間窗內估計增加了多少
- 這次 raw counter 很清楚：兩個 Pod 最後各到 `3`，總共就是 `6`。這是最適合用來驗證「這次手動操作總共發生了 6 次」的證據。
- 但 `sum by (event_type) (increase(line_webhook_events_total[1m]))` 或 `[5m]` 沒有剛好到 `6`，不代表系統少算，也不代表 Prometheus 壞掉；更常見的原因是：
	- Prometheus 不是 event log，它只看到每次 scrape 當下的 counter 值
	- 你的 6 次點擊發生在很短時間內，而且流量很小
	- scrape interval 目前是 `30s`
	- 這些點擊又分散到兩個 Pod 的兩條 series 上
	- 新 series 在觀察窗內未必從 `0` 被完整看到
- 在這種條件下，`increase()` 比較像「估算最近這段時間確實有一波 `postback` 增加」，而不是「精準逐筆對帳器」。
- 所以這次看到峰值大約 `4`，比較合理的解讀是：Prometheus 在目前這組樣本密度下，看到了明確上升趨勢，但沒有足夠條件把那 6 次手動操作精準還原成峰值 `6`。
- 這也是為什麼在低流量、短時間窗、fresh series 的測試裡，`increase()` 比較適合拿來看趨勢與方向，而不是要求它精準等於人工按了幾次。
- 如果需求真的是「每分鐘精準點擊數」，常見的做法通常會是：
	- 提高 scrape 頻率，例如從 `30s` 降到 `10s`
	- 接受它仍是監控估算值，不是事件帳本
	- 或另外用 event log / analytics 系統保存精準逐筆資料
- 這題可以收斂成一句話：**raw counter 比較適合驗證總次數；`increase()` 比較適合驗證某段時間內是否出現一波流量上升。兩者沒有矛盾，只是在回答不同問題。**

### App dashboard 要用 `1m` 還是 `5m`

- 這題沒有單一永遠正確的答案，因為 `increase()[1m]` 和 `increase()[5m]` 本來就在回答不同問題。
- `increase(...[5m])` 比較像在看最近 5 分鐘內有沒有一波活動，畫面會比較平滑，也比較適合平常放在 dashboard 上長時間看趨勢。
- `increase(...[1m])` 會更接近「剛剛這一分鐘有沒有點擊」這種即時脈衝感，但它也會更抖，對 scrape timing 更敏感，在低流量情境下更不穩。
- 所以 `5m` 的缺點確實是會把同一波流量在接下來幾個 scrape 點裡持續納入，看起來像拖尾；但這不是它不準，而是它本來就在回答「最近 5 分鐘整體活動量」這個問題。
- 若需求是平常 dashboard 主要觀察用，我們先選 `5m` 當主 panel 比較穩。
- 若之後想補一張更偏即時脈衝感的圖，可以再加一張 `1m` panel，但不把它當成唯一主指標。
- 所以這次 W7 的收斂決策是：**App dashboard 主 panel 先維持 `5m`，若後面需要更即時的補充視角，再額外加 `1m` panel，而不是一開始就把主 panel 換成 `1m`。**



## Flashcards

<!-- 待回填 -->
