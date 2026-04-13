# 2026-04-13 Darkmind Get Describe Events Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天只練 `get`、`describe`、`events` 這條 Day 1 觀察鏈，不提前混入 `logs`、`exec`、`port-forward` 或 `rollout` 主題。
- 今天的壞情境以 `image-pull-error` 為主，目標是把第一層縮圈做穩，不追求一次碰多種故障家族。

### Repo 對照文件與觀察點

- `darkmind/README.md`：確認 Day 1 的操作目標與經典場景邊界。
- `darkmind/healthy.yaml`：建立健康基準，知道正常狀態長什麼樣。
- `darkmind/scenarios/image-pull-error.yaml`：對照 image tag 故意不存在時，Kubernetes 會給什麼訊號。

### 暫時不在今天展開的點

- `logs`、`logs --previous` 留到 Day 2。
- `exec`、`port-forward` 留到 Day 3。
- `readiness-fail` 與 `bad-rollout` 情境今天不正式展開。

## Notes

### `kubectl get` vs `kubectl describe`

- `kubectl get` 比較像列表式、高層的狀態摘要，適合第一輪快速掃描：先找出哪個 resource 不健康、異常大概落在哪一類。
- `kubectl describe` 比較像針對單一 resource 的展開式 Kubernetes 視角，適合第二輪往下看：`State`、`Conditions`、`Reason`、`Events`、probe 狀態、image pull 訊號等。
- 一句話口訣：`get` 先幫我找到哪裡怪，`describe` 再幫我看 Kubernetes 具體怎麼描述這個怪狀態。

### `describe` vs `events`

- `describe` 是以單一 resource 為中心的展開式觀察，回答的是「這個 Pod / resource 現在怎麼了」。
- `kubectl get events --sort-by=.lastTimestamp` 是以 event 列表為中心的觀察，回答的是「最近這個 namespace 裡先後發生了哪些事」。
- `describe` 裡的 `Events` section 可以看成以單一 resource 為中心擷取出的事件片段；`kubectl get events` 則是把 event 當成獨立列表來看。

### Kubernetes `Event` 是什麼

- `Event` 本身就是 Kubernetes API 裡的一種 resource kind，只是它屬於輔助型、短生命週期的事件紀錄資源。
- `Event` 不只記錯誤，也可能記正常流程，例如 `Scheduled`、`Pulled`、`Created`、`Started`；只是 debug 時通常會特別注意 warning 或 failure 類事件。
- 一句話口訣：`Event` 不是錯誤清單，而是 Kubernetes 的事件流；只是故障排查時，warning event 最有訊號價值。

### 同一份 YAML 放多個 resource

- 像 `darkmind/healthy.yaml` 這樣把 `Deployment` 和 `Service` 放在同一份檔案裡是完全合法的，只要用 `---` 把多個 YAML document 分開即可。
- Kubernetes 會把同一份檔案中的每個 document 視為獨立 resource 來套用，因此 `kubectl apply -f darkmind/healthy.yaml` 會一次建立兩個物件。
- 這種寫法很常用在彼此高度相關、通常一起建立與刪除的資源上；例如同一個練習情境中的 `Deployment` 加 `Service`。

### Darkmind 裡的 labels 在做什麼

- `app: darkmind-healthy` 是這份情境自己最直接使用的 label，通常用在 `selector`、`matchLabels` 或快速用 `-l app=...` 篩資源。
- `app.kubernetes.io/name: darkmind` 和 `app.kubernetes.io/component: healthy` 則比較接近 **Kubernetes 常見的推薦式 app labels**。它們不是 Kubernetes 強制要求，但很常見，目的是讓資源在工具、文件與跨團隊閱讀時有比較一致的語意。
- 可以先把它們理解成：`name` 表示這整組東西屬於哪個應用或 lab，`component` 表示它在這個應用裡扮演哪個角色或情境。
- WeaMind 正式 manifests 目前沒有全面採這套寫法也完全正常，因為這不是必填欄位；Darkmind 這裡多放，是為了讓練習素材的分類語意更清楚，也比較接近常見的 Kubernetes 標記慣例。

### 用 label 做 `describe` 的實務理由

- 在這次情境裡，用 Pod 名稱和用 `-l app=darkmind-image-pull-error` 看到的內容可以一樣，但 **label 寫法通常更穩**。
- 原因是 Deployment 管理下的 Pod 可能被重建，名稱會跟著變；若把排查流程綁死在某個具體 Pod 名稱，下一次重建後就可能失效。
- 用 label 的前提是：你知道這組 label 的語意穩定，而且當下不會同時選到一大批不想看的 Pod。對這種單情境練習 lab 來說，用 label 很合理。

### 多 replica 時，label 和 Pod 名稱怎麼取捨

- 你剛剛指出的問題是對的：如果同一組 label 背後有 `2`、`3`、`4` 個 replica，`describe pod -l ...` 可能會一次列出多個 Pod 的內容。
- 這時不代表 label 寫法錯了，而是代表 **label 比較適合做第一層鎖定範圍**；若你下一步只想精看某一個 replica，通常就要先 `kubectl get pods -l ...` 找出目標，再改用具體 Pod 名稱來看。
- 也就是說，實務上常是兩段式：先用 label 找集合，再用 Pod 名稱看單點。
- 若你能用更窄的 label 把範圍縮到單一 Pod，當然也可以；但若穩定 selector 本來就對應整個 replica 集合，那最後精看某一顆 Pod 時，用 Pod 名稱是正常做法。
- 一個小修正是：通常**不會先 `describe` 整組 replica 再決定要看哪一顆**。更常見的做法仍是先 `kubectl get pods -l ...`，因為你選 Pod 的第一輪依據通常只需要高層資訊，例如 `READY`、`STATUS`、`RESTARTS`、`AGE`、`NODE`。
- 若 `kubectl get pods` 的摘要已足夠辨認哪顆最異常，就直接用那顆 Pod 名稱做 `describe`。只有在 summary 還不夠、而且 replica 數量仍然很小時，才可能接受一次看多顆 Pod 的 `describe`；但那不是預設最佳路徑。
- 一句話原則：**選目標 Pod 先靠 `get`，深挖單一 Pod 再靠 `describe`。**

### Image pull 類 `describe` 的看點

- `Status`: 先看 Pod 是不是還停在 `Pending`，這通常表示它還沒進到穩定執行階段。
- `State` / `Reason`: 這裡若看到 container `State=Waiting` 且 `Reason=ImagePullBackOff`，表示它卡在拉 image 或 image 準備前段。
- `Ready` / `ContainersReady`: 若都是 `False`，代表它當然還不能提供服務，但這只是結果，不是根因。
- `Restart Count`: 這裡若仍是 `0`，很有價值，因為它暗示問題不是 container 啟動後反覆 crash，而是根本還沒成功開始執行。
- `Image`: 要確認實際 image 引用是否就是你懷疑的那個值；這次直接看到 `nginx:this-tag-should-not-exist-darkmind`，就已經很有訊號。
- `Events`: image pull 類問題常會在這裡看到完整因果鏈，例如 `Pulling` → `Failed to pull image ... not found` → `ErrImagePull` → `BackOff` / `ImagePullBackOff`。
- 一句話口訣：image pull 類 `describe` 先看 `Reason`，再看 `Events`，同時用 `Restart Count` 幫自己排除「其實是 app crash」這條支線。

### `kubectl get events` 太多時怎麼看

- `kubectl get events` 預設不會自動只顯示最後幾行；它通常會把 API 目前回傳的 event 列表整批印出來。真正限制它的，常常是 **event 本身只保留短時間**，而不是 CLI 自動幫你 tail。
- Kubernetes `Event` 通常不是長期保存資料；很多叢集的 event TTL 都偏短，常見是大約 `1` 小時左右，實際仍看 API server 設定。
- 若輸出太多，實務上通常優先先用 `kubectl` 本身的篩選能力縮小範圍，再視需要接 shell pipe 做最後整理。
- 常見的第一層篩法包括：先鎖 namespace、再加 `--field-selector`，例如 `type=Warning`、`involvedObject.kind=Pod`、`involvedObject.name=<pod-name>`。
- 當 `kubectl` 端已經把範圍縮小後，若你只是想快速看最後幾行或找特定關鍵字，再接 `tail`、`grep` 這類 pipe 就很合理。
- 一句話原則：**先盡量用 Kubernetes 自己的欄位與 selector 縮範圍，再用 shell pipe 做最後整理。**
- 比如`kubectl get events -n darkmind --sort-by=.lastTimestamp | tail -n 20`或
`kubectl get events -n darkmind --sort-by=.lastTimestamp | grep ImagePull`

### `kubectl delete namespace darkmind` 會做什麼

- 這個指令不是只刪掉 `Namespace` 物件名字本身，而是會啟動 **整個 namespace 及其底下所有 namespaced resources 的刪除流程**。
- 以 Day 1 這個情境來說，執行後會連同 `darkmind` 裡的 `Deployment`、`ReplicaSet`、`Pod`、`Service`、以及同 namespace 下的其他 namespaced 物件一起清掉。
- 這就是為什麼它很適合拿來當 lab 的固定收尾：不用一個一個刪 `Deployment`、`Pod`、`Service`，而是整包回到乾淨狀態。
- 但也因為它是整包刪除，所以它的效果比 `kubectl delete pod ...` 或 `kubectl delete deploy ...` 大很多；在 production namespace 上必須非常小心。
- 實務上執行後常會先看到 namespace 進入 `Terminating`，代表 Kubernetes 正在把裡面的資源逐步清掉，不一定是瞬間完全消失。
- 一句話口訣：**`kubectl delete namespace <name>` 是整個工作區打包清空，不是單刪一個資源。**


## Flashcards

- `kubectl get` 在 Day 1 排查鏈裡主要是在做什麼？ #DevOps #card
	- 看第一層高層狀態摘要
	- 先回答哪個 resource 看起來不對勁
	- 適合快速縮圈，不適合直接做最後定案

- `kubectl describe` 和 `kubectl get events --sort-by=.lastTimestamp` 的分工差在哪裡？ #DevOps #card
	- `describe` 看單一 resource 的展開式 Kubernetes 視角
	- `events` 看整個 namespace 的事件流與時間序列
	- 一個偏單點深挖，一個偏整體時序

- 為什麼 Day 1 要先建立健康基準，再套壞情境？ #DevOps #card
	- 先知道正常長什麼樣
	- 之後才看得出哪些欄位和訊號是異常偏離
	- 健康基準是比較座標系，不是多餘前置作業

- Image pull 類問題可以怎麼快速判讀？ #DevOps #card
	- `get` 先看到 `ImagePullBackOff`
	- `describe` 再看 `State=Waiting`、`Reason=ImagePullBackOff`、`Restart Count=0`
	- `events` 最後補完整因果鏈

- 為什麼 `Restart Count=0` 在 image pull 類問題裡很有價值？ #DevOps #card
	- 代表 container 還沒成功開始執行
	- 問題卡在 image pull / 啟動前段
	- 可用來排除「其實是 app 啟動後 crash」這條支線

- 多 replica 時，label 和 Pod 名稱通常怎麼搭配用？ #DevOps #card
	- 先用 label 配 `get` 找集合與異常摘要
	- 再挑單一 Pod 名稱做 `describe`
	- label 適合穩定鎖範圍，Pod 名稱適合精看單點

- Kubernetes `Event` 為什麼不是單純錯誤清單？ #DevOps #card
	- `Event` 本身是 resource kind
	- 它會同時記正常與異常流程
	- debug 時只是特別關注 warning 與 failure 類事件

- `kubectl delete namespace darkmind` 的效果是什麼？ #DevOps #card
	- 會啟動整個 namespace 底下所有 namespaced resources 的刪除流程
	- 適合拿來當 lab 的固定收尾
	- 在 production namespace 上要非常小心
