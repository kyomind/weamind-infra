# 2026-05-04 Terraform State and Declarative Model Outline

## 今日主題

- 把 Terraform 的 `state`、`plan` / `apply` 與宣告式模型，正式對回 repo 內的 Terraform 目錄規劃與 Kubernetes manifests。

## 這次要解的專案問題

1. Terraform 為什麼需要 `state`，而且它不只是 cache？
2. Terraform 與 Kubernetes manifest 都是宣告式，但在 reconcile、lifecycle 與 drift 上到底差在哪裡？
3. 這個 repo 現在新增 `terraform/` 目錄，代表它在專案邊界上扮演什麼角色，和 `manifests/` 又怎麼分工？

## 這份 lesson 是否需要外部預習

- 需要，且已完成。
- 原因：今天的難點先在 Terraform 核心工作流與 `state` 概念，不先補純知識骨架，repo-backed lesson 很容易退化成邊查名詞邊對照檔案。

## 要對照的 repo 檔案

1. `learning/prework/2026-05-04-terraform-core-workflow-and-state.md`
2. `references/phase2/w9-iac-minimum-spec.md`
3. `terraform/README.md`
4. `terraform/gcp-free-tier-vm/README.md`
5. `manifests/deployment.yaml`

## 建議學習順序

1. 先用 prework 回來的骨架，確認 `state`、`plan` / `apply`、`drift` 的最小口頭模型是否穩定。
2. 對照 `terraform/README.md` 與 `terraform/gcp-free-tier-vm/README.md`，說清楚這個 repo 為什麼新增 Terraform 區塊，以及它和現行 deploy source 的邊界。
3. 對照 `manifests/deployment.yaml`，比較 Terraform 與 Kubernetes manifest 在宣告式、reconcile 與 drift 上的相似與不同。
4. 最後收斂今天真正能講清楚的短版說法，為明天的 implement-heavy lesson 做準備。

## 今日 command 練習

- 今天不做 command drill。Day 1 重點是把概念模型與 repo 邊界講清楚，實作與指令驗證留到 Day 2 的 implement-heavy lesson。

## 文件分工

1. `01-outline.md`：規劃今天學習順序。
2. `02-qa.md`：記錄今天的專案問題、回答摘要與修正。
3. `04-report.md`：收斂今天真正學到的內容。
4. `05-note.md`：記錄延伸問答、暫時結論與卡片整理。

## 這次要追問的 Why / How 題

1. 為什麼 Terraform 需要 `state` 才能穩定管理資源，而 Kubernetes 使用者通常不需要直接碰一份對應的 state file？
2. 為什麼這個 repo 現在適合把 Terraform 放進獨立子目錄，而不是混進 `manifests/`？
3. 明天真的開始寫 `.tf` 時，哪些證據才算證明「有走過 IaC workflow」，而不是只把檔案寫出來？

## 這份 lesson 的完成標準

1. 能講清楚 `state` 不只是 cache，而是 Terraform 管理資源身份與變更判斷的核心。
2. 能用這個 repo 的 `terraform/` 與 `manifests/` 說明 Terraform 與 Kubernetes manifest 的邊界與差異。
3. 能講出明天 W9 Day 2 最低要留下哪些實作證據，並知道它們各自要證明什麼。
