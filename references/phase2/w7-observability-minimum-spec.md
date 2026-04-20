# WeaMind Observability Demo MVP Spec

這份文件整理 Phase 2 / W7 會反覆用到、但不需要每次都讀的 demo-grade observability MVP 規格。

它不是週計畫，也不是每日進度檔。

它的角色是：當 W7 要實作或驗收 observability demo 時，提供一份穩定、可公開、可對照的 reference。

這份 spec 的定位是純 demo MVP，不是 production MVP。它要展示的是：WeaMind 已經有一條可以被 Prometheus / Grafana 觀察的最小鏈路，並且能用少量指標說明 Kubernetes node 資源狀態與 LINE webhook 主路徑的健康狀態。

它不承諾完整告警、SLO、incident response、dependency tracing、black-box probing 或 production-grade dashboard 設計。

## 先說結論

W7 的 demo MVP 交付物是：

- Node 3
- App 4
- 1 個 Grafana dashboard

目的不是做完整監控體系，而是做出一版可安裝、可觀察、可 demo、可面試重講的最小成果。

這 7 項指標的核心敘事是：

- Node 3：回答「Kubernetes node 有沒有明顯資源壓力」
- App 4：回答「LINE webhook 有沒有進來、有沒有成功、有沒有失敗、有沒有變慢」

換句話說，這是一版 demo-grade baseline：足以展示 observability 的基本概念與實作鏈路，但不把範圍膨脹成完整 production monitoring。

## Node 3

Node 層先固定看這 3 個基礎指標：

- `CPU usage`
- `memory usage`
- `filesystem usage`

這 3 個是最常見、最容易理解、也最像基礎盤的 node metrics。

它們在 demo 中的角色是資源背景盤，不是完整 root cause analysis。也就是說，dashboard 應讓觀看者一眼知道 node 是否有 CPU、memory、filesystem 壓力，但不需要在 W7 追到每個 container、process 或 disk inode 細節。

## App 4

App 層先固定看 webhook 處理鏈的 4 個基礎指標：

- `webhook request total`
- `webhook success total`
- `webhook error total`
- `webhook latency`

在正式 metric naming 上，第一版先收斂成：

- `line_webhook_events_total`
- `line_webhook_events_success_total`
- `line_webhook_events_error_total`
- `line_webhook_event_duration_seconds`

這 4 個 app metrics 對齊的是服務監控裡常見的 request rate / success / error / latency 思路。對 WeaMind 這種 LINE Bot 來說，核心使用者路徑不是一般網頁瀏覽，而是 LINE webhook，因此第一版先觀察 webhook chain 是合理的 demo 取捨。

## App 4 Metric 規格

### `line_webhook_events_total`

- 用途：統計所有進來的 LINE webhook event 總量
- 建議 labels：`event_type`
- 建議掛點：`app/line/router.py` 的 `line_webhook` 驗證完成後、排入 background task 前

### `line_webhook_events_success_total`

- 用途：統計已成功完成處理的 LINE webhook event 數
- 建議 labels：`event_type`
- 建議掛點：`app/line/router.py` 內 `_process_webhook()` 成功完成後

### `line_webhook_events_error_total`

- 用途：統計 webhook 處理過程中失敗的 event 數
- 建議 labels：`event_type`, `error_type`
- 建議掛點：`app/line/router.py` 內 `_process_webhook()` 的例外處理區塊

### `line_webhook_event_duration_seconds`

- 用途：量測單次 webhook event 的處理時間
- 建議 labels：`event_type`
- 建議掛點：`app/line/router.py` 內 `_process_webhook()` 的處理前後
- 建議型別：優先使用 histogram，讓 Grafana 至少可以展示平均或 p95 類型的 latency；若第一版實作成本過高，才退回較簡化的 duration 記錄

## `event_type` 最小分類規則

第一版不追求完整 taxonomy，只對齊目前 WeaMind app 已有的 handler：

- `message_text`：對應文字訊息事件，主要掛到 `handle_message_event()`
- `message_location`：對應位置訊息事件，主要掛到 `handle_location_message_event()`
- `follow`：對應 `handle_follow_event()`
- `unfollow`：對應 `handle_unfollow_event()`
- `postback`：對應 `handle_postback_event()`
- `default`：對應 `handle_default_event()` 或目前未特別細分的其他事件
- `unknown`：保底值；若第一版在 router 層還無法穩定辨識 event type，可先用這個值起步

## 第一版實作原則

- 這 4 個 app metrics 先以 LINE webhook 處理鏈為主，而不是先拆成每個功能模組各自一套 metrics。
- 不要求一開始就在 router 層把所有 event type 完整 parse 到位；若成本偏高，可先用 `unknown` 跑通整體 metrics 管線，再逐步補上分類。
- 若要做最小分類，應優先對齊目前 WeaMind 已有的 handler，而不是先發明更細的 business taxonomy。
- `error_type` 也應採最小策略，先以高層類別為主，例如 `signature_error`、`handler_error`、`reply_error`，不追求一開始就對所有例外做精細建模。

## Grafana Dashboard Demo 原則

Dashboard 的目標不是做漂亮完整的 production cockpit，而是讓觀看者在 30 到 60 秒內看懂這條 observability MVP：

1. 這個 K3s cluster 的 node 資源狀態是否大致正常
2. LINE webhook 是否真的有流量進來
3. webhook 成功與失敗是否能被分開觀察
4. webhook latency 是否能被觀察到趨勢

Dashboard 上應優先呈現「可讀的 demo 訊號」，而不是只貼 raw counter：

- webhook events per minute
- webhook success / error count
- webhook error rate
- webhook latency，例如 average 或 p95
- node CPU usage
- node memory usage
- node filesystem usage

若時間有限，寧可把這些圖做得少而清楚，不要補很多沒有解釋價值的 panel。

## Scrape / Query Window 原則

W7 demo MVP 先統一使用 `30s` scrape interval。

這個服務流量很小，不需要一開始就用 `5s` 或 `10s` 這種高頻 scrape。高頻不會讓低流量服務的判讀更準，只會讓 demo 看起來像在假裝 production。

也不建議第一版預設用 `60s`。它雖然更省，但 demo 體感偏慢；使用者送出一個 LINE webhook 後，Grafana 可能要等太久才出現明顯變化。

Dashboard 查詢以 `5m` window 為主，避免低流量服務因樣本太少造成圖表過度跳動：

- webhook events per minute：`increase(line_webhook_events_total[5m]) / 5`
- webhook error rate：`increase(line_webhook_events_error_total[5m]) / increase(line_webhook_events_total[5m])`
- webhook success / error count：`increase(...[5m])`
- latency：demo 初期可先看 average；若 `line_webhook_event_duration_seconds` 使用 histogram，再補 p95

如果後續只是長期放著觀察，而不是 demo 現場展示，再把 node 或 app scrape interval 調成 `60s` 也可以。但 W7 第一版先不要分太細，統一 `30s` 就好。

## 非目標

W7 demo MVP 不追求以下內容：

- 完整 alert rule 與 Alertmanager routing
- SLO / error budget / burn rate
- PostgreSQL、Redis、外部天氣 API 的 dependency latency
- webhook queue / background task backlog
- tracing 或 OpenTelemetry
- black-box probe 或 synthetic monitoring
- production-grade dashboard 權限、folder、provisioning 與長期維護設計

這些都可以作為後續延伸，但不應阻擋 W7 demo MVP 收尾。

## 驗收時要看到什麼

W7 收尾時，至少應能回答：

1. Node 3 是哪三個指標
2. App 4 是哪四個指標
3. 這 4 個 app metrics 掛在哪條處理鏈
4. `event_type` 第一版怎麼分
5. Grafana dashboard 是否已能把這些指標做成最小可 demo 畫面
6. 這份成果為什麼是 demo MVP，而不是 production MVP

一版合格的收尾說法可以是：

> 這是 WeaMind 的 demo-grade observability MVP。它先覆蓋 node resource 與 LINE webhook 主路徑的 request / success / error / latency，目標是展示 Prometheus / Grafana 鏈路與服務健康觀察方式。它不是 production monitoring；production 版本還需要補 dependency latency、alerting、SLO、black-box probe 與更完整的 incident response 設計。

## 這份 reference 的用途

- 當 W7 要做 install / dashboard / app metrics implement 時，作為穩定規格參考
- 避免把具體 metric 命名、labels、掛點、分類規則全部塞在週計畫裡
- 讓計畫檔只保留節奏、進度、實作目標與短版驗收標準
- 避免 demo MVP 被誤解成 production observability 規格
