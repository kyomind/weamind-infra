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
kubectl logs -n darkmind -l app=darkmind-crash-loop --previous
kubectl logs -n darkmind -l app=darkmind-crash-loop --previous
kubectl get pods -n darkmind
kubectl logs -n darkmind -l app=darkmind-crash-loop --previous
```

### 關鍵輸出

```bash
darkmind crash-loop scenario: container will exit now

unable to retrieve container logs for containerd://e788ff6eb312b2594610893b7264098144fbab0723ad043cd90c1d73100dd848

NAME                                  READY   STATUS             RESTARTS      AGE
darkmind-crash-loop-f6dfb6fdd-7d97k   0/1     CrashLoopBackOff   8 (20s ago)   16m
darkmind-healthy-85c6dcf689-zth8m     1/1     Running            0             33m

darkmind crash-loop scenario: container will exit now
```

### 使用者選擇理由

- 使用者選第一個指令，理由是上一輪已經確認這是 `CrashLoopBackOff`，所以這一輪應該要直接看上一個已終止 container instance 的輸出。
- 使用者也敏銳觀察到一個很重要的現象：`kubectl logs --previous` 並不是每次都穩定成功，同一個 Pod 上有時拿得到、有時又短暫拿不到。

### AI 判讀與修正

- 這個選擇是對的，而且你觀察到的「有時拿得到、有時拿不到」正是 `CrashLoopBackOff` 排查裡非常真實的一個細節。`kubectl logs --previous` 看的不是固定歷史檔案，而是 **目前這個 Pod 對應的上一個已終止 container instance**；在快速重啟循環裡，這個對象本身就是流動的。
- 你這次拿到的內容和 current log 一樣，不是因為 `current` 與 `previous` 本質上一定相同，而是因為這個 lab 裡每一輪 container 執行的行為都一樣：都只印出 `darkmind crash-loop scenario: container will exit now`，然後立刻 `exit 1`。所以不論你抓到 current 還是 previous，內容都可能一模一樣。
- 中間那次 `unable to retrieve container logs for containerd://...` 也很有代表性。這通常不表示 Pod 被自動刪掉了，而更常見的是：**你查詢的那個瞬間，上一個已終止 container instance 的 log 目標正好不可用**。在快速重啟時，current / previous 的切換是移動中的，所以 `--previous` 天生就比一般 `logs` 更容易遇到時序窗口。
- 這也再次說明：如果你真的很在意上一輪退出前的輸出，最好 **盡早抓、盡早存**，而不是假設之後任何時間都一定能補拿到。

### 一句話收斂

- `kubectl logs --previous` 很適合抓上一輪怎麼退出，但在 `CrashLoopBackOff` 的快速重啟循環裡，它不是每次都穩定可得；若每一輪 app 行為相同，current 和 previous 的內容也可能看起來完全一樣。

### 狀態

- 已完成

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
kubectl apply -f darkmind/scenarios/bad-rollout-01-good.yaml
kubectl rollout status deploy/darkmind-rollout -n darkmind --timeout=60s
```

### 關鍵輸出

```bash
deployment.apps/darkmind-rollout created
service/darkmind-rollout created

deployment "darkmind-rollout" successfully rolled out
```

### 使用者選擇理由

- 使用者選第一組指令，理由是要先建立 `darkmind-rollout` 的健康基準，確認正常版本的 Deployment 能順利完成 rollout，後面套壞版本時才有對照組。
- 使用者也追問了兩個重點：第一次 `apply` 建立 Deployment 是否也算 rollout，以及 `kubectl rollout status --timeout=60s` 若超時代表什麼。

### AI 判讀與修正

- 這個選擇是對的。進壞 rollout 之前，先用 good version 建立一條「正常 rollout 會成功完成」的基準線，這樣後面 bad version 卡住時，你才知道問題不是 rollout 指令本身，而是新版本內容有問題。
- 你第一個追問方向也對：**第一次 apply 建立 Deployment，實務上也會觸發第一次 rollout**。因為 Deployment controller 會依照新建立的 Pod template 建立第一個 ReplicaSet，再把 Pod 推到目標副本數。也就是說，雖然它不是「從舊版更新到新版」的 rollout，但在 Deployment 視角下，這仍是一個 rollout 過程，所以 `kubectl rollout status` 查得到完全合理。
- 第二個追問也很重要：`--timeout=60s` 的意思不是「60 秒後幫你修好」，而是 **最多等 60 秒看 rollout 有沒有完成**。若時間內沒完成，`kubectl rollout status` 會以 timeout / non-zero exit 結束，回答你的是「**在這段等待時間內，rollout 沒有成功收斂**」。它本身不會自動 rollback，也不會自動刪資源。
- 所以這一輪可以收成兩個穩定觀念：
- 第一，**第一次 apply 建立 Deployment 也可以視為第一次 rollout**。
- 第二，`rollout status --timeout` 是觀察等待上限，不是修復機制；超時代表 rollout 仍未完成，下一步才輪到你做更深觀察或回退判斷。

### 一句話收斂

- 先用 good version 建立正常 rollout 基準；第一次 apply 建立 Deployment 本身也會形成第一次 rollout，而 `rollout status --timeout` 只是設定等待上限，超時代表 rollout 尚未完成，不代表系統自動修復或自動回退。

### 狀態

- 已完成

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
kubectl apply -f darkmind/scenarios/bad-rollout-02-bad.yaml
kubectl rollout status deploy/darkmind-rollout -n darkmind --timeout=30s
kubectl rollout history deploy/darkmind-rollout -n darkmind
kubectl rollout undo deploy/darkmind-rollout -n darkmind
kubectl rollout status deploy/darkmind-rollout -n darkmind --timeout=30s
kubectl rollout history deploy/darkmind-rollout -n darkmind
```

### 關鍵輸出

```bash
deployment.apps/darkmind-rollout configured

Waiting for deployment "darkmind-rollout" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition

deployment.apps/darkmind-rollout
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

deployment.apps/darkmind-rollout rolled back

deployment "darkmind-rollout" successfully rolled out

deployment.apps/darkmind-rollout
REVISION  CHANGE-CAUSE
2         <none>
3         <none>
```

### 使用者選擇理由

- 使用者選第一組指令，理由是要依照今天的 rollout 排查鏈，先套壞版本、再確認 rollout 卡住、接著看 revision 軌跡，最後做 `undo` 回退。
- 使用者也刻意把四個主要指令分開時間執行，並在 `undo` 後額外再跑一次 `rollout status` 與 `rollout history`，確認 rollback 之後 Deployment 真的重新收斂。
- 使用者補充追問了兩個很好的觀察點：`CHANGE-CAUSE` 為什麼是 `<none>`，以及為什麼 `undo` 後 revision 會從 `2` 變成 `3`。

### AI 判讀與修正

- 這個選擇是對的，而且你這次不是機械式照抄，而是把四個步驟拆開觀察，這很接近真實 incident 的節奏。這份輸出其實把整條 rollout 排查鏈都走完了：先 `configured` 套上壞版本，再用 `rollout status` 看到它在等待舊 replica 終止且最終 timeout，接著用 `rollout history` 確認目前至少有 revision `1` 和 `2`，最後 `undo` 後再用一次 `rollout status` 確認恢復成功。
- `Waiting for deployment ... 1 old replicas are pending termination...` 這段訊息很有價值。它代表 Deployment controller 正在進行 rolling update，但新舊 ReplicaSet 的替換沒有順利收斂，所以在你設定的等待窗口內 rollout 沒完成。這就是今天想練的 Deployment 層級證據，而不是單顆 Pod log。
- 你最後再跑一次 `rollout history` 非常好，因為它驗證了一個容易誤解的點：`kubectl rollout undo` **不是把 revision 計數器倒退**，而是建立一個新的 rollout，讓 Deployment 的 Pod template 回到先前 revision 的內容。所以 undo 後看到 revision `3` 很正常；它代表「第三次 rollout 的內容等同於先前的好版本」，不是把數字改回 `1`。
- 這一輪也順手補出一個實務判斷：rollout 類問題的最小修復鏈通常不是「先長時間盯 Pod」，而是 **先判斷 rollout 是否卡住、確認可回退 revision，再做 undo，最後再確認 rollout 是否恢復成功**。

### 一句話收斂

- 壞版本 rollout 卡住時，先用 `rollout status` 確認失敗，再用 `rollout history` 看 revision 軌跡，最後用 `rollout undo` 觸發新的回退 rollout；undo 成功後 revision 會往前增加，不會倒退回舊數字。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- `kubectl logs` 與 `kubectl logs --previous` 讓我分清楚 current 與上一輪已退出 container 的證據邊界，也看到了 `CrashLoopBackOff` 裡 `--previous` 不一定每次都穩定可得。
- `kubectl rollout status`、`kubectl rollout history`、`kubectl rollout undo` 讓我看懂 Deployment rollout 卡住時，不該只盯單顆 Pod，而要切到 revision 與回退這個控制面層級。

### 練習後還不順手的地方

- rollout 卡住時，何時該先補 `describe` / `events`，何時該直接 rollback，這個 incident 判斷還要再多練。

### 補充

- 固定收尾待執行：

```bash
kubectl delete namespace darkmind
```
