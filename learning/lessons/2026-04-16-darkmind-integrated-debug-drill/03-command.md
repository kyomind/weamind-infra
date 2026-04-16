# 2026-04-16 Darkmind Integrated Debug Drill Command

## 今日指令練習目標

1. 練習面對壞情境時，先選最能縮小範圍的第一步，而不是輪流把所有指令打一遍。
2. 把 `get`、`describe`、`events`、`logs`、`exec`、`rollout` 接成完整縮圈 sequence。
3. 練到每走一步都能說出：我現在正在驗證哪一層，以及為什麼下一步是它。

## 這次要驗證的路徑或問題

1. `ImagePullBackOff` 類問題，第一輪更像是 Kubernetes 狀態與事件題，而不是 app 內部題。
2. `CrashLoopBackOff` 類問題，第一輪更像是 container 與 app 輸出時間線題，而不是 rollout 題。
3. bad rollout 類問題，要把單顆 Pod 壞掉與部署切版失敗分開判讀。

## 今天要看的資源

1. `darkmind` namespace
2. `darkmind-image-pull-error` 相關 Deployment / Pod / Events
3. `darkmind-crash-loop` 相關 Deployment / Pod / Logs
4. `darkmind-rollout` 相關 Deployment / ReplicaSet / Rollout 狀態

---

## Command 1

### 要驗證的問題

- 如果今天看到的是 image pull 類錯誤，哪組操作最適合先抓到「問題還卡在 image 下載階段」這個事實？

### 三個可選指令

```bash
kubectl get pods -n darkmind
kubectl describe pod -n darkmind -l app=darkmind-image-pull-error

kubectl logs -n darkmind -l app=darkmind-image-pull-error

kubectl exec -it -n darkmind deploy/darkmind-image-pull-error -- sh
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

- 如果今天看到的是 crash loop 類錯誤，哪組操作最適合先回答「container 上一輪到底怎麼死的」？

### 三個可選指令

```bash
kubectl logs -n darkmind -l app=darkmind-crash-loop --previous

kubectl get events -n darkmind --sort-by=.lastTimestamp

kubectl rollout status deployment/darkmind-crash-loop -n darkmind
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

- 如果今天懷疑不是單顆 Pod 自己壞掉，而是 rollout 交接出了問題，哪組操作最適合先確認部署層是否卡住或需要回滾？

### 三個可選指令

```bash
kubectl rollout status deployment/darkmind-rollout -n darkmind
kubectl rollout history deployment/darkmind-rollout -n darkmind

kubectl exec -it -n darkmind deploy/darkmind-rollout -- sh

kubectl port-forward -n darkmind svc/darkmind-rollout 8080:80
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

- 若今天時間不足，可至少完成前 2 題整合情境，再把第三題留作收尾或下次複習素材。
