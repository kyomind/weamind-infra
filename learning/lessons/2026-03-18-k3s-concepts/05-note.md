# 2026-03-18 K3s Concepts Notes

## 學習注意事項

### 外部預習回帶重點

- K3s 是 Kubernetes distribution，不是另一套不同的編排系統；重點是整合與輕量化，而不是脫離 Kubernetes。
- control-plane 主要負責叢集控制與決策，worker 主要負責實際執行 workload。
- Scheduler 屬於 control-plane，負責 Pod placement；kubelet 在 node 上負責把 Pod 真的跑起來。
- kubelet 是透過 watch API Server 得知哪些 Pod 已被指派到自己，而不是由 Scheduler 直接命令 kubelet 啟動 Pod。
- kubeconfig 至少要能回答三件事：連哪個 cluster、用哪個身分、目前預設用哪個 context。

### 今天進 lesson 前先記住的邊界

- 今天不是重學一般 Kubernetes 名詞，而是把 K3s 概念對回 WeaMind 的實際設計決策。
- kubeconfig 題目先聚焦在最小連線骨架，不先展開多 cluster 管理技巧。
- rollout 補強題先處理 `rollout status`、conditions、strategy 的邊界，不先延伸到所有 Deployment controller 細節。

### 待驗證的 repo 對照點

- README 與架構文件裡，K3s 被描述成什麼樣的設計取捨，而不是只寫成「因為輕量」。
- `PROGRESS.md` 裡的 kubeconfig 與 SSH tunnel 設定，如何對回外部預習中學到的 `cluster`、`user`、`context`。
- `manifests/deployment.yaml` 雖然沒有明寫 strategy，但在預設 rolling update 下，`rollout status` 與 conditions 應該怎麼理解。

### 暫時不在今天展開的點

- Scheduler 的具體調度演算法。
- kubelet 與 container runtime 更底層的 CRI 實作細節。
- 多 cluster kubeconfig 管理技巧。

## Notes

### 今日 QA 的最小收斂

- Q1 收斂出的主幹是：WeaMind 選 K3s，不是因為它只是「比較簡單」，而是因為它在小型叢集、單人維運、成本控制與作品展示價值之間，提供了比 kubeadm 更務實、比 EKS / GKE 更可控的折衷。
- Q2 收斂出的主幹是：control-plane / Scheduler 是控制與決策這一側，worker / kubelet 是實際承載 workload 與 Pod 落地這一側；`nodeSelector.nodepool=worker` 則是把這個角色分工真正轉成 scheduler 的選節點條件。
- Q3 收斂出的主幹是：本機 kubectl 會讀 `~/.kube/config`，其中 `cluster` 定義 API server 與 CA、`user` 定義登入身分、`context` 決定目前使用哪組 cluster + user；由於 WeaMind 是透過 SSH tunnel 把遠端 API server 映射到本機 `127.0.0.1:6443`，所以 kubeconfig 的 `server` 才會改成 localhost。
- Q4 收斂出的主幹是：`kubectl rollout status` 看的是 rollout 有沒有完成；Deployment conditions 看的是物件本身較細的狀態訊號；rolling update strategy 則是在定義新舊 Pod 怎麼交接。這三者不是同一層。

### Deployment conditions 到底有哪些

- 使用者追問：Deployment conditions 究竟有哪些，除了 rollout success 之外還會看到什麼。
- 這題最小先收斂成：Deployment conditions 不是一份永遠固定超長的清單；在日常最常看到、最值得先記住的，通常是 `Available` 與 `Progressing` 兩種 condition type。
- `Available` 主要在回答：這個 Deployment 目前是否已經有足夠的可用 Pod。常見 reason 例如 `MinimumReplicasAvailable`。
- `Progressing` 主要在回答：這個 Deployment 是否仍在推進 rollout，或最近一次 rollout 是否已成功推進到新的 ReplicaSet。常見 reason 例如 `NewReplicaSetAvailable`、`ReplicaSetUpdated`，若卡住太久也可能看到和 progress deadline 有關的訊號。
- 另外還可能碰到 `ReplicaFailure`，它比較像異常訊號，表示 Deployment 底下的 ReplicaSet / Pod 建立過程出現失敗，例如拉 image、權限、配額或其他建立層面的問題。
- 所以更穩的記法不是硬背很多名稱，而是先記兩個最常見的主條件：
- `Available` 看可用性
- `Progressing` 看 rollout 推進狀態
- 若出現 `ReplicaFailure`，通常代表建立或維持副本時發生錯誤
- 在 WeaMind 這個專案過去的 command 記錄裡，已經看過 Deployment 的 conditions 範例：`Available=True` 搭配 `MinimumReplicasAvailable`，以及 `Progressing=True` 搭配 `NewReplicaSetAvailable`。這代表那次 Deployment 既有足夠可用副本，也已成功推進到新的 ReplicaSet。
- 所以如果面試或複習時要用一句話收斂，可以說：Deployment conditions 最常見先看 `Available` 與 `Progressing`，前者回答可用副本是否到位，後者回答 rollout 是否正在順利推進；若出現 `ReplicaFailure`，通常代表副本建立過程出錯。

### Kubelet 不是 worker 上所有事情的唯一入口

- 使用者追問：既然 kubelet 是 worker node 上很重要的 agent，那有哪些事情其實不需要透過 kubelet 就可以做。
- 這題的最小收斂是：kubelet 很重要，但它主要負責的是「這台 node 上 Pod 如何落地執行，以及狀態如何回報」，不是整個 Kubernetes 系統裡所有事情的唯一總入口。
- 不需要透過 kubelet 才能完成的事情，至少有幾類：
- 第一，control-plane 的決策與控制流程，例如 API 驗證、admission、controller reconciliation、Scheduler 決定 Pod placement，這些都發生在 control-plane 這一側，不是由 kubelet 負責。
- 第二，某些 node 網路與資料平面元件也不是 kubelet 本身在做，例如 Service 流量轉送通常更接近 kube-proxy 或 CNI / dataplane 元件的責任，而不是 kubelet 自己負責分流封包。
- 第三，直接的節點維運操作也不需要經過 kubelet，例如 SSH 進機器看 OS 狀態、查磁碟、看 systemd 服務、調整防火牆或檢查 container runtime 服務，這些都是 node / OS 層面的操作。
- 第四，像 Hetzner LB、Traefik 這類入口流量處理，也不是透過 kubelet 才能運作；kubelet 主要確保對應的 Pod 在 node 上被跑起來，但真正的 L4 / L7 流量承接與路由，是其他元件的責任。
- 所以更精準的說法是：在 worker node 上，「Pod 被指派到這台機器後，怎麼真的跑起來」這件事，主要要靠 kubelet；但 Kubernetes 的控制決策、網路資料平面與 node OS 維運，不是都要先經過 kubelet。

### 不同環境下的 `ROLES` 顯示不一定一樣

- 使用者追問：在 WeaMind 的 K3s 環境裡，worker 的 `ROLES` 顯示為 `<none>` 是正常的；那在 EKS 或 kubeadm 上，`ROLES` 會不會不一樣。
- 這題最重要的先收斂是：`kubectl get nodes` 的 `ROLES` 欄位不是一個跨所有發行版都完全可靠的排程依據，它通常是根據 node 上某些 role labels 推導出來的顯示結果。
- 在 kubeadm 環境裡，control-plane node 通常會顯示成 `control-plane`，較舊版本也可能看到 `master`；worker nodes 則很常仍然是 `<none>`，除非你另外加了 role label。
- 在 EKS 這類 managed Kubernetes 環境裡，control-plane 根本不是以可見 node 的形式出現在你的 `kubectl get nodes` 輸出裡，所以你通常只會看到 worker nodes。這些 worker nodes 的 `ROLES` 也常常是 `<none>`；真正比較穩定可用的，往往是雲廠商或 node group 自己加的 labels，而不是 `ROLES` 欄位本身。
- 這也代表：K3s 並不是唯一會出現 worker = `<none>` 的環境。更準確地說，很多 Kubernetes 發行版或 managed 服務裡，worker 沒有顯示成明確 role 名稱，其實都不算罕見。
- 回到 WeaMind，`PROGRESS.md` 已經記下來：K3s 裡 control-plane 顯示為 `control-plane`，worker 顯示為 `<none>` 是正常現象。因此這個專案沒有把排程限制建立在 `ROLES` 欄位，而是自己加 `nodepool=worker` label，再讓 `nodeSelector` 去匹配這個 label。這做法比依賴 `ROLES` 顯示更穩，也更可控。
- 所以這題最穩的可講版是：不同環境下 `ROLES` 顯示可能不同，甚至 worker 常常就是 `<none>`；排程限制不應建立在這個顯示欄位上，而應建立在你明確可控的 node labels、taints 與 selectors 上。

### Worker node 上不是所有事情都一定要經過 kubelet

- 使用者進一步追問：如果把範圍縮到單一 worker node 本身，那是不是凡是和這台 worker 有關的事情，都一定要經由 kubelet 處理。
- 這題要先把「和這台 node 有關」拆成兩層。第一層是 Kubernetes workload lifecycle，也就是 Pod 被指派到這台 node 後，怎麼建立 sandbox、拉 image、啟動 containers、回報 Pod / node 狀態。這一層裡，kubelet 確實是核心 agent，幾乎所有 Pod 落地相關流程都會經過它協調。
- 第二層是 node 上所有其他事情。這一層就不能說都要經過 kubelet，因為 worker node 上還有很多不是由 kubelet 直接掌管的部分，例如 container runtime 本身、CNI / dataplane、kube-proxy、CSI node plugin，以及更底層的 Linux OS、systemd、磁碟、網路介面與防火牆設定。
- 所以更精準的說法是：只要你問的是「這個 Pod 在這台 node 上怎麼真的跑起來」，kubelet 幾乎一定在核心路徑裡；但如果你問的是「這台 worker 上所有和節點有關的事情」，那就不能把 kubelet 當成唯一入口。
- 在 WeaMind 這個專案裡，可以用一個很務實的方式記：app workload 被排到 worker 後，kubelet 會是你理解 Pod 落地與狀態回報的核心；但若你在查 LB、Traefik、node 網路、container runtime 或 OS 層問題，就不該把思路全部塞回 kubelet。

### `ROLES` 不是 node 物件裡的一個原生 label 欄位

- 使用者追問：`kubectl get nodes` 裡的 `ROLES` 本身是不是一個 label；它究竟是 Kubernetes 預設值，還是某個 distribution 後來加上去的東西。
- 這題最重要的先收斂是：`ROLES` 不是 Node API 物件裡一個叫做 `roles` 的正式欄位，也不是一個固定存在的單一 label key。它比較像是 `kubectl get nodes` 顯示時，根據 node 上某些 role labels 推導出來的一個人類可讀欄位。
- 也就是說，真正存在於 node 物件上的，通常是 labels，例如常見的 `node-role.kubernetes.io/control-plane`，或更舊一點的 `node-role.kubernetes.io/master`。`kubectl` 看到這些 labels 後，才在表格裡把它整理成你看到的 `ROLES` 欄位。
- 這也解釋了為什麼不同環境下 `ROLES` 會長得不一樣：不是因為 Kubernetes API 裡有一個全世界都固定一致的 `roles` 欄位，而是因為不同發行版、安裝工具或雲平台，會替 node 打上不同的 labels，於是 `kubectl get nodes` 顯示出來的 `ROLES` 也就可能不同。
- 以 kubeadm 來說，control-plane 常見會帶 `node-role.kubernetes.io/control-plane`，因此顯示成 `control-plane`；worker 往往沒額外 role label，所以常看到 `<none>`。K3s 在 WeaMind 這個專案裡也呈現類似情況：control-plane 有明確角色顯示，worker 則是 `<none>`。EKS 則更進一步，control-plane 對你根本不可見，worker 也常不會顯示成明確 role，而是依靠雲端或 node group labels 來表達節點屬性。
- 所以這題最穩的最小說法是：`ROLES` 是 `kubectl` 根據 node labels 整理出來的顯示結果，不是 node 物件裡一個原生、固定、可拿來直接信任的 API 欄位。真正可控、可依賴的仍是你實際看得到的 node labels、taints 與 selectors。

### rollout status、conditions、strategy 的範圍怎麼再切得更細

- 使用者目前的主骨架已經接近正確：`kubectl rollout status` 回答的是「這一次 rollout 的執行結果」；`spec.strategy.rollingUpdate` 回答的是「更新時採用什麼交接策略」；`status.conditions` 則還不夠穩，尚在確認它是不是只回答 rollout 狀態，還是範圍比 rollout 更廣。
- 更精準的收斂是：`kubectl rollout status` 站在 CLI 觀察入口，回答的是「這次 rollout 現在是否已完成」。它比較像濃縮過後的結果訊息。
- `status.conditions` 不是只看 rollout 結果，也不只是單一成功或失敗標記。它回答的是「Deployment 物件目前有哪些狀態訊號」，其中有些和 rollout 推進直接相關，例如 `Progressing`；有些則和可用性相關，例如 `Available`。
- 所以如果只把 `conditions` 理解成 rollout 狀態，會太窄。更準確的說法是：rollout 狀態只是 `conditions` 裡的一部分觀察面，不是它的全部。
- `spec.strategy.rollingUpdate` 則完全不在結果層或狀態層。它站在 spec / 設定層，回答 controller 在更新時被允許怎麼交接新舊 Pod，例如 `maxSurge`、`maxUnavailable` 這類規則。
- 也可以把三者收斂成三個問題：
- `kubectl rollout status`：這次 rollout 現在完成了沒？
- `status.conditions`：這個 Deployment 目前有哪些狀態訊號？
- `spec.strategy.rollingUpdate`：新舊 Pod 交接時，規則是怎麼定的？
- 這題最穩的面試版說法是：`rollout status` 比較像這次部署交接的結論入口；`conditions` 是 Deployment status 裡較細的狀態訊號；`strategy` 則是 Deployment spec 裡預先定義的更新規則。三者分別站在結果層、狀態層、設定層。

### rollout 成功後，conditions 和 strategy 不能怎麼誤推

- 使用者目前的方向是對的：`rollout status` 成功，不等於 `status.conditions` 就只會剩下和成功有關的單一訊號；也不等於 `spec.strategy.rollingUpdate` 會直接告訴你這次為什麼成功。
- 更準確地說，`status.conditions` 是 Deployment 目前較廣的狀態訊號集合，不只覆蓋 rollout 推進，也覆蓋可用性，必要時還可能帶出失敗訊號。因此 rollout 成功後，不能把 conditions 縮成單一「成功說明欄」。
- 例如在一個正常成功的 Deployment 裡，你常同時看到 `Progressing=True` 與 `Available=True`。前者比較接近 rollout 已推進到新 ReplicaSet，後者則是在回答可用副本是否到位。這兩個都不是單純「success」三個字的同義改寫。
- `spec.strategy.rollingUpdate` 則更明確不在原因層。它回答的是 controller 更新時被允許遵守什麼交接規則，例如最多可多建多少 Pod、最多可少掉多少可用 Pod；但它本身不會告訴你這次 rollout 為什麼成功。
- 這次 rollout 之所以成功，通常還涉及新 Pod 是否能正常建立、是否能通過 readiness、image 能否拉下來、app 是否健康等執行期因素。strategy 只是提供更新規則邊界，不是成功原因說明。
- 這題最穩的收斂可以講成：`rollout status` 成功，只代表這次部署交接已完成；`conditions` 仍是較廣的狀態訊號集合；`strategy` 則只是更新規則，不負責解釋這次成功的原因。

### `maxSurge` 和 `maxUnavailable` 各自在限制什麼

- 使用者對 `maxSurge` 的直覺方向是對的：它和更新過程中「可以暫時多出多少 Pod」有關，也確實是在用資源換較平滑的交接。
- 更準確地說，`maxSurge` 回答的是：在 rolling update 過程中，最多允許超出目標副本數多少新的 Pod。它描述的是「可以額外加上去的上限」。
- 例如 Deployment 期望副本數是 2，若 `maxSurge: 25%`，在這種小副本數情境下，實際常可理解成更新時最多暫時多出 1 個 Pod，讓新 Pod 先起來，再逐步把舊 Pod 降下去。
- `maxUnavailable` 則是在回答另一個方向：在更新過程中，最多允許有多少原本應該可用的 Pod 暫時不可用。它描述的是「可以先少掉多少可用容量的上限」。
- 所以這兩個值一個是在管「可以多多少」，另一個是在管「可以少多少」：
- `maxSurge` 管額外增加的上限
- `maxUnavailable` 管暫時不可用的上限
- 這也就是為什麼你剛剛會覺得 `maxSurge` 比較像「衝到最多幾個 Pod」；那個方向是對的，只是更精準的說法不是「同時更新中的 Pod」數量，而是「更新期間允許超出目標副本數的額外 Pod」數量。
- 這題最穩的面試版說法是：`maxSurge` 決定 rolling update 時最多能先多開多少新 Pod，以換取更平滑的交接；`maxUnavailable` 決定更新過程中最多可暫時少掉多少可用 Pod，用來限制服務可用性的下降幅度。

### 3 個副本從 v1 更新到 v2 的實際例子

- 假設現在 Deployment 的 `replicas: 3`，目前正在跑 3 個 v1 Pod。
- 更新策略假設是：

```yaml
strategy:
	type: RollingUpdate
	rollingUpdate:
		maxSurge: 1
		maxUnavailable: 1
```

- 這組設定的意思可以先白話講成：
- 更新時，最多允許暫時多出 1 個 Pod
- 更新時，最多允許暫時少掉 1 個可用 Pod

- 如果從 v1 更新到 v2，一個常見的交接節奏可以這樣理解：

1. 一開始有 3 個 v1 Pod 在跑，可用 Pod 數是 3。
2. 因為 `maxSurge: 1`，controller 可以先多建立 1 個 v2 Pod，所以總 Pod 數暫時變成 4。
3. 等這個新的 v2 Pod Ready 之後，就可以開始減掉 1 個舊的 v1 Pod。
4. 此時總 Pod 數回到 3，但裡面的組成變成 2 個 v1 + 1 個 v2。
5. 接著再重複同樣節奏：先補新的 v2，再降一個舊的 v1，直到最後變成 3 個 v2。

- 這裡 `maxUnavailable: 1` 的作用，不是說 controller 一定要先讓 1 個 Pod 掛掉，而是說更新過程中，最多容忍有 1 個本來應該可用的 Pod 暫時不可用；不能讓可用容量掉得更多。
- 所以在 `replicas: 3` 的情境下，這組設定可白話理解成：更新時總 Pod 數最多可到 4，但可用 Pod 數不應低到少於 2 太多。
- 這也說明兩個參數是一起工作的：`maxSurge` 讓你能先加新 Pod，`maxUnavailable` 則限制你不能把可用容量掉得太兇。

## Flashcards

### 第一批卡片

- WeaMind 為什麼選 K3s，而不是 kubeadm 或 EKS / GKE？ #DevOps #card
	- 因為這個專案是小型叢集、單人維運、成本敏感
	- K3s 比 kubeadm 更省整合成本
	- K3s 比 EKS / GKE 更保有叢集操作與作品展示價值

- K3s 在這個專案裡不是「比較簡單」而已，真正的定位是什麼？ #DevOps #card
	- 它是正規 Kubernetes distribution
	- 重點是整合度高、維運成本低、仍保留可控性
	- 不是少掉 cluster state datastore

- control-plane 和 worker 在 WeaMind 裡各自負責什麼？ #DevOps #card
	- control-plane 負責叢集控制與決策
	- worker 負責實際承載 workload
	- Scheduler 在 control-plane，kubelet 在 worker

- `nodeSelector.nodepool=worker` 在 WeaMind 裡真正解決什麼問題？ #DevOps #card
	- 把 line-bot workload 固定在 worker 節點
	- 避免 app workload 跑到 control-plane
	- 讓角色分工真正落到 scheduler 的選節點條件

- kubelet 在 worker node 上最精準的角色是什麼？ #DevOps #card
	- 它是每台 node 上的 agent
	- 負責把已指派給自己的 Pod 真正落地執行
	- 並持續回報 node 與 Pod 狀態

- 為什麼不能把 kubelet 當成 worker 上所有事情的唯一入口？ #DevOps #card
	- Pod 落地很依賴 kubelet
	- 但控制面決策、網路資料平面、OS 維運不都由 kubelet 負責
	- 查 LB、Traefik、runtime 或 OS 問題時不能只盯 kubelet

- kubeconfig 的 `cluster`、`user`、`context` 各自在回答什麼問題？ #DevOps #card
	- `cluster` 回答 API server 在哪裡、怎麼驗證它
	- `user` 回答我用什麼身分登入叢集
	- `context` 回答目前要用哪組 cluster + user
	- `context` 不是另一種獨立連線資訊，名稱像 `default` 也不是重點

- 為什麼 WeaMind 的 kubeconfig `server` 會是 `https://127.0.0.1:6443`？ #DevOps #card
	- 因為本機透過 SSH tunnel 把遠端 API server 映射到 localhost:6443
	- 這代表本機連線入口，不代表 API server 真正在本機執行
	- kubectl 讀 `~/.kube/config` 後就是透過這條路徑進叢集

- `ROLES` 欄位是 node 物件裡一個原生可依賴的欄位嗎？ #DevOps #card
	- 不是
	- 它是 `kubectl get nodes` 根據 node labels 整理出的顯示結果
	- worker 顯示 `<none>` 不一定有問題；排程限制應建立在 labels、taints、selectors，不是 `ROLES`

- `kubectl rollout status`、Deployment conditions、rolling update strategy 各自回答什麼問題？ #DevOps #card
	- `rollout status` 看這次 rollout 有沒有完成
	- conditions 看 Deployment 目前有哪些狀態訊號，不只 rollout，也含可用性
	- strategy 看新舊 Pod 應該怎麼交接，不直接解釋這次為什麼成功

- Deployment conditions 最常先看哪兩個？ #DevOps #card
	- `Available` 看可用副本是否到位
	- `Progressing` 看 rollout 是否正在順利推進
	- 若出現 `ReplicaFailure`，通常代表副本建立過程出錯

- WeaMind 的 Deployment 沒有明寫 strategy，這代表什麼？ #DevOps #card
	- 不是沒有更新策略
	- 而是使用 Deployment 預設的 `RollingUpdate`
	- 也就是新舊 ReplicaSet 會漸進式交接

### 第二批卡片

- Scheduler 和 kubelet 最小責任邊界怎麼分？ #DevOps #card
	- Scheduler 只負責決定 Pod 應該去哪台 node
	- kubelet 負責把已指派給自己的 Pod 真正落地執行
	- 不要把排程責任和節點執行責任混成同一層

- 為什麼 `nodeSelector` 不是在告訴 kubelet 怎麼跑 container？ #DevOps #card
	- 因為 `nodeSelector` 是給 scheduler 的選節點條件
	- 它先縮小可選 node 範圍
	- 之後目標 node 上的 kubelet 才處理 Pod 落地

- kubeadm、K3s、EKS 在 `ROLES` 顯示上可能有什麼差異？ #DevOps #card
	- kubeadm 的 control-plane 常顯示 `control-plane`，worker 常是 `<none>`
	- K3s 在這個專案裡也是 control-plane 有角色，worker 為 `<none>`
	- EKS 常只看到 worker nodes，且 `ROLES` 也常是 `<none>`

- `Available=True` 和 `Progressing=True` 各自最常代表什麼？ #DevOps #card
	- `Available=True` 常代表已有足夠可用副本
	- `Progressing=True` 常代表 rollout 正在推進或新 ReplicaSet 已可用
	- 常見 reason 分別是 `MinimumReplicasAvailable` 與 `NewReplicaSetAvailable`

- `ReplicaFailure` 在 Deployment conditions 裡通常暗示什麼？ #DevOps #card
	- 它偏向副本建立或維持過程出錯
	- 可能和 image、權限、配額或建立流程失敗有關
	- 它不是單純代表 rollout 還沒完成

- `RollingUpdate` 和 `Recreate` 最小差別是什麼？ #DevOps #card
	- `RollingUpdate` 是新舊 Pod 漸進式交接
	- `Recreate` 更接近先停舊版，再起新版
	- 前者重點是降低中斷，後者重點是簡單直接

- 為什麼 WeaMind 不適合用「只因為 K3s 比較輕」來解釋選型？ #DevOps #card
	- 因為真正的理由還包含單人維運、成本、整合度與展示價值
	- 只講輕量會把架構決策講得太空
	- 面試時應把情境、限制與 trade-off 一起講出來

### 第三批卡片

- `kubectl get nodes -L nodepool` 裡的 `-L` 在做什麼？ #DevOps #card
	- 它會在表格裡額外顯示指定的 label key
	- 很適合快速驗證 node 上是否真的有某個 label
	- 如果該 node 沒有這個 label，對應欄位就會留空

- `kubectl config view --minify` 最適合用來回答什麼問題？ #DevOps #card
	- 最適合先看 kubectl 目前正在使用的那組 kubeconfig 設定
	- 它會濃縮 active context 相關的最小骨架
	- 若不加 `--minify`，常會把其他 clusters、users、contexts 一起展開

- command drill 裡怎麼選第一個 kubectl 指令？ #DevOps #card
	- 先對齊題目所在的層級與資源
	- 選能最短路徑回答當前問題的入口
	- 不要一開始就用資訊更完整但雜訊更高的指令

- 如果題目只是在問 rollout 有沒有完成，為什麼不該先看 `describe deployment` 或 `get deployment -o yaml`？ #DevOps #card
	- 因為那兩種入口會把 strategy、conditions 等資訊一起攤開
	- 它們不是不能看，而是對這題來說第一眼不夠貼題
	- 先用 `kubectl rollout status` 確認結果，再決定要不要往更細的層次下鑽

- `maxSurge` 和 `maxUnavailable` 最小差別是什麼？ #DevOps #card
	- `maxSurge` 限制的是更新時最多可額外多出多少 Pod
	- `maxUnavailable` 限制的是更新時最多可暫時少掉多少可用 Pod
	- 一個在管「可以多多少」，一個在管「可以少多少」
	- 例如 `replicas: 3`、`maxSurge: 1`、`maxUnavailable: 1` 時，總 Pod 數最多暫時到 4，並用先補新、再降舊的方式逐步交接
