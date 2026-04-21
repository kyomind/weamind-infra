# 2026-04-21 Helm Kube Prometheus Stack Basics Outline

## 今日主題

- 用 Helm 在 WeaMind 的 K3s 叢集安裝 `kube-prometheus-stack`，並把 Helm、release、chart、values 與主要元件分工先建立成一版可驗收的最小骨架。

## 今日套用的 lesson mode

- `implement-heavy`

## 為什麼今天要套用 implement-heavy mode

1. 今天的主體不是先做 repo-backed QA，而是要真的在叢集上完成一次最小 Helm 安裝。
2. 驗收重點是安裝是否成功、建立了哪些資源、要如何驗證 Prometheus / Grafana / supporting components 已經起來，而不是單純理解名詞。

## 這次要解的專案問題

1. Helm 在這次安裝裡實際扮演什麼角色，和直接 `kubectl apply` raw manifests 有什麼最小差異。
2. `kube-prometheus-stack` 這個 chart 裡，Prometheus Operator、Prometheus、Grafana、Alertmanager、Node Exporter、`kube-state-metrics` 分別站在什麼位置。
3. 在 WeaMind 這種既有 K3s 叢集裡，要怎麼完成一次最小安裝，又不把今天的範圍膨脹成 production-grade observability 設計。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：W7 Day 1 的兩份 prework 已經把 Metrics Server / Prometheus / Grafana / Alertmanager 的最小角色邊界切清楚。今天的重點是把這些骨架接到 Helm 安裝、chart 元件地圖與叢集內真實資源。

## 要對照的 repo 檔案

1. `.privatedocs/Phase2三週計畫.md`
2. `references/phase2/w7-observability-minimum-spec.md`
3. `learning/prework/2026-04-20-metrics-server-kubectl-top-hpa-basics.md`
4. `learning/prework/2026-04-20-prometheus-grafana-alertmanager-basics.md`
5. `docs/Kubernetes-Dashboard-臨時安裝紀錄.md`

## 今日實作邊界

1. 今天先追求 `kube-prometheus-stack` 的最小安裝與元件辨識，不展開 PromQL、Alert rule、Grafana dashboard 設計或 app metrics 掛點。
2. 今天先接受使用 chart 預設值或最小必要設定，不把範圍擴成完整客製 values 架構設計。
3. 今天的成功標準是能說清楚 Helm release 與 chart 安裝產生了哪些核心資源，並驗證它們在叢集裡已成功建立。

## 驗收訊號與回退點

### 驗收訊號

1. 能成功以 Helm 安裝一個 `kube-prometheus-stack` release。
2. 叢集內至少可觀察到 Prometheus、Grafana 與一組 supporting components 已建立且進入可用狀態。
3. 能用自己的話指出今天實際看到了哪些 namespace / resource / workload，並把它們對回 chart 主要元件分工。

### 回退點

1. 若 chart 安裝失敗，先縮回 Helm repo、cluster access、target namespace、release name 與 chart version 這幾個最小前提，不急著追 values 細節。
2. 若 release 建立成功但 Pod 不健康，先在 `06-implementation.md` 的對應 step 補 `helm status`、`kubectl get pods`、`kubectl describe` 與 `events` 這條最小證據鏈，不要先擴成 app metrics 問題。
3. 若今天 install 成功但還沒來得及做 dashboard 或對外存取，仍算 lesson 主線完成；GUI 存取與進一步觀察可留到後續收尾。

## 建議學習順序

1. 先用 `06-implementation.md` 確認今天的實作主體、驗收訊號與每個 step 的操作閉環。
2. 先做 cluster 與 Helm 前置驗證，確認本機 CLI 到遠端 K3s API 的控制鏈是通的。
3. 再確認 chart repo / release / namespace 的最小安裝策略，避免一開始就陷入 values 細節。
4. 完成 install 後，直接在 `06-implementation.md` 補最小驗證證據，確認核心 workload 是否建立並進入穩定狀態。
5. 只有在實作主體完成後，再回 `02-qa.md` 做 post-implementation QA 的短版定位題收斂。
6. 若過程中出現 implementation-specific 補充觀察，同步整理到 `07-implementation-note.md`。
7. 最後回 `04-report.md` 收斂成一版可口述的 W7D2 結論。

## 文件分工

1. `01-outline.md`：宣告今天套用 `implement-heavy`，並寫清楚主題、邊界、驗收與回退點。
2. `02-qa.md`：記錄 post-implementation QA 的短版定位題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的內容。
4. `05-note.md`：記錄一般 lesson 延伸問答、暫時結論與卡片素材。
5. `06-implementation.md`：記錄今天的安裝主體與每個 step 的實作閉環，包含必要的驗證證據。
6. `07-implementation-note.md`：承接 `06` 過程中的 implementation-specific 關鍵觀察與決策討論。

## 這份 lesson 的完成標準

1. 能完成一次 `kube-prometheus-stack` 的最小 Helm 安裝，並保留可複習的驗證證據。
2. 能指出 chart 內幾個主要元件各自做什麼，且這個回答能對回今天實際建立的資源。
3. 能用 WeaMind 脈絡講出 Helm release 與 raw manifests 的最小差異，不把兩者混成抽象口號。
