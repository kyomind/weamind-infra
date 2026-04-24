# 2026-04-24 Observability Targets ServiceMonitor Dashboard Outline

## 今日主題

- 把 W7 的 observability baseline 往前推到 target discovery、ServiceMonitor / PodMonitor 與 Grafana 最小 dashboard，並明確切開 cluster metrics 與 WeaMind app metrics 的接法。

## 今日套用的 lesson mode

- `implement-heavy`

## 為什麼今天要套用 implement-heavy mode

1. 今天的主體不是抽象理解，而是要真的檢查 Prometheus targets、確認 Operator 模型下的 discovery 邊界，並視情況補最小可用的 app metrics / dashboard 接法。
2. 驗收重點是觀測鏈路有沒有真的成立、哪些 target 已被 scrape、WeaMind app 目前卡在哪一層，而不是先把 PromQL 或 dashboard 設計哲學講很深。

## 這次要解的專案問題

1. Prometheus 在這套 `kube-prometheus-stack` 裡，到底是怎麼找到 target 的，為什麼不是手動在每台機器硬寫 scrape config。
2. `ServiceMonitor`、`PodMonitor` 與 Prometheus Operator 彼此怎麼分工，今天的 WeaMind app 若要被 scrape，最小接法會落在哪一層。
3. W7 的 Node 3、App 4、1 個 dashboard，今天最多要把哪一段打通，哪些仍可接受先留成 skeleton。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：W7 Day 1 prework 已建立 Prometheus / Grafana / Alertmanager 的最小骨架，W7 Day 2 也已完成 `kube-prometheus-stack` 安裝。今天主要是把既有觀測堆疊接到 target discovery、CRD 與 dashboard 驗收這一層。

## 要對照的 repo 檔案

1. `.privatedocs/Phase2三週計畫.md`
2. `references/phase2/w7-observability-minimum-spec.md`
3. `learning/lessons/2026-04-21-helm-kube-prometheus-stack-basics/04-report.md`
4. `learning/lessons/2026-04-21-helm-kube-prometheus-stack-basics/05-note.md`
5. `manifests/deployment.yaml`
6. `manifests/service.yaml`

## 今日實作邊界

1. 今天先把 target discovery 與 `ServiceMonitor` / `PodMonitor` 的最小模型講清楚，並對回目前叢集裡已存在的 Prometheus 觀測資源。
2. 今天以 W7 demo MVP 為邊界，優先處理 Node 3、App 4 與 1 個 dashboard 的最小可觀察鏈路，不展開 production-grade alerting、retention、RBAC 或跨 cluster aggregation。
3. 如果 WeaMind app 端尚未具備 `/metrics` 或 app metrics 掛點，今天可以停在「確認缺口與最小下一步」，不硬把範圍膨脹成完整應用程式修改。

## 驗收訊號與回退點

### 驗收訊號

1. 能指出 Prometheus 目前有哪些 target 已被 scrape，並區分它們大致來自哪一類 discovery。
2. 能說清楚 `ServiceMonitor` / `PodMonitor` 在 Operator 模型裡如何把 Kubernetes 資源轉成 Prometheus scrape target。
3. 至少完成一個可 demo 的 Grafana 最小觀測結果，或明確確認今天卡住的是 app metrics 暴露層而不是 dashboard 本身。

### 回退點

1. 若 Prometheus / Grafana 本身無法存取，先回到 W7 Day 2 的 install 驗收證據，不直接進 app metrics。
2. 若 target discovery 看不到預期資源，先縮回 `Service`、label selector、namespace 與 `ServiceMonitor` / `PodMonitor` 定義，不急著怪 PromQL。
3. 若 WeaMind app 尚未暴露 `/metrics`，先把缺口定位在應用程式 instrumentation / service exposure 邊界，不假裝今天已完成 App 4。

## 建議學習順序

1. 先用 `06-implementation.md` 檢查今天已存在的 Prometheus targets 與 `ServiceMonitor` / `PodMonitor` 現況。
2. 對照 repo 內 WeaMind `Deployment` / `Service`，判斷 app metrics 若要接進來，最小修改點會落在哪。
3. 視現況決定今天是走「驗證既有 cluster metrics + Grafana dashboard」還是「補最小 app scrape skeleton」。
4. 只有在主要實作閉環完成後，再回 `02-qa.md` 做 post-implementation QA。
5. 若過程中出現 implementation-specific 設計取捨或實作補充，同步整理到 `05-note.md`。
6. 最後回 `04-report.md` 收斂今天真正打通或確認缺口的部分。

## 文件分工

1. `01-outline.md`：宣告今天套用 `implement-heavy`，並寫清楚主題、邊界、驗收與回退點。
2. `02-qa.md`：記錄 post-implementation QA 的短版定位題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的內容。
4. `05-note.md`：記錄一般 lesson 延伸問答、實作補充、暫時結論與卡片素材。
5. `06-implementation.md`：記錄今天 target discovery、`ServiceMonitor` / `PodMonitor` 與 dashboard 驗證的主體 step。

## 這份 lesson 的完成標準

1. 能講出 Prometheus target discovery 與 `ServiceMonitor` / `PodMonitor` 的最小角色分工，而且答案能對回叢集內真實資源。
2. 能指出 WeaMind app 指標若要被 scrape，目前是已打通、部分打通，還是卡在 `/metrics` 暴露層，並留下可複習證據。
3. 能以 W7 demo MVP 視角說清楚今天到底完成了哪一段 dashboard / metrics 鏈路，而不是籠統說「有裝 Grafana」。
