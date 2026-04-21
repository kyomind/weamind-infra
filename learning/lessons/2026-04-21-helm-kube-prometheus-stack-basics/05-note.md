# 2026-04-21 Helm Kube Prometheus Stack Basics Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天先完成 `kube-prometheus-stack` 的最小安裝與元件辨識，不追求 production-grade observability 設計。
- 今天可以先使用 chart 預設值或最小必要設定，不把範圍擴成完整 values 架構規劃。
- 今天先把 Helm install、resource 驗證與元件角色說清楚；dashboard、PromQL、alerting、app metrics 掛點留到後續 lesson。

### Repo 對照文件與觀察點

- `.privatedocs/Phase2三週計畫.md`：確認今天是 W7 Day 2、`implement-heavy`，以及最低驗收標準。
- `references/phase2/w7-observability-minimum-spec.md`：提醒今天 install 的最終去向是 W7 的 Node 3、App 4、1 個 dashboard，但不是今天一次做完。
- `learning/prework/2026-04-20-prometheus-grafana-alertmanager-basics.md`：回收 Prometheus / Grafana / Alertmanager 的角色骨架。
- `docs/Kubernetes-Dashboard-臨時安裝紀錄.md`：對照 Helm CLI 在本機、資源建立在遠端叢集這個操作邊界。

### 暫時不在今天展開的點

- PromQL 與 alert rule 細節
- Grafana dashboard 視覺設計
- WeaMind app metrics 實作與 `/metrics` 掛點

## Notes

## Prometheus 為什麼有狀態，仍然可以部署在 Kubernetes 內

- Prometheus 確實是 time-series database，所以它不是 stateless 元件；但這不等於它不能跑在 Kubernetes 裡，而是代表它不能再用 stateless 的方式亂放。
- 這次輸出已經直接顯示出正確做法：Prometheus 與 Alertmanager 走的是 `StatefulSet`，不是 `Deployment`。這表示 Kubernetes 並不是把它們當成一般無狀態 Pod，而是用適合有狀態工作負載的模型在管理。
- 更精準地說，大家真正擔心的不是「有狀態不能進 Pod」，而是「有狀態工作負載需要穩定身份、持久化儲存、升級策略與資料生命週期設計」。
- 所以這題比較好的講法是：Prometheus 可以放在 Kubernetes，但前提是要用對 workload model，例如 `StatefulSet` 加持久化，而不是把它當成普通 web app 那樣處理。

## Grafana 和 Prometheus 在實務上更常 in-cluster，還是獨立部署

- 單一 cluster、自己管 observability、想快速建立 baseline 的情境下，像今天這樣直接部署在 Kubernetes cluster 內，其實很常見。
- 規模再大一點時，常見做法會變成「收集在 cluster 內，長期儲存或集中查詢在外部平台」，例如 Thanos、Mimir、Cortex、VictoriaMetrics 或各種 managed service。
- 如果團隊不想自己維運整套 TSDB、retention、跨 cluster 查詢與告警，也常直接用雲端或 SaaS 的 managed Prometheus / managed Grafana。
- 所以不是只有一種唯一正解，而是要看規模與維運邊界。對今天這種 W7 baseline 來說，in-cluster 是合理且常見的第一步；對長期 production 大規模環境，集中化或 managed 也很常見。

## Flashcards

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的整理出卡片素材後再填。 -->
