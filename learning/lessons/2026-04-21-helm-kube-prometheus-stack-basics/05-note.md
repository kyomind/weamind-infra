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

## 小型 cluster 要不要把 Prometheus 和 Grafana 直接放在 cluster 內

- 我的預設建議是：像 WeaMind 這種小型、低流量、自管 K3s 環境，直接放在 cluster 內是對的，通常也是最省事、最穩的做法。
- 這樣做的好處很實際：部署最直接、ServiceMonitor / discovery 最自然、權限與網路邊界一致，也最符合 `kube-prometheus-stack` 這種整套觀測堆疊的預期使用方式。
- 除非你已經明確碰到 retention、磁碟、跨 cluster 聚合或 observability 平台獨立維運需求，不然現在把 Prometheus / Grafana 特地搬到堡壘機，多半是在提早承擔額外維運成本。

## 堡壘機剩餘資源更適合拿來做什麼

- 若現在堡壘機很空，我不建議為了「不要浪費」就把 Prometheus / Grafana 硬搬過去；比較好的做法是把這些餘裕保留給資料層與系統層的穩定性。
- 更務實的優先用途通常是：PostgreSQL / Redis 的 buffer 與快取空間、備份與還原工具、log rotation / system monitoring、未來可能要加的 exporter 或 maintenance job。
- 一句話說，堡壘機的空閒資源比較適合當穩定性緩衝，而不是為了填滿它去搬本來就很適合留在 cluster 內的 observability 元件。

## 怎麼判斷 Prometheus / Grafana 在 cluster 裡算不算吃資源

- 不要用「Pod 好像不多」來判斷；比較穩的做法是看三層：`requests/limits`、實際 usage、以及放回 node 容量後的相對占比。
- `requests/limits` 回答的是：這套東西理論上跟 scheduler 要多少資源，會不會一開始就擠壓原本的 workload。
- 實際 usage 回答的是：它現在真的吃多少 CPU / memory；這一層最該先盯的是 Prometheus，其次才是 Grafana，因為 Prometheus 比較容易隨著 target、retention、rules 慢慢變胖。
- node 占比回答的是：這些 usage 放回節點容量後，是否已經造成可觀察的壓力。單看 `500Mi` 或 `50m CPU` 沒意義，要看它占該節點總量的比例。
- 實務上可用的最小順序是：先看 workload 的 `requests/limits`，再看 `kubectl top pods`，最後看 `kubectl top nodes`；三層一起看，才像真的在做資源判讀。

## 這次 install 後的最小資源判讀

- 就這次量到的結果看，這套 `kube-prometheus-stack` 在 WeaMind 目前這個小型 cluster 上**不算重**，至少還看不到明顯資源壓力。
- Pod usage 裡最值得注意的是 Prometheus 與 Grafana：Prometheus 約 `46m CPU / 511Mi memory`，Grafana 約 `12m CPU / 380Mi memory`；其他元件都相對輕。
- Node usage 也支持同一個結論：三個節點目前大約落在 `3%` 到 `9%` CPU、`34%` 到 `38%` memory，沒有出現 install 後明顯被 observability stack 壓垮的跡象。
- 所以這次比較準確的說法是：Prometheus / Grafana 確實有在吃資源，但以目前規模來看屬於**吃得起、而且合理**的範圍；還不到需要因為它們而改架構的程度。
- 若之後要繼續追，下一輪才值得回頭看 `requests/limits`、retention、scrape interval 與 targets 數量，確認 Prometheus 不會在後續 lesson 裡逐步變胖。

## Flashcards

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的整理出卡片素材後再填。 -->
