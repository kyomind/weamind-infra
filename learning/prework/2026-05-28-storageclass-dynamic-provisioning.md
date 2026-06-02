# 2026-05-28 StorageClass and Dynamic Provisioning Prework

## Prework 內容

### 今日焦點

- 主題：Kubernetes StorageClass 與 dynamic provisioning 的核心模型
- 範圍：`StorageClass`、provisioner、parameters、reclaimPolicy、volumeBindingMode、allowVolumeExpansion、default StorageClass、PVC 如何觸發動態建立 PV
- 目標：讓我能分清楚 PV/PVC 的靜態綁定與 StorageClass 驅動的動態供應，並能看懂 CKA storage 題中的 `storageClassName`、default class、binding mode 與 resize 前提
- 時間：45 到 60 分鐘

### 這份在今天 storage prework 裡的位置

- 今天的 storage 預習被拆成三份，這一份是第二份。
- 第一份先處理 PV/PVC 的基本 binding 模型；這一份處理為什麼有 StorageClass，以及 PVC 如何透過它讓 cluster 自動建立 PV。
- 第三份會處理 Pod 掛載、shared volume 與 PVC resize 的操作題。
- WeaMind 目前沒有把主要資料庫放進 Kubernetes，所以這份只建立 CKA 所需的 portable storage 概念，不要求外部 AI 設計 WeaMind 的 production storage。

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補 WeaMind repo 細節。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 請聚焦 CKA 需要看懂和修改的 Kubernetes storage API 欄位；CSI driver 內部實作只需要用一句話帶過。

### 今天一定要學會的最小骨架

1. `StorageClass` 描述「某一類 storage 要如何被動態建立」，不是實際的一塊 volume。
2. PVC 可以透過 `storageClassName` 指定 StorageClass，進而觸發 provisioner 建立對應 PV。
3. static provisioning 是人先建 PV；dynamic provisioning 是 PVC 出現後，由 StorageClass 背後的 provisioner 建 PV。
4. default StorageClass 會影響沒有指定 `storageClassName` 的 PVC；這和明確寫 `storageClassName: ""` 不同。
5. `volumeBindingMode` 影響 PV 什麼時候被建立或綁定，常見是 `Immediate` 與 `WaitForFirstConsumer`。
6. `allowVolumeExpansion` 是 PVC resize 的前提之一，但實際能否擴容還受 storage backend 與檔案系統支援影響。
7. CKA 題目常見重點是補對 StorageClass YAML、看懂 PVC 使用哪個 class、知道 default class 與 resize 的基本條件。

### 建議教學順序

1. 先用白話解釋如果只有 PV/PVC，為什麼管理者會需要手動準備很多 PV，以及 StorageClass 想解決什麼問題。
2. 拆一份最小 StorageClass YAML：`apiVersion`、`kind`、`metadata.name`、`provisioner`、`parameters`、`reclaimPolicy`、`volumeBindingMode`、`allowVolumeExpansion`。
3. 說明 PVC 如何用 `storageClassName` 連到 StorageClass，以及 dynamic PV 是何時出現。
4. 比較三種 PVC storage class 寫法：不寫、寫空字串、寫 class 名稱。
5. 說明 default StorageClass 的 annotation，以及考題中如何查 default class。
6. 說明 `Immediate` 與 `WaitForFirstConsumer` 的差異，尤其是 topology / zone-aware storage 的直覺。
7. 最後用 2 到 3 題 CKA 風格小題練習：建立 StorageClass、建立 PVC 使用它、判斷 PVC Pending 或 resize 失敗原因。

### 額外要求

- 請特別回答下面這幾個問題：
  1. StorageClass、PV、PVC 三者各自回答什麼問題？
  2. 為什麼 StorageClass 不是 namespace-scoped？
  3. default StorageClass 如何影響 PVC？怎麼查哪個 class 是 default？
  4. `Immediate` 和 `WaitForFirstConsumer` 對 scheduling 有什麼差異？
  5. `allowVolumeExpansion: true` 代表什麼？它是否保證 resize 一定成功？
- 請用考試視角整理常見 YAML 片段，例如：
  - 一個最小 StorageClass。
  - 一個 PVC 指定 StorageClass。
  - 查詢 StorageClass、PVC、PV 狀態的常用 kubectl 指令。

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

- `StorageClass` 本身是 Kubernetes API object，不是 PVC 裡的一個普通字串，也不是實際的一塊 storage。它描述的是某一類 storage 應該如何被建立。
- PV、PVC、StorageClass 分別回答不同問題：
  - PV：cluster 裡目前有哪些可用的 storage？
  - PVC：workload 需要什麼 storage？
  - StorageClass：如果需要動態供應 storage，應該用什麼規則與 provisioner 建立？
- static provisioning 與 dynamic provisioning 的分界，不是「有沒有 StorageClass」，而是 PV 在 PVC 出現前是否已經存在：

```text
Static:
PV -> PVC -> Bound

Dynamic:
PVC -> StorageClass -> Provisioner -> Backend Storage -> PV -> Bound
```

- static PV 和 PVC 仍然可以帶相同的 `storageClassName`。只要 PV 是管理員事先建立，仍然屬於 static provisioning。
- StorageClass 裡的 `provisioner` 指定由誰實際建立 storage。實務上常由 CSI driver 承接；CKA 階段先記住它是實際執行者即可。
- StorageClass 的 `reclaimPolicy` 描述 PVC 釋放後如何處理動態建立的 PV 與底層 storage：
  - `Delete`：刪除 PV，通常也刪除底層 storage。
  - `Retain`：保留 PV 與資料，交由管理員後續處理。
- `volumeBindingMode` 影響建立或綁定 PV 的時機：
  - `Immediate`：PVC 建立後立即建立或綁定 PV。
  - `WaitForFirstConsumer`：等到 Pod 使用 PVC，再根據 Pod 的排程位置建立或綁定適合的 PV。這能避免 topology / zone 不相容。
- default StorageClass 使用 annotation 標示：

```yaml
annotations:
  storageclass.kubernetes.io/is-default-class: "true"
```

- PVC 的 `storageClassName` 有三種重要情況：
  - 省略：若 cluster 有 default StorageClass，PVC 會使用它。
  - 指定名稱，例如 `fast`：選擇該 StorageClass，也可以與事先存在的同 class static PV 配對。
  - 明確寫成 `""`：不使用任何 StorageClass，也不套用 default class，只尋找沒有 class 的現有 PV。
- `allowVolumeExpansion: true` 代表 StorageClass 允許 PVC 提出擴容申請，但不是 resize 一定成功的保證。實際結果仍取決於 storage backend、CSI driver 與檔案系統支援。
- CKA 排查 PVC `Pending` 時，第一步應先分辨目前走的是 static provisioning、dynamic provisioning，還是 `WaitForFirstConsumer` 正在等待 Pod。

```bash
kubectl get sc
kubectl get sc <name> -o yaml
kubectl get pv,pvc
kubectl describe pvc <name> -n <namespace>
```

### 已能白話講清楚什麼

- StorageClass 像一份建立 storage 的規格書；PV 是實際可用的 storage resource；PVC 是 workload 提出的 storage 需求。
- Dynamic provisioning 的完整路徑是 `PVC -> StorageClass -> Provisioner -> Backend Storage -> PV -> Bound`。
- StorageClass 和 dynamic provisioning 不是同義詞。PV 若事先存在，即使帶有 `storageClassName`，仍可能是 static provisioning。
- `storageClassName: ""` 不是漏寫，而是明確要求不要使用任何 StorageClass。
- `WaitForFirstConsumer` 是先知道 Pod 要排到哪裡，再準備合適的 storage，避免 topology 衝突。
- `allowVolumeExpansion` 只是允許申請擴容的必要條件之一，不是成功保證。

### 目前還卡住什麼

- PV 與 StorageClass 的 matching 細節，以及同時存在多個候選 PV 時 Kubernetes 如何選擇。
- 多個 StorageClass 共存時，PVC 明確指定 class、使用 default class、完全不要 class 的行為邊界。
- PVC resize 的完整操作流程，以及修改 PVC request 後如何觀察 PV、Pod 與檔案系統狀態。
- CSI driver 與 backend storage 的實際互動方式，目前先保留在概念層。

### 今日最重要的觀念

1. StorageClass 是描述 provisioning 規則的 Kubernetes object，不是 storage 本身。
2. static / dynamic provisioning 的真正分界是 PV 是否事先存在，不是有沒有 StorageClass。
3. dynamic provisioning 的核心流程是 `PVC -> StorageClass -> Provisioner -> PV -> Bound`。
4. 省略 `storageClassName`、指定 class、明確寫成 `storageClassName: ""` 是三種不同語意。
5. `WaitForFirstConsumer` 與 `allowVolumeExpansion` 都是 StorageClass 的重要行為設定：前者控制綁定時機，後者只允許提出擴容申請。

### 帶回 repo 內對照的問題

1. 建立或讀取一份 StorageClass YAML，將 `provisioner`、`reclaimPolicy`、`volumeBindingMode`、`allowVolumeExpansion` 全部翻譯成白話，並用 `kubectl get sc <name> -o yaml` 驗證。
2. 故意建立一個使用 `storageClassName: ""` 的 PVC，在沒有符合 PV 時觀察 `kubectl describe pvc` 與 `kubectl get pv,pvc`，解釋它為什麼維持 `Pending`。
