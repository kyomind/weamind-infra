# 2026-05-05 Terraform GCP Free Tier VM Minimum Apply Outline

## 今日主題

- 用 Terraform 在 GCP 上完成一版符合 Free Tier 邊界的最小 VM 練習，並留下可驗收的 IaC workflow 證據。

## 今日套用的 lesson mode

- implement-heavy mode

## 為什麼今天要套用 implement-heavy mode

1. 今天的重點不是再補 Terraform 概念，而是把昨天收斂的 IaC 骨架落成實際 `.tf` 設定與最小 `plan` / `apply` 證據。
2. 驗收依賴 preflight gate、實作結果與 Free Tier 規格核對，因此 lesson 主體應採 implementation-first。

## 這次要解的專案問題

1. 在這個 repo 的 `terraform/gcp-free-tier-vm/` 邊界下，第一版 `.tf` 骨架最少要包含哪些層，才算真正可執行。
2. 今天要如何先確認 Terraform CLI、GCP project、billing 與必要 API 都已就緒，避免把 apply 失敗和 HCL 問題混在一起。
3. 就算今天只做最小版本，也要留下哪些證據，才能證明這台 VM 真的對齊 Free Tier 條件，而不是隨便建一台 GCE。

## 這份 lesson 是否需要外部預習

- 不需要
- 原因：W9 Day 1 已完成 Terraform core workflow、state 與宣告式模型 prework 與 repo-backed lesson，今天直接進 implement-heavy lesson 即可。

## 要對照的 repo 檔案

1. `references/phase2/w9-iac-minimum-spec.md`
2. `terraform/README.md`
3. `terraform/gcp-free-tier-vm/README.md`
4. `.privatedocs/Phase2三週計畫.md`

## 今日實作邊界

1. 第一版只做單一 GCP Free Tier VM 的最小 Terraform 練習，不展開 module、remote state、workspace 或多環境策略。
2. 今天先以 preflight gate、`.tf` 骨架、`plan` / `apply` 證據與 Free Tier 規格核對為主；若平台前置條件未齊，就誠實停在 preflight，不假裝已完成 apply。
3. project 建立、billing 開通與帳號 bootstrap 不納入今天 Terraform 自動化範圍，但必須列為 Step 1 的明確 gate。

## 驗收訊號與回退點

### 驗收訊號

1. `terraform/gcp-free-tier-vm/` 內出現一版清楚、可讀、可執行的最小 `.tf` 骨架。
2. 至少留下一次可信的 `terraform plan`，若 preflight 條件完整則再推進到一次最小 `terraform apply`。
3. 能用明確 checklist 說明 VM 是否符合 Free Tier 邊界，包括 region、machine type、boot disk、network tier 等條件。

### 回退點

1. 若 Terraform CLI、GCP auth、billing 或 API 沒準備好，今天就停在 preflight gate 與 `.tf` 骨架，不硬做失真的 apply。
2. 若某個 GCP 設定會讓範圍膨脹成完整網路或 IAM 設計，回退到 default network 與最小 firewall 表達。

## 建議學習順序

1. 先用 `06-implementation.md` 進 Step 1，確認 Terraform CLI、GCP auth、project、billing 與必要 API 的 preflight gate。
2. gate 過後，再在 `terraform/gcp-free-tier-vm/` 收斂第一版 `.tf` 骨架與變數邊界。
3. 接著以 `terraform plan` 與視情況 `terraform apply` 留下最小 IaC workflow 證據。
4. 最後用 Free Tier checklist 收斂這台 VM 是否真的對齊規格。
5. 實作主體完成後，再回 `02-qa.md` 做 post-implementation QA。
6. 最後回 `04-report.md` 做整體收斂。

## 文件分工

1. `01-outline.md`：宣告今天套用 implement-heavy mode，並寫清楚流程、邊界、驗收與回退點。
2. `02-qa.md`：記錄 post-implementation QA 的短版定位題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的內容。
4. `05-note.md`：記錄一般 lesson 延伸問答、實作補充、暫時結論與卡片整理。
5. `06-implementation.md`：記錄今天的主要實作 step，包含 preflight gate、實作證據與 Free Tier 核對。

## 這份 lesson 的完成標準

1. 能清楚指出今天的第一版 Terraform 練習到底做到哪裡，並說明若卡住是卡在 preflight 還是 HCL / resource 設計。
2. 留下一版足以支持 `plan` / `apply` 的最小 `.tf` 骨架，且能口述每個檔案各自扮演什麼角色。
3. 能用自己的話講清楚這次實作如何對齊 Free Tier 規格，以及它還沒處理哪些 production-grade 議題。
