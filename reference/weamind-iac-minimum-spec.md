# WeaMind IaC Minimum Spec

這份文件整理 Phase 2 / W9 會反覆用到、但不需要每次都讀的最小 IaC 規格。

它不是週計畫，也不是 production-grade Terraform 設計文件。

它的角色是：當 W9 要做 Terraform prework、最小練習與 IaC 驗收時，提供一份穩定、可公開、可對照的 reference。

## 先說結論

W9 的最低目標不是把 Terraform 學到專精，而是完成一版可實作、可解釋、可面試重講的最小 IaC 經驗。

第一版應收斂成：

- 理解 core workflow：plan / apply / destroy
- 理解 provider / resource / state 的最小角色分工
- 以 https://kucw.io/blog/gcp-free-tier/ 那篇教學中的 Free Tier VM 條件為規格，用 Terraform 建出一台等價的 GCP VM
- 能講清楚 Terraform 與 Kubernetes manifest 的相似與不同

## W9 的範圍邊界

W9 在 Phase 2 裡的定位是：

- Terraform 獨立於 WeaMind 主線
- 用 GCP Free Tier 做最小實作，且目標不是隨便建一台 VM，而是盡量對齊既有教學中的 Free Tier VM 規格
- 重點是 IaC workflow 與 state / drift 概念，不是完整雲端平台設計

第一版不追求：

- production-grade remote state 架構
- 完整 module 設計
- 多環境 workspace 策略
- 大量 provider / resource 覆蓋
- Google 帳號、billing、project 開通等平台 bootstrap 流程自動化

## 本週要對齊的 VM 規格

W9 的 VM 目標，不是自行隨機發明，而是對齊這篇教學的核心免費條件：

- region 為 `us-west1`、`us-central1`、`us-east1` 其中之一
- machine type 為 `e2-micro`
- boot disk 使用標準 HDD，而非 SSD
- boot disk 大小控制在 Free Tier 邊界內
- network 設定避免多餘的付費選項

更精準地說，W9 要驗收的是：在前置帳號與 project 都已就緒的前提下，是否能用 Terraform 產生一台和教學手動建立結果等價的 VM。

## 最小概念骨架

W9 至少要能穩定分開這幾件事：

- `provider`：Terraform 怎麼連到外部平台
- `resource`：Terraform 實際宣告與管理的基礎設施物件
- `plan`：比對目前狀態與宣告內容後，預計要做的變更
- `apply`：真正把變更套出去
- `state`：Terraform 用來追蹤受管資源與目前已知狀態的核心資料
- `drift`：真實世界的資源狀態和 Terraform 期待狀態出現脫鉤

## 與 Kubernetes manifest 的最小對照

第一版最重要的對照不是語法，而是 state 與 lifecycle：

- 兩者都屬於宣告式
- Kubernetes 偏向把 desired state 交給 controller 持續 reconcile
- Terraform 依賴 state 來知道自己管理過哪些資源，以及下一次該改什麼
- 若 runtime 被手動改動，Terraform 比較容易直接遇到 drift 問題

## 第一版最小實作目標

W9 的最小實作應至少留下這些證據：

- 一次完整的 `plan`
- 一次完整的 `apply`
- 一台符合教學 Free Tier 條件的 GCE VM
- 一次對 state / 資源變更的實際觀察
- 至少一段可用來講 drift 或手動修改風險的說明

這裡的重點不是資源本身多複雜，而是你真的走過一次 IaC 基本循環。

## 第一版最小風險邊界

W9 至少要能講出這幾類風險：

- 手動改雲端資源後，Terraform state 與真實狀態脫鉤
- secret / credential 不應直接粗暴寫進設定
- remote state 與共享協作有風險，但本階段只要知道問題輪廓，不要求完整解法

## W9 驗收時至少要能回答什麼

1. Terraform 為什麼需要 state
2. plan / apply 各自回答什麼問題
3. Terraform 與 Kubernetes manifest 都是宣告式，但差異在哪裡
4. drift 為什麼麻煩
5. 你這次是否真的用 Terraform 建出一台符合教學規格的 Free Tier VM，以及你如何確認它沒有偏離免費條件

## 這份 reference 的用途

- 當 W9 做 prework、最小練習與 drift 收斂時，作為穩定範圍邊界參考
- 避免把 Terraform 核心骨架、state / drift 邏輯與 Phase 2 的取捨原則全部塞在週計畫裡
- 讓計畫檔只保留節奏、進度、實作目標與短版驗收標準
