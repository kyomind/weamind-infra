# 來自書中截圖的 Kubernetes Prework 總綱

## Prework 內容

### 這份文件要做什麼

這份總綱只負責把這 18 張照片背後的知識元素重新分群、排順序，整理成之後可逐份展開的 prework 地圖。

詳細的 prework 格式、段落骨架與輸出規則，直接沿用 `learning/prework/README.md` 和 `learning/prework/prework-template.md`。這裡不重複寫一次。

重點只保留三件事：

1. 哪些主題值得先學。
2. 每個主題的最小理解骨架是什麼。
3. 建議先後順序如何安排。

---

### 目前學習背景

你現在不是從零開始，所以這批照片比較適合拿來補深一層語意、收斂骨架，順便把還沒系統化處理的邊角補起來。

---

### 18 張照片可以整理成的主題池

### A. kubectl 與操作介面

對應元素：

1. kubectl 是 Kubernetes 的命令列入口。
2. Dashboard 是輔助 UI，不是主要操作心智模型。
3. `kubectl apply`、`create`、`edit`、`scale`、`rollout`、`port-forward` 這些操作其實分屬不同層次。

### B. Pod 與生命週期

對應元素：

1. Pod 是最小執行單位。
2. Pod phase。
3. restart policy。
4. init container。
5. probe 在 Pod 穩定運行中的角色。

### C. Service 與存取方式

對應元素：

1. Service 是什麼。
2. Service 如何挑一群 Pod。
3. `port-forward` 的定位。
4. 什麼時候該看 Service，什麼時候不該直接跳進 Pod。

### D. Deployment 的日常操作

對應元素：

1. `scale` 調整副本數。
2. `rollout history` 與 rollback。
3. 修改 `spec.template` 才會形成新的 revision。
4. Deployment 管理更新，Pod / restart policy 管容器重啟，這兩層不要混。

### E. Cluster 元件與控制平面

對應元素：

1. Node 是 Pod 真正運行的主機。
2. kube-apiserver。
3. kube-scheduler。
4. kube-controller-manager。
5. etcd。

### F. 設定管理與封裝

對應元素：

1. Kustomize 的 base / overlay / patch 心智模型。
2. Kustomize 想解什麼問題。
3. Helm 與 Kustomize 的差異。

---

### 建議拆成 5 份 prework，不照書本順序

下面這 5 份是我認為最合理的拆法。它們不是正式排程，只是之後若要逐份展開時，最順的依賴順序。

---

### Prework 1：Kubectl 作為 Kubernetes 操作入口

#### 為什麼先學這份

這批照片裡最底層的共通點，不是 Pod 或 Service，而是「你到底在用什麼方式跟叢集互動」。

如果這層先清楚，後面看到 `apply`、`describe`、`scale`、`rollout`、`port-forward` 才不會變成一堆孤立指令。

#### 吸收哪些照片元素

1. kubectl 介紹。
2. Dashboard 介紹與限制。
3. `kubectl create`、`apply`、`edit`、`scale`。
4. `kubectl port-forward`。

#### 這份 prework 要建立的最小骨架

1. kubectl 是連到 kube-apiserver 的主要入口，不只是 CLI 工具箱。
2. 不同 kubectl 子命令在做的事不同：有的是宣告資源、有的是改期望狀態、有的是看狀態、有的是建立臨時觀察通道。
3. Dashboard 是輔助視覺化工具，不應取代對資源模型與 kubectl 的理解。
4. `port-forward` 比較像臨時觀察 / 本地驗證通道，不是正式對外暴露方案。

#### 和你目前進度的關係

你已經會用 `describe`、`logs`、`exec` 做 debug，所以這份不是從零學 kubectl，而是把已經會用的工具重新放回一個比較完整的 API / 資源操作框架中。

#### 先不要展開什麼

1. 不先講所有 kubectl 子命令大全。
2. 不先進 RBAC、context 切換細節。
3. 不先講 Dashboard 安裝與權限配置。

#### 學完後應能帶回來的問題

1. 在 WeaMind 裡，哪些 kubectl 指令是在改期望狀態，哪些是在拿執行期證據？
2. 為什麼你在 debug 時多半先用 kubectl，而不是先找 Dashboard？

---

### Prework 2：Pod 生命週期補強版

#### 為什麼排第二

你已經學過 probe、Deployment 管理鏈、debug 工具，但書中這批照片補的是另一層：Pod 自己在生命週期中有哪些狀態、哪些重啟規則、哪些初始化機制。

這一份能把你現在對 Pod 的理解從「會 debug」補成「知道 Pod 內部是怎麼一路走到 Running / Failed / Restart」。

#### 吸收哪些照片元素

1. Pod 是核心單位。
2. Pod phase。
3. restart policy。
4. init container。
5. probe 與 Pod 穩定運行的關聯。
6. `kubectl create -f` / `apply -f` 建立 Pod。

#### 這份 prework 要建立的最小骨架

1. Pod phase 是 Kubernetes 對 Pod 整體生命週期的高階狀態，不等於 container 內部每個細節。
2. restart policy 是 Pod 層級對 container 終止後的重啟規則，不是 Deployment rollout 策略。
3. init container 是主容器啟動前的前置步驟，適合做依賴檢查或初始化工作。
4. probe 是 Pod 進入穩定服務狀態後的健康判斷機制，和 phase、restart、init container 彼此相關但不相同。

#### 和你目前進度的關係

你已經能分清 readiness / liveness，也會看 `describe pod`、`logs --previous`。這份要補的是：這些工具背後在觀察 Pod 哪個階段、哪個機制。

#### 先不要展開什麼

1. 不先講 StatefulSet、Job、CronJob 的完整差異。
2. 不先展開所有 container lifecycle hooks。
3. 不先做大量 YAML 寫作題。

#### 學完後應能帶回來的問題

1. 在 WeaMind 的 line-bot Pod 裡，哪些狀態屬於 phase，哪些屬於 container state 或 probe 狀態？
2. 為什麼 Deployment 的 rolling update 和 Pod 的 restart policy 不能混成同一件事？

---

### Prework 3：Service 與本地觀察通道

#### 為什麼排第三

你前面已經學過 Service / Ingress 流量骨架，但這批照片比較像是在補 Service 的抽象定義，以及 `port-forward` 這種「不是正式流量路徑，但很常拿來觀察」的入口。

這份比較適合放在 Pod 生命週期之後，因為你先理解 Pod，再回頭看 Service 挑 Pod、對外如何暫時接近它，會比較穩。

#### 吸收哪些照片元素

1. Service 是什麼。
2. Service 如何透過 selector 指向一群 Pod。
3. `kubectl port-forward` 的定位。
4. Dashboard 與 GUI 工具對理解的幫助與限制。

#### 這份 prework 要建立的最小骨架

1. Service 是穩定入口與流量抽象，不是單純「一個網址」而已。
2. Service 挑的是一組符合條件的 Pods，不是綁死某一顆 Pod。
3. `port-forward` 是從本機暫時打到某個 Pod 或 Service 的觀察手段，不等於正式網路設計。
4. GUI 能幫助初學，但真正排錯時仍要回到資源、selector、endpoints、連通路徑這些結構。

#### 和你目前進度的關係

你其實已經很熟 WeaMind 的 Service → Endpoints → Pod 這條路。這份不是補專案路徑，而是把 Service 的抽象層和 `port-forward` 的用途補得更乾淨。

#### 先不要展開什麼

1. 不先講 kube-proxy、iptables、IPVS 深水區。
2. 不先講完整 NetworkPolicy。
3. 不先展開多種 Service discovery 細節。

#### 學完後應能帶回來的問題

1. 在 WeaMind 裡，哪些情況適合先看 Service / Endpoints，哪些情況更像 Ingress 或外部 LB 問題？
2. 為什麼 `port-forward` 能幫你縮圈，但不能證明整條對外入口都正常？

---

### Prework 4：Deployment 日常操作與 revision 心智模型

#### 為什麼排第四

你已經學過 rollout status、conditions、strategy，但書中照片補的是比較操作層的觀念：`scale`、`edit`、revision、`rollout history`、rollback。

這份不是再講 Deployment 是什麼，而是把「平常怎麼改、怎麼看版本、怎麼回退」補成一條完整操作線。

#### 吸收哪些照片元素

1. `kubectl scale deployment --replicas`。
2. `kubectl edit deploy`。
3. `rollout history`。
4. rollback。
5. 只有 `spec.template` 的變更才會形成新的 revision。

#### 這份 prework 要建立的最小骨架

1. Deployment 的某些修改只是改期望數量，有些修改會真的形成新版 Pod 模板。
2. `replicas` 變更不一定產生新的 revision，但 `spec.template` 內的變更會。
3. `rollout history` 是在看 Deployment 的版本演進，不是在看 Pod 重啟歷史。
4. rollback 回的是 Deployment 模板版本，不是把所有 runtime 問題自動修好。

#### 和你目前進度的關係

你已經會看 rollout status，也知道 strategy / conditions 的差異。這份會把你現有理解再往「版本史與回滾」這條線補完整。

#### 先不要展開什麼

1. 不先進 GitOps / Argo CD / progressive delivery。
2. 不先講 canary、blue-green 等進階發布策略。
3. 不先談 production rollback SOP 細節。

#### 學完後應能帶回來的問題

1. 在 WeaMind 目前的 Deployment 裡，哪些修改只是在調整副本數，哪些修改會真的換出新一版 Pod？
2. 為什麼 `CrashLoopBackOff` 問題不能直接理解成「用 rollout undo 就好」？

---

### Prework 5：Cluster 元件與設定管理

#### 為什麼最後才學這份

這裡其實是兩組主題：一組是 cluster 元件，另一組是 Kustomize / Helm。它們都重要，但比起 Pod / Service / Deployment 的第一線理解，更適合放在後面，因為它們比較偏「架構與配置方法論」。

#### 吸收哪些照片元素

1. Node。
2. kube-apiserver、kube-scheduler、kube-controller-manager、etcd。
3. Kustomize 的 base / overlay / patch 心智模型。
4. Helm 與 Kustomize 的差異。

#### 這份 prework 要建立的最小骨架

1. kube-apiserver 是所有資源操作的 API 入口。
2. scheduler 負責決定 Pod 去哪個 node。
3. controller-manager 會持續把實際狀態拉回期望狀態。
4. etcd 保存叢集狀態資料。
5. Kustomize 是在既有 YAML 上做組合與 patch。
6. Helm 偏向模板化與套件生命週期管理，Kustomize 偏向原生 YAML 疊加。

#### 和你目前進度的關係

你已經能講 Scheduler / kubelet，也理解 control-plane / worker。這份可以把 control-plane 元件補完整，再順勢接到「那設定檔平常怎麼管理」這個層次。

#### 先不要展開什麼

1. 不先講 kubeadm 安裝細節。
2. 不先講 etcd 高可用與備份策略。
3. 不先做 Helm chart 寫作實作。
4. 不先做 Kustomize 實際 patch 練習。

#### 學完後應能帶回來的問題

1. 在 WeaMind 這種小型 K3s 專案裡，哪些 control-plane 元件的理解最值得拿來講架構與 debug？
2. 這個 repo 目前直接放 manifests；如果未來要分環境，Kustomize 或 Helm 分別會帶來什麼取捨？

---

### 優先順序建議

如果你不是要一次吃完全部，我建議優先順序如下：

1. Prework 2：Pod 生命週期補強版
2. Prework 5：Cluster 元件與設定管理
3. Prework 1：Kubectl 作為 Kubernetes 操作入口
4. Prework 4：Deployment 日常操作與 revision 心智模型
5. Prework 3：Service 與本地觀察通道

這樣排的理由是：

1. 你現在最不缺的是 Service / Ingress 的基本骨架。
2. 你目前最值得補的是 Pod 生命週期深一層的語意，以及 control-plane 元件與設定管理這兩塊新主題。
3. kubectl 那份很重要，但更像幫你把已經會用的東西重新收斂，不一定要放第一份。

---

### 哪些元素我刻意降權處理

#### Dashboard

這批照片裡有幾頁提到 Dashboard，但以你目前的學習方向來看，Dashboard 更適合被當成一個對照物，而不是獨立主題。

原因是：

1. 你現在的主線是能講清楚架構、能 debug、能面試。
2. 這三件事的主力工具仍然是 kubectl 與資源模型，不是 GUI。
3. 所以 Dashboard 我把它併進 Prework 1 或 Prework 3 裡當補充，不另外拆一份。

#### 書中的零散操作片段

像 `kubectl create -f`、`edit deploy`、`scale` 這些，我沒有各自拆成單獨 prework，因為它們比較適合被收進「操作心智模型」或「Deployment revision」裡，不然會太碎。

---

### 下一步可以怎麼做

這份總綱之後可以直接拿來挑一份展開成正式 prework；如果要實用優先，我建議先從 Prework 2 或 Prework 5 開始。

## 學習報告

這裡是回填區，細節格式仍沿用 `learning/prework/prework-template.md`。

### 今日學到什麼

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 VS Code 的問題

1.
2.
