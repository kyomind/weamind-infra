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
- 同一路徑同時承擔 readiness 與 liveness，代表「停止導流」與「觸發重啟」**兩種責任被綁在一起**。對簡單服務可以接受，但系統變複雜後，常會拆成不同判斷邏輯以降低耦合。

### `http://:http/health` 顯示格式補充

- 使用者在 command drill 第一輪後追問：`kubectl describe deployment` 裡的 `http://:http/health` 看起來像重複寫了 HTTP，這段到底該怎麼讀。
- ⭐️這段不是在顯示兩段網址，而是**把 probe 的協定、host、port 與 path 壓縮成同一行**。`http://` 是協定，空白的 host 代表沒有特別指定 host，`:http` 則是命名 port，不是 domain。
- 在 [manifests/deployment.yaml](manifests/deployment.yaml#L35-L45) 可以直接對到：container port 被命名為 `http`，而 readiness / liveness probe 的 `httpGet.port` 也都是填 `http`。
- 所以比較好懂的人話是：probe 會用 HTTP 對這個 container 的 `http` port 發出 `/health` 請求；host 留白代表預設對 Pod 自己檢查，不是對外部網域發請求。

### 命名 port 叫 `http` 是否妥當

- 使用者補問：container port 命名成 `http` 會不會太混淆，這是常見寫法還是代表 YAML 寫法不夠好。
- 這個命名本身是常見且合理的，尤其在一個 container 只有單一 HTTP 服務埠時，直接命名為 `http` 很常見，也方便 Service、Probe 或 Ingress 以名稱而不是硬編碼數字 port 來引用。
- 真正讓人第一次看覺得怪的，不是命名本身，而是 `kubectl describe` 的輸出格式會把它渲染成 `:http`，看起來有點像 host 或 domain 的一部分。
- ⭐️若未來一個 Pod 裡有多個 port，或同時有 HTTP、metrics、admin 之類不同用途的端口，命名可以更語意化，例如 `web`、`http-api`、`metrics`。但在這份 WeaMind Deployment 裡，`http` 作為單一應用 port 名稱是正常做法，不算不妥。
- 🐱：反正重點是，這裡的 port 命名是為了語意化，區分情境，而不是表示 port 數字

### NodeSelector 問題補充

- 使用者在 Q2 中追問：Kubernetes 到底怎麼知道哪個 node 是 worker、哪個是 control-plane，因為 `nodepool=worker` 看起來像自訂 label，而不是 Kubernetes 自己保證存在的固定欄位。
- 這題的最小收斂是：`nodeSelector` 比對的是 node labels。`worker` 不是 Kubernetes 自帶的必然身分；像 `nodepool=worker` 這種寫法，通常是叢集管理者額外加在 node 上的自訂 label。
- control-plane 比較常見會帶有內建角色 label，例如 `node-role.kubernetes.io/control-plane`，也常搭配 taint，避免一般 workload 被排上去；worker 端則常以自訂 label 來表達「這批 node 是給哪類 Pod 跑的」。
- 這也表示：Deployment YAML 只寫了 Pod 端的需求，真正的 label 來源是在 cluster node 物件上，而不是這個 app repo 裡另外一份 manifests。
- repo 內已找到直接證據：`PROGRESS.md` 記錄了「對 worker 節點加上 label（`nodepool=worker`），並於 Deployment 加入 `nodeSelector`」，因此這不是單純推測，而是這個專案確實做過的手動設定。
- 同一份 `PROGRESS.md` 也記錄了 K3s 裡 worker 節點的 `ROLES` 顯示為 `<none>` 屬正常行為。這說明 worker 不一定會自然出現在一個固定的內建 role 欄位裡，所以另外加自訂 label 來做排程限制，在這個專案裡是合理且可追溯的。
- `nodepool` 不是唯一正解，它只是這個專案採用的 label key。只要 Pod 端 selector 與 node 端 labels 對得上，像 `disktype=ssd`、`dedicated=ingress`、`topology.kubernetes.io/zone=...` 都可以拿來當排程條件。

### Node labels 的一般查法補充

- 使用者在 command drill 後追問：除了 `kubectl get nodes -L nodepool` 這種指定單一 label key 的查法之外，若想看 node 的 labels 更完整地怎麼查。
- `-L` 適合在表格裡快速附加顯示少數幾個你特別關心的 label keys，例如 `nodepool`、`topology.kubernetes.io/zone`。
- 若想一次看所有 labels，最直接的做法通常是 `kubectl get nodes --show-labels`，或針對單一 node 用 `kubectl get node <node-name> --show-labels`。
- 若想搭配更多節點資訊一起看，`kubectl describe node <node-name>` 也會列出 labels。
- 若需要最完整、最適合精準查欄位的形式，則可以看 `kubectl get node <node-name> -o yaml`，到 `metadata.labels` 底下直接看原始資料。

### Logs 與觀察層級補充

- 使用者在 Q3 裡主動指出：`kubectl logs` 其實也很適合單獨做一輪 command drill，因為它很容易和 `rollout status`、`describe pod` 混在一起。
- 這個觀察很有價值，因為今天這組題目的核心，不只是記住三個指令，而是先分辨你現在要查的是 Deployment rollout、Pod 狀態與事件，還是 app 自己的錯誤輸出。
- 最小收斂可以固定成三句：`rollout status` 看 Deployment 交接進度，`describe pod` 看 Pod 狀態與事件，`logs` 看 container 內應用程式的 stdout / stderr。

### `describe pod` 在 Ready 問題裡的角色

- 使用者在拆題後的情境 B 選擇先看 `kubectl describe pod -n weamind <pod-name>`，並補充自己的實際排查順序通常會是：先看 `describe pod`，若沒有關鍵資訊，再補看 `kubectl logs`。
- ⭐️這個順序是合理的。若題目是「某個 Pod 明明 **Running，但 READY 是 0/1**」，第一個**最穩的入口**通常就是 `describe pod`，因為它最容易同時看到 **Pod conditions、container state、restart count、probe 設定，以及 events**。
- 這次因為使用者拿來觀察的是健康 Pod，所以輸出裡看到的是 `Ready: True`、`ContainersReady: True`、`Restart Count: 0`、`Events: <none>`。這剛好說明一件事：健康 Pod 的 `describe` 主要是在告訴你「目前沒有異常跡象」，而不是主動展示失敗案例。
- 若真的有問題，常見線索通常會出現在這些地方：
- `Conditions` 裡的 `Ready=False` 或 `ContainersReady=False`
- `State` / `Last State` 出現 waiting、terminated、OOMKilled、CrashLoopBackOff 等狀態
- `Restart Count` 持續增加
- `Events` 出現 `Readiness probe failed`、`Liveness probe failed`、`Back-off restarting failed container`、`FailedScheduling`、`Failed to pull image` 等訊息
- 所以更精準的說法不是「describe 一定能直接給答案」，而是「describe 是 Pod 層的第一個狀態面板」。若它已指出 probe fail、restart 或事件，通常先沿著那條線查；若它沒有給出足夠原因，再去看 logs 補 app process 的細節。

### Pod 物件與實際資源消耗補充

- 使用者進一步追問：既然 API Server 裡已經有 Pod 物件，而 Pod 又不是完全虛無的抽象，那這個 Pod 到底消耗哪裡的資源，能不能說它的藍圖是跑在 control-plane 或 etcd 上。
- 這題要先拆成兩個層次。第一層是「Pod object」：這是 Kubernetes API 裡的一筆物件資料，包含 metadata、spec、status 等欄位。它會被 API Server 接受、被控制器與 scheduler 觀看，並被持久化到 cluster 的 datastore。這一層確實會占用 control-plane 端少量資源，例如 API Server / scheduler / controller 的記憶體、watch cache 與 datastore 儲存空間，但它不是你平常在講 app workload 時真正關心的那種執行期 CPU / RAM 消耗。
- 第二層是「running Pod」：當 Pod 被綁到某台 node 後，該 node 上的 kubelet 會協調 container runtime 建立 Pod sandbox、網路 / namespace 邊界，然後在這個邊界裡啟動 container。這時真正明顯消耗 CPU / 記憶體的是 node 上跑起來的 containers，以及為了支撐這個 Pod 而存在的執行期開銷。
- 所以可以說：Pod 在 control-plane 上先以「API 物件」形式存在，在 worker node 上再以「執行邊界」形式落地。這兩者都是真的，但不是同一種存在方式。
- etcd 或其他 cluster datastore 的角色比較接近「儲存 Pod 物件狀態」，不是「執行 Pod」。所以不建議說 Pod 藍圖是「跑在 etcd 上」；更精準的說法是：Pod spec / state 會被持久化在 cluster datastore，而不是由 datastore 來執行。
- 這也解釋了你對記憶體的直覺：未排程的 Pod object 確實不是零成本，但它消耗的是控制面的資料與協調成本；而當大家在談 Pod 吃多少 CPU / 記憶體時，通常指的是它被排到 node 後，Pod 內 containers 在 worker 上的實際執行資源。
- ⭐️若要再講得更精準一點，scheduler 在做排程判斷時，主要看的也不是「Pod object 在 control-plane 自己吃了多少 RAM」，而是 Pod spec 裡**宣告的 requests / ~~limits~~ 與 node 可用資源**，必要時也會把 Pod overhead 算進去。

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

### 第三批卡片

- `kubectl describe` 裡的 `http://:http/health` 該怎麼讀？ #DevOps #card
	- `http://` 是協定
	- 空白 host 代表沒有特別指定 host
	- `:http` 指的是命名 port `http`
	- `/health` 才是 path

- 為什麼把 container port 命名成 `http` 在 Kubernetes 裡通常是合理的？ #DevOps #card
	- 因為對單一 HTTP 服務來說，`http` 是常見且可讀的命名
	- Service、Probe、Ingress 都可以直接用名稱引用這個 port
	- 這比到處硬寫數字 port 更有語意

- `kubectl get pods -o wide` 能回答什麼，不能回答什麼？ #DevOps #card
	- 它能回答 Pod 目前被排到哪些 nodes
	- 但不能單靠這個輸出證明 node labels 一定符合 `nodeSelector`
	- 若要補齊證據，還要再看 nodes 的 labels

- 若要完整驗證 `nodeSelector.nodepool=worker` 是否真的生效，最小閉環通常是什麼？ #DevOps #card
	- 先用 `kubectl get pods -o wide` 看 Pods 被排到哪些 nodes
	- 再用 `kubectl get nodes -L nodepool` 看那些 nodes 是否真的帶有 `nodepool=worker`
	- 前者看排程結果，後者看 label 證據

- 為什麼健康 Pod 的 `kubectl describe pod` 可能看起來「沒什麼資訊」？ #DevOps #card
	- 因為 `describe pod` 比較像 Pod 層的狀態面板
	- 健康 Pod 常只會顯示 `Ready=True`、`Restart Count=0`、`Events=<none>`
	- 它的價值是先告訴你「目前沒有異常跡象」，不是主動展示失敗案例

- 排查時為什麼不能替指令腦補超過證據邊界的結論？ #DevOps #card
	- 因為每個指令只回答特定層級的問題
	- 例如 `rollout status` 不等於 app 一定正常，`get pods -o wide` 也不等於 node labels 已被證明
	- 真正穩的排查是先確認這個指令回答了什麼，再決定下一個證據入口

- 想看 node labels 時，除了 `kubectl get nodes -L nodepool`，還有哪些常用查法？ #DevOps #card
	- `kubectl get nodes --show-labels` 適合快速看所有 nodes 的 labels
	- `kubectl describe node <node-name>` 可以連同節點其他資訊一起看
	- `kubectl get node <node-name> -o yaml` 最適合直接看 `metadata.labels` 的原始資料

- 遇到不同排查問題時，第一眼常見的命令分工怎麼選？ #DevOps #card
	- 想看 Deployment 交接是否完成，先看 `kubectl rollout status`
	- 想看 Pod 為什麼 Running 但 NotReady，先看 `kubectl describe pod`
	- 想看 app process 是否報錯，先看 `kubectl logs`
	- 想看 Pods 被排到哪些 nodes，先看 `kubectl get pods -o wide`
	- 想驗證 node labels，先看 `kubectl get nodes -L <label-key>` 或 `--show-labels`
