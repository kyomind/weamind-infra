# 2026-03-24 K8s Debug Tools Note
複習：2026-05-12
## 學習注意事項

### 外部預習回帶重點

- 今天不另外做外部 prework，直接承接昨天已完成的 W3 Day 1 debug 分層框架。
- 今天的前提不是重背 Pod 狀態定義，而是把昨天的分層判讀接到工具選擇上。

### 今天進 lesson 前先記住的邊界

- 今天要解的是工具語意與證據類型，不是把所有 debug 故事全部重講一次。
- 今天會延續昨天的分層框架，但重點是回答「當我懷疑這一層時，先開哪種工具比較划算」。
- 今天會做最小 command drill，但不是大量堆指令；每一輪都要能回到為什麼選這個工具。

### 待驗證的 repo 對照點

- `manifests/deployment.yaml` 裡的 image、command、`envFrom`、probes，要對回 `describe` / `logs` / `logs --previous` 的較適合使用情境。
- `manifests/service.yaml` 與 `manifests/ingress.yaml`，要對回哪些情境其實不該第一步就 `exec` 進 Pod。
- `PROGRESS.md` 與 `docs/LINE-Webhook-切換流程.md`，要對回真實案例中各工具的第一輪證據價值。

### 暫時不在今天展開的點

- 今天先不展開 debug Pod、ephemeral container 或更進階的 troubleshooting workflow。
- 今天先不整理完整 flashcards，等 QA 或 command drill 累積到足夠穩定的結論後再補。

## Notes

### `describe pod` 裡沒有 Events 時，還能看什麼

- Pod 正常啟動、目前也沒有新的異常事件時，`Events: <none>` 是可能出現的，這不代表 `describe` 就沒有資訊可看。
- 這種情況下，`Conditions` 反而很值得看，因為它們是在回答「這個 Pod 目前通過了哪些狀態檢查」。
- 可以先把這兩塊分開理解：`Events` 比較像時間序列上的發生紀錄；`Conditions` 比較像當下這一刻的狀態快照。

### `Conditions` 各自代表什麼

- `PodScheduled=True`：Pod 已經成功被 scheduler 指派到某個 node，不再卡在排程階段。
- `Initialized=True`：若有 init containers，代表它們都已完成；若沒有 init containers，通常也會是 True。
- `PodReadyToStartContainers=True`：Pod sandbox 與基礎環境已就緒，可以開始啟動 containers。這是較新的 condition，常見於較新版本的 Kubernetes / K3s。
- `ContainersReady=True`：Pod 裡所有 containers 都已經處於 ready 狀態。
- `Ready=True`：這個 Pod 已被視為可接收流量。對有 Service 的情境來說，這通常是最直接影響能不能被當成可用後端的條件。

### `Conditions` 全部是 True，代表什麼；不代表什麼

- 若這些 conditions 都是 True，代表至少從 Kubernetes 的 Pod lifecycle 與 readiness 判斷來看，這個 Pod 目前沒有卡在排程、初始化、container ready 或整體 ready 這些基本檢查上。
- 但這不等於「完全正常」或「整條系統路徑都沒問題」。
- 例如：外部 DNS、Load Balancer、Ingress host/path 規則、應用邏輯錯誤、回應內容錯誤、慢查詢、偶發 timeout，這些都可能在 `Conditions` 全 True 的情況下依然存在。
- 更精準的說法是：`Conditions=True` 代表這個 Pod 通過了 Kubernetes 當前有在追蹤的那幾個生命週期 / readiness 條件，但不代表應用層與外部流量層的所有問題都被排除了。

### 一個實用的判讀方式

- 如果 Pod Pending、卡初始化、卡 container 建立，`Conditions` 常會幫你快速看到是哪個階段還沒過。
- 如果 `Conditions` 幾乎都已是 True，但你仍然遇到 404、500、timeout 或 webhook 行為不對，那注意力就應該開始往 Service、Ingress、應用 log 或外部流量路徑移動，而不是只停在 Pod lifecycle 本身。

### `Conditions` 有沒有時間上的連續性

- 有一種大方向上的先後關係，但不要把它想成永遠只會單向往前、而且後面 True 就保證前面永遠不會再變動的嚴格流水線。
- 一般會先看到 `PodScheduled=True`，再到 `Initialized=True`，再到 `PodReadyToStartContainers=True`，接著 containers 啟動、通過 readiness 後，才會看到 `ContainersReady=True` 與 `Ready=True`。
- 但這些 conditions 不是一次性寫死。特別是 `ContainersReady` 和 `Ready`，在 Pod 已經跑起來之後，仍然可能因為 container 重啟、readiness probe 失敗或應用暫時不健康而再變回 False。
- 所以比較精準的理解是：它們有生命周期上的大致順序，但不是「只要後面 True，前面就永遠不可能 False」的不可逆流程。

### readiness probe 與 liveness probe 大致站在哪裡

- readiness probe 比較接近「container 已經啟動後，Pod 能不能被視為可接流量」這一關。
- 在實務上，它影響的是 container 是否被標成 ready；當所有 containers 都 ready 之後，`ContainersReady=True`，接著整個 Pod 才會進入 `Ready=True`。
- 所以如果你硬要放在這串 conditions 中理解，readiness probe 最接近的是 `PodReadyToStartContainers=True` 之後、`ContainersReady=True` 與 `Ready=True` 之前的那段驗證。
- liveness probe 不太一樣，它不是在決定「可不可以開始接流量」，而是在 container 已經跑起來之後，持續確認「你是不是還活著」。
- liveness probe 成功時，通常不會額外把某個新的 Pod condition 改成 True；它比較像背景健康檢查。真正有感的是它失敗時，kubelet 會重啟 container，之後你就可能看到 container state 改變、restart count 增加，甚至連 `ContainersReady` / `Ready` 也跟著掉回 False。

### 一條最小時間線

- `PodScheduled=True`：scheduler 已把 Pod 放到某個 node。
- `Initialized=True`：init container 階段完成。
- `PodReadyToStartContainers=True`：Pod sandbox 與基礎環境已準備好，可以啟動 containers。
- container 開始啟動。
- readiness probe 開始檢查；通過後，container 會被視為 ready。
- `ContainersReady=True`：所有 containers 都 ready。
- `Ready=True`：整個 Pod 被視為可接流量。
- 之後 liveness probe 持續在背景檢查；若失敗，container 可能被重啟，Pod 的 ready 相關條件也可能重新掉回 False。

### `kubectl exec` 到底是進 Pod 還是進 container

- 使用者下 `kubectl exec` 時，是以 Pod 名稱作為入口；但真正執行命令的地方，仍然是 Pod 裡的某一個 container。
- 如果 Pod 只有一個 container，通常不需要額外指定 container 名稱。
- 如果 Pod 裡有多個 containers，應使用 `-c <container-name>` 明確指定，例如 `kubectl exec -it <pod-name> -c app -- /bin/sh`。
- 所以最短的正確說法不是「進 Pod 本體」，而是「透過 Pod 這個資源入口，進到其中一個 container 執行命令」。

### `exec` 最適合驗證什麼

- `exec` 最適合做 Pod 內部最小驗證，例如：環境變數有沒有正確注入、DNS 解析是否正常、Pod 內能不能打到 Service、能不能連到 PostgreSQL / Redis、某個檔案是否存在。
- 它回答的是「container 內部現在看到什麼」，不是「外部流量路徑是否完整正確」。
- 所以即使 `exec` 成功，也通常只代表至少有一個 container 目前可執行命令，不代表應用邏輯、Ingress、Load Balancer 或 webhook routing 一定都正常。

### `exec` 進去後工具不存在，要怎麼判讀

- 在偏精簡的 production image 裡，`wget`、`nc`、`curl` 這類 debug 工具不一定存在。
- 如果在 `exec` 進去後看到像 `/bin/sh: wget: not found` 或 exit code `127`，第一個判讀應是「這個 binary 不存在」，不是「Service / DB 連不通」。
- 也就是說，先分清楚你現在失敗的是「命令執行前提」還是「網路連線本身」。
- 若容器內沒有合適工具，可改用容器內現成的語言 runtime、專用 debug Pod，或其他已知存在的最小工具，不要把工具缺失誤判成系統異常。

## Flashcards

- `kubectl describe pod` 比較像在拿哪一類證據？ #DevOps #card
	- 它比較像在看 Kubernetes 對 Pod 的觀察
	- 高價值欄位常是 state、conditions、restart count、events
	- 適合先判讀 Pod lifecycle、排程與重啟訊號

- 為什麼 Pending、ImagePullBackOff、CreateContainerError 第一輪常先看 `describe`？ #DevOps #card
	- 因為它們多半還沒順利進到 app 穩定執行期
	- 第一輪更需要 Kubernetes / runtime 事件證據
	- 這時 logs 不一定有足夠內容

- `kubectl logs --previous` 什麼時候特別有價值？ #DevOps #card
	- 當 Pod 反覆重啟時
	- 它看的是上一個已死 container 的最後輸出
	- 很適合追 CrashLoopBackOff 前一輪真正的錯誤訊息

- 為什麼外層 routing 問題不該先 `kubectl exec -it`？ #DevOps #card
	- 因為 `exec` 拿到的是 Pod 內部視角
	- 若 host / path 根本沒命中，先進 Pod 很可能只會看到 Pod 正常
	- 這不能直接解釋外部為什麼回 404

- `Conditions` 全部是 True，代表什麼？ #DevOps #card
	- 代表這個 Pod 通過了 Kubernetes 目前追蹤的 lifecycle / readiness 條件
	- 不代表 DNS、LB、Ingress、app 邏輯或 response 一定全都正確
	- 它是 Pod 狀態快照，不是整條系統健康保證

- readiness probe 和 liveness probe 最小差別是什麼？ #DevOps #card
	- readiness 決定 Pod 能不能被視為可接流量
	- liveness 決定 container 活不活、要不要被重啟
	- readiness 更接近 `ContainersReady` / `Ready`，liveness 是執行期背景檢查

- `kubectl exec` 是進 Pod 還是進 container？ #DevOps #card
	- 它是以 Pod 名稱為入口
	- 但真正執行命令的地方仍是某一個 container
	- 多 container Pod 需要用 `-c <container-name>` 指定目標

- 在 `exec` 之後看到 `wget: not found` 或 exit code 127，要怎麼判讀？ #DevOps #card
	- 先判讀成 binary 不存在
	- 不是直接判成 Service 或 DB 連不通
	- 要先分清楚是工具缺失還是網路失敗
