# 2026-05-05 Terraform GCP Free Tier VM Minimum Apply Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 在 `terraform/gcp-free-tier-vm/` 建立第一版可執行的 Terraform 骨架，先確認 preflight gate，再往最小 `plan` / `apply` 與 Free Tier 核對推進。

## 今日實作順序

1. 先確認 Terraform CLI、GCP auth、project、billing 與必要 API 的 preflight gate。
2. 在 `terraform/gcp-free-tier-vm/` 收斂第一版 `.tf` 骨架與參數邊界。
3. 先回頭逐檔閱讀 Step 2 產出的 Terraform 檔案，確認每個檔案各自在做什麼。
4. 再把 `main.tf`、`outputs.tf` 與 value flow 讀懂。
5. 最後才由使用者親手執行第一次 `terraform plan`。

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
- 至少留下由使用者親手跑出的第一次可信 `terraform plan`。
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
- 這一步完成後，後續 Step 3 就不再是在猜 Terraform 檔該怎麼長，而是直接進入檔案閱讀與值流理解。

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

### Step 5

#### 這一步要驗證什麼

- 在已經看懂檔案分工、值流與 outputs 角色後，使用者是否能親手跑出第一份可讀的 `terraform plan`。

#### 預計採取的動作

- 由使用者在 `terraform/gcp-free-tier-vm/` 親手執行第一次 `terraform plan`。
- 執行前先確認 `project_id` 的輸入來源，避免把 `.tfvars.example` 誤當成自動生效設定。
- 執行後只先觀察三件事：Terraform 打算建立哪些資源、主要 spec 值是否落對、哪些 outputs 會在 plan 階段直接顯示。
- 若 `plan` 失敗，再分辨是 provider / auth、輸入值，還是 resource schema / API 限制問題。

#### 實際執行內容

- 本次由使用者實作
- 使用者第一次執行 `terraform plan -var="project_id=$(gcloud config get-value project 2>/dev/null)"` 時，人位於 `terraform/`，不是 `terraform/gcp-free-tier-vm/`。
- Terraform 當場回覆 `Error: No configuration files`，因為目前工作目錄下沒有任何 `.tf` 設定檔。
- 進一步確認後，`main.tf`、`variables.tf`、`provider.tf`、`outputs.tf` 等檔案都在 `terraform/gcp-free-tier-vm/`，不是在 `terraform/` 根目錄。
- 使用者之後切到 `terraform/gcp-free-tier-vm/`，再次執行同一條 `terraform plan`，這次成功展開 execution plan。
- 成功的 plan 清楚顯示 Terraform 打算建立 3 個資源：`google_compute_firewall.allow_http`、`google_compute_firewall.allow_https`、`google_compute_instance.free_tier_vm`。
- 在 VM 規格上，也已經直接看到這次最重要的 Free Tier 邊界都有正確落下：`machine_type = e2-micro`、`name = free-tier-vm`、`zone = us-east1-b`、boot disk `size = 25`、`type = pd-standard`，以及 `access_config.network_tier = STANDARD`。
- 在 outputs 區塊中，`instance_name`、`instance_zone`、`machine_type`、`project_id` 已能在 plan 階段直接看到，而 `external_ip` 仍維持 `known after apply`。

#### 結果

- 這次失敗不是 provider、ADC、輸入值或 GCP API 問題。
- 真正原因是執行目錄錯誤：Terraform 只會讀目前所在目錄的設定檔，而 `terraform/` 根目錄沒有 `.tf` 檔，所以無法產生 plan。
- 修正工作目錄後，第一次有效的 `terraform plan` 已成功完成。
- 這份 plan 目前的收斂非常清楚：`3 to add, 0 to change, 0 to destroy`，也就是 1 台 VM 加上 2 條 firewall，沒有額外雜訊資源。
- 這也證明目前的 Terraform 骨架、輸入值、provider 與認證前提都已經接起來了。

#### AI 判讀與收斂

- 這是一個典型但很有價值的第一層 debug：先分辨是「設定壞了」還是「工具根本沒讀到設定」。
- 這次訊號很乾淨，因為 `No configuration files` 直接指向工作目錄，而不是 Terraform schema 或雲端權限。
- 在切到正確目錄後，成功的 plan 又補上第二層確認：不只工具能讀到設定，連資源類型、主要 spec 值與 outputs 邊界也都符合預期。
- plan 最後那句關於 `-out` 的 note，不是在說這次 plan 有問題，而是在提醒：如果現在直接跑 `terraform apply`，Terraform 會重新計算一次當下狀態；它不保證一定和這次螢幕上看到的 plan 逐欄完全一致。
- 因此 Step 5 可以正式收斂為已完成；下一步若要繼續，才適合新開 step 處理 apply 前最後確認。

#### 目前狀態

- 已完成

### Step 6

#### 這一步要驗證什麼

- 在真正執行 `terraform apply` 前，是否已經把最後一批會影響結果判讀的確認點收乾淨。

#### 預計採取的動作

- 先用剛完成的 `plan`，回頭確認這次要建立的資源集合與原本 lesson 範圍一致。
- 再確認目前是否接受兩條 firewall 規則、`project_id` output 暫時保留，以及 external IP 會在 apply 後才知道。
- 最後再確認這次 apply 若真的往下做，預期要觀察的重點是什麼，不把 apply 做成純按鍵動作。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 先回頭用剛完成的 `terraform plan` 檢查這次要建立的資源集合，確認目前仍維持 lesson 原本預期的最小範圍：1 台 VM 加 2 條 firewall，沒有額外長出 VPC、subnetwork、IAM 或其他不在今天目標內的資源。
- 接著逐一確認 apply 前的三個關鍵判讀點：目前接受保留兩條 firewall 規則、接受 `project_id` output 先保留、也接受 `external_ip` 必須等 apply 後才會真正出現。
- 最後再把 apply 後真正要觀察的重點說清楚：不是只看指令有沒有成功，而是要看 VM 是否真的建立、external IP 是否出現，以及輸出結果是否仍符合這次 Free Tier 最小規格。

#### 結果

- apply 前最後確認已完成。
- 這次 plan 所代表的資源集合與 lesson 範圍一致，沒有超出今天的最小 Terraform 練習邊界。
- 目前對兩條 firewall 規則、`project_id` output 與 `external_ip` 的判讀邊界都已確認可接受。
- 因此從 lesson 結構來看，現在已具備進入 apply step 的條件。

#### AI 判讀與收斂

- Step 6 的價值，不是在技術上新增什麼設定，而是在真正 apply 前，先把「我們準備接受什麼結果」說清楚。
- 這一步完成後，後面的 apply 就不再只是機械式往下按，而是帶著明確觀察目標去驗證：資源數量是否正確、external IP 是否出現、以及最後產物是否仍在 Free Tier 練習邊界內。
- 因此 Step 6 可以收斂為已完成；下一步若要繼續，就應新開 apply step，而不是再回頭改這一版 plan。

#### 目前狀態

- 已完成

### Step 7

#### 這一步要驗證什麼

- 在前面 `plan` 與 apply 前確認都完成後，這份 Terraform 設定是否真的能在 GCP 上建立出預期的最小資源。

#### 預計採取的動作

- 由使用者在 `terraform/gcp-free-tier-vm/` 親手執行第一次 `terraform apply`。
- apply 過程中先觀察 Terraform 是否真的建立 1 台 VM 與 2 條 firewall。
- apply 完成後，先記下 outputs，特別是 `external_ip` 是否已出現。
- 若 apply 失敗，再分辨是 GCP API、配額 / Free Tier 邊界、還是資源建立階段的 schema / policy 問題。

#### 實際執行內容

- 本次由使用者實作
- 使用者在 `terraform/gcp-free-tier-vm/` 執行第一次 `terraform apply`，這次沒有用 `-var` 額外帶入 `project_id`，而是直接讓 Terraform 進入互動式提問。
- Terraform 先提示 `var.project_id` 尚未提供，並顯示說明文字 `GCP project ID for the free-tier VM exercise.`；接著由使用者手動輸入這次要使用的 project ID。
- 變數補齊後，Terraform 重新展開 apply 前的 execution plan，內容仍和前一個 step 的 plan 一致：建立 2 條 firewall 與 1 台 VM。
- 使用者在 approval prompt 輸入 `yes` 後，Terraform 依序建立 `google_compute_firewall.allow_http`、`google_compute_firewall.allow_https` 與 `google_compute_instance.free_tier_vm`。
- 最終 apply 成功完成，輸出顯示 `Resources: 3 added, 0 changed, 0 destroyed`，而且 `external_ip` 已在 outputs 中實際出現。

#### 結果

- 這份 Terraform 設定已成功在 GCP 上建立出預期的最小資源集合：1 台 VM 加 2 條 firewall。
- 這次 apply 的實際結果與先前的 plan 一致，沒有額外長出 lesson 範圍外的資源。
- apply 完成後，outputs 已成功回傳 `external_ip`、`instance_name`、`instance_zone`、`machine_type` 與 `project_id`；其中 `external_ip` 已從 `known after apply` 變成實際可觀察值。
- 因此 Step 7 的核心驗證已完成：這份最小 Terraform 骨架不只可讀、可 plan，也真的可 apply。

#### AI 判讀與收斂

- 這一步補上的是 IaC workflow 最關鍵的最後一段證據：前面的 HCL、provider、auth 與 plan 並不是停在靜態檢查，而是真的成功建立出雲端資源。
- 這次過程也順便驗證了一個很實用的 Terraform 行為：若必要 variable 沒有預先提供，Terraform 在互動模式下會直接要求使用者補值，對單人手動練習很方便；但若放到 CI/CD 或非互動環境，就不能依賴這種補值方式。
- apply 完成後，最值得記住的觀察點是：`external_ip` 這類要等資源真正建立後才知道的欄位，只有在 apply 完成後才會從 `known after apply` 變成具體值。
- 因此 Step 7 可以收斂為已完成；若要再往下走，下一步就不該再重複 apply，而是新開 step 做 post-apply 檢查或 cleanup 決策。

#### 目前狀態

- 已完成

### Step 8

#### 這一步要驗證什麼

- `terraform apply` 成功之後，GCP 上目前看到的實際資源狀態，是否真的和 Terraform outputs 與 lesson 預期一致。

#### 預計採取的動作

- 由使用者用 `gcloud` 直接檢查剛建立的 VM 是否存在、zone 是否正確、外部 IP 是否和 Terraform output 一致。
- 再檢查兩條 firewall 規則是否都已建立，且 target tags 與允許的 port 符合目前設定。
- 最後只做觀察與核對，不在這一步直接修改 Terraform 設定或銷毀資源。

#### 實際執行內容

- 本次由使用者實作
- 使用者在 apply 完成後，接著用 `gcloud` 做 post-apply 檢查，並回報整體檢查結果為 `ok`。
- 這一輪明確貼出的輸出，來自兩條 firewall 規則的 `gcloud compute firewall-rules describe` 結果。
- `free-tier-vm-allow-http` 的檢查結果顯示：`direction = INGRESS`、`priority = 1000`、`sourceRanges = 0.0.0.0/0`、`targetTags = allow-http`，而且允許的 port 為 TCP `80`。
- `free-tier-vm-allow-https` 的檢查結果顯示：`direction = INGRESS`、`priority = 1000`、`sourceRanges = 0.0.0.0/0`、`targetTags = allow-https`，而且允許的 port 為 TCP `443`。
- 兩條規則的 `network` 都指向該 project 的 `default` network，與目前 Terraform 設定一致。

#### 結果

- 這一輪 post-apply 檢查已確認 firewall 實際狀態與 Terraform 設定一致。
- HTTP 與 HTTPS 兩條規則都已存在，而且 target tag、source range、priority 與允許的 port 都正確落下。
- 使用者也同步回報整體檢查結果為 `ok`，因此目前沒有看到 apply 後明顯偏離 lesson 預期的資源狀態。

#### AI 判讀與收斂

- Step 8 的價值在於把 Terraform output 再往前推一步，改用雲端控制面的實際查詢來驗證資源，而不是只相信 apply 當下的終端機輸出。
- 這次至少已明確驗到兩條 firewall 規則確實存在於 GCP，且細節與 Terraform 宣告一致，代表 apply 不是只更新 state，而是真的把規則建立到雲端上。
- 由於使用者已回報整體檢查 `ok`，這一步可以先收斂為完成；若後續還要延伸，下一步才適合新開 cleanup 或 destroy 決策 step。

#### 目前狀態

- 已完成

### Step 9

#### 這一步要驗證什麼

- `terraform apply` 完成之後，是否已經看懂 state 裡哪些欄位最值得讀，以及它們和 HCL、plan、雲端實際狀態之間的對應關係。

#### 預計採取的動作

- 由使用者用 `terraform state list` 與 `terraform state show` 觀察目前 state 中已被 Terraform 納管的資源。
- 先聚焦在最有教學價值的欄位，例如 instance 的 `id`、`name`、`zone`、`machine_type`、`tags`、`network_interface`、`nat_ip`，以及 firewall 的 `name`、`target_tags`、`source_ranges`、`allow`。
- 一邊讀欄位，一邊分辨哪些值是 HCL 原本就寫死的、哪些值是 apply 後才由雲端回填進 state 的。

#### 實際執行內容

- 本次由使用者實作
- 使用者先執行 `terraform state list`，確認目前 state 中已被 Terraform 納管的資源共有 3 個：`google_compute_firewall.allow_http`、`google_compute_firewall.allow_https`、`google_compute_instance.free_tier_vm`。
- 接著使用者執行 `terraform state show google_compute_instance.free_tier_vm`，把閱讀焦點先集中在 VM 這個最有代表性的資源。
- 在 instance state 裡，先對照幾組最重要的欄位：`id` / `self_link` 代表這個資源在 GCP 中的唯一定位；`name`、`project`、`zone`、`machine_type` 對應這台 VM 的基本識別；`tags` 對應前面 firewall rule 要套用到哪台 VM。
- 再往下讀 `boot_disk` 與 `network_interface`：前者可以看到 disk 的實際 image、size 與 type；後者則能直接看到 `network_ip` 與 `access_config.nat_ip`，也就是內網 IP 與外網 IP。
- 最後再把 instance state 裡幾個 apply 後才會出現的值收出來，例如 `current_status = RUNNING`、`cpu_platform = Intel Broadwell`、`creation_timestamp`、`instance_id`、`network_ip = 10.142.0.2`、`nat_ip = 35.211.162.104`。

#### 結果

- 目前已完成第一輪 state 閱讀，至少已能看懂 Terraform state 裡最核心的兩層資訊：哪些資源正在被 Terraform 管，以及某一個資源目前在雲端上的實際狀態。
- `terraform state list` 證明目前 state 裡確實有 2 條 firewall 與 1 台 VM，與今天 apply 建立的資源集合一致。
- `terraform state show` 則補上了 plan 與 output 看不到的細節，例如 VM 已經進入 `RUNNING`、實際 CPU platform、內網 IP、外網 IP，以及 GCP 資源的完整 `id` / `self_link`。
- 因此 Step 9 的核心學習目標已達成：state 不是單純備份 HCL，而是 Terraform 對「目前真實資源狀態」的結構化記錄。

#### AI 判讀與收斂

- 讀 state 時，最重要的不是逐欄背誦，而是先分成三類來看：一類是你在 HCL 裡主動宣告的值，例如 `machine_type`、`zone`、`tags`；一類是 apply 後由雲端回填的值，例如 `instance_id`、`creation_timestamp`、`cpu_platform`、`network_ip`、`nat_ip`；第三類則是 Terraform / provider 為了追蹤資源關聯而保留的識別欄位，例如 `id`、`self_link`、各種 fingerprint。
- 這也是為什麼 state 值得讀：它讓你看到「Terraform 想建立什麼」和「雲端最後真的長成什麼」之間的接合面。
- 這一步先用 instance 當主體已經足夠，因為 VM 幾乎把 state 最常見的欄位型態都示範過一次；後續若要延伸，再去讀 firewall 的 state 就會更容易。
- 因此 Step 9 可以收斂為已完成；下一步才適合進 Step 10，做 destroy 前確認與執行。

#### 目前狀態

- 已完成

### Step 10

#### 這一步要驗證什麼

- 在已經完成 state 閱讀後，是否要把今天建立的最小資源完整銷毀，並確認 Terraform 能把它們乾淨移除。

#### 預計採取的動作

- 先確認 destroy 的目的、風險與預期影響範圍，只鎖定今天建立的 1 台 VM 與 2 條 firewall。
- 再由使用者親手執行 `terraform destroy`。
- destroy 完成後，確認 state 與雲端控制面都不再保留這批資源。

#### 實際執行內容

- 本次由使用者實作
- 使用者在 `terraform/gcp-free-tier-vm/` 執行 `terraform destroy`，這次同樣沒有先用 `-var` 帶入 `project_id`，因此 Terraform 先進入互動式提問，由使用者手動輸入 `gemini-420216`。
- Terraform 先 refresh 現有 state，確認目前仍受管理的資源就是 2 條 firewall 與 1 台 VM。
- destroy plan 清楚顯示這次要移除的資源共有 3 個：`google_compute_firewall.allow_http`、`google_compute_firewall.allow_https`、`google_compute_instance.free_tier_vm`，同時 outputs 也都會從具體值回到 `null`。
- 使用者在 destroy confirmation prompt 輸入 `yes` 後，Terraform 依序銷毀兩條 firewall 與 VM，最後回報 `Destroy complete! Resources: 3 destroyed.`

#### 結果

- 今天由 Terraform 建立的最小資源集合已全部成功銷毀。
- destroy 的實際範圍與 lesson 預期一致，沒有超出今天這包 Terraform 所建立的 1 台 VM 與 2 條 firewall。
- outputs 中原本的 `external_ip`、`instance_name`、`instance_zone`、`machine_type`、`project_id` 也都隨著 destroy 回到 `null`，符合 Terraform 對已刪除資源的預期表現。
- 因此這次最小 IaC workflow 已完成閉環：從 HCL、plan、apply、post-apply 檢查，到最後 destroy 都已實際走完一次。

#### AI 判讀與收斂

- Step 10 的關鍵價值，不只是把資源刪掉，而是驗證 Terraform 不只會建立資源，也能根據同一份 state 與設定，正確地把它們完整回收。
- destroy plan 也再次示範了一個重要閱讀方式：畫面中大量 `-> null` 的變化，代表這些欄位所屬的資源即將從 state 與雲端控制面一起消失。
- 這次流程也再次驗證互動式 variable 補值在手動操作時確實可行，但若搬到自動化流程，仍應事先把變數供應好，而不是依賴 prompt。
- 因此 Step 10 可以收斂為已完成；就今天這個 lesson 而言，最小 Terraform IaC 練習已完整收尾。

#### 目前狀態

- 已完成
