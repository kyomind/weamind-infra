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
