# WeaMind Observability Minimum Spec

這份文件整理 Phase 2 / W7 會反覆用到、但不需要每次都讀的最小 observability 規格。

它不是週計畫，也不是每日進度檔。

它的角色是：當 W7 要實作或驗收 observability 時，提供一份穩定、可公開、可對照的 reference。

## 先說結論

W7 的最低交付物是：

- Node 3
- App 4
- 1 個 Grafana dashboard

目的不是做完整監控體系，而是做出一版可安裝、可觀察、可 demo、可面試重講的最小成果。

## Node 3

Node 層先固定看這 3 個基礎指標：

- `CPU usage`
- `memory usage`
- `filesystem usage`

這 3 個是最常見、最容易理解、也最像基礎盤的 node metrics。

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

## 驗收時要看到什麼

W7 收尾時，至少應能回答：

1. Node 3 是哪三個指標
2. App 4 是哪四個指標
3. 這 4 個 app metrics 掛在哪條處理鏈
4. `event_type` 第一版怎麼分
5. Grafana dashboard 是否已能把這些指標做成最小可 demo 畫面

## 這份 reference 的用途

- 當 W7 要做 install / dashboard / app metrics implement 時，作為穩定規格參考
- 避免把具體 metric 命名、labels、掛點、分類規則全部塞在週計畫裡
- 讓計畫檔只保留節奏、進度、實作目標與短版驗收標準
