# 2026-03-24 K8s Debug Tools Note

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

## Flashcards
