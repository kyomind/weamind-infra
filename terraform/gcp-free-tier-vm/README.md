# GCP Free Tier VM

這個目錄是 Phase 2 W9 的最小 Terraform 練習。

目標不是做 production-grade GCP 基礎設施設計，而是留下第一版可執行、可驗收、可面試重講的 Terraform 實作。

## 這個目錄要解什麼問題

- 用 Terraform 走完一次最小 IaC workflow：`plan`、`apply`、必要時 `destroy`
- 用 GCP Free Tier VM 當作第一個可驗收的 Terraform 練習目標
- 留下一份真正可執行的 `.tf` 設定，而不是只停留在概念或 reference

## 範圍邊界

- 第一版目標是建出一台符合 Free Tier 條件的 GCE VM。
- 重點放在 `provider`、`resource`、`state`、`plan / apply` 與 drift 概念，不展開 module、workspace 或 production-grade remote state。
- 這裡的內容獨立於 WeaMind 目前的 K3s cluster deploy source；它是 Terraform 練習與能力展示，不是現行 cluster 部署入口。

## 第一版預計檔案

- `versions.tf`：Terraform 與 provider 版本約束
- `provider.tf`：GCP provider 設定
- `variables.tf`：可調整參數，例如 project、region、zone、instance name
- `main.tf`：主要資源定義
- `outputs.tf`：必要輸出
- `terraform.tfvars.example`：範例變數檔

## 驗收方向

完成後，這個目錄至少應能支持下面這些證據：

- 一次完整的 `terraform plan`
- 一次完整的 `terraform apply`
- 一台符合 Free Tier 條件的 VM
- 一份可用來說明 state / drift 的最小操作基礎

更完整的規格與邊界，見 `references/phase2/w9-iac-minimum-spec.md`。
