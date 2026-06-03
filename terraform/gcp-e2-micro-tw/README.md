# GCP E2 Micro Taiwan VM

這個目錄是 `terraform/gcp-free-tier-vm/` 之後的第二個最小 Terraform 練習。

目標不是建立 production-grade GCP 架構，而是用 Terraform 建出一台台灣區、低成本、可 SSH 驗證的 `e2-micro` VM，並用第一個月帳單觀察實際成本。

## 這個目錄要解什麼問題

- 用 Terraform 管理一台不在 Free Tier 區域內的 GCE VM
- 保留與 free tier 版本相近的最小 IaC workflow：`plan`、`apply`、必要時 `destroy`
- 明確記錄這台 VM 的成本邊界，避免監控、備份或額外資源默默擴張

## 成本契約

第一版刻意使用下面這組規格：

- region：`asia-east1`
- zone：`asia-east1-b`
- machine type：`e2-micro`
- boot disk：`pd-balanced` 25GB
- external IP：ephemeral external IP，network tier 為 `STANDARD`
- monitoring：不安裝 Ops Agent，也不透過 startup script 安裝 monitoring agent
- backups：不建立 Backup and DR backup plan、snapshot schedule 或其他自動備份資源

25GB boot disk 是第一個月的保守起點，用來替 external IPv4、少量 network egress 或其他估算外項目保留緩衝。若第一個月帳單穩定，再評估是否擴到 30GB。

## 範圍邊界

- 這裡只建立一台 VM、三條必要 firewall rule，以及最小 SSH access path。
- 這裡使用既有 `default` network，不建立自訂 VPC、subnet、Cloud NAT、load balancer 或 IAM service account。
- 這裡不管理現行 WeaMind cluster；目前 Kubernetes deploy source 仍是 `manifests/`。
- 停止 VM 不等於停止所有成本；若不再需要這台 VM，應以 `terraform destroy` 移除本目錄建立的資源。

## 檔案

- `versions.tf`：Terraform 與 provider 版本約束
- `provider.tf`：GCP provider 設定
- `variables.tf`：可調整參數，例如 project、region、zone、instance name、disk 與 SSH 輸入
- `main.tf`：VM 與 firewall resource
- `outputs.tf`：apply 後用來驗證的輸出
- `terraform.tfvars.example`：範例變數檔

## 基本操作

先複製範例值到本地 `terraform.tfvars`，再填入真實 project 與 SSH key 資訊。

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

若只是第一個月觀察成本，建議同時在 Cloud Billing 設定 budget alert。這件事不由本目錄 Terraform 管理，避免把帳務設定混進單台 VM 練習。
