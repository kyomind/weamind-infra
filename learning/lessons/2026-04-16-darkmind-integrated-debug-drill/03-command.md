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
kubectl logs -n darkmind -l app=darkmind-crash-loop --previous
```

### 關鍵輸出

```bash
darkmind crash-loop scenario: container will exit now
```

### 使用者選擇理由

- 使用者選第一個指令，理由是這題要回答的是「上一輪到底怎麼死的」，而 `kubectl logs --previous` 正是在看前一個已終止 container instance 的輸出。
- 使用者也進一步追問了 `-l app=...` 這種 label selector 寫法的邊界：若要改成指定單一 Pod 該怎麼寫；若 selector 命中多個 Pod，輸出會如何呈現；若多個 replicas 中有些有 previous、有些沒有，`--previous` 的行為又會如何。

### AI 判讀與修正

- 這次選第一個指令是對的。因為 crash loop 類問題真正想回答的是 **上一輪 container 啟動後吐了什麼，然後為什麼結束**，這正是 `kubectl logs --previous` 最直接的用途。
- 你這次拿到的輸出雖然只有一行，但已經足夠證明這個 lab 的故障模型：container 確實有成功啟動過，接著主程序很快自己退出，所以 Pod 才會進入反覆重啟與 `CrashLoopBackOff`。
- 和上一題 image pull 很不同：上一題根本還沒成功進到 app 執行期，所以先看 `describe` / events；這一題則是 container 已經啟動過，所以 `logs --previous` 直接變成高價值第一手證據。
- 你追問 selector 的邊界也很實務。這題最穩的結論是：**當你已經知道要看哪一顆 Pod 的上一輪死亡原因時，最好直接指定 Pod 名稱，而不是繼續用 selector 做模糊選取。** 因為 selector 命中多個 Pod 時，輸出可能混在一起，甚至其中某些 Pod 沒有 previous instance 時會直接報錯，反而降低可讀性。

### 一句話收斂

- crash loop 類問題若要先回答「上一輪 container 怎麼死的」，最直接的第一步就是 `kubectl logs --previous`；等於先抓上一個已終止 container 的輸出，而不是先去看 rollout 或只看一般 events。

### 狀態

- 已完成

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
kubectl rollout status deployment/darkmind-rollout -n darkmind
kubectl rollout history deployment/darkmind-rollout -n darkmind
```

### 關鍵輸出

```bash
error: deployment "darkmind-rollout" exceeded its progress deadline

deployment.apps/darkmind-rollout
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

### 使用者選擇理由

- 使用者選第一組，理由是這題已明確懷疑不是單顆 Pod 自己壞掉，而是 deployment rollout 交接出了問題；因此第一輪要先看 deployment 層的 rollout 是否卡住，以及目前有幾個 revision。
- 使用者從輸出中已先抓到一個關鍵結論：`rollout status` 已直接表明這次 rollout 失敗，而且目前 deployment 底下至少有 revision 1 與 revision 2 兩版。
- 使用者另外追問兩個實務問題：第一，`kubectl logs` 是否只能針對 Pod 類資源；第二，若只看 `rollout status` / `rollout history`，有沒有更多欄位或參數可以更清楚判斷 rollout 成功或失敗。

### AI 判讀與修正

- 這次選第一組是對的。因為這題真正要回答的不是「某個 app process 噴了什麼」，而是 **deployment 這次版本交接有沒有卡住，以及現在叢集中存在哪些 revision。**
- `kubectl rollout status` 在這題已經給出很關鍵的結果：`deployment "darkmind-rollout" exceeded its progress deadline`。這代表 deployment 在允許的 progress window 內沒能把新版本 rollout 完成，所以這是 **deployment 層級的失敗訊號**，不是單顆 Pod 層級的偶發錯誤。
- `kubectl rollout history` 則補出另一個面向：目前至少有兩個 revision，代表這次確實發生過版本交接。但像你觀察到的，它本身不會直接把「哪一版成功、哪一版失敗」用一個清楚欄位完整列給你；`CHANGE-CAUSE` 也只有在你自己有維護對應 annotation 時才會更有意義。
- 這種時候，真正更有價值的下一步常常不是繼續問 `rollout history` 要不要多印欄位，而是補看 `kubectl describe deployment darkmind-rollout -n darkmind`。這次現場輸出就很典型：`Progressing=False`、`Reason=ProgressDeadlineExceeded`，再加上 `OldReplicaSets`、`NewReplicaSet`、`Replicas: 2 desired | 2 updated | 3 total | 1 available | 2 unavailable`，這些都比單看 history 更能回答 rollout 是否失敗、卡在哪裡。
- 所以這題的最穩結論是：**rollout 類問題先看 `rollout status` 確認是否卡住，再看 `rollout history` 確認 revision，再視需要接 `describe deployment` 看 conditions、ReplicaSets 與可用副本數。**

### 一句話收斂

- rollout 類問題的第一輪應先看 `rollout status` 與 `rollout history`：前者先確認 deployment 交接是否卡住，後者確認 revision 脈絡；若要真正看出失敗原因與目前卡點，再補 `describe deployment` 看 conditions、ReplicaSets 與 available / unavailable 數量。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- `kubectl get pods` 加 `kubectl describe pod`，幫我把 image pull 類問題縮圈到「container 根本還沒成功啟動，卡在 image 下載 / back-off」這一層。
- `kubectl logs --previous`，幫我直接回答 crash loop 情境裡上一輪 container 到底吐了什麼、怎麼死的。
- `kubectl rollout status` 加 `kubectl rollout history`，幫我把單顆 Pod 壞掉和 deployment rollout 交接失敗分開，確認這是 deployment 層的問題。

### 練習後還不順手的地方

- `kubectl logs` 用 selector 時，多 Pod 與 `--previous` 的輸出邊界還需要再多練一次，才會更直覺地先鎖定單一壞 Pod。
- `rollout status`、`rollout history`、`describe deployment` 三者在 rollout 類問題中的分工已理解，但還需要再多做一輪，讓切換更快。

### 補充

- 若今天時間不足，可至少完成前 2 題整合情境，再把第三題留作收尾或下次複習素材。
