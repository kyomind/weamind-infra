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

### Terraform resource block 怎麼看

- `resource "google_compute_firewall" "allow_https" { ... }` 可以先拆成兩段看：`google_compute_firewall` 是資源種類，`allow_https` 是這份 Terraform 設定裡給它取的本地名字。
- 前者表示「這是 GCP firewall 規則」，後者表示「在這份程式裡我要怎麼引用它」。
- 所以之後如果別處要引用它，常見形式就會像 `google_compute_firewall.allow_https.name`，也就是「資源種類 + 本地名字 + 欄位」。

### Terraform output 與 project ID 暴露邊界

- `output "project_id"` 不會讓 project ID 自動變成公開 artifact，但它會變成 Terraform output 的一部分，也通常會進 local state。
- 也就是說，`terraform apply` 後你在終端機、state 檔、或之後若保留 plan / output 紀錄，都可能看到真實 project ID。
- 目前這個 repo 已忽略 `terraform.tfstate`，所以主要風險不在 Git 自動提交，而是在你是否把真實 output 貼進 lesson、截圖或公開紀錄。

### 哪些名稱是 schema 固定，哪些才是你能自訂的

- 在 Terraform 裡，最容易混淆的是「看起來都像名字」，但其實有些是 provider schema 固定的，有些才是你自己命名的。
- 以 `resource "google_compute_firewall" "allow_https" { ... }` 為例：
- `resource` 是 Terraform 關鍵字，固定。
- `google_compute_firewall` 是 provider 定義的資源種類，固定，不能亂改成別的字。
- `allow_https` 是你在這份 Terraform 裡替這個資源取的本地名字，可以自訂。
- block 裡像 `name`、`network`、`allow`、`source_ranges`、`target_tags` 這些欄位名稱，也是 provider schema 定義的，固定；但它們右邊塞的值，很多才是你可調整的。
- 例如在目前這份設定裡：
- `instance_name`、`free-tier-vm`、`allow-http`、`allow-https`、`free_tier_vm`、`allow_http`、`allow_https` 都屬於你可以命名或調整的部分。
- `google_compute_instance`、`google_compute_firewall`、`machine_type`、`network_interface`、`access_config`、`network_tier` 這些則屬於 provider 資源種類或欄位名，不能自己發明。
- 可以先記一個判斷口訣：**Terraform / provider 規定的是「語法骨架與欄位名」；你通常能改的是「本地資源名與欄位值」。**

### `target_tags`、VM tags 與 firewall rule 的關係

- `target_tags` 和 `locals.instance_tags` 的關係，可以理解成：firewall rule 不是直接綁某一台 VM，而是綁「有某個 tag 的 VM」。
- 因此同一個 network 裡可以有多台 VM 共用同一組 firewall rule，只要它們帶了對應 tag。
- 更精準地說，目前這份 Terraform 沒有建立 network，本例只是使用既有的 `default` network，並在這個 network 上建立 firewall rule，同時建立一台帶 tag 的 VM。
- 若之後再多建幾台 VM，且它們也掛相同 tag，就可以一起吃到同一條 rule。

## Flashcards

<!-- lesson 過程中再回填 -->
