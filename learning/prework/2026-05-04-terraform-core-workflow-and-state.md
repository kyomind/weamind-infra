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

- Terraform 的核心不是單純「用程式碼建立雲端資源」，而是先比對目前狀態與目標狀態，算出差異，再決定要做哪些變更，最後才執行。
- `plan` 回答的是「如果現在套用，世界會變成怎樣」；`apply` 才是把變更真正套出去。`destroy` 也可以理解成一種以刪除為目標的 apply。
- `provider` 是 Terraform 連到外部平台的入口，本質接近 API client；`resource` 則是 Terraform 實際宣告與管理的基礎設施物件。
- `state` 不是單純 cache，而是 Terraform 用來維持 resource 與真實雲端資源 ID 對應關係的核心資料。它解的關鍵問題不是「資源長怎樣」，而是「這是誰」。
- Terraform 判斷資源該 update 還是 create，核心不是靠設定內容，而是靠 state 裡的身份對應。
- `drift` 是 Terraform 的認知與現實世界脫鉤；它麻煩的地方不只是不同步，而是會讓 Terraform 在下一次 plan / apply 做出錯誤或高風險決策。
- Terraform 和 Kubernetes 都屬於宣告式，但 Kubernetes 偏向 controller 持續 reconcile，Terraform 則更像手動 reconcile，需要明確的 plan / apply 週期。

### 已能白話講清楚什麼

- Terraform 不是直接執行設定，而是先比對目前狀態與目標狀態，算出差異，再決定要做哪些變更，最後才執行。
- Terraform 需要 state 來記錄 resource 和真實資源的對應關係，否則它無法穩定判斷應該 update、create，還是誤以為要重建資源。
- `drift` 是現實世界的資源被手動改動，但 Terraform 的 config 和 state 沒有同步更新，導致三者不一致。
- Kubernetes 會持續 reconcile，所以 drift 會偏向被自動修復；Terraform 不會持續自動修，只會在下次 `plan` 或 `apply` 時才處理。
- Terraform 的冪等性不是靠自己手寫很多保護邏輯，而是靠每次重新計算 diff 來決定變更。

### 目前還卡住什麼

- state 與 real world 的互動細節還沒完全打通，例如 refresh 行為、state 與 provider 的同步方式，以及某些 unexpected diff 為什麼會出現。
- drift 發生後的操作策略還需要更多實際案例去分辨：什麼時候應該讓 reality 回到 config，什麼時候應該先更新 config 或 state 來對齊 reality。
- 目前已經知道 `provider`、`resource`、`plan`、`apply`、`state`、`drift` 的骨架，但還沒進到 GCP 實作與 plan output 細讀階段。

### 今日最重要的觀念

- Terraform 是決策系統，不只是執行工具。
- `plan` 可以先理解成 Terraform 的 diff engine。
- `state` 最重要的角色是 identity mapping，而不只是快取。
- Terraform 判斷資源靠的是 ID 與狀態對應，不是只看設定內容。
- `drift` 的麻煩點在於它會帶來錯誤決策風險，而不只是單純不同步。

### 帶回 VS Code 的問題

1. 如果我建立一個 VM，然後手動在 GCP 改設定，再跑 `terraform plan`，會出現哪些 diff？這些 diff 是怎麼從 state 加上 real world 一起算出來的？
2. 如果我刪掉 local state file，再重新跑 `terraform plan`，Terraform 會發生什麼？為什麼會出現 resource 重建或錯誤判斷？
