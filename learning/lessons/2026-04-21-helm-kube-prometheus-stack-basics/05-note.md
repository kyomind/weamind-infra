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

## Alertmanager 為什麼也常用 `StatefulSet`

- Alertmanager 不像 Prometheus 那樣是完整的 time-series database，但它也不是完全無狀態的純 web app。
- 它常被放在 `StatefulSet`，主要是因為它仍需要相對穩定的身份與資料邊界，例如 silences、notification log，以及高可用模式下的 peer 協調狀態。
- 更白話一點說，Alertmanager 雖然通常比 Prometheus 輕，但它也不是那種可以任意漂移、完全不在意身份與持久化的元件，所以 chart 常直接把它放在 `StatefulSet` 這個較穩的工作負載模型裡。
- 這題最好的收斂不是「它是不是資料庫」，而是「它有沒有穩定身份與狀態邊界需求」。用這個角度看，就比較能理解它為什麼不是單純的 `Deployment`。

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

## 今天這套 observability stack 到底哪些元件已經可用

- 從 high level 來看，今天已經不是「只有 chart 裝上去」，而是幾個核心元件都已進入可使用但尚未進一步展示或客製的狀態。
- Prometheus 已經在運作，而且不是空殼。因為 Prometheus Pod / `StatefulSet` 都已 `Ready`，同時 Node Exporter、`kube-state-metrics`、多個 `ServiceMonitor` 與 `PrometheusRule` 也都已建立，表示它已具備開始收集 cluster / node / k8s objects metrics 的基礎。
- Node Exporter 已經在運作，因為 `DaemonSet` 已 `READY 3/3`，代表每個 Linux node 上都已有一份 exporter 在提供 node 層 metrics。
- `kube-state-metrics` 已經在運作，表示 Kubernetes objects / state 類型的 metrics 也已能被提供出來。
- Prometheus Operator 也已在運作，表示這套 stack 的 operator 模型已成立，後續要講 `ServiceMonitor`、`PodMonitor`、Prometheus / Alertmanager CRD 等東西時，已經有 controller 在接手。
- Alertmanager 也已部署完成並可用，但今天還沒有進一步設定通知路由，所以目前比較像「服務已在、後續再配置通知策略」的狀態。
- Grafana 也已部署完成並可用，而且 chart 已替它準備資料來源與一批 dashboard 相關 `ConfigMap`；只是今天還沒有做登入、`port-forward` 與實際 UI 驗證，所以它目前是「可用但尚未展示」的狀態。
- WeaMind app 自己的業務 metrics 還沒有接進來，所以今天能說的是：cluster / node / k8s 基礎觀測鏈已經成立，但 app-specific metrics 與 demo dashboard 會留到 W7 Day 3。

## Implementation 過程補充觀察

### 為什麼 `helm status` 也會像卡前景一樣慢一下

- `helm status` 不是單純回一行「成功 / 失敗」而已。對 `kube-prometheus-stack` 這種大型 chart，它會整理 release metadata，還會把許多已建立的 resources 一起列出來。
- 所以它雖然不是 watch 指令，但也不像 `kubectl get ns` 這種很薄的查詢。chart 越大、資源越多，體感上越可能像前景卡一下。
- 這次的實際輸出也證明了這件事：它不只回 `STATUS: deployed`，還展開了 Alertmanager、Prometheus、Service、PrometheusRule、ServiceMonitor、Deployment、StatefulSet、DaemonSet 等大量資源資訊。

### install 後大量的 `observability-...` 名稱是怎麼來的

- 這些名稱主要不是 namespace 自動決定，而是 chart 依 Helm release name 組合出來的資源命名結果。
- 這次真正由我們手動決定的，至少有兩個重要值：release name `observability` 與 namespace `observability`。
- chart 模板通常會把 release name 拼進資源名，所以你才會看到像 `observability-grafana`、`observability-kube-state-metrics`、`observability-kube-prometh-operator` 這種前綴很一致的名字。
- 但它也不是只有簡單前綴拼接而已，像 `prometheus-observability-kube-prometh-prometheus`、`alertmanager-observability-kube-prometh-alertmanager` 這種名字，還混合了 chart 內部對元件角色的命名規則。
- 這也是為什麼這題應該被理解成「Helm release name 加上 chart 模板的命名策略」，而不是只看 namespace 一個因素。

## Flashcards

- `chart`、`release`、`values` 在 Helm 各自回答什麼問題？ #DevOps #card
	- `chart` 是安裝藍圖，包模板、預設值與要建立的一組資源
	- `release` 是某個 chart 在 cluster / namespace 裡實際安裝出來的實例
	- `values` 是這次實例化時帶入的參數，今天先採用預設值做最小安裝

- 為什麼 Helm 不能簡化成只是另一種 `kubectl apply`？ #DevOps #card
	- `kubectl apply` 比較像送既定 manifest 到 API server
	- Helm 多了模板渲染、values 覆蓋、release 管理、revision 與 upgrade / rollback 邊界
	- 這次看到的 `REVISION: 1` 就是 release 管理層的直接證據

- 這次 `kube-prometheus-stack` 的核心元件對應到哪些 workload？ #DevOps #card
	- Grafana、Prometheus Operator、`kube-state-metrics` 是 `Deployment`
	- Prometheus 與 Alertmanager 是 `StatefulSet`
	- Node Exporter 是 `DaemonSet`

- 為什麼 Node Exporter 用 `DaemonSet` 最合理？ #DevOps #card
	- 它的任務是每個 node 都各跑一份 exporter
	- 這正是每節點型工作負載的典型模型
	- `READY 3/3` 代表每個 Linux node 都已有一份在提供 node metrics

- 如果 Helm release 建了，但 Pod 起不來，第一輪應怎麼縮圈？ #DevOps #card
	- 先看 `helm status`，確認 release 層有沒有明顯失敗訊號
	- 再看 `kubectl get pods` 找出壞掉的 workload
	- 最後對特定 Pod 做 `describe` 或看 `events`
	- 在核心 workload 還沒穩之前，不跳去 app metrics 或 dashboard

- Prometheus 為什麼有狀態，卻仍然可以部署在 Kubernetes 內？ #DevOps #card
	- 關鍵不是能不能進 Pod，而是不能把它當 stateless web app 處理
	- 它需要穩定身份、持久化儲存與適合的升級模型
	- 所以更合理的做法是用 `StatefulSet` 加持久化來管理

- WeaMind 這種小型 K3s cluster，為什麼先把 Prometheus / Grafana 放在 cluster 內是合理 baseline？ #DevOps #card
	- 部署最直接，discovery 與 `ServiceMonitor` 模型最自然
	- 權限與網路邊界一致，符合 `kube-prometheus-stack` 的預期使用方式
	- 在還沒碰到 retention、跨 cluster 或平台獨立維運需求前，不需要先搬到堡壘機
