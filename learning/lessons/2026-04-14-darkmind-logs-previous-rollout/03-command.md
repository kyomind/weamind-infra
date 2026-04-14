# 2026-04-14 Darkmind Logs Previous Rollout Command

## 今日指令練習目標

1. 用 `crash-loop` 情境練出 `logs` 與 `logs --previous` 的最小判讀鏈。
2. 用 `bad-rollout` 情境練出 `rollout status`、`history`、`undo` 的 Deployment 層級操作鏈。
3. 練到看到輸出時能說出：我現在在看 app 證據、container 重啟前證據，還是 Deployment rollout 證據。

## 這次要驗證的路徑或問題

1. CrashLoopBackOff 類問題和 image pull 類問題，為什麼第一個高價值指令不同。
2. `logs` 與 `logs --previous` 在 crash 類問題裡如何互補。
3. rollout 卡住時，為什麼應切到 Deployment 視角看 `status`、`history`、`undo`。

## 今天要看的資源

1. `darkmind` namespace
2. `darkmind-crash-loop` Deployment / Pod
3. `darkmind-rollout` Deployment / Service / Pods

---

## Command 1

### 要驗證的問題

- 正式進 Day 2 壞情境前，哪組操作最適合先建立今天的健康基準與乾淨工作區？

### 三個可選指令

```bash
kubectl apply -f darkmind/namespace.yaml
kubectl apply -f darkmind/healthy.yaml
kubectl get pods -n darkmind

kubectl apply -f darkmind/scenarios/crash-loop.yaml

kubectl logs -n darkmind -l app=darkmind-crash-loop
```

### 指令

```bash
kubectl apply -f darkmind/namespace.yaml
kubectl apply -f darkmind/healthy.yaml
kubectl get pods -n darkmind
kubectl get pods -n darkmind
```

### 關鍵輸出

```bash
namespace/darkmind created
deployment.apps/darkmind-healthy created
service/darkmind-healthy created

NAME                                READY   STATUS    RESTARTS   AGE
darkmind-healthy-85c6dcf689-zth8m   0/1     Running   0          2s

NAME                                READY   STATUS    RESTARTS   AGE
darkmind-healthy-85c6dcf689-zth8m   1/1     Running   0          19s
```

### 使用者選擇理由

- 使用者選第一組指令，理由是 Day 2 仍然要先建立 `namespace` 與健康基準資源，讓後面 `crash-loop` 與 `bad-rollout` 的觀察都有乾淨的比較座標。
- 使用者也主動補了一次 `kubectl get pods -n darkmind`，確認健康 Pod 從剛建立時的 `0/1 Running` 暫態，進一步收斂到 `1/1 Running` 的穩定狀態。

### AI 判讀與修正

- 這個選擇是對的，而且你多補一次 `kubectl get pods -n darkmind` 這個動作也很對。Day 2 雖然主題變成 `logs` 與 `rollout`，但前提仍然是先建立 **可比較的健康基準**，不然後面看到壞情境時，很難分清楚哪些是異常、哪些只是剛建立時的正常暫態。
- 你這次輸出裡最值得注意的點是：第一次 `get pods` 時看到 `0/1 Running`、`AGE 2s`，第二次再看則變成 `1/1 Running`。這很適合拿來提醒自己：`Running` 不等於已 Ready，`0/1` 到 `1/1` 的過程本身就是正常啟動鏈的一部分。
- 也就是說，今天這一輪不只是在「建立資源」，而是在建立 **之後辨認 crash 或 rollout 問題時的健康對照組**。

### 一句話收斂

- Day 2 進壞情境前，仍要先建立健康基準並確認 Pod 真正收斂到 `1/1 Running`；這樣後面看到 `CrashLoopBackOff` 或 rollout 卡住時，才有穩定的比較座標。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- 若要把 CrashLoopBackOff 情境真正放進叢集，哪個操作最適合先建立觀察對象，並確認它已經出現異常？

### 三個可選指令

```bash
kubectl apply -f darkmind/scenarios/crash-loop.yaml
kubectl get pods -n darkmind

kubectl describe pod -n darkmind -l app=darkmind-healthy

kubectl rollout history deploy/darkmind-rollout -n darkmind
```

### 指令

```bash
kubectl get pods -n darkmind
kubectl apply -f darkmind/scenarios/crash-loop.yaml
kubectl get pods -n darkmind
```

### 關鍵輸出

```bash
NAME                                READY   STATUS    RESTARTS   AGE
darkmind-healthy-85c6dcf689-zth8m   1/1     Running   0          19s

deployment.apps/darkmind-crash-loop created

NAME                                  READY   STATUS             RESTARTS      AGE
darkmind-crash-loop-f6dfb6fdd-7d97k   0/1     CrashLoopBackOff   1 (11s ago)   18s
darkmind-healthy-85c6dcf689-zth8m     1/1     Running            0             17m
```

### 使用者選擇理由

- 使用者選第一組指令，理由是要先把預期會壞掉的 `Deployment` 套進叢集，讓 `CrashLoopBackOff` 情境真正出現，後面才有正確的觀察對象可看。
- 使用者也刻意把 `apply` 和第二次 `get pods` 分開執行，避免 apply 完立刻觀察時還沒收斂到異常狀態，這個操作節奏是合理的。

### AI 判讀與修正

- 這個選擇是對的，而且你這次刻意把 `apply` 與後續觀察拆開，這個節奏很實務。因為 `CrashLoopBackOff` 類問題不是一套上去就一定瞬間穩定顯示同一個狀態；先建立情境，再補一次 `get pods`，比較容易看到已經進入重啟循環後的樣子。
- 這份輸出最有價值的地方，是你同時保留了健康基準與壞情境的對照：`darkmind-healthy` 仍是 `1/1 Running`，而新的 `darkmind-crash-loop` 已經變成 `0/1 CrashLoopBackOff`，而且 `RESTARTS` 已經是 `1`。這正好說明今天的問題已經不是 image pull 前段，而是 **container 有啟動過、又退出，開始進入重啟 backoff**。
- 你這輪也順手再次驗證了一個很重要的概念：不是所有 `Running` 都等於 Ready，也不是所有異常都該先從 `describe` 開始。現在既然已經看到 `CrashLoopBackOff` 和 `RESTARTS` 增加，下一輪最有價值的證據就會開始往 `logs` 偏移。

### 一句話收斂

- 把 `crash-loop` 情境套進叢集後，先用 `kubectl get pods -n darkmind` 確認它真的進到 `CrashLoopBackOff` 且已有重啟次數；這表示問題已經落到 container 執行與退出循環，而不是建立前段。

### 狀態

- 已完成

---

## Command 3

### 要驗證的問題

- 已經看到 Pod 卡在 `CrashLoopBackOff` 後，哪個指令最適合先拿到這次 container 執行期留下的應用輸出？

### 三個可選指令

```bash
kubectl logs -n darkmind -l app=darkmind-crash-loop

kubectl get events -n darkmind --sort-by=.lastTimestamp

kubectl rollout undo deploy/darkmind-crash-loop -n darkmind
```

### 指令

```bash
kubectl logs -n darkmind -l app=darkmind-crash-loop
kubectl get pods -n darkmind
```

### 關鍵輸出

```bash
darkmind crash-loop scenario: container will exit now

NAME                                  READY   STATUS             RESTARTS        AGE
darkmind-crash-loop-f6dfb6fdd-7d97k   0/1     CrashLoopBackOff   6 (2m19s ago)   8m20s
darkmind-healthy-85c6dcf689-zth8m     1/1     Running            0               17m
```

### 使用者選擇理由

- 使用者選第一個指令，理由是既然上一輪已經確認 Pod 進到 `CrashLoopBackOff`，這一輪最有價值的下一步就是直接看 app / container 自己留下的輸出。
- 使用者也補了一次 `kubectl get pods -n darkmind`，確認目前 Pod 仍停在 `CrashLoopBackOff` 且 `RESTARTS` 已持續增加。

### AI 判讀與修正

- 這個選擇是對的。當上一輪已經明確看到 `CrashLoopBackOff` 與 `RESTARTS` 增加時，`kubectl logs` 是今天最直接的下一步，因為它開始回答「**container 自己到底輸出了什麼**」，而不是只停在 Kubernetes 狀態摘要。
- 這份輸出也很適合對照 `darkmind/scenarios/crash-loop.yaml`：你看到的 `darkmind crash-loop scenario: container will exit now`，正好就是 YAML 裡刻意設計的輸出，代表這顆 container 確實有啟動、印出訊息、然後退出。這進一步支持我們對 `CrashLoopBackOff` 的判讀：問題不是 image pull，也不是 container 根本沒跑起來，而是 **它有跑，但很快結束**。
- 你補的第二次 `get pods` 也很有價值，因為 `RESTARTS=6` 代表 kubelet 還在持續嘗試重啟。這時 `kubectl logs` 通常還看得到最新那一輪或當前 container instance 的輸出，但如果你真正要抓「上一輪怎麼死的」，下一步會更適合看 `kubectl logs --previous`。

### 一句話收斂

- 當 Pod 已進到 `CrashLoopBackOff`，先用 `kubectl logs` 看 app 自己留下的直接輸出；若已確認它會反覆重啟，下一步就該切到 `kubectl logs --previous` 去補上一輪退出前的證據。

### 狀態

- 已完成

---

## Command 4

### 要驗證的問題

- 如果 container 很快就重啟，你想看上一輪已退出 container 的最後輸出，哪個指令最適合？

### 三個可選指令

```bash
kubectl logs -n darkmind -l app=darkmind-crash-loop --previous

kubectl exec -it -n darkmind deploy/darkmind-crash-loop -- sh

kubectl get svc -n darkmind
```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待回答

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 5

### 要驗證的問題

- 在做壞 rollout 前，哪組操作最適合先建立 `darkmind-rollout` 的健康基準，確認正常 rollout 會成功完成？

### 三個可選指令

```bash
kubectl apply -f darkmind/scenarios/bad-rollout-01-good.yaml
kubectl rollout status deploy/darkmind-rollout -n darkmind --timeout=60s

kubectl logs -n darkmind -l app=darkmind-healthy

kubectl delete namespace darkmind
```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待回答

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 6

### 要驗證的問題

- 當壞版本套上去後 rollout 卡住，哪組最小指令序列最適合先確認卡住、再看 revision 軌跡、最後做回退？

### 三個可選指令

```bash
kubectl apply -f darkmind/scenarios/bad-rollout-02-bad.yaml
kubectl rollout status deploy/darkmind-rollout -n darkmind --timeout=30s
kubectl rollout history deploy/darkmind-rollout -n darkmind
kubectl rollout undo deploy/darkmind-rollout -n darkmind

kubectl get configmap -n darkmind

kubectl port-forward -n darkmind svc/darkmind-rollout 8080:80
```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待回答

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- 待回填
- 待回填

### 練習後還不順手的地方

- 待回填

### 補充

- 固定收尾待回填。
