# 2026-04-15 Darkmind Exec Port Forward Readiness Fail Command

## 今日指令練習目標

1. 用 healthy baseline 練出 `exec` 與 `port-forward` 各自的正常用途。
2. 用 `readiness-fail` 情境練出 `Running`、`Ready`、`Service endpoints` 之間的差異。
3. 練到看到輸出時能說出：我現在是在驗證 container 內部、local tunnel，還是 Service 是否會把流量收進來。

## 這次要驗證的路徑或問題

1. `exec` 比較像 container 內部觀察，不等於正常服務流量已成立。
2. `port-forward` 很適合做臨時連線驗證，但可能繞過正式流量收斂。
3. readiness fail 時，container 可能還在跑，但 `endpoints` 會把它排除在 Service 後面。

## 今天要看的資源

1. `darkmind` namespace
2. `darkmind-healthy` Deployment / Service / Pod
3. `darkmind-readiness-fail` Deployment / Service / Pod / Endpoints

---

## Command 1

### 要驗證的問題

- 正式進 Day 3 前，哪組操作最適合先建立健康基準與乾淨工作區？

### 三個可選指令

```bash
kubectl apply -f darkmind/namespace.yaml
kubectl apply -f darkmind/healthy.yaml
kubectl get pods,svc,endpoints -n darkmind

kubectl apply -f darkmind/scenarios/readiness-fail.yaml

kubectl exec -it -n darkmind deploy/darkmind-healthy -- sh
```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待補

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 2

### 要驗證的問題

- 在 healthy baseline 下，哪個指令最適合先回答「container 裡面的服務本身有沒有正常回應」？

### 三個可選指令

```bash
kubectl exec -it -n darkmind deploy/darkmind-healthy -- sh

kubectl rollout history deploy/darkmind-healthy -n darkmind

kubectl get events -n darkmind --sort-by=.lastTimestamp
```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待補

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 3

### 要驗證的問題

- 在 healthy baseline 下，若想從本機臨時打到叢集裡的 HTTP 服務，哪組操作最適合建立 local tunnel 並驗證服務可達？

### 三個可選指令

```bash
kubectl port-forward -n darkmind svc/darkmind-healthy 8080:80

kubectl describe pod -n darkmind -l app=darkmind-healthy

kubectl logs -n darkmind -l app=darkmind-healthy
```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待補

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 4

### 要驗證的問題

- 若要把 readiness fail 情境放進叢集，並先確認它已經呈現 `Running` 但不 `Ready`，哪組操作最適合？

### 三個可選指令

```bash
kubectl apply -f darkmind/scenarios/readiness-fail.yaml
kubectl get pods,endpoints -n darkmind

kubectl rollout undo deploy/darkmind-readiness-fail -n darkmind

kubectl exec -it -n darkmind deploy/darkmind-readiness-fail -- sh
```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待補

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 5

### 要驗證的問題

- 當 Pod 已經 `Running` 但 `0/1 Ready` 時，哪組最小操作最適合對照「container 內部其實活著」和「Service 仍不會把它收進去」這兩件事？

### 三個可選指令

```bash
kubectl exec -it -n darkmind deploy/darkmind-readiness-fail -- sh
kubectl get endpoints -n darkmind darkmind-readiness-fail

kubectl rollout history deploy/darkmind-readiness-fail -n darkmind

kubectl logs -n darkmind -l app=darkmind-readiness-fail --previous
```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待補

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- 待補
- 待補

### 練習後還不順手的地方

- 待補

### 補充

- 視需要補最小上下文即可。
