# 2026-04-14 Darkmind Logs Previous Rollout Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天只練 `logs`、`logs --previous`、`rollout status`、`rollout history`、`rollout undo` 這條 Day 2 操作鏈，不提前混入 `exec`、`port-forward` 或 `readiness-fail` 主題。
- 今天的壞情境只用 `crash-loop` 與 `bad-rollout`，目標是把 app-level 證據和 Deployment-level 證據分清楚，不追求一次碰更多故障家族。

### Repo 對照文件與觀察點

- `darkmind/README.md`：確認 Day 2 的操作目標與情境邊界。
- `darkmind/scenarios/crash-loop.yaml`：對照 container 一啟動就退出時，`logs` 與 `logs --previous` 會對應到哪種證據。
- `darkmind/scenarios/bad-rollout-01-good.yaml` 與 `darkmind/scenarios/bad-rollout-02-bad.yaml`：對照正常 rollout 和壞版本 rollout 卡住時，Deployment 層級指令要怎麼接。

### 暫時不在今天展開的點

- `exec`、`port-forward` 留到後續 lesson。
- `readiness-fail` 與 service endpoints 今天不正式展開。
- 更細的 `kubectl logs` 篩選參數與多 container log 變體今天不先展開。

## Notes

### `Running` 和 `Ready` 差在哪裡

- 這兩個不是同一件事。`Running` 比較接近 **Pod phase / container 進程已經跑起來**；`Ready` 比較接近 **這個 Pod 是否已被 Kubernetes 判定可以安全接流量 / 提供服務**。
- 所以你會看到一種很常見的暫態：`STATUS` 顯示 `Running`，但 `READY` 欄位還是 `0/1`。這代表 container 已經啟動了，但 Kubernetes 還沒把它判成 ready。
- 若 container **有設定 `readinessProbe`**，那通常要等 probe 成功後，該 container 才會被標成 ready，Pod 的 `Ready` condition 才可能變成 `True`。
- 若 container **沒有設定 `readinessProbe`**，那它通常在成功啟動後，就可能很快被視為 ready；也就是說，不是所有 Pod 都一定要有 readiness probe 才能 ready。
- 更完整地說，Pod 被判成 Ready，通常要滿足兩層：
	1. Pod 內該 ready 的 containers 都是 ready
	2. 若有額外 `readinessGates`，那些條件也要成立
- 在 `kubectl get pods` 裡看到的 `READY 1/1`，比較像「**1 個 container ready / 總共 1 個 container**」的摘要顯示；不是單純 phase 名字。
- 一句話口訣：`Running` 是「程式有跑起來」，`Ready` 是「Kubernetes 願意把流量交給你」。

### rollout undo 前後，壞 Pod 的 logs 還看不看得到

- 這個追問很重要，因為它碰到 **先救火還是先保全證據** 的實務取捨。
- 一般比較穩的處理順序是：
	1. 先用最小成本確認 rollout 真的卡住，例如 `kubectl rollout status`。
	2. 若壞 Pod 還存在，先用最小必要指令保留證據，例如 `kubectl get pods`、`kubectl describe pod`、`kubectl logs`、必要時 `kubectl logs --previous`。
	3. 若這已經是 production 影響中的 incident，而你也已經足夠確認是新版本導致，通常就應優先 `kubectl rollout undo` 先恢復服務，再回頭分析已保留下來的證據。
- `kubectl rollout undo` 的效果不是「瞬間把壞 Pod 憑空抹掉」，而是把 Deployment 的目標 revision 改回先前版本。之後控制器會開始建立舊版本 Pod、縮掉新版本 ReplicaSet。也就是說，**壞 Pod 可能會暫時還在，但通常不保證會留很久**。
- 這代表兩件事：
	1. 若你想看壞 Pod 的 `logs`，**最穩的做法是先看、先記、必要時先貼進 lesson 或 incident note，再做 undo**。
	2. 如果你已經先做了 `undo`，但壞 Pod / container 還沒被完全清掉，你仍然**有可能**暫時看得到它們的 `logs`；但這不應被當成穩定保證，因為 rollout 控制器之後可能會把這批壞 Pod 刪掉。
- 所以比較實務的原則是：**若服務正在受影響，就先拿最小證據再快速 rollback；不要把完整深挖放在 rollback 之前拖太久。**
- 一句話口訣：`undo` 不是 log 保存機制；它是恢復動作。壞 Pod 的 logs 可能在 undo 後暫時還看得到，但不保證會一直存在。

### rollout 類問題的最小處理順序

- 若 rollout 卡住，第一輪先問的是「是否要先恢復服務」，不是立刻展開超長 debug。
- 一條實務上常見的最小順序是：
	1. `kubectl rollout status` 確認 rollout 卡住
	2. `kubectl get pods` / `kubectl describe pod` / `kubectl logs` 對壞 Pod 留最小證據
	3. `kubectl rollout history` 確認可回退 revision
	4. `kubectl rollout undo` 先恢復
	5. 之後再對保留下來的輸出、YAML 差異與 revision 細節做根因分析

### 實務上怎麼留「最小證據」

- 你問得對，`kubectl get pods` / `kubectl describe pod` / `kubectl logs` 只是指令類型，不是完整採證寫法。真實 incident 裡，通常至少會做兩件事：
	1. 先在 terminal 直接看，快速確認問題類型。
	2. 再把最小但高價值的輸出存成檔案，避免 rollback 或 Pod 消失後證據不見。
- 一組很常見、夠小又夠用的最小採證指令長這樣：

```bash
mkdir -p incident-evidence

kubectl get pods -n darkmind -o wide > incident-evidence/pods.txt
kubectl describe pod -n darkmind <bad-pod-name> > incident-evidence/describe-pod.txt
kubectl logs -n darkmind <bad-pod-name> > incident-evidence/current.log
kubectl logs -n darkmind <bad-pod-name> --previous > incident-evidence/previous.log
kubectl get events -n darkmind --sort-by=.lastTimestamp > incident-evidence/events.txt
kubectl rollout history deploy/<deploy-name> -n darkmind > incident-evidence/rollout-history.txt
```

- 如果你當下還不知道壞 Pod 名稱，通常會先這樣縮圈：

```bash
kubectl get pods -n darkmind
kubectl get pods -n darkmind -l app=darkmind-rollout
kubectl describe pod -n darkmind <bad-pod-name>
```

- 如果你想一邊看、一邊順手留檔，常見寫法是用 `tee`：

```bash
kubectl describe pod -n darkmind <bad-pod-name> | tee incident-evidence/describe-pod.txt
kubectl logs -n darkmind <bad-pod-name> | tee incident-evidence/current.log
kubectl logs -n darkmind <bad-pod-name> --previous | tee incident-evidence/previous.log
```

- 如果 rollout 類問題是 Deployment 層級，而不是單顆 Pod 就能講完，通常還會多補這兩個：

```bash
kubectl get rs -n darkmind -o wide > incident-evidence/replicasets.txt
kubectl get deploy -n darkmind -o yaml > incident-evidence/deployments.yaml
```

- 真正的重點不是把所有東西都 dump 下來，而是保留「**足夠支撐回顧與根因分析**」的最小證據。對 rollout / crash 類問題來說，最常見的最小集合就是：
	1. `get pods`
	2. `describe pod`
	3. `logs`
	4. `logs --previous`
	5. `get events`
	6. `rollout history`
- 如果是 production 正在燒，這組最小集合通常就夠你先 rollback，再慢慢分析。

### `CrashLoopBackOff` 會不會到某個上限就停住或自動刪掉

- 一般 `Deployment` 底下的 Pod，不會因為 `CrashLoopBackOff` 重啟很多次就自動被刪掉。更準確地說，kubelet 會持續重試重啟，只是重試間隔會做 **exponential backoff**。
- 這個 backoff 會愈來愈長，但不是「到某個重啟次數就自動放棄並刪 Pod」。在常見行為下，延遲會一路增加到上限，之後停在一個較長的固定等待時間，再繼續重試。
- 對一般 `Deployment` / `ReplicaSet` 管理的 Pod 來說，**預設沒有一個「重啟幾次就停止」的次數上限**。只要 Pod 還存在、`restartPolicy` 允許重啟，而且控制器還想維持這個 Pod，kubelet 就會繼續重試。
- 真正常見的「有次數上限」比較像 `Job` 的 `backoffLimit`，那是另一種工作負載語意；不要把它和 `Deployment` 的 `CrashLoopBackOff` 混在一起。
- 在 kubelet 常見行為下，重試等待時間會逐步增加，**上限通常收斂到大約 5 分鐘左右**，之後就不是無限越等越久，而是維持在較長的 backoff 節奏繼續重試。
- 所以你看到 `CrashLoopBackOff` 時，更接近「**還在重試，但目前因 backoff 暫停一下**」，不是「這個 Pod 已經被系統放棄並清掉」。
- 也因此，只要 Pod 還存在，而且對應 container logs 還沒被節點上的 log rotation 或 garbage collection 清掉，你通常都還能 `kubectl logs` / `kubectl logs --previous` 去看。
- 但這裡要補兩個邊界：
	1. `kubectl logs --previous` 只保證上一個已終止的 container instance，不是所有歷史輪次都保留。
	2. 如果 Pod 被刪掉、被新 Pod 取代、節點重開、或容器日志已被清理，你就可能拿不到先前那一輪的 logs。
- 一句話口訣：`CrashLoopBackOff` 對 `Deployment` 來說通常是 **沒有固定最大重啟次數、只會持續重試且 backoff 時間有上限**；但 logs 能不能一直拿到，不是永久保證，所以重要證據要早點留。

### 為什麼 `current log` 和 `--previous` 有時看起來一樣

- 在這個 `darkmind` lab 裡，`crash-loop.yaml` 的 container 每一輪執行的事情都一樣：印一行固定字串，然後立刻退出。
- 所以你看到 `kubectl logs` 和 `kubectl logs --previous` 內容一樣，**不是因為 current 與 previous 本質上沒有差別**，而是因為每一輪程式行為都完全一樣，輸出自然就重複。
- 如果是真實應用，current 和 previous 很可能不同。例如 current 只跑到初始化前半段，previous 才真正印出 stack trace 或 fatal error。

### 為什麼 `kubectl logs --previous` 有時會短暫拿不到

- `kubectl logs --previous` 看的不是「任意舊版本 log」，而是 **目前這個 Pod 的上一個已終止 container instance**。
- 在 `CrashLoopBackOff` 的快速重啟循環中，這個對象是移動中的，所以你可能遇到時序窗口：
	1. 剛好上一個 container instance 的 log 還沒準備好
	2. current / previous 剛切換完成，`kubectl` 查詢時撞到過渡瞬間
	3. container runtime / kubelet 暫時無法把那個上一輪 instance 的 log 取回
- 所以你這次看到「先拿到、再拿不到、過一下又拿到」，在 crash-loop 類情境裡其實很合理，重點是：**`--previous` 天生就比一般 `logs` 更吃時機**。
- 這不一定代表「你拿得太晚」或「Pod 已被刪掉」，雖然那兩種情況也可能導致拿不到。更常見的解釋是：你碰到的是快速重啟循環裡的時序窗口。
- 如果你真的很在意上一輪退出前的輸出，實務上要嘛盡快抓，要嘛第一時間用 `tee` 或重新導向把它存下來，不要假設稍後一定還能補拿。

### 第一次 `apply` 建立 Deployment，算不算 rollout

- 算，而且這個觀念很重要。只要 Deployment controller 根據一個 Pod template 去建立 / 推進對應的 ReplicaSet 與 Pods，從 Deployment 視角看，就有 rollout 過程。
- 所以第一次 `kubectl apply -f ...` 建立一個新的 Deployment 時，雖然不是「舊版升級到新版」，但它仍然會有第一個 revision、第一個 ReplicaSet、第一波 Pods 被推起來，因此 `kubectl rollout status` 查得到完全合理。
- 可以把它理解成：**第一次 apply 是第一次發布，更新 template 則是後續發布**；兩者都屬於 rollout，只是前者沒有舊版對照。

### `kubectl rollout status --timeout` 超時代表什麼

- `--timeout=60s` 的意思是：CLI 最多等 60 秒，看這個 rollout 能不能收斂完成。
- 如果時間內完成，你會看到 `successfully rolled out`。
- 如果時間內沒完成，`kubectl rollout status` 會 timeout 結束，通常伴隨非零 exit code。它回答的是：**在這個等待窗口內，rollout 還沒成功完成**。
- 這不等於 Deployment 被刪掉，也不等於 Kubernetes 幫你自動 rollback。它只是告訴你：現在 rollout 還卡著，下一步該做更深觀察，例如看 Pod 狀態、revision、事件，或評估要不要 `rollout undo`。
- 一句話口訣：`--timeout` 是等待上限，不是修復機制。

### `kubectl rollout history` 裡的 `CHANGE-CAUSE` 是什麼

- `CHANGE-CAUSE` 是給人看的變更原因欄位，用來幫你回想「這次 rollout 是因為什麼變更」。
- 你現在看到 `<none>` 很正常，因為一般直接 `kubectl apply -f ...` 並不會自動幫你填 change cause。
- 歷史上常見做法是用 `kubectl annotate deployment ... kubernetes.io/change-cause="..."`，或某些工作流曾搭配 `--record` 類寫法把命令記進去。這樣 `rollout history` 裡就可能看到例如：
	1. `update image to nginx:1.27-alpine`
	2. `rollback to stable revision after bad rollout`
	3. `change readiness probe path to /health`
- 所以 `CHANGE-CAUSE` 不是 Kubernetes 自己推理出來的根因，而是 **你是否有主動留下人類可讀的變更說明**。

### 為什麼 `namespace: darkmind` 只宣告一次，不用在 Pod template 再寫一次

- 這題要先分清楚：Deployment 是一個 namespaced resource，而 Pod template 不是獨立送進 API server 的另一個頂層 resource；它只是 Deployment spec 裡的一段「未來要建立的 Pod 規格」。
- 所以當你在 Deployment 的 `metadata.namespace: darkmind` 指定 namespace 時，這個 Deployment controller 之後建立出來的 ReplicaSet 與 Pods，本來就會落在同一個 namespace，不需要在 `template.metadata` 再寫一次。
- 反過來說，`labels` 之所以在外層和 `template.metadata.labels` 都常出現，是因為它們用途不同：
	1. 外層 `metadata.labels` 是貼在 Deployment 物件自己身上
	2. `template.metadata.labels` 是貼在未來建立出來的 Pod 身上
- 這就是為什麼 namespace 不像 label 那樣常重複宣告。namespace 是由上層 namespaced resource 決定的範圍；label 則是不同物件各自要攜帶的屬性。

### `imagePullPolicy: IfNotPresent` 是什麼意思

- `IfNotPresent` 的意思是：**如果這個節點本機已經有該 image，就直接用本地快取；如果沒有，才去 registry 拉。**
- 以 [darkmind/scenarios/bad-rollout-01-good.yaml](darkmind/scenarios/bad-rollout-01-good.yaml) 來說，若 node 上之前已經拉過 `nginx:1.27-alpine`，那 container runtime 可能就不會再重新 pull。
- 它和 `Always` 的差異在於：`Always` 幾乎每次啟動都會先嘗試向 registry 確認 / 拉取；`IfNotPresent` 則優先信任 node 本地已有的 image。
- 實務上，`IfNotPresent` 常用於較穩定的版本標籤或 lab；`Always` 常用於你明確想每次都去確認最新內容的情境。不過真正上 production，很多團隊更偏好直接用 immutable image tag 或 digest，避免 `latest` 類歧義。

### `revisionHistoryLimit` 是什麼

- `revisionHistoryLimit: 5` 的意思是：Deployment 最多保留最近 `5` 份舊 revision 對應的歷史 ReplicaSets，方便之後查 `rollout history` 或做 `rollout undo`。
- 它不是「只能 rollout 五次」，而是 **舊 revision 歷史最多保留幾份**。超過之後，更舊的歷史 ReplicaSet 可能會被清理掉。
- 所以這個欄位主要影響的是：
	1. 你能往回看的 revision 深度
	2. 你能直接 rollback 的歷史範圍
	3. 要不要保留太多舊 ReplicaSet 佔用控制面資訊
- 在這個 lab 裡設成 `5`，就是讓你還有幾版歷史可觀察，但不把歷史無限累積下去。

### ⭐️如果第二次 apply 的 YAML 和第一次差很多，最後誰說了算

- 在這個 lab 裡，[darkmind/scenarios/bad-rollout-01-good.yaml](darkmind/scenarios/bad-rollout-01-good.yaml) 和 [darkmind/scenarios/bad-rollout-02-bad.yaml](darkmind/scenarios/bad-rollout-02-bad.yaml) 的 Deployment 都是同一個 resource：
	1. kind 都是 `Deployment`
	2. `metadata.name` 都是 `darkmind-rollout`
	3. `metadata.namespace` 都是 `darkmind`
- 所以它們不是兩個 Deployment controller 在互相打架，而是 **同一個 Deployment 物件被第二次 apply 更新內容**。換句話說，控制器還是只有一個，名字也還是同一個，只是它的 spec 被改了。
- 在一般 `kubectl apply -f` 的語意下，對同名同 namespace 的同一個物件再 apply 新 YAML，API server 會更新這個既有物件；Deployment controller 接著就根據更新後的 spec 行事。簡單講，**後 apply 的宣告式期望狀態會成為新的目標狀態**。
- 但要補一個重要邊界：這句話只對「同一個物件」成立。如果第二份 YAML 換了不同的 `name` 或不同的 `namespace`，那就會變成另一個 Deployment，也就真的會有第二個控制器存在。
- 還有一個常見誤解也要一起講清楚：第二份 YAML 若**沒有**包含第一份 YAML 裡的某個「不同資源」，不代表它會自動刪掉那個資源。今天 good 檔裡有 `Service`、bad 檔裡沒有，但你對 bad 檔 apply 之後，原本那個 Service 不會因為「第二份沒寫」就自動被刪除。因為 Service 是另一個獨立物件，不是同一個 Deployment 物件的一部分。
- 一句話口訣：**同名同 namespace 的 Deployment 再 apply，是更新同一個控制器；不是兩個控制器互相聽指揮。**

### 為什麼 `kubectl rollout undo` 之後 revision 會變成 3

- 這個點很重要：`undo` 不是把 revision 計數器往回撥，而是 **建立一次新的 rollout**，只不過它把 Pod template 改回先前 revision 的內容。
- 所以你原本有 revision `1` 和 `2`，做 `undo` 後看到 revision `3`，完全合理。revision `3` 的內容可能和 revision `1` 很像，甚至一樣，但它仍是一次新的發布事件。
- 可以把它理解成：
	1. revision `1`：最初 good version
	2. revision `2`：bad version
	3. revision `3`：把內容回退到 revision `1` 的新 rollout
- 一句話口訣：**undo 回的是內容，不是 revision 編號。**

### kubelet 到底根據什麼決定要不要重啟 container

- 在 node 上，真正盯著 Pod 與 container 狀態並執行重啟的是 kubelet。
- 對 kubelet 來說，核心問題不是「你這個 app 邏輯有沒有 bug」，而是：**這個 Pod 規格要求應該有一個正在運作的 container，但它現在退出了，是否應該再把它拉起來**。
- 常見會觸發 kubelet 重新啟動 container 的情況包括：
	1. container 主程序退出，且 exit code 非 `0`
	2. container 正常退出，但 Pod 的 `restartPolicy` 要求應重啟
	3. liveness probe 失敗，kubelet 會把 container kill 掉，再依 `restartPolicy` 決定是否重啟
- 所以 kubelet 決定是否重啟，看的主要是 **container 是否終止**、**Pod 規格允不允許重啟**、以及 **健康檢查是否要求它被重建**，而不是直接理解應用程式的商業邏輯。
- 一句話口訣：**kubelet 重啟 container，不是因為它懂你的 app，而是因為它要把 Pod 規格要求的執行狀態維持住。**

### `restartPolicy` 在 Deployment 裡實際扮演什麼角色

- `restartPolicy` 是 **Pod spec 的欄位**，不是 Deployment spec 自己獨有的欄位。
- 但這裡要修正成更準的說法：當 Pod 是由 Deployment 管理時，template 裡的 `restartPolicy` **實際上必須是** `Always`。不是只是習慣如此，而是這種控制器的工作負載語意本來就是長期維持服務。
- 如果你在 Deployment 的 Pod template 裡改成 `OnFailure` 或 `Never`，一般不會變成一個「只是比較少見但還能正常跑」的設計，而是更接近 **不符合 Deployment / ReplicaSet 的預期語意，通常會在 API 驗證層就被拒絕**。
- 從設計上也能看出衝突：Deployment 想維持的是長期提供服務的 Pod 集合；若 Pod 內 container 結束後不應再自動重啟，那它會更像 `Job` / `CronJob` 這類「做完就結束」的工作負載，而不是 Deployment。
- ⭐️這代表什麼？代表同一顆 Pod 裡的 container 若退出，**先由 kubelet 在 Pod 內重啟 container**；不會第一時間就靠 Deployment 重新建一顆新 Pod。
- 只有在 Pod 這個物件本身消失、不再符合條件、或 ReplicaSet 需要補副本時，控制器層才會再建立新的 Pod。
- 所以在 Deployment 情境裡，你可以把責任拆成兩層：
	1. **kubelet + restartPolicy=Always**：處理「同一顆 Pod 裡 container 掛了怎麼辦」
	2. **Deployment / ReplicaSet**：處理「整體應該維持幾顆 Pod、用哪個 template、要不要 rollout / rollback」
- 一句話口訣：**Deployment 負責維持 Pod 集合，restartPolicy 負責同一顆 Pod 裡 container 掛掉後怎麼處理。**

### 如果想把 crash-loop 壞 Pod 停掉，還不要讓它再自動重建

- 這題要先分清楚「我想刪的是 Pod 還是我想停的是控制器」。
- 如果 `darkmind-crash-loop` 是由 Deployment 管理，那 **不應該** 直接只刪 Pod，因為 ReplicaSet 會立刻再補一顆新的 Pod，結果只是再壞一次。
- 這種情況下，常見正確做法有兩種：
	1. **暫時停掉但保留 Deployment**：

```bash
kubectl scale deploy/darkmind-crash-loop -n darkmind --replicas=0
```

	2. **整個情境不要了，直接移除控制器**：

```bash
kubectl delete deploy darkmind-crash-loop -n darkmind
```

- 不建議的做法則是這種：

```bash
kubectl delete pod -n darkmind <crash-loop-pod-name>
```

- 因為這只是在刪現有 Pod，不是在停掉背後的期望狀態；Deployment / ReplicaSet 看到少一顆，就會補一顆回來。
- 一句話口訣：**要停自動重建，就處理 Deployment / ReplicaSet，不要只刪 Pod。**

### 對新版 YAML 再做一次 `kubectl apply`，算不算常見 rollout 做法

- 算，這是很常見的 **declarative update** 思路。你把新的 Deployment YAML 套上去，若 Pod template 有差異，Deployment controller 就會啟動新的 rollout。
- 在小型專案、手動操作、教學情境、或 GitOps / CI 產出的最終步驟裡，對新版 YAML 做 `kubectl apply -f ...` 是很常見的更新方式。
- 真實團隊裡常見的不是每次都手打這條命令，而是：
	1. `kubectl apply -f` 由 CI/CD 幫你執行
	2. `kustomize build ... | kubectl apply -f -`
	3. `helm upgrade`
	4. GitOps controller 代為套用宣告式變更
- 但底層精神是一樣的：**把新的期望狀態宣告給 API server，再讓 Deployment controller 做 rollout。**

### `bad-rollout-01-good.yaml` 和 `bad-rollout-02-bad.yaml` 的主要差異

- 如果只看「會不會造成 rollout 卡住」這件事，兩份 YAML 的 **關鍵差異主要只有兩個**：
	1. `image`
	2. `imagePullPolicy`
- 在 [darkmind/scenarios/bad-rollout-01-good.yaml](darkmind/scenarios/bad-rollout-01-good.yaml) 裡，image 是 `nginx:1.27-alpine`，`imagePullPolicy` 是 `IfNotPresent`。
- 在 [darkmind/scenarios/bad-rollout-02-bad.yaml](darkmind/scenarios/bad-rollout-02-bad.yaml) 裡，image 是 `nginx:this-tag-should-not-exist-darkmind`，`imagePullPolicy` 是 `Always`。
- 其他 rollout 相關核心欄位，例如 `replicas`、`strategy.rollingUpdate.maxUnavailable`、`maxSurge`、`readinessProbe`、resources、labels、selector，基本上都維持一致。
- 還有一個 repo 層面的差異值得注意：good 版本 YAML 另外還包含一個 `Service`，bad 版本 YAML 則只有 `Deployment`。但這個差異 **不是這次 rollout 卡住的主因**，因為你前一步已經建立過同名 Service；後面只對 bad Deployment apply，不會自動刪掉先前的 Service。
- 所以如果今天要收成一句最精準的說法：**這兩份 rollout YAML 的設計重點，就是盡量只改 image 相關條件，讓你能把 rollout 卡住的主因鎖在 image pull 失敗，而不是混入其他變數。**

### 實務上 rollout 最常改的是不是 image 版本

- 在很多服務型應用裡，**最常見的 rollout 觸發點確實是 image tag / digest 更新**。這是最典型、最容易對應到「發布新版本」的情境。
- 但實務上不只這一種。只要 Deployment 的 **Pod template** 發生變化，都可能觸發新的 rollout，例如：
	1. image tag / digest 變更
	2. environment variables 變更
	3. command / args 變更
	4. readiness / liveness probe 變更
	5. resource requests / limits 變更
	6. volume mount、secret / config reference 變更
	7. labels / annotations 寫在 Pod template 內的變更
- 所以可以這樣記：**最常見的是 image 版本變更，但不是唯一；真正會觸發 rollout 的，是 Pod template 的變更。**

### 為什麼 `CrashLoopBackOff` 明明是 Pod 狀態，但真正反覆重啟的是 container

- 這個混淆非常常見。你在 `kubectl get pods` 看到的是 Pod 列表，所以 `STATUS` 欄位會把人最關心的狀態濃縮顯示在 Pod 那一行上，例如 `Running`、`ImagePullBackOff`、`CrashLoopBackOff`。
- 但 `CrashLoopBackOff` 真正描述的，不是「Pod 整個物件被刪掉又重建很多次」，而是 **Pod 裡的某個 container 一直啟動、退出、再被 kubelet 重啟，並進入 backoff**。
- 在今天這個 `darkmind-crash-loop` 情境裡，你可以從 **⭐️Pod 名稱幾乎不變**、但 `RESTARTS` 一直增加看出這點。這說明大多數時候是 **⭐️同一顆 Pod 還在，只是其中的 container 不斷重啟**。
- 若是 Pod 本身真的被刪掉又重建，你通常更容易看到的是 **Pod 名稱改變**、新的 Pod 被產生，這比較接近 ReplicaSet / Deployment 層的替換行為。
- 所以 `CrashLoopBackOff` 可以理解成：**Pod 那一行在替你摘要顯示「這顆 Pod 裡的 container 正在 crash + backoff」**，不是說 Pod 物件自己在不停重建。
- 一句話口訣：**畫面上是 Pod 狀態，底層上是 container 重啟循環。**

## Flashcards

<!-- lesson 進行後再回填 -->
