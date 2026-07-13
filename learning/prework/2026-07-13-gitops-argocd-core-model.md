# 2026-07-13 GitOps and Argo CD Core Model

## Prework 内容

### 今日焦點

- 主題：GitOps 的最小概念骨架與 Argo CD 核心模型
- 範圍：GitOps 的 pull model 本質、和 push-based CD 的差異、Argo CD 的 Application / syncPolicy / selfHeal / prune 是什麼、Sealed Secrets 怎麼讓 Secret 安全進 Git；不進入 Argo CD 安裝指令、不展開 Flux 比較、不展開多 cluster 管理
- 目標：把「我聽過 GitOps 但其實不知道它本質上哪裡不同」補成「我能白話講清楚 GitOps 的 pull model、Argo CD 的核心元件、以及為什麼它和之前做的 push-based CD 根本不同」
- 時間：控制在 45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的節奏是：上午先完成這份 prework，下午回到 VS Code 做 WeaMind 的 repo-backed implement-heavy lesson（實際安裝 Argo CD + Sealed Secrets）。
- 我目前的真實狀態是：已經了解 CI/CD 的基本概念，也做過 push-based CD（GitHub Actions 觸發 kubectl apply），但對 GitOps 的 pull model、Argo CD 的 Application CRD、syncPolicy 這些名詞其實沒有清晰骨架。
- 今天請優先幫我建立 GitOps 的本質理解與 Argo CD 的核心運作模型，不要先跳進安裝步驟或 YAML 細節。

### 今天一定要學會的最小骨架

1. GitOps 的關鍵不是「用 Git」，而是「pull model」——controller 在 cluster 內部持續拉取 Git 中的期望狀態，並自動對齊 cluster 實際狀態。
2. Push-based CD（如 GitHub Actions kubectl apply）和 GitOps 的根本差異：push 是外部觸發一次性的部署，pull 是內部 controller 持續 reconcile。
3. Argo CD 的 Application CRD 是「把哪個 Git repo 的哪個 path 同步到哪個 cluster 的哪個 namespace」的宣告。
4. syncPolicy 控制自動同步行為：automated（自動同步）、selfHeal（偵測到 drift 時自動修復）、prune（Git 中刪掉的資源也在 cluster 中刪除）。
5. Sealed Secrets 的核心是 asymmetric encryption：cluster 中有 private key（controller 持有），開發者用 public key（kubeseal CLI）加密 Secret，加密後的 SealedSecret 可以安全放進 Git，只有目標 cluster 能解密。

### 建議教學順序

1. 先用白話講 GitOps 的 pull model 本質：它不是「把 CI/CD pipeline 搬到 Git 裡」，而是「cluster 內部有一個 controller 持續看著 Git，發現不一樣就自己修正」。
2. 再對比 push vs pull 的具體差異：觸發者（外部 CI vs 內部 controller）、持續性（一次 vs 持續 reconcile）、drift detection（沒有 vs 內建）。
3. 接著講 Argo CD 的三層核心概念：Application（宣告期望來源與目標）、syncPolicy（控制同步行為）、reconcile loop（每 3 分鐘比對 Git 與 cluster 狀態）。
4. 解釋 syncPolicy 的三個關鍵選項：selfHeal 的風險（手動緊急修復會被蓋掉）、prune 的風險（誤刪 Git 資源會連 cluster 一起刪）。
5. 最後講 Sealed Secrets 的安全模型：為什麼加密後的 Secret 可以放心進 Git、controller 怎麼在 cluster 內解密、和 External Secrets Operator 的定位差異（Sealed Secrets 是加密後存 Git，ESO 是從外部 secret manager 拉）。

如果我卡住，請優先用更具體的例子（例如：GitHub Actions 推一次 vs Argo CD 每 3 分鐘自己檢查一次）來對比，不要直接丟術語表。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 用一句話說清楚 push-based CD 和 GitOps（pull model）的根本差異。
  7. 我今天下午回到 VS Code 做 implement 時，應該注意的 2 個設計前提或風險點。
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

### Push-based CD vs GitOps 一句話差異

- 待填

### 下午 implement 前要注意的前提或風險

1.
2.
