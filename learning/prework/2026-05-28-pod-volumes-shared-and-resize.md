# 2026-05-28 Pod Volumes, Shared Volume, and Resize Prework

## Prework 內容

### 今日焦點

- 主題：Pod 如何使用 volume、shared volume 題型，以及 PVC resize 的操作骨架
- 範圍：`spec.volumes`、`containers[].volumeMounts`、PVC volume、`emptyDir`、shared volume between containers、mountPath、subPath、PVC resize、觀察 Pod / PVC / PV 狀態
- 目標：讓我能在 CKA storage 題裡快速把 PVC 掛到 Pod，分清楚「同一個 Pod 內多 container 共享 volume」與「多 Pod 共享 persistent storage」，並知道 resize 題要改哪個物件與看哪些狀態
- 時間：45 到 60 分鐘

### 這份在今天 storage prework 裡的位置

- 今天的 storage 預習被拆成三份，這一份是第三份。
- 第一份處理 PV/PVC 基本模型，第二份處理 StorageClass 與 dynamic provisioning；這一份收斂到 CKA 題目最常要動手改的 Pod 掛載、shared volume 與 resize。
- 這份會碰到 Pod YAML，但仍然是概念與 CKA 操作骨架，不是要把 WeaMind 的資料庫搬進 cluster。

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補 WeaMind repo 細節。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 請優先教 CKA 會考的 YAML 位置、指令觀察與常見陷阱，不要展開成完整 storage performance 或 backup 策略。

### 今天一定要學會的最小骨架

1. Pod 層級的 `spec.volumes` 定義 volume 來源，container 層級的 `volumeMounts` 決定把 volume 掛到容器內哪個 path。
2. PVC 掛載到 Pod 時，Pod YAML 裡使用 `persistentVolumeClaim.claimName`，不是直接寫 PV 名稱。
3. 同一個 Pod 內多個 containers 可以 mount 同一個 volume，這是 CKA 常見 shared volume 題型。
4. `emptyDir` 是 Pod 生命週期內的臨時共享 volume；PVC 是跨 Pod 重建後仍可能保留資料的 persistent storage。
5. accessModes 影響多 Pod / 多 node 使用同一份 persistent storage 的能力，但不等於容器內檔案權限。
6. PVC resize 通常是修改 PVC 的 `spec.resources.requests.storage`，不是直接改 PV capacity。
7. resize 要看 StorageClass 是否允許 expansion、PVC/PV 狀態、Pod 是否需要重啟或 filesystem 是否完成擴容。

### 建議教學順序

1. 先用白話建立 Pod volume 的兩層模型：Pod 定義 volume 來源，container 決定 mount path。
2. 拆一個 Pod 掛載 PVC 的最小 YAML，特別標出 `spec.volumes[].persistentVolumeClaim.claimName` 與 `containers[].volumeMounts[]`。
3. 用一個 sidecar / two-container Pod 解釋 shared volume：兩個 container mount 同一個 `emptyDir` 或 PVC 到不同或相同路徑。
4. 比較 `emptyDir`、ConfigMap/Secret volume、PVC volume 的生命週期與用途，只講 CKA 會用到的差異。
5. 說明 accessModes 和 shared volume 題目的關係：同 Pod shared volume vs 多 Pod shared persistent volume 要分開想。
6. 說明 PVC resize 的基本流程：確認 StorageClass、修改 PVC request、觀察 PVC/PV、確認 Pod 內 filesystem。
7. 最後用 2 到 3 題 CKA 風格小練習：把 PVC 掛到 Pod、建立 shared `emptyDir`、把 PVC 從 1Gi 擴到 2Gi 並觀察狀態。

### 額外要求

- 請特別回答下面這幾個問題：
  1. `volumes` 和 `volumeMounts` 分別在 YAML 的哪一層？各自負責什麼？
  2. shared volume 是不是一定等於 `ReadWriteMany`？
  3. 同一個 Pod 內兩個 containers 共享 `emptyDir`，和兩個 Pods 共享 PVC，有什麼本質差異？
  4. PVC resize 時應該改 PVC 還是 PV？為什麼？
  5. resize 後要用哪些 kubectl 指令確認狀態？
- 請用考試視角整理常見 YAML 片段，例如：
  - Pod 掛載 PVC 到 `/data`。
  - two-container Pod 共享同一個 `emptyDir`。
  - 修改 PVC request 做 resize。
  - 用 `kubectl describe pod` / `kubectl describe pvc` 查掛載或 resize 問題。

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

- Pod 使用 storage 時有兩層模型：
  - `spec.volumes` 定義 volume 來源，回答「這個 Pod 有哪些 storage 可以用」。
  - `containers[].volumeMounts` 定義掛載位置，回答「這個 container 要在哪個路徑看到這份 storage」。
- PVC 掛到 Pod 時，Pod YAML 裡使用 `persistentVolumeClaim.claimName`，而且填的是 PVC 名稱，不是 PV 名稱。

```yaml
volumes:
- name: data-volume
  persistentVolumeClaim:
    claimName: weather-data-pvc
```

- 正確心智模型是：

```text
Pod -> PVC -> PV -> Storage
```

- shared volume 不一定等於 `ReadWriteMany`。同一個 Pod 內多個 containers 共享同一個 `emptyDir` 或同一個 volume，不需要先思考 RWO / ROX / RWX；accessModes 主要影響多 Pod / 多 node 使用同一份 persistent storage 的能力。
- `emptyDir` 是跟 Pod 生命週期綁定的暫存 volume，適合 sidecar、log sharing、暫存檔案。Pod 刪除後資料也消失。
- ConfigMap 掛載成 volume 後，不是把 YAML 原樣放進 container，而是 key 變成檔名、value 變成檔案內容。

```text
ConfigMap data key -> file name
ConfigMap data value -> file content
```

- PVC volume 才是 persistent storage 的入口，適合 database、user upload、application data 等需要跨 Pod 重建保留的資料。
- `ReadWriteOnce` 不是「只能寫一次」，也不等於「只能給一個 Pod」。它的重點是同一時間只能由一個 node 掛載讀寫。
- PVC resize 時應修改 PVC 的 `spec.resources.requests.storage`，不是直接改 PV capacity。因為 PVC 是需求來源，PV 是供給結果。
- StorageClass 控制 resize 能否被接受，因為真正能否擴容取決於底層 storage backend 與 CSI driver 能力。流程可以理解成：

```text
PVC 提出需求
StorageClass 描述能力
CSI Driver 執行擴容
PV 反映結果
Storage Backend 提供實際容量
```

- resize 後最常用 `kubectl describe pvc <name>` 觀察 capacity、conditions、events，再用 `kubectl get pv` 確認 PV capacity 是否同步更新；必要時用 `kubectl describe pod <pod-name>` 看 filesystem resize 相關事件。

### 已能白話講清楚什麼

- `volumes` 是來源，`volumeMounts` 是 container 內的掛載位置。
- Pod 永遠透過 PVC 使用 persistent storage，不直接找 PV。
- 同 Pod 內多 container 共享 volume，和多 Pod 共享 persistent storage，是兩種不同問題。
- `emptyDir` 適合 Pod 內暫存與 sidecar sharing；PVC 適合需要保留的資料。
- ConfigMap volume 會把 key-value 轉成檔案，不是把 ConfigMap YAML 原樣掛進去。
- RWO 的重點是 node，不是「一次」或「一個 Pod」。
- resize 改 PVC，不改 PV；StorageClass 決定這個 resize request 是否有能力被實現。

### 目前還卡住什麼

- CSI driver 實際如何執行 expansion，目前只理解到它是執行者。
- 不同 storage backend，例如 NFS、Longhorn、EBS，對 resize 與 access mode 的支援差異。
- filesystem resize 與 volume resize 的細節，以及哪些情況需要 Pod 重啟或等待 filesystem resize 完成。

### 今日最重要的觀念

1. `volumes` 定義來源，`volumeMounts` 定義掛載位置。
2. Pod 透過 PVC 使用 storage，不直接引用 PV。
3. shared volume 不等於 RWX；同 Pod 共享與多 Pod 共享要分開想。
4. ConfigMap 掛載後是檔案模型：key 是檔名，value 是檔案內容。
5. PVC resize 改 PVC，不改 PV；StorageClass 與 CSI driver 決定能不能真正完成擴容。

### 帶回 repo 內對照的問題

1. 如果未來把 WeaMind 的 PostgreSQL 搬進 Kubernetes，PVC、StorageClass、access mode 應該如何設計？目前 PostgreSQL 留在 VM 的混合架構，避免了哪些 in-cluster storage 維運問題？
2. 如果 `line-bot` Pod 增加一個 log sidecar，使用 `emptyDir` 共享日誌的 YAML 會怎麼設計？哪些欄位屬於 `volumes`，哪些欄位屬於 `volumeMounts`？
3. 如果未來導入 Longhorn，PVC resize 是否仍可理解成 `修改 PVC -> StorageClass -> CSI Driver -> PV`？Longhorn 在這條鏈路中扮演哪個角色？
