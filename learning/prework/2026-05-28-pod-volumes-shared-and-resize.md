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

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 repo 內對照的問題

1.
2.
