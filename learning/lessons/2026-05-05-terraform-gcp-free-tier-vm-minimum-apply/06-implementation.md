# 2026-05-05 Terraform GCP Free Tier VM Minimum Apply Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 在 `terraform/gcp-free-tier-vm/` 建立第一版可執行的 Terraform 骨架，先確認 preflight gate，再往最小 `plan` / `apply` 與 Free Tier 核對推進。

## 今日實作順序

1. 先確認 Terraform CLI、GCP auth、project、billing 與必要 API 的 preflight gate。
2. 在 `terraform/gcp-free-tier-vm/` 收斂第一版 `.tf` 骨架與參數邊界。
3. 先回頭逐檔閱讀 Step 2 產出的 Terraform 檔案，確認每個檔案各自在做什麼，以及值怎麼流進 provider / resource。
4. 等檔案角色與主要欄位都讀懂後，再決定是否新增下一個實作 step 去做 `terraform plan`。

## 使用提醒

1. step 數量不設上限；若後續發現某一步過大，應直接往下拆成新的 `Step N`，不要勉強維持少量大步驟。
2. 新增一個 step 時，預設先只建立骨架：至少寫到 `#### 預計採取的動作`；`實際執行內容`、`結果`、`AI 判讀與收斂` 先維持待填，等這一步真的走完再回填。
3. 每個 step 的 `實際執行內容` 第一個 bullet，應先標記這次主要由誰實作，例如：`本次由 AI 實作`、`本次由使用者實作`；若屬於明確分段協作，也可以寫成 `本次由 AI 與使用者協作`。
4. `06-implementation.md` 的帶法、回填時機與例外情況，統一回 `references/lesson-plugins/implementation/implementation-guide.md`，本模板只保留骨架直接需要的提醒。

## Session 開場提醒

- `06-implementation.md` 的實際帶法不要寫死在模板裡；開場規則、step 推進、提問邊界與回填原則改讀 `references/lesson-plugins/implementation/implementation-guide.md`。

## 驗收訊號與回退點

### 驗收訊號

- `terraform/gcp-free-tier-vm/` 內出現一版清楚、可讀、可執行的最小 `.tf` 骨架。
- 至少留下一次可信的 `terraform plan`；若平台前置條件完整，再進一步留下一次最小 `terraform apply`。
- 能用 Free Tier checklist 說明 VM 是否符合 `e2-micro`、允許 region、標準 HDD 與 `STANDARD` network tier 等邊界。

### 回退點

- 若 Terraform CLI、GCP auth、billing 或 API 沒準備好，今天就停在 preflight gate 與 `.tf` 骨架，不硬做失真的 apply。
- 若某個資源設計把範圍拉向完整 VPC / IAM 規劃，回退到 default network 與最小 firewall 規則。

### Step 1

#### 這一步要驗證什麼

- 今天要卡在 Terraform HCL 還是卡在 GCP 平台前置條件，能否先在一開始就分清楚。

#### 預計採取的動作

- 檢查 Terraform CLI 是否可用。
- 檢查目前是否已完成 GCP auth。
- 檢查 project、billing 與 Compute Engine API 是否已就緒。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 使用者先回報本機原本 `terraform` 與 `gcloud` 都不存在。
- AI 先確認 Homebrew 可用，接著以 `brew tap hashicorp/tap && brew install hashicorp/tap/terraform google-cloud-sdk` 補齊 Terraform 與 Google Cloud CLI。
- 安裝後重新驗證版本，確認 `terraform v1.15.1` 與 `Google Cloud SDK 566.0.0` 都已可從 PATH 執行。
- AI 先做最小 gcloud preflight，發現目前沒有預設 project，而且 `gcloud auth list` 顯示本機尚未登入任何 GCP 帳號。
- 接著由 AI 啟動 `gcloud auth login`，使用者完成瀏覽器登入，成功把既有帳號接到本機 CLI。
- 登入後再以 `gcloud projects list` 列出目前可用 projects，準備選定今天 Terraform 練習要使用的目標 project。
- 使用者補充：其中一個原本直覺會選的 project 正處於服務條款申訴情境，因此不適合作為今天的 Terraform 練習環境。
- AI 先把另一個曾拿來手動開 Free Tier VM 的 project 設成 current project，並嘗試補開 `compute.googleapis.com`；GCP 回傳 `FAILED_PRECONDITION`，明確指出這個 project 目前沒有可用 billing account，因此暫時無法用來啟用 Compute Engine API。
- 接著 AI 比較其他可用 project 的 Compute Engine API 狀態，確認最後選定的練習 project 已經啟用 `compute.googleapis.com`。
- AI 再把 current project 切到這個可用 project，並以 `gcloud compute zones list --limit=3` 驗證 Compute Engine 入口可正常讀取。

#### 結果

- 本機原先卡住的點已確認不是 billing 或 GCP 帳號本身，而是單純缺少 Terraform / gcloud 安裝，以及 gcloud 尚未在這台機器完成登入。
- Terraform 與 gcloud 現在都已安裝完成，CLI 層前置條件已補齊。
- gcloud 已成功登入一個可用的使用者帳號。
- 其中一個原本直覺會選的 project 有服務條款申訴風險，不適合作為今天的練習 project。
- 另一個你之前手動開過免費 VM 的 project，則因 billing account 不存在，無法啟用 Compute Engine API。
- 最後選定的練習 project 已啟用 `compute.googleapis.com`，而且 `gcloud compute zones list` 可正常讀取，代表今天要做 Terraform GCE VM 練習時，它是目前最穩定可用的 project。
- 因此 Step 1 最後採用的是一個已驗證可用、但在公開 lesson 中不直接揭露 ID 的 working project。

#### AI 判讀與收斂

- Step 1 的完整收斂是：今天最先卡住的不是 Terraform HCL，而是本機 CLI 缺件與 gcloud 尚未登入；補齊後，真正的 project 選擇又受到專案風險與 billing 狀態影響。
- 若只在原本最直覺的兩個候選 project 二選一，較合理的方向會是那個沒有條款申訴風險的 project；但就今天實作可行性來看，它仍被 billing gate 擋住。
- 因此為了讓 W9 Day 2 能繼續推進，今天的實作 project 先收斂到目前已驗證可用、但在公開文件中不直接揭露 ID 的 working project。
- 這代表 Step 1 已完成，下一步可以直接進 `terraform/gcp-free-tier-vm/` 的 `.tf` 骨架。

#### 目前狀態

- 已完成

### Step 2

#### 這一步要驗證什麼

- 第一版 `.tf` 骨架最少要長成什麼樣，才足以表達 GCP Free Tier VM 的主要規格與可讀性。

#### 預計採取的動作

- 在 `terraform/gcp-free-tier-vm/` 建立 `versions.tf`、`provider.tf`、`variables.tf`、`main.tf`、`outputs.tf` 與 `terraform.tfvars.example`。
- 先用 provider、variables、compute instance、必要 firewall 與 outputs 收斂第一版結構。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 在確認 working project 可用後，AI 直接於 `terraform/gcp-free-tier-vm/` 建立第一版 Terraform 骨架。
- 新增 `versions.tf`，把 Terraform 與 `hashicorp/google` provider 的版本邊界先固定下來。
- 新增 `provider.tf`，先用最小 `project` 與 `region` provider 設定收斂 Google provider 入口。
- 新增 `variables.tf`，把 `project_id`、`region`、`zone`、`instance_name`、`machine_type`、boot disk、image 與 network 等容易調整的值抽成變數。
- 新增 `main.tf`，先只放一個 `google_compute_instance` 與兩條 firewall rule，對應 HTTP / HTTPS 入口，不展開 VPC、subnetwork、IAM 或 module。
- 新增 `outputs.tf`，保留 `project_id`、instance name、zone、machine type 與 external IP，讓後續 `plan` / `apply` 與 Free Tier 核對有明確輸出。
- 新增 `terraform.tfvars.example`，把今天實際採用的起始值示範成 placeholder project ID，加上 `us-east1`、`us-east1-b`、`e2-micro`、`pd-standard` 與 25GB。
- 額外新增資料夾內 `.gitignore`，先忽略 `.terraform/`、`terraform.tfstate`、`terraform.tfvars` 等執行產物，避免把本地 state 與敏感設定直接帶進 repo。

#### 結果

- `terraform/gcp-free-tier-vm/` 不再只有 README，而是已具備第一版最小可執行 Terraform 結構。
- 這版骨架已經能清楚看出 W9 最小實作的五個核心層次：provider、variables、compute instance、必要 firewall、outputs。
- VM 規格目前先收斂在 Free Tier 可接受邊界：`us-east1` / `us-east1-b`、`e2-micro`、`pd-standard`、25GB、default network、external IP 採 `STANDARD` network tier。
- 今天刻意沒有把範圍擴到自建 VPC、subnetwork、service account、startup script automation 或 module 化，避免第一版骨架失焦。

#### AI 判讀與收斂

- Step 2 的短結論是：第一版 `.tf` 骨架不需要很多資源，但必須讓人一眼看出這台 VM 的 Free Tier 意圖與主要規格。
- 目前的收斂方式是正確的，因為它先把「最小可讀、最小可驗證」放在第一位，而不是過早追求 production-grade Terraform 結構。
- 這一步完成後，後續 Step 3 就不再是在猜 Terraform 檔該怎麼長，而是直接驗證這份骨架能否穩定跑出 `plan`，以及 provider / auth 會卡在哪一層。

#### 目前狀態

- 已完成

### Step 3

#### 這一步要驗證什麼

- 在真的跑 `plan` 之前，是否已經先看懂 Step 2 產出的 Terraform 骨架，知道每個檔案在解什麼問題。

#### 預計採取的動作

- 先閱讀 `versions.tf`、`provider.tf` 與 `variables.tf`。
- 先講清楚每個檔案的角色，確認 Terraform 工具版本、provider 入口與輸入參數表的分工。
- 再做 `main.tf` 的第一輪閱讀，只先看整體結構與主要 resource，不急著把所有值流一次講完。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先帶讀 `versions.tf`，把它收斂成工具版本契約：Terraform 最低版本與 `hashicorp/google` provider 版本範圍都先固定在這裡。
- 接著帶讀 `provider.tf`，確認它的角色是宣告 Google provider，並從 `var.project_id`、`var.region` 取得操作 GCP 時的 project 與 region。
- 再帶讀 `variables.tf`，把它收斂成這份 Terraform 的輸入參數表，包含 project、region、zone、instance name、machine type、disk、image 與 network 等值。
- 最後做 `main.tf` 的第一輪閱讀，只先抓大圖：這個檔案目前有三塊主要內容，分別是 `locals`、一個 `google_compute_instance`，以及兩條 `google_compute_firewall`。
- 在 VM resource 這一輪先只收斂出幾個主要欄位：`name`、`machine_type`、`zone`、`tags`、`boot_disk`、`network_interface`，並確認最容易影響 spec 的部分是 machine type、disk type/size 與 network tier。

#### 結果

- 目前已能把 Step 2 產出的 Terraform 骨架分成三層理解：
- `versions.tf` 是工具版本契約。
- `provider.tf` 是 Terraform 連到 GCP 的入口。
- `variables.tf` 是這份設定的輸入參數表。
- `main.tf` 的第一輪閱讀也已完成，至少已能看懂它的高層結構是「一台 VM + 兩條 firewall」，而不是一大坨看不出邊界的 HCL。

#### AI 判讀與收斂

- Step 3 的短結論是：在真的跑 `plan` 前，先把檔案分工看懂是對的，因為目前阻力不是 Terraform 語法，而是還沒建立穩定的檔案角色感。
- 目前最有價值的收斂不是背欄位，而是先知道 `versions/provider/variables/main` 各自負責哪一層；這樣後面再讀值流或跑 `plan` 才不會變成盲看輸出。
- 下一步不應直接跳回執行，而是把剩下還沒細讀的部分拆成新 step，繼續讀 `main.tf` 與 `outputs.tf`。

#### 目前狀態

- 已完成

### Step 4

#### 這一步要驗證什麼

- 在已經看懂檔案分工後，是否能繼續讀懂 `main.tf` 的細部值流與 `outputs.tf` 的角色，而不是急著跑 `plan`。

#### 預計採取的動作

- 回到 `main.tf`，把 `boot_disk`、`network_interface`、firewall rule 與 tags 的關係再讀細一層。
- 再讀 `outputs.tf`，確認哪些值是 apply 後拿來觀察結果的出口。
- 若這一輪閱讀完成後，再決定是否新增下一個 `plan` 驗證 step。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先回到 `main.tf`，把 `boot_disk` 與 `network_interface` 這兩段再讀細一層。
- 在 `boot_disk` 這段，收斂出 `image`、`size`、`type` 三個主要欄位，並確認 `size` 與 `type` 會分別吃 `var.boot_disk_size_gb`、`var.boot_disk_type`。
- 在 `network_interface` 這段，收斂出 `network`、`access_config` 與 `network_tier` 的角色，並確認 `access_config` 的存在本身就代表這台 VM 會有 external IP。
- 接著回到兩條 firewall rule，補清 `target_tags` 與 VM tags 的對應關係：rule 不是直接綁某台 VM，而是綁有特定 tag 的 VM。
- 之後再讀 `outputs.tf`，把它收斂成 apply 後用來觀察結果的出口，並區分兩類來源：一類是直接吐 variable，例如 `project_id`；另一類是從真正建立出的資源欄位取值，例如 `instance_name`、`instance_zone`、`machine_type`、`external_ip`。
- 最後補清 `terraform.tfvars.example` 的角色：它是給人看的輸入樣板，不會自動被 Terraform 套用；真正的 `project_id` 真值通常是在 `plan` / `apply` 前，由實際輸入來源決定。

#### 結果

- 目前已能把 `main.tf` 的細部值流分成三塊理解：
- `boot_disk` 主要承接 OS image、disk size 與 disk type。
- `network_interface` 主要承接 network、external IP 與 network tier。
- firewall rule 主要承接對外流量允許範圍，以及它是如何透過 tag 套到 VM 身上的。
- `outputs.tf` 的角色也已經清楚：它不是建立資源，而是把 apply 後最值得觀察的結果吐出來。
- 另外也已釐清：`.tfvars.example` 是樣板，不是自動生效的設定；`project_id` 的真值通常是在執行前才由實際輸入來源決定。

#### AI 判讀與收斂

- Step 4 的短結論是：目前真正重要的不是先跑 `plan`，而是先把值流與觀察出口看懂。
- 到這一步為止，已經能把整份設定講成一條路徑：輸入值先經過 variables，provider 決定操作範圍，main 定義資源，outputs 則在最後把重要結果吐出來。
- 這代表後續若要進下一個 step，才適合開始做真正的 `plan` 驗證，因為現在已經不是盲看 Terraform 輸出了。

#### 目前狀態

- 已完成
