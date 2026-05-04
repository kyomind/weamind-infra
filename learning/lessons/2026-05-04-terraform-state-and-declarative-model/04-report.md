# 2026-05-04 Terraform State and Declarative Model Report

## 今日主題

Terraform 的 `state`、`plan` / `apply`、drift 與 Kubernetes 宣告式模型的 repo-backed 對照。

## 狀態

已完成 Day 1 QA 收斂，可作為明天 W9 Day 2 implement-heavy lesson 的概念起點。

## QA 收斂了什麼

- Terraform 的 `state` 不是單純 cache，而是 Terraform resource 與真實雲端資源之間的身份對應表；沒有它，`plan` / `apply` 的變更判斷就不穩定。
- Terraform 與 Kubernetes 都是宣告式，但 Terraform 依賴 `state` 與明確的 `plan` / `apply` 週期做一次次的人為 reconcile；Kubernetes 則依靠 controller 持續 reconcile。
- 這個 repo 裡的 `terraform/` 代表 Terraform 能力與可執行 IaC 資產，`manifests/` 則是目前 WeaMind cluster runtime 的 deploy source，兩者不應混成同一種部署入口。
- 明天若要證明真的走過一次最小 IaC workflow，不能只有 `.tf` 檔，還要留下 `plan`、`apply`、可讀的 Terraform 檔案骨架，以及 Free Tier 規格核對證據。

## 使用者原本卡住什麼

- 原本對 `state` 的角色還沒有完全穩定，容易把它想成一般快取，而不是資源 identity mapping。
- 原本對 Terraform 與 Kubernetes 的差異有直覺，但還沒有收斂成 reconcile / lifecycle / deploy source 這三個比較軸線。
- 原本對「符合 Free Tier 邊界的證據」這句話比較模糊，不確定它是在問 Terraform workflow，還是在問雲端資源規格驗證。
- 另外延伸卡點是：Terraform 到底能控制到哪些資源，以及它的控制範圍真正受限於什麼。

## 今日真正留下來的核心收穫

- Terraform 的核心不是「寫 IaC 設定」，而是「透過 config + state + provider 現況去做變更決策」。
- `state` 的關鍵價值在於先回答「這是誰」，而不是先回答「它長怎樣」。
- drift 麻煩的地方不是不同步本身，而是它會讓 Terraform 在下一次 `plan` / `apply` 做出錯誤或高風險決策。
- Terraform 能控制的範圍，不只受 HCL 語法限制，而是同時受目標平台 API、provider 實作品質，以及該資源是否適合宣告式管理這三層限制。

## 學完後已能講清楚什麼

- 為什麼 Terraform 需要 `state`，而且它不只是 cache。
- Terraform 與 Kubernetes manifest 雖然都屬於宣告式，但在 reconcile 與 lifecycle 上如何不同。
- 為什麼這個 repo 現在適合把 Terraform 放在獨立子目錄，而不是混進 `manifests/`。
- 明天若要完成 W9 Day 2，最低應留下哪些證據，才算真的走過一次最小 IaC workflow。

## 仍待補強什麼

- `terraform plan` 的實際輸出應如何判讀，尤其是 diff 與 resource change 類型怎麼讀。
- `state` 與 real world 的同步細節，例如 refresh、unexpected diff 與手動修改後的實務判斷。
- GCP provider 與 Free Tier VM 實作細節，包括 project、region、zone、disk、network tier 等欄位如何具體落成 `.tf` 設定。

## 下一步

- 進入 W9 Day 2 implement-heavy lesson。
- 在 `terraform/gcp-free-tier-vm/` 建立第一版 Terraform 檔案骨架。
- 以 GCP Free Tier VM 為目標，留下 `plan`、`apply`、規格核對與最小 state / drift 觀察證據。
