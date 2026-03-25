# 2026-03-25 K8s Debug Operations Command

## 今日指令練習目標

1. 練習把故障情境先分層，再挑第一輪較合適的觀察指令。
2. 練習看完輸出後，能說出下一步為什麼改往那一層查。
3. 練習把每一輪操作收斂成一個可複習的 debug sequence，而不是指令流水帳。

## 這次要驗證的路徑或問題

1. 外層 routing 類問題，第一輪應先看哪一層的證據。
2. Pod / app 類問題，怎麼把 `describe` 和 `logs` 串成前後兩步。
3. Pod 到 VM 依賴類問題，`exec` 能幫你驗證什麼，不能直接證明什麼。

## 今天要看的資源

1. `weamind` Deployment 產生的 Pod
2. `weamind-line-bot` Service
3. `k8s.kyomind.tw` 對應的 Ingress 與 `/health` 路徑

---

## Command 1

### 要驗證的問題

- 某次 webhook Verify 回 `404`，但 `https://k8s.kyomind.tw/health` 正常。第一輪你比較想先驗證外層 routing 是否命中正確 host / path，哪個指令或觀察點更合適？

### 三個可選指令

```bash
kubectl describe ingress weamind -n weamind
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl logs <pod-name> -n weamind
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

- 某個 Pod 看起來在反覆重啟，你第一輪想先拿 Kubernetes 對 Pod 狀態的描述，再決定是否往 app log 深挖，哪個指令比較合適？

### 三個可選指令

```bash
kubectl describe pod <pod-name> -n weamind
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl get ingress -n weamind
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

- Pod 已經 Running / Ready，但你懷疑 Pod 內部到 PostgreSQL 或 Redis 的依賴路徑有問題，想做最小內部驗證，哪個指令比較合適？

### 三個可選指令

```bash
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl describe service weamind-line-bot -n weamind
kubectl get ingress -n weamind
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

- 若 AI 為了環境驗證代跑指令，只算輔助，不等於使用者已完成 command drill。
