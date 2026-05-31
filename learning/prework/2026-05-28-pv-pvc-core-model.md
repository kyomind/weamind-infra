# 2026-05-28 PV and PVC Core Model Prework

## Prework 內容

### 今日焦點

- 主題：Kubernetes PersistentVolume 與 PersistentVolumeClaim 的核心模型
- 範圍：`PersistentVolume`、`PersistentVolumeClaim`、binding、capacity、accessModes、storage request、reclaimPolicy、volumeMode、static provisioning、常見 CKA YAML
- 目標：讓我能在 CKA storage 題裡看懂 PV/PVC 誰定義實體儲存、誰提出需求、兩者如何配對，以及 Pod 為什麼通常透過 PVC 使用 storage
- 時間：45 到 60 分鐘

### 這份在今天 storage prework 裡的位置

- 今天的 storage 預習被拆成三份，這一份是第一份。
- 這一份先建立 PV/PVC 的基本心智模型：cluster 內的 storage resource、namespace 內的 storage request，以及兩者如何綁定。
- 第二份會處理 `StorageClass` 與 dynamic provisioning；第三份會處理 Pod 掛載、shared volume 與 resize。
- WeaMind 目前主要把資料庫留在 VM 上，沒有把 DB 跑進 cluster，所以今天先用 CKA / lab 視角學 portable 概念，不急著套回 WeaMind 實作。

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補 WeaMind repo 細節。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 請優先用 CKA 題型角度教我判讀與手寫 YAML，不要展開成雲端 CSI driver 或 production storage 架構比較。

### 今天一定要學會的最小骨架

1. `PersistentVolume` 是 cluster-scoped 的儲存資源，描述「有一塊 storage 可以被使用」。
2. `PersistentVolumeClaim` 是 namespace-scoped 的儲存需求，描述「某個 namespace 裡的 workload 需要一塊符合條件的 storage」。
3. PV 與 PVC 的 binding 主要看 capacity、accessModes、storageClassName、volumeMode、selector 等條件是否匹配。
4. Pod 通常不直接綁 PV，而是透過 PVC 使用 storage，讓 workload 和底層 storage 細節解耦。
5. static provisioning 是先建立 PV，再建立 PVC 去 claim；dynamic provisioning 會留到下一份 prework。
6. `persistentVolumeReclaimPolicy` 決定 PVC 被刪除後 PV 背後資料如何處理，常見有 `Retain`、`Delete`、`Recycle`。
7. CKA 題目常見重點不是 storage 產品選型，而是能不能正確補出 PV/PVC YAML 欄位、看懂 Bound / Pending 狀態。

### 建議教學順序

1. 先用白話解釋為什麼 Kubernetes 需要 PV/PVC，而不是讓 Pod 直接知道磁碟位置。
2. 拆解 PV 最小 YAML：`apiVersion`、`kind`、`metadata.name`、`spec.capacity.storage`、`spec.accessModes`、`spec.persistentVolumeReclaimPolicy`、`spec.storageClassName`、一種 volume source。
3. 拆解 PVC 最小 YAML：`metadata.namespace`、`spec.accessModes`、`spec.resources.requests.storage`、`spec.storageClassName`。
4. 用「PV 提供什麼、PVC 要求什麼、條件是否匹配」教我判斷 binding。
5. 說明常見 access mode：`ReadWriteOnce`、`ReadOnlyMany`、`ReadWriteMany`、`ReadWriteOncePod`，並提醒它們是 storage backend 能力與調度語意，不是 Linux file permission。
6. 說明 `Retain` 與 `Delete` 的差異，以及 CKA 題目裡看到 reclaim policy 時應該怎麼判讀。
7. 最後用 2 到 3 題 CKA 風格小題練習：建立 PV、建立 PVC、排查 PVC 為什麼 Pending。

### 額外要求

- 請特別回答下面這幾個問題：
  1. PV 是 cluster-scoped，PVC 是 namespace-scoped，這在題目裡會造成什麼影響？
  2. PVC request 小於 PV capacity 時可不可以綁定？反過來呢？
  3. `storageClassName: ""`、不寫 `storageClassName`、寫某個 class 名稱，差在哪裡？
  4. `Retain` policy 下 PVC 刪掉後，PV 和資料大概會進入什麼狀態？
  5. 為什麼 Pod 通常應該引用 PVC，而不是直接引用某個 PV？
- 請用考試視角整理常見 YAML 片段，例如：
  - static PV + PVC。
  - PVC 綁不到 PV 的幾種典型原因。
  - 用 `kubectl get pv,pvc` 與 `kubectl describe pvc` 看狀態。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 repo 內後，應該拿去做 CKA 練習或專案對照的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

- PV（PersistentVolume）是 cluster-scoped 的 storage resource，描述 cluster 裡有一塊可供使用的儲存空間，包括容量、access mode、reclaim policy、storage class 與 volume source。
- PVC（PersistentVolumeClaim）是 namespace-scoped 的 storage request，描述某個 namespace 裡的 workload 需要多少容量、哪種 access mode 與哪一類 storage。
- Pod 不直接引用 PV，而是透過同一個 namespace 裡的 PVC 使用 storage：

```text
Pod -> PVC -> PV -> Storage Backend
```

- 這層抽象讓 application 不需要知道底層使用的是 `hostPath`、NFS、cloud disk 或 CSI driver。
- static provisioning 的基本流程是先建立 PV，再建立 PVC。Kubernetes 會依條件找出適合的 PV 並完成 binding。
- PV 與 PVC binding 時，至少要注意 capacity、access modes、`storageClassName` 與 `volumeMode` 是否匹配。PVC request 小於等於 PV capacity 時可以綁定；需求大於供給時 PVC 會維持 `Pending`。
- access mode 描述 storage backend 的掛載能力，不是 Linux file permission。`ReadWriteOnce`（RWO）限制的是單一 node 可讀寫，不等於只能有一個 Pod 使用。
- `persistentVolumeReclaimPolicy` 描述 PVC 被刪除後如何處理 storage。`Retain` 會保留資料，PV 通常進入 `Released`，需要管理員介入才能再次使用；`Delete` 則會連底層 storage 一起刪除。
- `storageClassName: ""` 和完全省略 `storageClassName` 不同：前者明確表示不使用 StorageClass；後者可能使用 default StorageClass。完整模型留到下一份 prework。
- 排查 PVC `Pending` 時，先依序確認容量、access modes、`storageClassName`、是否存在可用 PV，再用事件收斂原因：

```bash
kubectl get pv
kubectl get pvc -n <namespace>
kubectl describe pvc <name> -n <namespace>
```

### 已能白話講清楚什麼

- PV 是 cluster 裡提供 storage 的 Kubernetes 物件；PVC 是 namespace 裡提出 storage 需求的物件。
- Kubernetes 會替 PVC 找條件相符的 PV，讓 application 不需要直接知道磁碟、NFS 或 cloud volume 的細節。
- PV 是 cluster-scoped；PVC 是 namespace-scoped。Pod 只能引用同 namespace 的 PVC。
- PVC `Pending` 通常代表目前沒有符合條件的 PV，不是 Kubernetes 本身故障。
- `Retain` 不代表下一個 PVC 可以立刻接手舊 PV；資料保留下來後，通常仍需要管理員處理。

### 目前還卡住什麼

- StorageClass 與 dynamic provisioning 的完整模型，尤其是省略 `storageClassName` 與明確寫成 `storageClassName: ""` 時，背後行為為何不同。
- `volumeMode` 的 `Filesystem` 與 `Block` 差異，目前只有初步概念。
- 還需要透過 CKA 題目從零手寫一次完整 PV/PVC YAML，將概念轉成操作能力。

### 今日最重要的觀念

1. PV 提供 storage；PVC 提出 storage 需求。
2. PV 是 cluster-scoped；PVC 是 namespace-scoped。
3. PVC 會依 capacity、access modes、storage class 與 volume mode 尋找適合的 PV。
4. Pod 透過 PVC 使用 PV，形成 `Pod -> PVC -> PV -> Storage Backend`。
5. PVC `Pending` 通常代表條件不匹配或沒有可用 PV，應先看資源狀態與事件。

### 帶回 repo 內對照的問題

1. WeaMind 目前把 PostgreSQL 留在 VM；如果改成跑在 Kubernetes，至少需要哪些 PV/PVC 設計？這會增加哪些維運成本與風險？
2. 建立一組 `10Gi`、`ReadWriteOnce`、`Retain`、`hostPath` 的 static PV 與對應 PVC，從零手寫 YAML，並驗證 PVC 是否進入 `Bound`。
