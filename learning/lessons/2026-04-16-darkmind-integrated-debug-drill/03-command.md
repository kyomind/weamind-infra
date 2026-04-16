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
kubectl get pods -n darkmind
kubectl describe pod -n darkmind -l app=darkmind-image-pull-error
```

### 關鍵輸出

```bash
NAME                                         READY   STATUS             RESTARTS   AGE
darkmind-image-pull-error-6d4c7fc945-7tcbx   0/1     ErrImagePull       0          6m

Status:           Pending
Image:            nginx:this-tag-should-not-exist-darkmind
State:            Waiting
	Reason:         ImagePullBackOff
Ready:            False

Events:
	Normal   Pulling   ...   kubelet   Pulling image "nginx:this-tag-should-not-exist-darkmind"
	Warning  Failed    ...   kubelet   Failed to pull image "nginx:this-tag-should-not-exist-darkmind": ... not found
	Warning  Failed    ...   kubelet   Error: ErrImagePull
	Warning  Failed    ...   kubelet   Error: ImagePullBackOff
	Normal   BackOff   ...   kubelet   Back-off pulling image "nginx:this-tag-should-not-exist-darkmind"

NAME                                         READY   STATUS             RESTARTS   AGE
darkmind-image-pull-error-6d4c7fc945-7tcbx   0/1     ImagePullBackOff   0          7m
```

### 使用者選擇理由

- 使用者選第一組，因為 image pull 類問題第一輪應先確認 Pod 狀態字樣，再看 Kubernetes 對這顆 Pod 的事件與等待原因，而不是一開始就去看 `logs` 或嘗試 `exec`。
- 使用者原本一度以為 `kubectl get pods` 可能只能看到像 `Running` 但 `NotReady` 這種較粗的結果，但實際執行後確認：`get pods` 本身就已經能直接看出 `ErrImagePull` 這種高價值狀態字樣，所以足以做第一輪縮圈。
- 使用者也主動觀察到一個重要時間差：這顆 Pod 一開始先顯示 `ErrImagePull`，過一段時間後才進到 `ImagePullBackOff`，代表這不是兩個互不相干的錯誤，而是同一條 image pull 失敗後的狀態演進。

### AI 判讀與修正

- 這次選第一組是對的，而且你這次真正抓到的是 **image pull 類問題最穩的第一輪證據鏈**：先用 `get pods` 辨認狀態字樣，再用 `describe pod` 看 waiting reason 與 events 時間線。
- 你剛剛自己修正的那個點很重要：`kubectl get pods` 並不只是模糊地告訴你 Pod 不健康，它常常已經會直接把高價值狀態字樣印出來，例如 `ErrImagePull`、`ImagePullBackOff`、`CrashLoopBackOff`。所以它非常適合當第一眼縮圈入口。
- `describe pod` 在這題的價值，是把 Kubernetes 視角補齊成完整因果鏈：`Status: Pending`、container `State: Waiting`、`Reason: ImagePullBackOff`、`Ready: False`，再加上 events 裡的 `Pulling -> Failed -> ErrImagePull -> ImagePullBackOff -> BackOff`。這條時間線已經足夠證明：**問題還卡在 image 下載 / 解析階段，container 根本還沒成功啟動。**
- 你觀察到 `ErrImagePull` 之後又變成 `ImagePullBackOff`，這個理解是對的。更精確地說：`ErrImagePull` 比較像「這次拉 image 失敗了」，`ImagePullBackOff` 比較像「Kubernetes 發現連續失敗後，進入退避重試階段」。所以後者通常會晚一點出現。
- ⭐️也因為 container 根本還沒成功起來，所以這一題不適合先看 `logs`，更不適合先 `exec`。因為這時候你真正要回答的不是 app 裡面噴了什麼，而是 **image 根本拉不下來，容器還沒進入可執行 app 的階段**。

### 一句話收斂

- image pull 類問題的第一輪應先看 `get pods` 與 `describe pod`：前者先辨認 `ErrImagePull` / `ImagePullBackOff`，後者再用 waiting reason 與 events 證明問題卡在 image 下載失敗與 back-off 重試，而不是 app 執行期錯誤。

### 狀態

- 已完成

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
