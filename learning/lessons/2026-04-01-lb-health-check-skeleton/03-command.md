# 2026-04-01 LB Health Check Skeleton Command

## 今日指令練習目標

1. 把「Health Check 失敗」拆成 Host header 問題，而不是直接說 app 壞掉。
2. 把「LB 後端只放 worker」對回 Deployment、node label 與 Pod 落點證據。

## 這次要驗證的路徑或問題

1. host-based Ingress 規則下，沒有 Host header 的 `/health` 為什麼會回 `404`。
2. `nodepool=worker`、Pod 排程位置與 LB 後端設計之間是怎麼連起來的。

## 今天要看的資源

1. Ingress
2. Deployment
3. Nodes
4. Pods

---

## Command 1

### 要驗證的問題

- 當 LB Health Check 沒帶正確的 Host header 時，問題到底是 app `/health` 壞掉，還是 Ingress host-based routing 沒被命中？

### 三個可選指令

```bash
curl http://127.0.0.1/health
curl -H 'Host: k8s.kyomind.tw' http://127.0.0.1/health
kubectl get ingress weamind -n weamind -o yaml
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

- 如果要證明「LB 後端只放 worker」不是口號，而是對應到目前 app Pod 的實際落點，你會先看哪一層？

### 三個可選指令

```bash
kubectl get deployment weamind -n weamind -o yaml
kubectl get nodes -L nodepool
kubectl get pods -n weamind -o wide
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

- 待補

### 練習後還不順手的地方

- 待補

### 補充

- 若需要，可補一輪把 `curl https://k8s.kyomind.tw/health` 與 TLS termination 的觀察接起來。
