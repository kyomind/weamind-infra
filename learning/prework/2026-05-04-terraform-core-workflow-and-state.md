# 2026-05-04 Terraform Core Workflow and State

## Prework 內容

### 今日焦點

- 主題：Terraform 核心工作流與 state 骨架
- 範圍：先建立 `provider`、`resource`、`plan`、`apply`、`destroy`、`state`、`drift` 的最小關係，並和 Kubernetes manifest 做第一層對照；不進入 GCP 實作細節、不展開 remote state、module、workspace 或 production-grade Terraform 設計
- 目標：把「知道 Terraform 是 IaC 工具」補成「至少能用白話講清楚它怎麼運作、為什麼需要 state，以及它和 Kubernetes manifest 同樣宣告式但不完全一樣」
- 時間：控制在 45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 我目前的真實狀態是：我知道 Terraform 大概是用來宣告雲端資源的，但對它為什麼需要 state、`plan` / `apply` 到底各自回答什麼問題，以及它和 Kubernetes manifest 的差異，骨架還不穩。請把教學重點放在白話模型，而不是預設我已經做過完整 Terraform 實作。
- 今天不要先展開 GCP provider 細節、憑證設定、API enable、module 設計、remote state 架構、workspace 策略，或各家雲平台比較。
- 明天回到 VS Code 之後，我才會把這個骨架對回 GCP Free Tier VM 的最小 Terraform 練習；今天先把概念地基切清楚。

### 今天一定要學會的最小骨架

1. Terraform 是宣告式 IaC 工具，但它不是只把設定檔送出去，而是要先比對目前狀態、算出變更，再決定要建立、修改或刪除哪些資源。
2. `provider` 是 Terraform 連到外部平台的入口，`resource` 是 Terraform 實際宣告與管理的基礎設施物件。
3. `plan` 的核心是在回答「如果現在套用，Terraform 預計會改什麼」，`apply` 才是把這些變更真正套出去。
4. `state` 不是單純 cache，而是 Terraform 用來追蹤自己管理過哪些資源與目前已知狀態的核心資料。
5. `drift` 是真實雲端資源狀態和 Terraform 期待狀態脫鉤；這也是 Terraform 和 Kubernetes manifest 在 lifecycle 上最值得先切開的地方。
6. Terraform 和 Kubernetes manifest 都屬於宣告式，但 Kubernetes 偏向 controller 持續 reconcile，Terraform 則更依賴 state 與明確的 plan / apply 週期。

### 建議教學順序

1. 先用白話講 Terraform 在解什麼問題，並說明它為什麼不只是「用程式碼建立雲端資源」這麼簡單。
2. 再把 `provider`、`resource`、`plan`、`apply`、`destroy` 各自分開講清楚，避免名詞混成一團。
3. 接著重點講 `state`：Terraform 為什麼需要它、沒有它會怎樣、它和單純設定檔有什麼差別。
4. 然後講 `drift`：手動改雲端資源後，Terraform 會遇到什麼問題，為什麼這件事麻煩。
5. 最後再做 Terraform 與 Kubernetes manifest 的最小比較，重點放在 state、reconcile、lifecycle，不要變成 YAML 語法比較。

如果我卡住，請先用更白話的比喻或最小例子講一次，再讓我重述；不要一開始就丟很多術語定義。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 VS Code 後，應該拿去和 GitHub Copilot 對照 lesson 的 2 個問題。
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

### 帶回 VS Code 的問題

1.
2.
