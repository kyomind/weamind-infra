# 2026-05-05 Terraform GCP Free Tier VM Minimum Apply Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天的第一個失敗面不一定是 Terraform 寫錯，也可能只是 GCP billing、project、API 或 auth 還沒過 gate。
- 若 apply 沒做成，重點是誠實分辨卡點層級，而不是硬把 lesson 假裝收斂成完成。
- 第一版目標是留下最小 IaC workflow 證據，不是一次把 GCP 網路、IAM 與 state 協作策略全部做完。

## Notes

### ADC 是什麼，為什麼今天 Terraform 會需要它

- `ADC` 是 `Application Default Credentials`，可以先把它理解成「Google 提供給程式、SDK 與 provider 使用的預設憑證」。
- 它和 `gcloud auth login` 不完全一樣：`gcloud auth login` 主要是讓「你這個使用者」能操作 `gcloud`；但 Terraform 的 Google provider 通常會去找 ADC，而不是直接沿用那份 CLI 登入狀態。
- 這就是為什麼今天會出現一個看起來已經登入 gcloud，但 `terraform plan` 還是報 `No credentials loaded` 的情況。
- 對今天這個 lesson 來說，ADC 很重要，因為 `terraform init` 或 `terraform validate` 可能只檢查 provider 安裝與 HCL 結構；但一旦到 `plan` 或 `apply`，provider 真的要去查或改 GCP 資源時，就需要可用的 ADC。
- 今天可以把它先記成一句話：**ADC 是給程式與 provider 用的 GCP 預設憑證；Terraform 能不能真的操作 GCP，關鍵不在 `gcloud auth login`，而在 ADC 有沒有設好。**

### `gcloud auth login`、ADC、service account 的差別

- `gcloud auth login` 的重點是讓「人」可以用 `gcloud` CLI 操作 GCP；它偏向互動式、使用者層的登入。
- `ADC` 的重點是讓「程式、SDK、Terraform provider」有一份可自動讀取的預設憑證；它偏向應用程式層的認證入口。
- `service account` 則是給機器或自動化流程用的身分，不代表某個真人，而是代表一個工作負載或系統角色。
- 所以今天這個情境裡，`gcloud auth login` 解的是「你能不能在終端機用 gcloud」；`ADC` 解的是「Terraform provider 能不能自己拿到憑證去呼叫 GCP API」；`service account` 則通常是之後把這套流程搬到 CI/CD 或正式自動化時，更常見的做法。
- 可以先把三者壓成一句話：**`gcloud auth login` 是給人用的 CLI 登入，ADC 是給本機程式用的預設憑證，service account 是給機器或自動化流程用的身分。**

## Flashcards

<!-- lesson 過程中再回填 -->
