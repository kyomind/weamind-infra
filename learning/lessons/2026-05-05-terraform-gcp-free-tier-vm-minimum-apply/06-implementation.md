# 2026-05-05 Terraform GCP Free Tier VM Minimum Apply Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 在 `terraform/gcp-free-tier-vm/` 建立第一版可執行的 Terraform 骨架，先確認 preflight gate，再往最小 `plan` / `apply` 與 Free Tier 核對推進。

## 今日實作順序

1. 先確認 Terraform CLI、GCP auth、project、billing 與必要 API 的 preflight gate。
2. 在 `terraform/gcp-free-tier-vm/` 收斂第一版 `.tf` 骨架與參數邊界。
3. 以 `terraform plan` 驗證 HCL 與資源意圖；若 gate 完整則再進一步做最小 `terraform apply`。
4. 用 Free Tier checklist 核對結果，並記下後續 drift / destroy 收尾邊界。

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
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 2

#### 這一步要驗證什麼

- 第一版 `.tf` 骨架最少要長成什麼樣，才足以表達 GCP Free Tier VM 的主要規格與可讀性。

#### 預計採取的動作

- 在 `terraform/gcp-free-tier-vm/` 建立 `versions.tf`、`provider.tf`、`variables.tf`、`main.tf`、`outputs.tf` 與 `terraform.tfvars.example`。
- 先用 provider、variables、compute instance、必要 firewall 與 outputs 收斂第一版結構。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 3

#### 這一步要驗證什麼

- 這份第一版 Terraform 設定是否已能穩定產生可讀的 `plan`，以及若 gate 完整時是否可安全進到最小 `apply`。

#### 預計採取的動作

- 執行 `terraform fmt`、`terraform init` 與 `terraform plan`。
- 若 preflight 條件完整且 `plan` 穩定，再視情況執行一次最小 `terraform apply`。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 4

#### 這一步要驗證什麼

- 無論今天是否真的做到 `apply`，最後能否用明確證據說明 VM 規格是否對齊 Free Tier 邊界，並知道後續 destroy / drift 該怎麼收尾。

#### 預計採取的動作

- 用 `references/phase2/w9-iac-minimum-spec.md` 的 checklist 核對 region、zone、machine type、boot disk、network tier、HTTP / HTTPS 與額外 agent / backup 設定。
- 記下若後續手動改資源，最容易形成 drift 的點。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始
