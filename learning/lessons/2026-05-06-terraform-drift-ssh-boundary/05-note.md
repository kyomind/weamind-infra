# 2026-05-06 Terraform Drift SSH Boundary Note

## 學習注意事項

### 今天的 lesson 邊界

- 今天採 implement-heavy mode，主體放在 `06-implementation.md`，先做 access path，再做邊界收斂，最後才視時間進 drift。
- 今天不把 lesson 擴成新的完整 GCP IAM / IAP / OS Login 設計題，也不展開完整主機初始化流程。
- 若提到 SSH 可達性，必須明確區分「Terraform 保證」和「project / network 既有狀態剛好讓它可用」。
- 若提到改善方向，優先維持 W9 的 20/80 範圍：最小可操作、可講清楚、可回到 repo。

### 今天要刻意記住的口頭模型

- `Terraform` 先負責把基礎設施與 access prerequisite 寫清楚，不等於它必須包辦所有作業系統初始化與服務配置。
- `SSH access` 解的是「人能不能安全地進去機器」；bootstrap / config management 解的是「進去之後怎麼把機器變成可持續運作的服務主機」。
- `state` 與 drift 的價值，不只在於看差異，而在於分辨目前看到的行為到底是 IaC 內的預期、IaC 外的偶然，還是已經偏離預期。

### 今天的實作優先順序

- 先把最小 SSH access path 補明確，並盡量留下一次登入驗證。
- 然後把 access / bootstrap 責任分界講清楚。
- 只有前兩項完成，才做最小 drift 對照。

## Notes

### `terraform validate` 是什麼

- `terraform validate` 用來檢查目前目錄下的 Terraform 設定是否在語法、區塊結構、參數型別與 provider schema 層面成立。
- 它回答的問題是：這份 Terraform configuration 合不合法、能不能被 Terraform 正常理解；它不回答雲端資源最後能不能真的建成功。
- 以今天這一步來說，`terraform validate` 通過，代表我們新增的 `allow_ssh` firewall、`ssh_source_ranges` 變數與相關引用在配置層是有效的。

### `terraform validate` 怎麼用

- 最常見用法是在 Terraform 專案目錄直接執行 `terraform validate`。
- 常見搭配順序是：先 `terraform fmt`，再 `terraform validate`，之後才進 `terraform plan`。
- 一個實用的口頭模型是：`validate` 檢查「配置是否合法」，`plan` 檢查「這份合法配置實際會改什麼」，`apply` 才是「真的把變更打到雲端」。

### `terraform validate` 的邊界

- 它不會替你完成 runtime 驗證，所以就算 `validate` 通過，也不代表 SSH 一定能登入、GCP auth 一定正常、或 provider 呼叫雲端 API 一定成功。
- 它也不等於安全檢查；例如把 `ssh_source_ranges = ["0.0.0.0/0"]` 寫進變數檔，對 Terraform 來說仍可能是合法配置。
- 所以今天的 lesson 裡，`validate` 是 Step 1 的配置層驗證，不是整個 VM access path 的最終驗收。

### 這次的 `ssh_source_ranges` 決策

- issue 文件原本偏向固定 IP 或受控 CIDR，因為那是較穩妥的長期運行前提。
- 但以你目前這台機器的用途來看，沒有固定 IP，而且不一定長期運行，所以這次可以接受先把 `ssh_source_ranges` 寫成 `0.0.0.0/0`，優先換取可操作性。
- 這代表今天的 lesson 決策不是「最安全的預設」，而是「在短期、個人、非長期運行前提下，先讓 access path 成立」。
- 後面若這台機器轉成長期使用，再回頭把 SSH source range 收斂回固定 IP、VPN exit IP、IAP 或其他較受控方案。

## Flashcards

<!-- lesson 收尾後再統一生成 -->
