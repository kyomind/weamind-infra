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
- 所以你看到 `CrashLoopBackOff` 時，更接近「**還在重試，但目前因 backoff 暫停一下**」，不是「這個 Pod 已經被系統放棄並清掉」。
- 也因此，只要 Pod 還存在，而且對應 container logs 還沒被節點上的 log rotation 或 garbage collection 清掉，你通常都還能 `kubectl logs` / `kubectl logs --previous` 去看。
- 但這裡要補兩個邊界：
	1. `kubectl logs --previous` 只保證上一個已終止的 container instance，不是所有歷史輪次都保留。
	2. 如果 Pod 被刪掉、被新 Pod 取代、節點重開、或容器日志已被清理，你就可能拿不到先前那一輪的 logs。
- 一句話口訣：`CrashLoopBackOff` 通常是 **會繼續重試、不會自動刪 Pod**；但 logs 能不能一直拿到，不是永久保證，所以重要證據要早點留。

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

### 為什麼 `kubectl rollout undo` 之後 revision 會變成 3

- 這個點很重要：`undo` 不是把 revision 計數器往回撥，而是 **建立一次新的 rollout**，只不過它把 Pod template 改回先前 revision 的內容。
- 所以你原本有 revision `1` 和 `2`，做 `undo` 後看到 revision `3`，完全合理。revision `3` 的內容可能和 revision `1` 很像，甚至一樣，但它仍是一次新的發布事件。
- 可以把它理解成：
	1. revision `1`：最初 good version
	2. revision `2`：bad version
	3. revision `3`：把內容回退到 revision `1` 的新 rollout
- 一句話口訣：**undo 回的是內容，不是 revision 編號。**

## Flashcards

<!-- lesson 進行後再回填 -->
