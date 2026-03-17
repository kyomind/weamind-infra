# 2026-03-17 Pod Management And Probe Notes

## 學習注意事項

### 外部預習回帶重點

- liveness probe 的核心問題是「container 是否壞掉到該重啟」，readiness probe 的核心問題是「Pod 現在能不能接流量」，startup probe 則是保護慢啟動應用避免被 liveness 誤殺。
- readiness probe 失敗時，關鍵後果是 Pod 會先從可導流後端清單移除，而不是直接重啟 container。
- `nodeSelector` 是 Pod 對 scheduler 提出的 node label 限制；若找不到符合條件的 node，Pod 會停在 Pending。
- `kubectl logs` 主要看應用程式 stdout / stderr，`kubectl rollout status` 主要看 Deployment rollout 是否完成，兩者不是同一層的健康判斷。
- 最小執行鏈是 Pod 建立後先由 Scheduler 決定 node，再由該 node 上的 kubelet 協調 container runtime 啟動 container。

### 今天進 lesson 前先記住的邊界

- 管理鏈是 `Deployment → ReplicaSet → Pod`。
- 執行鏈是 `Scheduler → kubelet → container runtime`。
- probe 題目先處理用途與失敗後行為，不要一開始就跳進所有參數細節。
- rollout 題目先處理它在觀察哪一層，不要直接把 rollout、Pod events、app logs 混成同一種狀態。

### 待驗證的 repo 對照點

- 為什麼 WeaMind 的 readiness probe 與 liveness probe 都打 `/health`，但 `initialDelaySeconds` 與 `periodSeconds` 不同。
- `nodeSelector.nodepool=worker` 是否能直接對回這個專案的 control-plane / worker 分工。
- 如果某個 Pod 因 probe 或 image 問題卡住，今天的第一個觀察指令應該先落在 Deployment、Pod 事件還是 logs。

### 暫時不在今天展開的點

- startup probe 的實際 YAML 設計與適用條件。
- affinity / anti-affinity 與更進階排程策略。
- rollout restart 的實作細節與 production 風險評估。

## Notes

### Probe 問題補充

- 使用者在 Q1 後追問：readiness probe 與 liveness probe 都打同一個 `/health`，Kubernetes 到底怎麼分辨這次失敗該算 readiness fail 還是 liveness fail。
- 這題的最小收斂是：差異不是由應用在 response 裡主動標記，而是 kubelet 本來就分別執行兩組不同的 probe 設定。即使 path 相同，kubelet 仍知道這次檢查屬於 readiness 還是 liveness，並套用不同後續處理。
- readiness 失敗的直接後果是 Pod 被標成 NotReady，先從可導流後端清單移除；liveness 失敗的直接後果則是 kubelet 依探針結果觸發 container restart。
- 同一路徑同時承擔 readiness 與 liveness，代表「停止導流」與「觸發重啟」兩種責任被綁在一起。對簡單服務可以接受，但系統變複雜後，常會拆成不同判斷邏輯以降低耦合。

### NodeSelector 問題補充

- 使用者在 Q2 中追問：Kubernetes 到底怎麼知道哪個 node 是 worker、哪個是 control-plane，因為 `nodepool=worker` 看起來像自訂 label，而不是 Kubernetes 自己保證存在的固定欄位。
- 這題的最小收斂是：`nodeSelector` 比對的是 node labels。`worker` 不是 Kubernetes 自帶的必然身分；像 `nodepool=worker` 這種寫法，通常是叢集管理者額外加在 node 上的自訂 label。
- control-plane 比較常見會帶有內建角色 label，例如 `node-role.kubernetes.io/control-plane`，也常搭配 taint，避免一般 workload 被排上去；worker 端則常以自訂 label 來表達「這批 node 是給哪類 Pod 跑的」。
- 這也表示：Deployment YAML 只寫了 Pod 端的需求，真正的 label 來源是在 cluster node 物件上，而不是這個 app repo 裡另外一份 manifests。
- repo 內已找到直接證據：`PROGRESS.md` 記錄了「對 worker 節點加上 label（`nodepool=worker`），並於 Deployment 加入 `nodeSelector`」，因此這不是單純推測，而是這個專案確實做過的手動設定。
- 同一份 `PROGRESS.md` 也記錄了 K3s 裡 worker 節點的 `ROLES` 顯示為 `<none>` 屬正常行為。這說明 worker 不一定會自然出現在一個固定的內建 role 欄位裡，所以另外加自訂 label 來做排程限制，在這個專案裡是合理且可追溯的。
- `nodepool` 不是唯一正解，它只是這個專案採用的 label key。只要 Pod 端 selector 與 node 端 labels 對得上，像 `disktype=ssd`、`dedicated=ingress`、`topology.kubernetes.io/zone=...` 都可以拿來當排程條件。

### Logs 與觀察層級補充

- 使用者在 Q3 裡主動指出：`kubectl logs` 其實也很適合單獨做一輪 command drill，因為它很容易和 `rollout status`、`describe pod` 混在一起。
- 這個觀察很有價值，因為今天這組題目的核心，不只是記住三個指令，而是先分辨你現在要查的是 Deployment rollout、Pod 狀態與事件，還是 app 自己的錯誤輸出。
- 最小收斂可以固定成三句：`rollout status` 看 Deployment 交接進度，`describe pod` 看 Pod 狀態與事件，`logs` 看 container 內應用程式的 stdout / stderr。

### 管理鏈與執行鏈補充

- 使用者在 Q4 中已經抓到一個很好的區分：管理鏈偏期望狀態與控制器層級，執行鏈偏實際把 Pod 跑出來的過程。
- 這題最需要修正的點是 scheduler / kubelet 的互動方式。比較精準的說法不是 scheduler 直接命令 kubelet「開兩個 Pod」，而是 scheduler 先替待執行的 Pod 決定 node，之後該 node 上的 kubelet 觀察到 Pod 已綁到自己，才去協調 container runtime 落地執行。
- Pod 不是純抽象名詞，但也不是像 VM 一樣獨立存在的一台小機器。比較穩的理解是：Pod 是 Kubernetes 的最小部署單位與執行邊界，container 則是在這個邊界裡真正跑起來的進程。
- 因此兩條鏈雖然最後都會碰到 Pod，但管理鏈在回答「應該維持哪些 Pods 存在」，執行鏈在回答「這些 Pods 怎麼在某台 node 上真的跑起來」。

### Pod 物件與實際資源消耗補充

- 使用者進一步追問：既然 API Server 裡已經有 Pod 物件，而 Pod 又不是完全虛無的抽象，那這個 Pod 到底消耗哪裡的資源，能不能說它的藍圖是跑在 control-plane 或 etcd 上。
- 這題要先拆成兩個層次。第一層是「Pod object」：這是 Kubernetes API 裡的一筆物件資料，包含 metadata、spec、status 等欄位。它會被 API Server 接受、被控制器與 scheduler 觀看，並被持久化到 cluster 的 datastore。這一層確實會占用 control-plane 端少量資源，例如 API Server / scheduler / controller 的記憶體、watch cache 與 datastore 儲存空間，但它不是你平常在講 app workload 時真正關心的那種執行期 CPU / RAM 消耗。
- 第二層是「running Pod」：當 Pod 被綁到某台 node 後，該 node 上的 kubelet 會協調 container runtime 建立 Pod sandbox、網路 / namespace 邊界，然後在這個邊界裡啟動 container。這時真正明顯消耗 CPU / 記憶體的是 node 上跑起來的 containers，以及為了支撐這個 Pod 而存在的執行期開銷。
- 所以可以說：Pod 在 control-plane 上先以「API 物件」形式存在，在 worker node 上再以「執行邊界」形式落地。這兩者都是真的，但不是同一種存在方式。
- etcd 或其他 cluster datastore 的角色比較接近「儲存 Pod 物件狀態」，不是「執行 Pod」。所以不建議說 Pod 藍圖是「跑在 etcd 上」；更精準的說法是：Pod spec / state 會被持久化在 cluster datastore，而不是由 datastore 來執行。
- 這也解釋了你對記憶體的直覺：未排程的 Pod object 確實不是零成本，但它消耗的是控制面的資料與協調成本；而當大家在談 Pod 吃多少 CPU / 記憶體時，通常指的是它被排到 node 後，Pod 內 containers 在 worker 上的實際執行資源。
- 若要再講得更精準一點，scheduler 在做排程判斷時，主要看的也不是「Pod object 在 control-plane 自己吃了多少 RAM」，而是 Pod spec 裡宣告的 requests / limits 與 node 可用資源，必要時也會把 Pod overhead 算進去。

### Pod 在 control-plane 與 worker 的成本差異

- 使用者最後收斂出的問題是：能不能把 Pod 理解成在 control-plane 與 worker 兩邊都會有資源消耗，只是形式不同。
- 這個理解方向是對的，但更精準的說法是：Pod 在 control-plane 主要有控制面成本，在 worker 主要有執行期成本。
- 在 control-plane，Pod 是 API 物件，成本來自 API Server、scheduler、controller 的觀察與協調，以及 datastore 對 Pod 狀態的保存。
- 在 worker，Pod 則是承載 containers 的運行單位，這一側才會出現比較直覺的 CPU、記憶體、sandbox、網路等執行期開銷。
- 所以如果面試或複習時要用一句話收斂，可以說：Pod 在 control-plane 是一筆要被管理的物件，在 worker 才是實際承載 container 的運行單位。

## Flashcards

### 第一批卡片

- readiness probe 和 liveness probe 的核心差別是什麼？ #DevOps #card
	- readiness probe 在看 Pod 現在能不能接流量
	- liveness probe 在看 container 是否壞到需要被重啟

- 同樣都打 `/health`，Kubernetes 怎麼分辨這次失敗算 readiness 還是 liveness？ #DevOps #card
	- 因為 kubelet 會分別執行兩組不同的 probe 設定
	- 差異來自 kubelet 對兩種 probe 的不同處理
	- 不是來自 `/health` 回應自己標記類型

- readiness probe 失敗時最直接的效果是什麼？ #DevOps #card
	- Pod 會變成 NotReady
	- 並先從 Service 的可導流後端清單移除
	- 不會直接重啟 container

- liveness probe 失敗時最直接的效果是什麼？ #DevOps #card
	- kubelet 會依探針結果重啟 container

- `nodeSelector.nodepool=worker` 在 WeaMind 裡的作用是什麼？ #DevOps #card
	- 它是 Pod 對 scheduler 提出的 node label 篩選條件
	- 用來把 line-bot workload 固定在 worker
	- 避免 control-plane 同時承擔 app 負載

- `nodepool=worker` 是 Kubernetes 自帶的固定欄位嗎？ #DevOps #card
	- 不是
	- 它是這個專案手動加在 worker 節點上的自訂 label
	- repo 可由 `PROGRESS.md` 找到證據

- `kubectl rollout status`、`kubectl describe pod`、`kubectl logs` 各自在看哪一層？ #DevOps #card
	- `rollout status` 看 Deployment 交接進度
	- `describe pod` 看 Pod 狀態與事件
	- `logs` 看應用程式自己的 stdout / stderr

- 管理鏈 `Deployment → ReplicaSet → Pod` 在回答什麼問題？ #DevOps #card
	- 它在回答系統想維持什麼 workload 狀態
	- 包括副本數、版本交接與誰負責維持這些 Pods 存在

- 執行鏈 `Scheduler → kubelet → container runtime` 在回答什麼問題？ #DevOps #card
	- 它在回答已被宣告要存在的 Pod
	- 最後怎麼被排到某台 node
	- 並在那台 node 上把 container 真正跑起來

- Pod 是純抽象嗎？ #DevOps #card
	- 不是
	- Pod 是 Kubernetes 的最小部署單位與容器外層包裝
	- 真正執行程式的是 container

- Pod 在 control-plane 和 worker 都會有成本嗎？ #DevOps #card
	- 會，但形式不同
	- control-plane 主要是 API 物件的控制面成本
	- worker 主要是承載 containers 的執行期成本

### 第二批卡片

- 為什麼同一個 `/health` 同時拿來做 readiness 和 liveness，會有耦合風險？ #DevOps #card
	- 因為同一個端點同時承擔「停止導流」與「觸發重啟」兩種責任
	- 對簡單服務可以接受
	- 對較複雜服務，常會拆成不同判斷邏輯避免過度耦合

- 為什麼拿掉 `nodeSelector.nodepool=worker` 後，不一定立刻壞掉，卻仍然有風險？ #DevOps #card
	- 因為 scheduler 的選擇邊界變鬆，不代表 app 立刻不能跑
	- app workload 可能被排到 control-plane
	- 之後會更難控制角色邊界、資源隔離與穩定性

- K3s 裡 worker 一定會有內建 `worker` role 嗎？ #DevOps #card
	- 不一定
	- 在這個專案的紀錄裡，worker 節點的 `ROLES` 顯示為 `<none>` 是正常行為
	- 所以另外加 `nodepool=worker` 這類自訂 label 來限制排程，是合理做法

- 為什麼 `kubectl rollout status` 不能拿來判斷 app 邏輯一定正常？ #DevOps #card
	- 它主要在看 Deployment 交接是否完成
	- 例如新 Pod 是否逐步變成 Ready
	- 它不是直接在看應用程式內部 exception 或業務邏輯是否正常

- `kubectl describe pod` 和 `kubectl logs` 最容易混淆的差別是什麼？ #DevOps #card
	- `describe pod` 看的是 Pod 狀態與事件
	- 常見內容包含 conditions、events、probe failed、FailedScheduling、image pull error
	- `logs` 才是看 container 內應用程式自己的 stdout / stderr

- 為什麼不能把 Deployment 講成直接負責排程或直接啟動 container？ #DevOps #card
	- 因為 Deployment 在管理鏈上，主要負責宣告期望狀態與更新策略
	- 排程是 scheduler 的責任
	- 在 node 上實際把 container 跑起來是 kubelet 與 container runtime 的責任

- scheduler 和 kubelet 的互動，最精準的最小說法是什麼？ #DevOps #card
	- scheduler 先替待執行的 Pod 決定 node
	- kubelet 之後觀察到「有 Pod 被綁到自己」
	- 再協調 container runtime 把它實際建立出來

- Pod object 和 running Pod 的差別是什麼？ #DevOps #card
	- Pod object 是 control-plane 裡的一筆 API 物件資料
	- running Pod 是 Pod 被綁到 node 後，在 worker 上的實際運行狀態
	- 前者偏資料與協調，後者偏執行與資源消耗

- 為什麼不建議說「Pod 跑在 etcd 上」？ #DevOps #card
	- 因為 etcd 或其他 datastore 的角色是儲存 Pod 物件狀態
	- 它不是執行 Pod 的元件
	- 更精準的說法是 Pod spec / state 會被持久化在 cluster datastore
