# 2026-04-13 Darkmind Get Describe Events Command

## 今日指令練習目標

1. 建立 Day 1 的固定套路：先看 `get`、再看 `describe`、最後用 `events` 補時間序列。
2. 用 `darkmind` 的健康基準與 `image-pull-error` 情境，練會第一層縮圈。
3. 練到看到輸出時能說出：我現在在哪一層、這個證據回答了什麼、下一步最小有用指令是什麼。

## 這次要驗證的路徑或問題

1. 健康基準長什麼樣，壞情境第一眼又長什麼樣。
2. `get`、`describe`、`events` 在 image pull 類問題裡如何接成一條最小排查鏈。
3. 練習在操作結束後正確清理 `darkmind` namespace。

## 今天要看的資源

1. `darkmind` namespace
2. `darkmind-healthy` Deployment / Service
3. `darkmind-image-pull-error` Deployment / Pod

---

## Command 1

### 要驗證的問題

- 正式進壞情境前，哪個操作最適合先建立 `darkmind` 的健康基準？

### 三個可選指令

```bash
kubectl apply -f darkmind/namespace.yaml
kubectl apply -f darkmind/healthy.yaml
kubectl get all -n darkmind

kubectl apply -f darkmind/scenarios/image-pull-error.yaml

kubectl delete namespace darkmind
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

- 套進 `image-pull-error` 後，你想先拿到第一層異常訊號，哪個指令最適合作為起點？

### 三個可選指令

```bash
kubectl get pods -n darkmind

kubectl describe deploy darkmind-image-pull-error -n darkmind

kubectl logs -n darkmind -l app=darkmind-image-pull-error
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

- 你已經從 `get` 看到 Pod 不健康，現在想知道 Kubernetes 對這個 Pod 的更細緻描述，哪個指令最適合？

### 三個可選指令

```bash
kubectl describe pod -n darkmind -l app=darkmind-image-pull-error

kubectl get svc -n darkmind

kubectl exec -it -n darkmind deploy/darkmind-image-pull-error -- /bin/sh
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

- 若你想把 image pull 失敗的時間序列補齊，而不是只看單一 Pod 描述，哪個指令最適合？

### 三個可選指令

```bash
kubectl get events -n darkmind --sort-by=.lastTimestamp

kubectl get deploy -n darkmind

kubectl logs -n darkmind -l app=darkmind-image-pull-error --previous
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

- Day 1 結束後，哪個操作最適合把整個 `darkmind` lab 清乾淨，確保下次練習能從乾淨狀態開始？

### 三個可選指令

```bash
kubectl delete namespace darkmind

kubectl delete pod -n darkmind -l app=darkmind-image-pull-error

kubectl rollout restart deploy/darkmind-healthy -n darkmind
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

- Day 1 只收斂 `get`、`describe`、`events` 的最小鏈，不提前混入 `logs`、`exec` 或 `rollout`。
