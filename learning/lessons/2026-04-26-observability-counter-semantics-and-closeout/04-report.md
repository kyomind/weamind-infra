# 2026-04-26 Observability Counter Semantics and Closeout Report

## 今日主題

- 用最小診斷實驗釐清 WeaMind app metrics 在多 worker 條件下的 counter 語意問題，並把 W7 observability demo MVP 的 Node / App dashboards 收到可展示狀態。

## 今日實際完成

- 用 raw counter、`increase()`、`resets()`、`changes()` 這組 PromQL 證據，確認半夜持續出現的 `postback` 數字比較不像真實流量，而更像不可信的 counter 序列被 Prometheus 誤解讀。
- 對照 app repo 的 metrics 實作與 deployment 設定，確認原始問題發生時的關鍵風險組合是 `uvicorn --workers 2` 搭配預設 in-process `prometheus_client` registry。
- 實際將 deployment 從 `workers: 2` 調整為 `workers: 1`，完成 rollout 並重新觀察 metrics 行為。
- 透過受控的 `postback x 6` 測試，確認 raw counter 與 `increase()[5m]` 已恢復成可解讀狀態，ghost traffic 問題對 W7 demo-grade 收尾已可視為解掉。
- 完成 `WatchMind Nodes` 與 `WatchMind Apps` 兩份 dashboards 的收尾。
- `WatchMind Apps` 已建立 6 個 panels，並完成首輪實測驗證：
	- `Webhook Events Total by Event Type`
	- `Webhook Events Recent Activity (5m)`
	- `Webhook Success Events (5m)`
	- `Webhook Error Events (5m)`
	- `Webhook Average Duration`
	- `Webhook P95 Duration`

## 今日最後確認的關鍵理解

- 這次最核心的問題不是 Grafana panel 畫錯，而是某條 `line_webhook_events_total` counter 序列本身在多 worker + in-process registry 條件下已經失真，所以 `increase()` 對它做出的換算自然也不可信。
- `workers: 1` 不是長期架構的最終解，但對 W7 這堂的 demo MVP 來說，是一個合理、可驗證、可解釋的保守收尾方案。
- raw counter 與 `increase()` 在回答不同問題：
	- raw counter 比較適合驗證總次數
	- `increase()[5m]` 比較適合驗證最近是否有一波活動
- panel 數量不應照 metric family 數量硬對齊，而應照問題來拆。這也是為什麼 App dashboard 最後不是 4 格，而是 6 格。
- `line_webhook_event_duration_seconds` 量的是 app 端處理 webhook event 的時間，不包含使用者到 LINE、或 LINE 到我們服務之前的外部網路延遲；目前 `postback` 路徑約為數百毫秒級，表示 server-side 處理時間仍有優化空間，但這不等於完整使用者體感延遲。

## 還沒完成但已明確定位的缺口

- `workers: 1` 是 demo-grade 收尾，不是 production-grade multiprocess monitoring 解法。若未來要回到多 worker，仍需要正式處理 Prometheus multiprocess aggregation。
- App dashboard 的 duration panels 已可用，但目前只完成低樣本條件下的首輪驗證；若要做更嚴謹的效能分析，還需要更多樣本與更精細的路徑拆解。
- 這次已略過 post-implementation QA；若之後要補口述收斂，可在下一堂 lesson 或後續複習時補回短版 QA / flashcards。

## 下一步

- 將今天確認的結論同步回 W7 / Phase 2 進度記錄，讓正式執行追蹤與 lesson 收尾一致。
- 若要繼續優化 observability，而不是只收 demo MVP，下一步優先考慮：
	- 正式評估 multiprocess metrics 設計
	- 釐清 `postback` handler 內部哪一段造成數百毫秒級延遲
	- 視需要補 QA / flashcards，讓今天的診斷與 trade-off 更容易口述
