# 2026-03-24 K8s Debug Tools Command

## 今日指令練習目標

1. 練習在不同情境下，先選較合適的第一個工具，而不是固定只開同一種指令。
2. 練習把指令輸出和 debug 分層框架接起來，知道自己拿到的是哪一層的證據。
3. 練習 `describe`、`logs`、`logs --previous`、`exec` 的最小使用情境。

## 這次要驗證的路徑或問題

1. CrashLoopBackOff / 重啟類問題，第一輪應先拿哪種證據。
2. Pod 內部最小驗證能證明什麼，不能證明什麼。
3. 工具選擇如何接回昨天的外到內 / 內到外 debug 骨架。

## 今天要看的資源

1. `weamind` Deployment 產生的 Pod
2. `weamind-line-bot` Service
3. WeaMind app 的 `/health` 與 webhook 路徑

---

## Command 1

### 要驗證的問題

- 某個 Pod 正在 CrashLoopBackOff，第一輪你想先拿到「Kubernetes 怎麼描述這個 Pod」這種證據，哪個工具比較合適？

### 三個可選指令

```bash
kubectl describe pod <pod-name> -n weamind
kubectl logs <pod-name> -n weamind
kubectl exec -it <pod-name> -n weamind -- /bin/sh
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

- Pod 反覆重啟，你想看「上一個已經死掉的 container 最後吐了什麼」，哪個工具比較合適？

### 三個可選指令

```bash
kubectl logs <pod-name> -n weamind --previous
kubectl describe pod <pod-name> -n weamind
kubectl exec -it <pod-name> -n weamind -- printenv
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

- 你懷疑 Pod 內部的環境變數、DNS 解析或對 Service / VM 的基本連線是否正常，想做最小內部驗證，哪個工具比較合適？

### 三個可選指令

```bash
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl logs <pod-name> -n weamind
kubectl describe pod <pod-name> -n weamind
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

- 今天的重點不是把四個工具排出絕對唯一順序，而是理解它們各自更擅長提供哪一種證據。
