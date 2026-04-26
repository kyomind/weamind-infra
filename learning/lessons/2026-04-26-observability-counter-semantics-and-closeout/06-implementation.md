# 2026-04-26 Observability Counter Semantics and Closeout Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 今天的主體是釐清 WeaMind app metrics 在目前 deployment 條件下的 counter 語意，並決定 W7 observability demo MVP 的收尾方式。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 用最小診斷實驗驗證 Grafana 上持續出現的 `postback` 數字，判斷它是來自真實流量、PromQL 解讀，還是多 worker 下的 Prometheus metrics runtime 問題。

## 今日實作順序

1. 先整理目前最可疑的根因假設，並確認要看的 raw counter / `increase()` / `resets()` / `changes()` 查詢。
2. 對照 WeaMind app metrics 實作與目前 deployment 命令，確認多 worker + 預設 registry 是否成立。
3. 做 `workers: 2 -> 1` 的最小 deployment 診斷實驗，並確認 rollout 已完成。
4. 重看 `/metrics`、Prometheus query 與 Grafana panel，判斷異常數值是否消失或明顯收斂。
5. 視結果決定今天是直接收尾 App 4 dashboard，還是把缺口正式留成已定位問題。

## 驗收訊號與回退點

### 驗收訊號

- 能說清楚目前 `postback` 長時間持續出現數值的主要根因。
- 能用 deployment、app code 與 PromQL 證據支持這個判斷。
- 能決定 App 4 panel 與 W7 收尾是直接完成，還是以保守設定先完成。

### 回退點

- 若改 `workers` 後圖仍異常，先回 raw counter、`resets()`、`changes()` 查詢，不急著擴大程式碼修改。
- 若 rollout 後結果沒有變化，先驗證 Pods 是否真的套用新命令與新 image，再判讀 Grafana。
- 若今天不能把 App 4 圖做到最終版，也至少要把不可信的根因與下一步保守方案寫清楚。

### Step 1

#### 這一步要驗證什麼

- 先把今天的問題從「Grafana 很怪」縮成幾個可測的假設，並整理要看的 PromQL 證據。

#### 預計採取的動作

- 對照目前 panel query 與現象，列出 raw counter、`increase()`、`resets()`、`changes()` 的最小查詢組。
- 定義今天第一輪判讀標準：哪些結果更像真實流量，哪些更像 counter reset / worker 切換。

第一輪最小查詢組先固定如下：

```promql
line_webhook_events_total{event_type="postback"}
```

- 用途：先看 raw counter 本身是否在不同序列間跳動，而不是一開始就只看 `increase()`。

```promql
sum by (event_type) (increase(line_webhook_events_total[5m]))
```

- 用途：對照目前 Grafana panel 的主要異常現象，確認問題重現的是哪一條 query。

```promql
resets(line_webhook_events_total{event_type="postback"}[30m])
```

- 用途：看 Prometheus 是否頻繁把這條序列判定成 counter reset。

```promql
changes(line_webhook_events_total{event_type="postback"}[30m])
```

- 用途：看這條序列在沒有真實流量時，是否仍持續發生大量值變化。

第一輪判讀標準先收斂成：

- 若 raw counter 看起來平穩，只在真實操作後才增加，則比較像 query window 或 panel 解讀問題。
- 若 raw counter 在沒有真實操作時仍反覆跳動，且 `resets()` / `changes()` 明顯偏高，則更像 worker 切換或 runtime aggregation 問題。
- 若 `increase()` 長時間有值，但 raw counter 與 `resets()` 也顯示不穩定，則不應把這些數字當成真實 5 分鐘流量。

#### 實際執行內容與結果

- 第一張 raw counter 圖：`line_webhook_events_total{event_type="postback"}` 回來兩條序列。
- 其中一條序列大致穩在 `5`，另一條則在 `3` 到 `4` 之間反覆跳動；這代表問題不是只有 `increase()` 在放大噪音，而是 raw counter 本身就已經不穩定。
- 第二張 `increase()` 圖：`sum by (event_type) (increase(line_webhook_events_total[5m]))` 的 `postback` 長時間落在約 `10` 到 `30` 之間，與目前真實使用情境不符，重現了原本 panel 的異常現象。
- 第三張 `resets()` 圖：`resets(line_webhook_events_total{event_type="postback"}[30m])` 顯示其中一條序列接近 `0`，另一條卻長時間落在約 `20` 到 `30`。這代表 Prometheus 在 30 分鐘視窗內，持續把其中一個 target 判成反覆 reset。
- 第四張 `changes()` 圖：`changes(line_webhook_events_total{event_type="postback"}[30m])` 其中一條序列約落在 `40` 到 `60`，另一條接近 `0`；這代表那個有問題的 target 在沒有真實流量對應的情況下，仍持續發生大量值變動。
- 這四張圖合在一起的訊號是：不是只有 panel query 很怪，而是某一條 `postback` counter 序列本身就不是可被 `increase()` 信任的單調遞增序列。

#### AI 判讀與收斂

- Step 1 已經拿到很強的第一輪證據，方向比原本更清楚。
- 最關鍵的不是第二張 `increase()` 圖，而是第一張 raw counter 圖。因為它顯示兩條 `postback` 序列裡，至少有一條 target 的原始 counter 自己就在 `3` 與 `4` 間來回跳；對真正的 counter 來說，這種下降本身就不合理。
- 第三張 `resets()` 與第四張 `changes()` 進一步把這件事坐實了：Prometheus 對其中一條序列觀察到大量 reset 與變動，而另一條幾乎沒有。這很符合「某個 scrape target 背後其實不是單一穩定 source，而是在不同 in-memory 狀態之間切換」的模型。
- 換句話說，現在最合理的判讀不是「半夜真的有很多 postback」，也不是「`increase()` 天生不準」，而是：Prometheus 正在對一條已經失真的 counter 序列做 `increase()`，所以才會算出長時間持續存在的假流量。
- 這也帶出一個更精準的定位：問題不是單純出在 panel 聚合；因為 raw counter、`resets()`、`changes()` 都已經在單條 `postback` 序列層級暴露異常。接下來最合理的下一步，就是回到 deployment 與 app metrics 實作，確認這是否正是 `uvicorn --workers 2` 搭配預設 in-process registry 造成的 runtime 問題。

#### 目前狀態

- 已完成

### Step 2

#### 這一步要驗證什麼

- WeaMind app 目前的 metrics 實作與 deployment 命令，是否真的構成「多 worker + in-process registry」這個高風險組合。

#### 預計採取的動作

- 對照 `/Users/kyo/Code/WeaMind/app/line/metrics.py` 與 `manifests/deployment.yaml`。
- 確認是否使用預設 `prometheus_client` registry、是否沒有 multiprocess collector、以及 deployment 是否仍以 `--workers 2` 啟動。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 3

#### 這一步要驗證什麼

- 把 `workers` 降到 1 之後，異常的 `postback` 長時間數值是否明顯收斂。

#### 預計採取的動作

- 將 deployment 的 `--workers` 從 `2` 改為 `1`，rollout 並確認 Pods 已更新。
- 用固定次數的 rich menu / webhook 操作重測，並重新觀察 `/metrics`、Prometheus query 與 Grafana panel。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 4

#### 這一步要驗證什麼

- 在新的診斷結果之上，今天能否把 App 4 panel 與 W7 demo MVP 做到合理收尾。

#### 預計採取的動作

- 若數值已可信，完成最小 App 4 panel 收尾並確認 W7 完成線。
- 若數值仍不可信，將今天結論收斂成已定位根因與後續方案，不假裝 dashboard 已完成。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始
