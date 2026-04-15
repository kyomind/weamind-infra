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

```

### 指令

```bash
kubectl get po,svc,endpoints -n darkmind
```

### 關鍵輸出

```bash
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                                    READY   STATUS    RESTARTS   AGE
pod/darkmind-healthy-85c6dcf689-4xd98   1/1     Running   0          10m

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/darkmind-healthy   ClusterIP   10.43.212.162   <none>        80/TCP    10m

NAME                         ENDPOINTS       AGE
endpoints/darkmind-healthy   10.42.1.27:80   10m
```

### 使用者選擇理由

- 使用者選第一組，理由是今天要先建立並確認 healthy baseline，後面做 `exec`、`port-forward` 與 `readiness-fail` 時才有穩定對照座標。
- 使用者也主動補充：現在較新的 Kubernetes 版本底層更偏向 `EndpointSlice`，但今天 command drill 仍先用 `endpoints` 作為較直觀的觀察入口。
- 這一輪實際貼回的輸出只有第三個指令 `kubectl get po,svc,endpoints -n darkmind`；前兩個 `apply` 的結果被終端洗掉。

### AI 判讀與修正

- 這個選擇是對的，而且雖然前兩個 `apply` 的輸出沒保留下來，**第三個 `get` 的結果已經足夠證明 healthy baseline 當下是成立的**。
- 這份輸出最重要的第一個訊號是：`darkmind-healthy` Pod 目前是 **`1/1 Running`**。這表示不只是 Pod phase 在 `Running`，連 readiness 也已經通過；今天後面若再看到 `0/1 Running`，就能明確辨認那是壞情境，不是正常啟動暫態。
- 第二個訊號是：`darkmind-healthy` Service 已經存在，而且 `endpoints/darkmind-healthy` 內有 **`10.42.1.27:80`**。這代表對應的 Service 目前確實有一個可送流量的後端 Pod，這正是今天後面要拿來對照 `readiness-fail` 的關鍵基準。
- 你提到 `EndpointSlice` 也很對。CLI 現在會提示 **`v1 Endpoints is deprecated in v1.33+`**，這表示底層新方向是 `EndpointSlice`；但在今天的練習裡，先用 `kubectl get endpoints` 仍然合理，因為它輸出較短、較容易直接看出「Service 後面現在有沒有 Pod」。
- 這一輪的真正目的不是學 `apply`，而是建立今天的健康對照組：**Pod 已 Ready、Service 已存在、endpoints 也已有後端**。沒有這個對照組，後面很難精準判讀 `readiness-fail` 到底少了哪一層。

### 一句話收斂

- Day 3 開始前要先確認 healthy baseline：Pod 必須是 `1/1 Running`，而且 Service 後面真的有 `endpoints`；這樣後面看到 `readiness-fail` 時，才能清楚分辨是「container 還活著」還是「Service 已不再收流量」。

### 狀態

- 已完成

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
kubectl exec -it -n darkmind deploy/darkmind-healthy -- sh
wget -qO- http://127.0.0.1/
```

### 關鍵輸出

```bash
Alias tip: kex -n darkmind deploy/darkmind-healthy -- sh
/ #

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<h1>Welcome to nginx!</h1>
...
/ #
```

### 使用者選擇理由

- 使用者選第一個指令，理由是今天這一輪要先切進 container 內部視角；若能成功進到 shell，至少代表這個 Pod / container 當下是活著且可互動的。
- 使用者同時敏銳提出一個關鍵疑問：成功進入 container，是否真的已經回答了「container 裡面的服務本身有沒有正常回應」？

### AI 判讀與修正

- 這個選擇是對的，因為在三個候選裡，`kubectl exec` 確實最接近今天要的 **container 內部視角**；`rollout history` 和 `events` 都不會直接回答 container 裡面現在長什麼樣。
- 你後面的懷疑也完全正確，而且這正是這一輪最值得留下來的收穫：**`exec` 成功，只代表你拿到了 container 內部操作入口，不代表你已經證明服務本身有正常回應。**
- `kubectl exec ... -- sh` 本身比較像「拿到觀察位置」，而不是「完成驗證」。要真正回答「服務有沒有正常回應」，還要在 container 內多做一步，例如打 `127.0.0.1`、看 listening port、或檢查實際程序。
- 這一輪在你補跑 `wget -qO- http://127.0.0.1/` 之後，第二層驗證也已經補齊了。因為你在 container 內直接打到 `127.0.0.1`，拿到了預期的 **nginx welcome page HTML**，這代表至少在 container 內部視角下，HTTP 服務本身確實有正常回應。
- 所以這一輪現在可以完整收斂成兩句：**`exec` 負責切進 container 內部；container 內再打 `127.0.0.1` 才真正回答服務是否有回應。**

### 一句話收斂

- `kubectl exec` 先讓你切進 container 內部視角；再用 container 內的 `wget http://127.0.0.1/` 拿到 nginx 回應後，才算真正證明 **服務在 container 內部確實正常回應**。

### 狀態

- 已完成

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
