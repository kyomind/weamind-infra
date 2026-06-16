# 2026-06-15 Workload Types DaemonSet StatefulSet Basics

## Prework 內容

### 今日焦點

- 主題：CKA 取向的 `DaemonSet` 與 `StatefulSet` 重學
- 範圍：用 `Deployment` 當基準，重新建立 `DaemonSet`、`StatefulSet` 的用途差異、最小 YAML 心智模型與考試處理方式
- 目標：看到題目時能判斷應該用哪種 workload，知道最小欄位要看哪裡，並能用白話講清楚為什麼不是普通 `Deployment`
- 時間：控制在 45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 這次不要把 `DaemonSet` 和 `StatefulSet` 展開成 Kubernetes controller 大百科。請用 CKA 考試比例較小、但容易混淆的角度，幫我補回最小可用骨架。
- 請優先幫我建立通用心智模型；WeaMind repo 內的實際 YAML、Prometheus、Alertmanager、Node Exporter、`svclb-traefik` 對照，之後再回 repo 內處理。

### 今天一定要學會的最小骨架

1. `Deployment` 管的是一組可替換、可伸縮的 stateless-ish replicas；重點是數量、自動修復與 rollout。
2. `DaemonSet` 管的是每個符合條件的 node 各跑一份 Pod；重點是 node-level coverage，不是 replicas 數量。
3. `StatefulSet` 管的是有穩定身份與狀態邊界的 replicas；重點是固定 pod identity、穩定 DNS、常見的 PVC 搭配與有序管理。
4. `DaemonSet` 的典型例子是 node exporter、log agent、每節點入口代理；`StatefulSet` 的典型例子是 Prometheus、資料庫、需要 peer identity 的元件。
5. CKA 角度不需要從零背完整 YAML；要知道 `apps/v1`、`selector.matchLabels` 與 `template.metadata.labels` 必須對上，並知道 `DaemonSet` / `StatefulSet` 通常要從官方文件範例改。
6. 不要把「有多個 Pod」當成判斷依據；要問的是這組 Pod 為什麼存在：服務副本、每節點能力，還是有狀態身份。

### 建議教學順序

1. 先用一張對照表切開 `Deployment`、`DaemonSet`、`StatefulSet`：它們各自回答什麼問題、適合什麼 workload、不適合什麼情境。
2. 用白話例子講 `DaemonSet`：為什麼 node exporter / log agent 需要每個 node 一份，而不是只開 3 replicas 的 `Deployment`。
3. 用白話例子講 `StatefulSet`：為什麼 Prometheus / database / peer-aware component 不能只當成普通可任意替換的 `Deployment`。
4. 帶我看最小 YAML 結構差異，但只講 CKA 必要欄位：`apiVersion`、`kind`、`metadata`、`spec.selector`、`spec.template`、`serviceName`、`volumeClaimTemplates` 的角色。
5. 補一段 CKA 解題策略：什麼情況直接用 `kubectl create deployment --dry-run=client -o yaml` 改，什麼情況應去官方文件複製 `DaemonSet` / `StatefulSet` 範例再改。
6. 用 5 個小情境讓我判斷該選 `Deployment`、`DaemonSet` 還是 `StatefulSet`，並要求我說出理由。

### 請特別幫我釐清的混淆點

1. `DaemonSet` 不是「很多 Pod」；它是「每個符合條件的 node 各一個」。
2. `StatefulSet` 不是「只要有 PVC 就一定要用」；它處理的是穩定身份、穩定網路名稱、資料與副本生命週期邊界。
3. `Deployment` 也可以掛 PVC，但這不代表它就能自然取代 `StatefulSet`。
4. `StatefulSet` 的 Pod 名稱穩定，例如 `web-0`、`web-1`，這件事和 Service discovery / peer identity 有關。
5. CKA 題目若要建立 `DaemonSet` 或 `StatefulSet`，不要浪費時間硬背完整 YAML；請教我如何快速從官方範例改成可用答案。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 repo 內後，應該拿去做專案對照的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

- 今天重新建立了 `Deployment`、`DaemonSet`、`StatefulSet` 的最小 workload 選型模型。
- 看到一組 Pods 時，不應先問「有幾個 Pod」，而要先問「為什麼這組 Pod 存在」。
- `Deployment` 回答的是「我要幾個服務副本」，重點是 replicas、自動修復、rolling update 與 rollback。
- `DaemonSet` 回答的是「每個符合條件的 Node 是否都有一份」，重點是 node coverage，而不是 Pod 總數。
- `StatefulSet` 回答的是「這些 Pods 是否需要穩定身份」，重點是 identity、穩定名稱、穩定 DNS、資料與副本生命週期邊界。
- `PVC` 不是 `StatefulSet` 的本體；`Deployment` 也可以掛 PVC。真正要判斷的是 Pod 是否需要固定身份。
- `volumeClaimTemplates` 的價值是讓 `StatefulSet` 為每個固定身份的 Pod 自動建立對應 PVC，例如 `web-0` 對自己的 data PVC。
- CKA 解題時不用硬背完整 YAML：`Deployment` 可先用 `kubectl create deployment --dry-run=client -o yaml` 生骨架；`DaemonSet` / `StatefulSet` 通常從官方文件範例複製再改。

### 已能白話講清楚什麼

- `Deployment`：我要幾個可替換的服務副本，Pod 名稱與身份通常不重要，誰接請求都可以。
- `DaemonSet`：我要每個符合條件的 Node 都有一份，例如 Node Exporter 或 log agent，因為每台機器都有自己的 CPU、memory、disk、network 或 logs 要收集。
- `StatefulSet`：我要固定身份的 Pod，例如 `web-0`、`web-1`；Pod 重建後仍保留同一個身份，適合 Prometheus、Redis Cluster、PostgreSQL replication 這類需要身份或資料邊界的元件。
- `replicas: 3` 只保證總共有 3 個 Pods，不保證 3 個 Nodes 各有 1 個 Pod，所以它不能取代 `DaemonSet` 的 node coverage。
- 有 PVC 不等於一定要用 `StatefulSet`；Identity 才是 `StatefulSet` 的核心。
- `selector.matchLabels` 必須對上 `template.metadata.labels`，否則 controller 找不到自己管理的 Pods，`Deployment`、`DaemonSet`、`StatefulSet` 都適用這個基本規則。

### 目前還卡住什麼

- `StatefulSet`、headless Service、`serviceName`、stable DNS 與 peer discovery 之間的完整關係還沒有深入展開。
- 例如 `web-0.nginx.default.svc.cluster.local` 這類穩定 DNS 名稱如何產生，以及為什麼分散式系統會依賴它，之後可以再補一輪。
- 目前已經有 workload 選型骨架，但還沒有回到 WeaMind repo 對照實際 `kube-prometheus-stack` 與資料層取捨。

### 今日最重要的觀念

- 不要問有幾個 Pods，要問為什麼有這些 Pods。
- `Deployment` 管服務副本。
- `DaemonSet` 管 node coverage。
- `StatefulSet` 管 identity。
- 有 PVC 不等於 `StatefulSet`；Identity 才是 `StatefulSet` 的核心。

### 帶回 repo 內對照的問題

1. 在 `kube-prometheus-stack` 中，Node Exporter 為什麼是 `DaemonSet`，Prometheus 為什麼是 `StatefulSet`，Grafana 為什麼通常是 `Deployment`？請用 replica purpose、node coverage、identity 三個角度回答。
2. WeaMind 目前把 PostgreSQL 與 Redis 留在 VM，而不是搬進 Kubernetes。如果未來要搬進 Kubernetes，需要補上哪些 `StatefulSet`、PVC、StorageClass、backup 與 disaster recovery 能力？
