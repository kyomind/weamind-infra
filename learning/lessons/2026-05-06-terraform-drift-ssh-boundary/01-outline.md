# 2026-05-06 Terraform Drift SSH Boundary Outline

## 今日主題

- 用 `terraform/gcp-free-tier-vm/` 的真實實作，把 VM access path 補成最小可驗證閉環，並收斂 drift 與 bootstrap 邊界。

## 今日套用的 lesson mode

- implement-heavy mode

## 為什麼今天要套用 implement-heavy mode

1. Phase 2 計畫已明示今天的第一優先不是抽象 QA，而是先把 VM access path 做出最小可驗證閉環。
2. 今天的驗收依賴實作結果與回退點，而不是單純概念對照，因此 lesson 主體應放在 `06-implementation.md`。

## 這次要解的專案問題

1. 目前 `terraform/gcp-free-tier-vm/` 為什麼還不算完成 VM access 最小閉環，差在哪些明確條件。
2. 今天要用哪一種最小 access 方案，把 22 port、SSH 身分與登入驗證收進可重講的 IaC 路徑。
3. access path 做完後，Terraform、後續 bootstrap 與最小 drift 對照各自應該停在哪裡。

## 這份 lesson 是否需要外部預習

- 不需要
- 原因：W9 Day 1 已完成 `state` / `drift` 骨架，W9 Day 2 已完成最小 `.tf` 實作；今天要做的是把 drift、SSH 與 bootstrap 邊界對回 repo 內已出現的真實問題分析。

## 要對照的 repo 檔案

1. `.privatedocs/Phase2三週計畫.md`
2. `terraform/gcp-free-tier-vm/main.tf`
3. `terraform/gcp-free-tier-vm/variables.tf`
4. `terraform/gcp-free-tier-vm/terraform.tfvars.example`
5. `terraform/gcp-free-tier-vm/README.md`
6. `terraform/gcp-free-tier-vm/ISSUE-ssh-access-for-personal-service-vm.md`
7. `learning/lessons/2026-05-05-terraform-gcp-free-tier-vm-minimum-apply/02-qa.md`

## 今日實作邊界

1. 第一優先只做 VM access 最小閉環：補 SSH 入口、選定 access 方案，並留下一次可驗證登入路徑。
2. 第二優先才是 access / bootstrap 邊界：今天不展開 Linux 使用者整理、套件安裝、dotfiles、startup script 大擴張或完整 Ansible 方案。
3. 只有前兩項完成，才進最小 drift 對照；若時間不足，drift 可以停留在設計與觀察層，不硬做多餘變更。

## 驗收訊號與回退點

### 驗收訊號

1. Terraform 規格中能明確看出一條最小 SSH access path，而不是只靠 GCP 專案既有預設。
2. 至少留下一次登入驗證或等價證據，能說清楚它依賴哪些條件。
3. 能把 Terraform 負責的 access path 與登入後 bootstrap 邊界講清楚。
4. 若時間足夠，能做一次低風險 drift 對照並說清楚 Terraform 如何反映狀態脫鉤。

### 回退點

1. 若 SSH 身分方案或登入驗證受平台條件阻塞，先誠實停在 Terraform access path 已明確但 runtime 驗證未完成，不假裝閉環已成立。
2. 若 drift 需要碰高風險或容易混淆的雲端設定，今天就停在 access 與責任邊界，不為了補 drift 而破壞 lesson 範圍。

## 建議學習順序

1. 先用 `06-implementation.md` 做主要實作與每個 step 的閉環記錄。
2. 對照 `main.tf` 與 issue 文件，先補出最小 SSH access path，再決定登入驗證如何進行。
3. 若 `06` 過程中出現 access / bootstrap 的設計取捨或暫時結論，同步整理到 `05-note.md`。
4. access path 完成後，視時間決定是否做一次低風險 drift 對照。
5. 只有在實作主體完成後，再回 `02-qa.md` 做 post-implementation QA。
6. 最後回 `04-report.md` 收斂今天真正留下來的 lesson 結論。

## 文件分工

1. `01-outline.md`：宣告今天套用 implement-heavy mode，寫清楚流程、邊界、驗收與回退點。
2. `02-qa.md`：記錄 post-implementation QA 的短版定位題、使用者回答摘要與 AI 修正。
3. `04-report.md`：等 lesson 結束後，收斂今天真正學到的 access / drift / bootstrap 邊界。
4. `05-note.md`：記錄實作補充、暫時結論與後續可能擴張但今天不做的邊界提醒。
5. `06-implementation.md`：記錄今天的主要實作 step、驗證證據與停點。

## 這份 lesson 的完成標準

1. 能完成一條可驗證的最小 VM access path，並說清楚它依賴哪些條件。
2. 能切清楚 Terraform 負責的 access path 與後續 bootstrap 的責任邊界。
3. 能用短版說明 drift 為什麼麻煩，以及至少兩個 Terraform 實務風險點。
