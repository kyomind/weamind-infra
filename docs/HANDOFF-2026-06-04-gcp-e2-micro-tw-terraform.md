# HANDOFF-gcp-e2-micro-tw Terraform 低成本台灣區 VM

整理日期：2026-06-04

## MEMOS

- 本次已在 `terraform/` 下新增 `gcp-e2-micro-tw/`，定位是第二個最小 Terraform target：台灣區付費 `e2-micro` VM。
- 這不是 Free Tier 練習；核心差異是 region 固定為 `asia-east1`，因此要用付費 VM / FinOps 視角看待。
- 第一版成本契約是 `e2-micro`、`pd-balanced` 25GB、`STANDARD` network tier、ephemeral external IP、不安裝 Ops Agent、不建立自動備份或 snapshot schedule。
- `terraform plan` 已由使用者截圖確認，顯示 `Plan: 4 to add, 0 to change, 0 to destroy`，符合一台 VM 加三條 firewall rule 的預期。
- 目前尚未 `terraform apply`，因此尚未建立 GCP 資源，也尚未做 SSH runtime 驗證。
- 本地 `terraform.tfvars` 已從 `terraform/gcp-free-tier-vm/terraform.tfvars` 複製到新目錄，主要提供 project 與 SSH key path；該檔被 `.gitignore` 排除，不應提交。
- 下一個 AI 若接手，請先確認使用者是否準備 apply；若尚未 apply，不要把此事寫成 DONE。

## 背景

使用者有 Google AI Pro，每月可領取一筆 Google Cloud 折抵金。基於這個額度，使用者想在 GCP 另外建立一台台灣區 `e2-micro` VM，用來做低成本、可長期觀察的 DevOps / Terraform 實驗。

原本 repo 已有 `terraform/gcp-free-tier-vm/`，這是 Phase 2 W9 的 Free Tier 最小 Terraform 練習。使用者希望不要改掉既有 free tier target，而是在 `terraform/` 底下新增一個獨立目錄：

- `terraform/gcp-free-tier-vm/`：Free Tier VM 練習。
- `terraform/gcp-e2-micro-tw/`：台灣區付費低成本 VM 練習。

## 已建立檔案

新增目錄：

- `terraform/gcp-e2-micro-tw/`

新增或建立的可提交檔案：

- `terraform/gcp-e2-micro-tw/.gitignore`
- `terraform/gcp-e2-micro-tw/README.md`
- `terraform/gcp-e2-micro-tw/versions.tf`
- `terraform/gcp-e2-micro-tw/provider.tf`
- `terraform/gcp-e2-micro-tw/variables.tf`
- `terraform/gcp-e2-micro-tw/main.tf`
- `terraform/gcp-e2-micro-tw/outputs.tf`
- `terraform/gcp-e2-micro-tw/terraform.tfvars.example`

已更新：

- `terraform/README.md`

本地檔案，不應提交：

- `terraform/gcp-e2-micro-tw/terraform.tfvars`
- `terraform/gcp-e2-micro-tw/.terraform/`
- `terraform/gcp-e2-micro-tw/.terraform.lock.hcl`

## 主要設計決策

### 目錄拆分

使用獨立目錄 `terraform/gcp-e2-micro-tw/`，而不是改造 `gcp-free-tier-vm/` 或直接做 `for_each` 多 VM 管理。

原因：

- 現階段重點是學習與可驗證，而不是抽象化。
- Free Tier 與台灣區付費 VM 的成本邊界不同，拆開比較容易口述與回顧。
- 之後若兩者都穩定，再考慮是否抽 module 或整理共用模式。

### 成本契約

第一版成本契約：

- region：`asia-east1`
- zone：`asia-east1-b`
- machine type：`e2-micro`
- boot disk：`pd-balanced` 25GB
- external IP：ephemeral external IP
- network tier：`STANDARD`
- monitoring：不安裝 Ops Agent，也不透過 startup script 安裝 monitoring agent
- backups：不建立 Backup and DR backup plan、snapshot schedule 或其他自動備份資源

一開始曾討論 `pd-balanced` 30GB，後來使用者決定先用 25GB，原因是保留一點費用緩衝，第一個月先觀察實際帳單。如果帳單穩定，再考慮擴到 30GB。

### Disk type

使用者一度比較 `pd-standard` 和 `pd-balanced`：

- `pd-standard` 較便宜，HDD 類型，容量成本低。
- `pd-balanced` 較貴，但更接近 GCP Console 建 VM 的預設 boot disk 體感。

最後決策是 `pd-balanced` 25GB。理由不是需要更大容量，而是這台 VM 可能是互動式低成本 lab，選較穩定的 boot disk 體感較合理。

### Validation

`variables.tf` 內對主要成本欄位加了 validation：

- `region` 必須是 `asia-east1`
- `zone` 必須在 `asia-east1-*`
- `machine_type` 必須是 `e2-micro`
- `boot_disk_size_gb` 必須是 `25`
- `boot_disk_type` 必須是 `pd-balanced`

這些 validation 的用意是把 README 中的成本契約變成 Terraform 層的 guardrail。若之後要改規格，請先和使用者確認，並同步更新 README、`terraform.tfvars.example` 與 validation。

## 驗證狀態

已由 AI 執行：

```bash
terraform fmt -recursive terraform/gcp-e2-micro-tw
terraform init
terraform validate
```

結果：

- `terraform init` 成功。
- `terraform validate` 通過。
- `terraform plan` 由使用者執行並提供截圖確認，output 顯示：
  - `Plan: 4 to add, 0 to change, 0 to destroy`
  - `boot_disk_size_gb = 25`
  - `boot_disk_type = "pd-balanced"`
  - `instance_name = "e2-micro-tw"`
  - `instance_zone = "asia-east1-b"`
  - `machine_type = "e2-micro"`
  - `external_ip = (known after apply)`

尚未執行：

- `terraform apply`
- SSH runtime 驗證
- 第一個月帳單觀察

## Apply 前檢查

下一次要 apply 前，建議先做：

```bash
cd terraform/gcp-e2-micro-tw
terraform validate
terraform plan
```

人工確認 plan 中至少包含：

- 1 個 `google_compute_instance.e2_micro_tw`
- 3 個 firewall rule：HTTP、HTTPS、SSH
- boot disk `type = "pd-balanced"`
- boot disk `size = 25`
- zone 在 `asia-east1-*`
- machine type 是 `e2-micro`
- external IP access config 的 `network_tier = "STANDARD"`
- 沒有 `startup-script` 安裝 Ops Agent
- 沒有 Backup and DR、snapshot schedule、resource policy 類資源

## Apply 後建議驗證

若使用者之後決定 apply，建議驗證：

```bash
terraform apply
terraform output
gcloud compute instances describe e2-micro-tw --zone asia-east1-b
gcloud compute ssh kyo@e2-micro-tw --zone asia-east1-b --ssh-key-file=/Users/kyo/.ssh/gcp
```

若要做更乾淨的 SSH 證據，也可用 `terraform output external_ip` 取得 IP 後，再用 raw SSH：

```bash
ssh -i /Users/kyo/.ssh/gcp kyo@<external-ip>
```

驗證時要注意：`gcloud compute ssh` 可能會混入 project metadata / helper 行為。若要確認 Terraform instance metadata key path 是否足夠，raw SSH 證據通常比較乾淨。

## 待處理事項

- 尚未 `terraform apply`。
- 尚未驗證 SSH 登入。
- 尚未觀察第一個月帳單。
- 尚未決定是否從 25GB 擴到 30GB。
- 尚未建立 `DONE-...` 文件；目前這份是 handoff，等 apply、SSH 驗證與必要的帳單觀察完成後，才適合改寫或另建 DONE。

## 無待處理事項

目前沒有已知 Terraform 語法或 validate blocker。

目前沒有已知需要立刻修正的 repo 結構問題。

## 後續文件建議

在 apply 與 SSH 驗證完成後，可以建立一份 DONE，例如：

`docs/DONE-2026-06-xx-gcp-e2-micro-tw-terraform-vm.md`

內容可包含：

- 實際 apply 結果
- outputs
- SSH 驗證結果
- 是否符合 no Ops Agent / no backups / no snapshot schedule
- 第一個月帳單觀察
- 是否調整 disk size

在那之前，這份 HANDOFF 加上 `terraform/gcp-e2-micro-tw/README.md` 已足夠讓下一個 AI 接手。
