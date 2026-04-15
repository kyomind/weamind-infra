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
kubectl port-forward -n darkmind svc/darkmind-healthy 8080:80
curl -I http://127.0.0.1:8080/
```

### 關鍵輸出

```bash
Alias tip: k port-forward -n darkmind svc/darkmind-healthy 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Handling connection for 8080

HTTP/1.1 200 OK
Server: nginx/1.27.5
Date: Wed, 15 Apr 2026 03:48:35 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Wed, 16 Apr 2025 12:55:34 GMT
Connection: keep-alive
ETag: "67ffa8c6-267"
Accept-Ranges: bytes
```

### 使用者選擇理由

- 使用者選第一個指令，因為這一輪的目標是從本機臨時打到叢集裡的 HTTP 服務，`kubectl port-forward` 正是三個選項裡唯一會真的建立 local tunnel 的操作。
- 使用者也明確要求：這一輪不只要知道怎麼執行，還要理解這個指令實際在資料路徑上做了什麼。

### AI 判讀與修正

- 這個選擇是對的，而且輸出也完整證明了本機臨時 tunnel 已成功建立，`curl` 確實打到了叢集內的 nginx 服務。
- 這一輪 `port-forward` 的具體資料路徑、`127.0.0.1:8080 -> 80` 的意義，以及實務上常見的 forwarding 對象與情境，整理在 `05-note.md`，command 這裡只保留最小收斂：**你已驗證 debug 用的本機 tunnel 可用，但這不等於正式 Service / Ingress / 外部流量路徑都已驗證完成。**

### 一句話收斂

- `kubectl port-forward` 會在本機開一個暫時的 `127.0.0.1:8080` 入口，並把流量透過 `kubectl` 轉送到叢集內 `svc/darkmind-healthy` 的 `80` port；`curl` 拿到 `200 OK` 代表這條 debug 用的本機 tunnel 已成功打到服務。

### 狀態

- 已完成

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
kubectl apply -f darkmind/scenarios/readiness-fail.yaml
kubectl get pods,endpoints -n darkmind
```

### 關鍵輸出

```bash
deployment.apps/darkmind-readiness-fail created
service/darkmind-readiness-fail created

Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                                          READY   STATUS    RESTARTS   AGE
pod/darkmind-healthy-85c6dcf689-4xd98         1/1     Running   0          56m
pod/darkmind-readiness-fail-8c5dffc59-bjl5c   0/1     Running   0          2s

NAME                                ENDPOINTS       AGE
endpoints/darkmind-healthy          10.42.1.27:80   56m
endpoints/darkmind-readiness-fail                   2s
```

### 使用者選擇理由

- 使用者選第一組，因為這一輪的目標就是先把 `readiness-fail` 情境放進叢集，再立刻確認它是否出現了預期的 `Running` 但不 `Ready`，以及 `endpoints` 有沒有因此變成空的。

### AI 判讀與修正

- 這個選擇是對的。這一輪最重要的不是先進 container，也不是先 rollback，而是先確認壞情境 **真的已經形成**。
- 輸出裡最關鍵的第一個訊號是：`pod/darkmind-readiness-fail-...` 目前是 **`0/1 Running`**。這正好對上今天前面 QA 與 Command 1 建立的對照：Pod phase 還在 `Running`，表示 container 沒 crash；但 `READY` 是 `0/1`，表示 Kubernetes 已明確判定它目前 **not ready**。
- 第二個關鍵訊號是：`endpoints/darkmind-readiness-fail` 目前是空的。這正是今天 Day 3 最核心的證據之一，因為它表示 **雖然 Pod 還活著，但 Service 並沒有把它收進可送流量的後端名單**。
- 也就是說，這一輪已經把今天想看的差異具體化了：**container 可能還在跑，但 readiness 沒過時，Service 仍可以完全不送流量給它。** 這也是為什麼 Day 3 一定要把 Pod 狀態和 `endpoints` 一起看。

### 一句話收斂

- `readiness-fail` 情境成立後，可以同時看到 **`0/1 Running`** 和 **空的 `endpoints`**；這表示 Pod / container 仍在跑，但 Service 已不把它當成可送流量的後端。

### 狀態

- 已完成

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
kubectl exec -it -n darkmind deploy/darkmind-readiness-fail -- sh
kubectl get endpoints -n darkmind darkmind-readiness-fail
```

### 關鍵輸出

```bash
Alias tip: kex -n darkmind deploy/darkmind-readiness-fail -- sh
/ #

Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS   AGE
darkmind-readiness-fail               5m42s
```

### 使用者選擇理由

- 使用者選第一組，理由是這一輪要把兩件事並排看清楚：一方面 `exec` 進得去，代表 Pod / container 其實還在運作；另一方面 `endpoints` 仍是空的，代表它雖然活著，卻不是可接流量的後端。

### AI 判讀與修正

- 這個選擇是對的，因為在三個候選裡，只有第一組能同時回答今天這一輪要刻意對照的兩件事：**container 內部是否仍可互動**，以及 **Service 是否仍把它納入後端**。
- 第一個關鍵訊號是：你仍然可以 `kubectl exec -it -n darkmind deploy/darkmind-readiness-fail -- sh` 進到 container 裡。這表示至少在這個情境下，Pod / container 並沒有 crash，也不是無法互動的狀態。
- 第二個關鍵訊號是：`kubectl get endpoints -n darkmind darkmind-readiness-fail` 仍然顯示 **空的 `ENDPOINTS`**。這表示雖然 container 還活著，但 Service 依然沒有把它當成健康後端。
- 這一輪正好把 Day 3 的核心邊界完整對齊：**`exec` 得進去，不等於 Service 會把流量送進去。** 也就是說，container 層的「活著 / 可互動」，和 Service 層的「可收流量」，是兩件必須分開看的事。

### 一句話收斂

- 在 `readiness-fail` 情境裡，**`exec` 仍可能成功**，但 `endpoints` 依然可以是空的；這表示 container 還活著，不代表它已被 Service 視為可收流量的健康後端。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- `kubectl get po,svc,endpoints -n darkmind` 幫我建立 healthy baseline：確認 Pod 已 Ready，而且 Service 後面真的有可送流量的後端。
- `kubectl exec ... -- sh` 加上 container 內 `wget http://127.0.0.1/`，幫我確認 container 內部服務本身是否有正常回應。
- `kubectl port-forward ...` 加上本機 `curl`，幫我驗證 debug 用的本機 tunnel 是否能打到叢集內 Service，但這不等於正式外部流量已驗證完成。
- `kubectl apply -f darkmind/scenarios/readiness-fail.yaml` 加上 `kubectl get pods,endpoints -n darkmind`，幫我確認壞情境是否已形成：Pod 可能仍在 `Running`，但 `endpoints` 已經是空的。
- `kubectl exec ...` 加上 `kubectl get endpoints ...`，幫我把最後的邊界釘死：container 可互動，不等於 Service 會送流量給它。

### 練習後還不順手的地方

- `port-forward` 的資料路徑、常見 forwarding 對象與情境，仍需要再多做一兩次實作才能更直覺。
- `Running`、`Ready`、`endpoints`、`exec`、`port-forward` 這五者的邊界已能講出來，但還需要再練一次口頭收斂，讓描述更短更穩。

### 補充

- 視需要補最小上下文即可。
