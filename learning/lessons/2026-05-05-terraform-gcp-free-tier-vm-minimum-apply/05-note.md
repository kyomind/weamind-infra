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

### `-out`、state 與 apply 的關係

- `terraform plan` 預設只是把「目前算出來的執行計畫」印到螢幕上，並不會把這份 plan 自動固定下來。
- 所以你這次看到的最後一句 note，重點不是在警告 plan 失敗，而是在提醒：如果你下一步直接跑 `terraform apply`，Terraform 會在那個當下重新計算一次最新的 plan，再依照重新計算後的結果去執行。
- 這代表畫面上這份 plan 和之後 `apply` 實際採取的動作，通常會很接近，但 Terraform 不保證兩者一定逐欄完全相同。
- 造成差異的來源可能很多，例如：你改了 `.tf` 檔、輸入值變了、雲端現況變了，或 provider 在重新查詢 API 後拿到不同資訊。
- 如果你想把「剛剛看到的這份 plan」凍結成一個明確的執行單，就要在 `plan` 時加上 `-out`，例如 `terraform plan -out=tfplan ...`。
- 之後再用 `terraform apply tfplan`，Terraform 就不是重新現場計算，而是直接套用剛剛存下來的那份 plan。
- `state` 跟 `plan` 不是同一件事：`plan` 是這次準備要做什麼，`state` 則是 Terraform 對「目前已受它管理的資源狀態」所保留的記錄。
- 更精準地說，`plan` 是一次性的比較結果；`state` 是後續每次 `plan` / `apply` 都會拿來參照的基準之一。
- 可以先把三者壓成一句話：**不用 `-out` 的 `plan` 只是螢幕上的預覽；`apply` 預設會重新計算；`state` 則是 Terraform 用來理解目前世界長什麼樣的狀態記錄。**

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

### `.tfvars.example` 的角色是什麼

- `terraform.tfvars.example` 目前只是範例檔，主要角色是給人看，說明這份 Terraform 預期有哪些輸入值，以及合理範例長什麼樣。
- 它不會自動被 Terraform 套用；真正會被 Terraform 拿來餵給 `variables.tf` 的，通常是實際的 `terraform.tfvars`、`-var`、`-var-file`、`TF_VAR_xxx`，或 variable 自己的 `default`。
- 因此更精準的說法是：`variables.tf` 先宣告有哪些輸入，`.tfvars.example` 只是示範這些輸入可以怎麼填。

### `project_id` 的真值是什麼時候決定的

- `project_id` 在目前這份設定裡沒有 `default`，所以它的真值通常是在你執行 `plan` 或 `apply` 前，透過實際輸入來源才被決定。
- 可以先把這件事壓成一句話：**`project_id` 的真值通常不是寫死在程式裡，而是在執行前，由實際輸入來源決定。**

### variable 沒先提供時，Terraform 會怎麼做

- 今天的 `terraform apply` 多驗證了一件事：如果某個必要 variable 沒有 `default`，而你也沒有用 `-var`、`-var-file`、環境變數或 `terraform.tfvars` 先提供，Terraform 會在互動模式下直接提示你輸入。
- 這也是為什麼這次會先看到 `var.project_id` 的說明文字，然後才讓使用者手動輸入值。
- 對單人手動練習來說，這個行為很方便，因為你就算忘了先帶 `-var`，Terraform 也不會立刻失敗，而是先給你補值機會。
- 但這種方便只成立在互動式終端機；如果是 CI/CD、腳本自動化或其他非互動環境，就不能期待 Terraform 停下來等人輸入。
- 可以先把它記成一句話：**必要 variable 若沒先提供，Terraform 在互動模式下會要求你當場補值；在非互動環境則通常必須事先把值供應好。**

### 第一次讀 Terraform state，先看哪些欄位

- `terraform state list` 先回答的問題不是「內容細節是什麼」，而是「目前有哪些資源正在被 Terraform 納管」。
- `terraform state show <resource>` 才是在看某一個資源目前被記錄成什麼樣子。
- 第一次讀 state，不要從上到下逐欄硬看；比較穩的方式是把欄位分成三類。
- 第一類是 HCL 原本就有宣告的值，例如 instance 的 `name`、`project`、`zone`、`machine_type`、`tags`、disk size/type、`network_tier`。
- 第二類是 apply 後由雲端回填的值，例如 `current_status`、`creation_timestamp`、`instance_id`、`cpu_platform`、`network_ip`、`nat_ip`。
- 第三類是 Terraform / provider 用來追蹤資源的識別或同步欄位，例如 `id`、`self_link`、`label_fingerprint`、`tags_fingerprint`、`metadata_fingerprint`。
- 以這次 VM 為例，最值得先讀的欄位是：`id`、`name`、`zone`、`machine_type`、`tags`、`boot_disk.initialize_params`、`network_interface.network_ip`、`network_interface.access_config.nat_ip`、`current_status`。
- 可以先把 state 的角色壓成一句話：**HCL 是你想要的樣子，plan 是 Terraform 打算怎麼做，state 則是 Terraform 目前認為世界已經長成什麼樣子。**

### HCL 目前在這個 repo 用在哪裡

- 目前這個 repo 裡，HCL 的實際使用範圍只有 Terraform，而且集中在 `terraform/gcp-free-tier-vm/` 這個練習目錄。
- 具體來說，`versions.tf`、`provider.tf`、`variables.tf`、`main.tf`、`outputs.tf` 都是 Terraform 設定本體，分別用來描述版本契約、provider、輸入變數、資源本身與輸出。
- `terraform.tfvars.example` 雖然是範例檔，不是目前自動生效的輸入檔，但它也屬於 Terraform 會認得的 HCL 風格變數格式。
- 目前 repo 裡沒有其他獨立的 `.hcl` 檔，所以 HCL 還沒有被拿去做 Terragrunt、Packer、Nomad 或其他 HashiCorp 工具設定。
- 也就是說，這個 repo 現在的 HCL 可以先收斂成一句話：**HCL 在這裡主要就是 Terraform 的語言；其餘基礎設施檔案，例如 Kubernetes manifests，仍然是 YAML。**

## Flashcards

- preflight gate 卡住時，問題最可能先落在哪一層？ #DevOps #card
	- 先落在工具、認證或平台前置條件層
	- 例如 Terraform CLI、gcloud auth、current project、billing、Compute Engine API
	- 不是先怪 HCL 或 resource schema

- 為什麼第一版 Terraform 骨架只先收斂成 provider、variables、VM、必要 firewall、outputs？ #DevOps #card
	- 這五層剛好構成最小可驗證 workflow
	- 已足夠完成宣告、輸入、建資源、開必要流量、觀察結果
	- 避免過早膨脹成完整 VPC、IAM、module 設計

- 怎麼用最小證據證明 VM 沒偏離 Free Tier 邊界？ #DevOps #card
	- `machine_type = e2-micro`
	- `zone = us-east1-b`
	- disk 是 `pd-standard` 且 size 25GB
	- external network tier 是 `STANDARD`
	- apply 後真的拿到 external IP

- HCL、plan、apply、state 四者各自扮演什麼角色？ #DevOps #card
	- HCL 是目標狀態宣告
	- plan 是差異預覽
	- apply 是執行變更
	- state 是真實資源狀態與資源對應關係的依據

- 為什麼不用 `-out` 時，`terraform apply` 會重新計算？ #DevOps #card
	- 因為沒有鎖定先前那份 plan
	- apply 會依當下 HCL、輸入值、state、雲端現況重算一次
	- 若要固定執行單，要先 `plan -out=...` 再 `apply` 該 plan 檔

- 第一次讀 `terraform state`，先怎麼分欄位？ #DevOps #card
	- 先分 HCL 宣告值、雲端回填值、Terraform 識別欄位三類
	- 先看 `state list` 確認有哪些資源被納管
	- 再看 `state show` 讀單一資源的真實狀態

- `gcloud auth login`、ADC、service account 的差別是什麼？ #DevOps #card
	- `gcloud auth login` 給人用 CLI 登入
	- ADC 給本機程式與 provider 讀取預設憑證
	- service account 給機器或自動化流程使用

- 必要 variable 沒先提供時，Terraform 在手動模式下會怎麼做？ #DevOps #card
	- 互動模式下會直接提示輸入
	- 適合單人手動練習
	- 不適合作為 CI/CD 或非互動環境的依賴方式

- `output "project_id"` 的風險邊界是什麼？ #DevOps #card
	- 不會自動變成公開 artifact
	- 但會出現在 plan、apply、state、output 紀錄裡
	- 風險重點常在終端輸出、截圖與公開筆記，不只是 Git commit
