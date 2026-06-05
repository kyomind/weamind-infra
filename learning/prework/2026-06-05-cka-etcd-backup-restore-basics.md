# 2026-06-05 CKA Etcd Backup Restore Basics

## Prework 內容

### 今日焦點

- 主題：CKA 題目中的 etcd backup / restore
- 範圍：etcd 在 control plane 中的角色、snapshot save / restore、endpoint / CA / cert / key / data-dir 的語意、restore 後的驗證
- 目標：建立能看懂 ETCD Backup / ETCD Restore 題的最小概念骨架，之後再回到題庫練精確指令
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的背景是：我正在刷 KillerCoda CKA 題庫，Architecture / Installation / Maintenance 類別裡有 ETCD Backup、ETCD Restore 題。請先教概念骨架與操作順序背後的原因，不要直接變成一長串指令背誦。

### 今天一定要學會的最小骨架

1. etcd 是 Kubernetes control plane 的狀態資料庫，保存 API server 看到的 cluster state。
2. etcd snapshot 是把當下 cluster state 備份下來；restore 是用 snapshot 建立一份新的 etcd data directory。
3. etcd backup / restore 題的核心不是只背 `etcdctl`，而是知道 endpoint、CA、cert、key、snapshot 檔案與 data-dir 分別在做什麼。
4. snapshot 能備份 Kubernetes API state，但不等於備份 node OS、container image 或外部資料庫資料。
5. restore 之後通常需要讓 control plane static Pod 或 etcd process 指向新的 data directory。
6. 維護題要養成「操作前確認狀態、操作後驗證 API server / nodes / pods」的節奏。

### 建議教學順序

1. 先用 control plane 架構說明 etcd、API server、scheduler、controller-manager 的責任分工。
2. 再說明為什麼 etcd snapshot 能代表 cluster state，以及它不能代表什麼。
3. 拆解 `etcdctl snapshot save` 背後每個參數的意義，重點是語意，不要求一次背熟完整指令。
4. 拆解 `etcdctl snapshot restore`、data-dir、static Pod manifest 之間的關係。
5. 用 CKA restore 題型講清楚為什麼 restore 後要驗證 API server 是否恢復可用。
6. 最後整理一條 etcd 維護題安全節奏：先查、備份、restore、切換 data-dir、重啟/等待 control plane、驗證。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 repo 內後，應該拿去做專案對照的 2 個問題。
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

