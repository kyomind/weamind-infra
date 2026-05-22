# 2026-04-13 Darkmind Get Describe Events Command
複習：2026-05-22
## 今日指令練習目標

1. 建立 Day 1 的固定套路：先看 `get`、再看 `describe`、最後用 `events` 補時間序列。
2. 用 `darkmind` 的健康基準與 `image-pull-error` 情境，練會第一層縮圈。
3. 練到看到輸出時能說出：我現在在哪一層、這個證據回答了什麼、下一步最小有用指令是什麼。

## 這次要驗證的路徑或問題

1. 健康基準長什麼樣，壞情境第一眼又長什麼樣。
2. `get`、`describe`、`events` 在 image pull 類問題裡如何接成一條最小排查鏈。
3. 練習把健康基準與壞情境放到同一條觀察鏈中，而不是跳步看單點輸出。

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
kubectl apply -f darkmind/namespace.yaml
kubectl apply -f darkmind/healthy.yaml
kubectl get all -n darkmind
```

### 關鍵輸出

```bash
namespace/darkmind created
deployment.apps/darkmind-healthy created
service/darkmind-healthy created

NAME                                    READY   STATUS              RESTARTS   AGE
pod/darkmind-healthy-85c6dcf689-rpn7p   0/1     ContainerCreating   0          3s

NAME                       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/darkmind-healthy   ClusterIP   10.43.104.37   <none>        80/TCP    2s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/darkmind-healthy   0/1     1            0           6s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/darkmind-healthy-85c6dcf689   1         1         0       6s
```

### 使用者選擇理由

- 使用者選第一組指令，理由是這是建立健康基準的正確起手式：先建立獨立 `namespace`，再套用 `darkmind/healthy.yaml` 產生健康的 `Deployment` 與 `Service`，最後用 `kubectl get all -n darkmind` 觀察這個 namespace 目前有哪些物件。
- 使用者也正確辨認出這一輪主要想看到的是：`Pod`、`Service`、`Deployment`、`ReplicaSet` 是否已經在 `darkmind` namespace 內出現。

### AI 判讀與修正

- 這個選擇是對的，因為 Day 1 的第一步不是直接看壞情境，而是先把健康基準建立起來。這組指令剛好完成三件事：建立隔離環境、建立健康工作負載、用 `get all` 看第一眼資源摘要。
- 你對資源種類的判讀也是對的：這一輪已經看到 `Service`、`Deployment`、`ReplicaSet` 與對應的 `Pod` 都出現了，這代表 `darkmind/healthy.yaml` 已經被成功套用。要補正一個小地方：這裡不是透過 repo 裡的 `manifests/deployment.yaml` 建的，而是透過 `darkmind/healthy.yaml` 裡面的 `Deployment` resource 建出來的。
- 另外一個要收得更準的地方是：你把 `0/1` 和 `ContainerCreating` 讀成「not ready」，這個方向不算錯，但 Day 1 這裡更準確的判讀應是它還在啟動中的過渡狀態，不一定代表異常。因為你是在剛 apply 完後立刻觀察，`AGE` 只有幾秒，這時 `Pod` 還在 `ContainerCreating`、`Deployment` 還沒 `Available`，是很常見的正常暫態。
- 這也正是健康基準有價值的地方：你不只是在看最後成功的狀態，也會看到正常系統從剛建立到 Ready 的過程。之後若某個 Pod 長時間卡在 `ContainerCreating`、`ImagePullBackOff`、`CrashLoopBackOff`，你才知道那不是正常暫態，而是已經偏離基準。

### 一句話收斂

- 建立健康基準時，先建 `namespace`、再套 `healthy.yaml`、最後用 `kubectl get all -n darkmind` 看第一眼資源摘要；剛建立幾秒內出現 `ContainerCreating` 這種狀態，通常先判讀成正常啟動中的暫態。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- 健康基準已建立後，哪個操作最適合把 `image-pull-error` 錯誤情境真正放進叢集，讓後面的觀察有對象可看？

### 三個可選指令

```bash
kubectl apply -f darkmind/scenarios/image-pull-error.yaml

kubectl get pods -n darkmind

kubectl delete namespace darkmind
```

### 指令

```bash
kubectl apply -f darkmind/scenarios/image-pull-error.yaml
```

### 關鍵輸出

```bash
deployment.apps/darkmind-image-pull-error created
```

### 使用者選擇理由

- 使用者選第一個指令，理由是要先把故意設計好的錯誤 scenario 套進叢集，後面的 `describe`、`events` 或其他觀察才會有實際目標可看。

### AI 判讀與修正

- 這個選擇是對的，因為這一輪的目標不是觀察，而是讓錯誤情境真的存在於 cluster 裡。如果還沒 `apply` 這個 Deployment，後面不管是 `get`、`describe` 或 `logs`，都不會有正確的觀察對象。
- 看到 `deployment.apps/darkmind-image-pull-error created`，表示 Kubernetes API 已接受這個新的 Deployment 物件；但這還不等於 Pod 已經成功跑起來。真正的異常訊號要到下一輪用 `kubectl get pods -n darkmind` 才看得出來。

### 一句話收斂

- 在觀察壞情境前，要先把 scenario 套進 cluster；`apply` 這一輪的作用是建立可被排查的目標，不是直接提供錯誤原因。

### 狀態

- 已完成

---

## Command 3

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
kubectl get pods -n darkmind
```

### 關鍵輸出

```bash
NAME                                         READY   STATUS             RESTARTS   AGE
darkmind-healthy-85c6dcf689-rpn7p            1/1     Running            0          12m
darkmind-image-pull-error-6d4c7fc945-28vff   0/1     ImagePullBackOff   0          24s
```

### 使用者選擇理由

- 使用者在套用錯誤 scenario 後，立刻補了一次 `kubectl get pods -n darkmind`，目的是先確認這個壞情境是否真的產生了預期中的異常。
- 使用者已經正確讀到第一層訊號：健康 Pod 維持 `Running`，而新建的錯誤 Pod 已經出現 `ImagePullBackOff`。

### AI 判讀與修正

- 這個起手式是對的，而且很符合 Day 1 的主軸。當你剛把壞情境套進去時，第一輪最適合先看 `kubectl get pods -n darkmind`，因為它能最快提供第一層狀態摘要：哪個 Pod 正常、哪個 Pod 異常、異常大概落在哪一類。
- 這份輸出很有價值，因為它同時保留了健康基準和壞情境的對照：`darkmind-healthy` 是 `1/1 Running`，而 `darkmind-image-pull-error` 是 `0/1 ImagePullBackOff`。這正好把你在 Q3 講的「健康基準對照」落成真實畫面。
- 這一輪也再次說明 `get` 的角色：它已經足夠告訴你問題類型大致落在 image pull / 啟動前階段，但它還沒告訴你更細節的原因，例如是 tag 不存在、registry 無法連、還是權限問題。那一層證據要留給下一輪的 `describe`。

### 一句話收斂

- 套完壞情境後，第一輪先用 `kubectl get pods -n darkmind` 看高層狀態摘要；它能先告訴我哪個 Pod 出事、目前停在哪一類失敗狀態，但還不會直接給出完整原因。

### 狀態

- 已完成

---

## Command 4

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
kubectl describe pod -n darkmind -l app=darkmind-image-pull-error
```

### 關鍵輸出

```bash
Status:           Pending
Containers:
  app:
    Image:          nginx:this-tag-should-not-exist-darkmind
    State:          Waiting
      Reason:       ImagePullBackOff
    Ready:          False
    Restart Count:  0
Conditions:
  Type              Status
  Ready             False
  ContainersReady   False
  PodScheduled      True
Events:
  Normal   Pulling  ...     kubelet  Pulling image "nginx:this-tag-should-not-exist-darkmind"
  Warning  Failed   ...     kubelet  Failed to pull image "nginx:this-tag-should-not-exist-darkmind": ... not found
  Warning  Failed   ...     kubelet  Error: ErrImagePull
  Normal   BackOff  ...     kubelet  Back-off pulling image "nginx:this-tag-should-not-exist-darkmind"
  Warning  Failed   ...     kubelet  Error: ImagePullBackOff
```

### 使用者選擇理由

- 使用者選 `kubectl describe pod -n darkmind -l app=darkmind-image-pull-error`，理由是既然上一輪已經用 `get` 鎖定這個 Pod 出事，下一步就應該進到單一 resource 的 Kubernetes 視角，往下看更細的狀態描述。
- 使用者也主動注意到一個很好的實務點：雖然直接用 Pod 名稱也能看，但用 label 比較穩，因為 Pod 若重建，名稱可能改變，而情境 label 通常維持一致。
- 使用者觀察到這份 `describe` 內容裡有多個很重要的看點：`Status=Pending`、container `State=Waiting`、`Reason=ImagePullBackOff`、`Ready=False`、`Restart Count=0`，以及底下很長的 `Events`。

### AI 判讀與修正

- 這個選擇是對的，而且你抓到兩個很重要的實務判斷。第一，上一輪 `get` 已經告訴你哪個 Pod 出事、屬於哪一類失敗；這一輪就該用 `describe` 往下看單一 resource 的細節。第二，用 label 來找目標通常比手打具體 Pod 名稱更穩，尤其在 Deployment 管理下，Pod 重建後名稱會變，但代表這個情境的 label 通常不變。
- 你這份輸出裡最有訊號價值的幾個欄位抓得很好，而且它們其實剛好構成一條很標準的 image pull 類 debug 鏈：`Status=Pending`、container `State=Waiting`、`Reason=ImagePullBackOff`、`Ready=False`、`Restart Count=0`，加上底下對應的 `Events`，已足夠讓你判讀問題卡在拉 image 前段，而不是 app 啟動後崩潰。

### 一句話收斂

- 當 `get` 已經告訴我 Pod 卡在 `ImagePullBackOff`，下一輪用 `kubectl describe pod` 看單一資源細節；若看到 `State=Waiting`、`Reason=ImagePullBackOff`、`Restart Count=0` 與對應 `Events`，就能判讀問題卡在拉 image 前段，而不是 app 啟動後崩潰。

### 狀態

- 已完成

---

## Command 5

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
kubectl get events -n darkmind --sort-by=.lastTimestamp
```

### 關鍵輸出

```bash
LAST SEEN   TYPE      REASON              OBJECT                                            MESSAGE
29m         Normal    Scheduled           pod/darkmind-image-pull-error-6d4c7fc945-28vff    Successfully assigned darkmind/darkmind-image-pull-error-6d4c7fc945-28vff to weamind-002
41m         Normal    Scheduled           pod/darkmind-healthy-85c6dcf689-rpn7p             Successfully assigned darkmind/darkmind-healthy-85c6dcf689-rpn7p to weamind-002
41m         Normal    SuccessfulCreate    replicaset/darkmind-healthy-85c6dcf689            Created pod: darkmind-healthy-85c6dcf689-rpn7p
41m         Normal    ScalingReplicaSet   deployment/darkmind-healthy                       Scaled up replica set darkmind-healthy-85c6dcf689 from 0 to 1
41m         Normal    Pulling             pod/darkmind-healthy-85c6dcf689-rpn7p             Pulling image "nginx:1.27-alpine"
41m         Normal    Created             pod/darkmind-healthy-85c6dcf689-rpn7p             Created container: app
41m         Normal    Pulled              pod/darkmind-healthy-85c6dcf689-rpn7p             Successfully pulled image "nginx:1.27-alpine" in 3.357s (3.357s including waiting).
41m         Normal    Started             pod/darkmind-healthy-85c6dcf689-rpn7p             Started container app
29m         Normal    SuccessfulCreate    replicaset/darkmind-image-pull-error-6d4c7fc945   Created pod: darkmind-image-pull-error-6d4c7fc945-28vff
29m         Normal    ScalingReplicaSet   deployment/darkmind-image-pull-error              Scaled up replica set darkmind-image-pull-error-6d4c7fc945 from 0 to 1
26m         Normal    Pulling             pod/darkmind-image-pull-error-6d4c7fc945-28vff    Pulling image "nginx:this-tag-should-not-exist-darkmind"
26m         Warning   Failed              pod/darkmind-image-pull-error-6d4c7fc945-28vff    Failed to pull image "nginx:this-tag-should-not-exist-darkmind": ... not found
26m         Warning   Failed              pod/darkmind-image-pull-error-6d4c7fc945-28vff    Error: ErrImagePull
4m31s       Normal    BackOff             pod/darkmind-image-pull-error-6d4c7fc945-28vff    Back-off pulling image "nginx:this-tag-should-not-exist-darkmind"
4m31s       Warning   Failed              pod/darkmind-image-pull-error-6d4c7fc945-28vff    Error: ImagePullBackOff
```

### 使用者選擇理由

- 使用者選第一個指令，理由是這一輪的目標不是再看單一 Pod 細節，而是把整個 image pull 失敗的事件流程攤開成時間序列來看。
- 使用者也正確觀察到：`events` 不只包含失敗訊號，也包含成功事件，因此它更像整體事件流，而不是單純錯誤列表。

### AI 判讀與修正

- 這個選擇是對的。當你已經靠 `get` 和 `describe` 鎖定問題類型後，`kubectl get events -n darkmind --sort-by=.lastTimestamp` 的價值在於把整個 namespace 近期發生過的事件拉成一條可比較的序列。
- 這份輸出最有價值的地方，是它把 image pull 失敗的因果鏈攤開：先 `SuccessfulCreate` / `Scaled up replica set`，接著 `Pulling image`，然後 `Failed to pull image ... not found`、`ErrImagePull`，最後進到 `BackOff` / `ImagePullBackOff`。這比單看 `describe` 裡的 `Events` section 更容易從 namespace 角度理解最近到底先後發生了哪些事。
- 也補一個小提醒：`kubectl get events` 雖然用了 `--sort-by=.lastTimestamp`，但因為 event 可能被聚合、重複計數，表格中的 `LAST SEEN` 相對時間看起來不一定每列都像完美線性時間軸。它仍然很有用，但要知道它是事件流線索，不是精密審計 log。

### 一句話收斂

- 當我想看最近整體先後發生了哪些事而不是只盯單一 Pod，就用 `kubectl get events --sort-by=.lastTimestamp`；它能把正常與異常事件一起攤開，幫我看懂失敗流程是怎麼演進的。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- `kubectl get all -n darkmind` 幫我建立健康基準，知道 namespace 內核心資源剛建立時的正常暫態長什麼樣。
- `kubectl get pods -n darkmind` 幫我快速看到第一層異常訊號；`kubectl describe pod -n darkmind -l app=darkmind-image-pull-error` 幫我確認問題卡在 image pull 前段；`kubectl get events -n darkmind --sort-by=.lastTimestamp` 則把整體事件流程拉成時間序列。

### 練習後還不順手的地方

- 多 replica 時，要更熟練地在 label、`get` 摘要與單一 Pod 名稱之間切換。
- `kubectl get events` 的篩選手法還需要再練，尤其是 `--field-selector` 的使用。

### 補充

- 固定收尾：

```bash
kubectl delete namespace darkmind
```

- 使用者實際輸出：

```bash
namespace "darkmind" deleted
```

- 這次 cleanup 已完成；刪除 namespace 的效果是把 `darkmind` 當成整個練習工作區一起清空，讓下次能從乾淨狀態重新開始。

- Day 1 只收斂 `get`、`describe`、`events` 的最小鏈，不提前混入 `logs`、`exec` 或 `rollout`。

### 固定收尾

```bash
kubectl delete namespace darkmind
```

- Day 1 的 cleanup 改為固定收尾步驟，不再占用主要判讀輪次。
