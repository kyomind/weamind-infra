# 2026-04-26 Observability Counter Semantics and Closeout Outline

## 今日主題

- 先釐清 WeaMind app metrics 在多 Pod / 多 worker 條件下的 counter 語意，再決定 W7 observability demo MVP 該如何正式收尾。

## 今日套用的 lesson mode

- `implement-heavy`

## 為什麼今天要套用 implement-heavy mode

1. 今天最重要的問題不是抽象理解，而是要用一輪小而有辨識力的實作驗證，確認 `line_webhook_events_total` 這類 counter 在目前部署條件下是否能被 Prometheus / Grafana 正確解讀。
2. 驗收重點是 metrics runtime 與查詢結果是否可信、dashboard 能否建立在可信序列上，而不是先展開新的 observability 通用概念。

## 這次要解的專案問題

1. 為什麼 Grafana 上的 `sum by (event_type) (increase(line_webhook_events_total[5m]))` 會在沒有真實流量時，仍持續出現 `postback` 數值。
2. 問題是否主要來自 `uvicorn --workers 2` 搭配預設 in-process Prometheus registry，而不是單純 query window 或 panel 設定。
3. 在這個診斷結果之上，W7 的 Node 3、App 4、1 個 dashboard 應該如何完成最小可 demo 收尾。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：今天的難點不是通用知識骨架，而是 WeaMind 目前 metrics 實作、Kubernetes deployment 與 Prometheus / Grafana 查詢結果之間的 repo-backed 診斷與收尾。

## 要對照的 repo 檔案

1. `.privatedocs/Phase2三週計畫.md`
2. `references/phase2/w7-observability-minimum-spec.md`
3. `manifests/deployment.yaml`
4. `learning/lessons/2026-04-24-observability-targets-servicemonitor-dashboard/04-report.md`
5. `learning/lessons/2026-04-24-observability-targets-servicemonitor-dashboard/05-note.md`
6. `learning/lessons/2026-04-24-observability-targets-servicemonitor-dashboard/06-implementation.md`
7. `/Users/kyo/Code/WeaMind/app/line/metrics.py`

## 今日實作邊界

1. 今天先聚焦在 `App 4` 的可信度問題，不重開 Node metrics、Helm install 或 `ServiceMonitor` 基礎辨識。
2. 今天的第一優先是判斷 metrics 序列是否可信；只有在序列可信後，才進一步收尾 dashboard。
3. 若確認目前做法在多 worker 下不成立，今天可以先用較保守的 deployment 設定完成 demo MVP，不在這一堂直接展開 production-grade multiprocess Prometheus 設計。

## 驗收訊號與回退點

### 驗收訊號

1. 能用 PromQL 與 deployment / app 實作證據，解釋為什麼圖上會出現「半夜也持續有 postback」這種不合理現象。
2. 能完成一輪有辨識力的診斷實驗，例如 `workers: 2 -> 1`，並對照 Grafana / Prometheus 的變化。
3. 能決定 W7 demo MVP 的 App 4 panel 應如何收尾，或明確寫出今天的停損點與後續方向。

### 回退點

1. 若改 `workers` 後 metrics 仍然異常，先縮回 raw counter、`resets()`、`changes()` 等 query 層證據，不急著擴大修改 app 程式碼。
2. 若 query 結果與預期不符，先檢查實際 rollout 是否完成、Pods 是否真的吃到新 deployment 命令，再回頭判讀圖表。
3. 若今天無法把 App 4 dashboard 收到完全可 demo，也至少要把「不可信的根因」與「下一步保守解法」寫清楚，不假裝已完成。

## 建議學習順序

1. 先用 `06-implementation.md` 收斂今天的診斷假設、PromQL 驗證點與 rollout 驗證順序。
2. 先看 raw counter / `increase()` / `resets()` / `changes()` 的差異，再決定 deployment 要改哪個最小控制變數。
3. 進行 `workers: 2 -> 1` 的診斷實驗，並確認 rollout、`/metrics`、Prometheus target 與 Grafana panel 是否同步反映。
4. 將額外的 Prometheus counter 語意、multiprocess 邊界、duration 計時範圍與 dashboard 設計取捨整理到 `05-note.md`。
5. 今天以 implementation closeout 為主，post-implementation QA 本日略過，不另外開 `02-qa.md` 互動。
6. 最後回 `04-report.md` 收斂今天真正確認的根因、結果與後續收尾線。

## 文件分工

1. `01-outline.md`：宣告今天套用 `implement-heavy`，並寫清楚診斷主線、邊界、驗收與回退點。
2. 今天不建立 `02-qa.md` 的互動收斂；若需要補口述題，改留待下一次 lesson 或直接吸收到 `04-report.md`。
3. `04-report.md`：收斂今天真正確認的 metrics 語意、實作結果與 W7 收尾狀態。
4. `05-note.md`：記錄 Prometheus counter / `increase()` / multiprocess 邊界 / duration 計時範圍等延伸問答與卡片素材。
5. `06-implementation.md`：記錄今天的診斷 step、rollout、查詢證據與 dashboard 收尾過程。

## 這份 lesson 的完成標準

1. 能說清楚目前 App 4 圖表異常比較像哪一層的問題：真實流量、query 語意、還是多 worker 下的 metrics runtime。
2. 能完成至少一輪最小診斷實驗，並留下可複習的 rollout / query / panel 證據鏈。
3. 能明確定義 W7 observability demo MVP 在今天結束時是「已收尾」、「部分收尾」，還是「因特定根因而保留缺口」，即使今天略過 QA 也不影響這條完成線。

## 今日流程備註

- 今天實作密度已高，晚間收尾以 implementation closeout 為優先，因此 post-implementation QA 本日略過。
- 這次略過 QA 不是因為主題不重要，而是因為今天已在 `06-implementation.md` 與 `05-note.md` 留下足夠的可複習證據鏈與口述素材。
