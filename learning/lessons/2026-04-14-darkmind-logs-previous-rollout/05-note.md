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

## Flashcards

<!-- lesson 進行後再回填 -->
