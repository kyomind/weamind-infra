# 2026-05-06 Terraform Drift SSH Boundary Implementation

## 這份文件的角色

- 這份檔案用來記錄今天 implement-heavy lesson 的主體 step，不是一般 command drill。
- 一般延伸補充、設計取捨與暫時結論，統一整理到 `05-note.md`。

## 今日實作主題

- 把 `terraform/gcp-free-tier-vm/` 的 VM access path 補成最小可驗證閉環，並視時間做最小 drift 對照。

## 今日實作順序

1. 先補 SSH access path 所缺的 Terraform 明示設定。
2. 再確認登入驗證依賴的身分條件與 runtime 驗證方式。
3. access path 穩定後，再切 access / bootstrap 邊界。
4. 若時間足夠，再做一次低風險 drift 對照。

## 使用提醒

1. 每個 step 先寫骨架，再根據實際執行結果回填，不一次預寫完成稿。
2. 每完成一個 step 就停下來，讓使用者參與判斷、執行或結果判讀。
3. 若 runtime 驗證受平台條件阻塞，要誠實記錄停點，不把未驗證成功寫成已完成。

## Session 開場提醒

- 目前從 `Step 1 補 SSH access 規格` 開始，先收斂唯一主問題：現有 Terraform 缺了哪些 access prerequisite，最小要補到哪裡才算不是碰運氣 SSH。

## 驗收訊號與回退點

### 驗收訊號

- Terraform 規格能明確描述最小 SSH access path。
- 能說清楚登入驗證依賴哪些條件，以及哪些還不屬於 Terraform 這次的責任。
- 若時間足夠，能觀察一次最小 drift 對照結果。

### 回退點

- 若登入驗證卡在平台外部條件，今天至少保住 Terraform access path 與邊界收斂，不硬做 drift。

### Step 1 補 SSH access 規格

#### 這一步要驗證什麼

- 現有 `main.tf` 與 `variables.tf` 缺了哪些最小 SSH access prerequisite，才能讓 Terraform 明確保證 SSH 入口，而不是依賴專案預設。

#### 預計採取的動作

- 先根據 issue 文件，收斂最小 Terraform 變更：新增 `allow-ssh` tag、`ssh_source_ranges` 變數與 `google_compute_firewall.allow_ssh`。
- 這一步我建議由我來做，因為它是低摩擦、可 review 的 repo 變更；做完我們再一起看 diff 和為什麼這樣收斂。

#### 實際執行內容

- 本次由 AI 實作
- 在 `terraform/gcp-free-tier-vm/main.tf` 的 `instance_tags` 加入 `allow-ssh`，讓 SSH firewall rule 能精準套到這台 VM。
- 在 `terraform/gcp-free-tier-vm/main.tf` 新增 `google_compute_firewall.allow_ssh`，只開放 TCP `22`，並把 `source_ranges` 綁到變數，讓 lesson 仍保留可調整空間。
- 在 `terraform/gcp-free-tier-vm/variables.tf` 新增 `ssh_source_ranges`，型別為 `list(string)`。
- 依使用者目前沒有固定 IP、且 VM 不一定長期運行的前提，把 `terraform/gcp-free-tier-vm/terraform.tfvars.example` 的示例設成 `ssh_source_ranges = ["0.0.0.0/0"]`，優先保住可操作性。

#### 結果

- `terraform validate` 通過，代表這次最小 SSH access path 變更在 Terraform 配置層是有效的。
- 目前已把 SSH 入口正式寫進 IaC，但還沒有處理登入身分方案與 runtime SSH 驗證。

#### AI 判讀與收斂

- Step 1 已完成：這次修正解的是 access path 的 network layer，不是完整登入方案。
- 這樣的收斂符合今天的第一優先，因為它先把「22 port 是否由 Terraform 明確管理」這件事固定下來，避免後面把 project 預設與 IaC 保證混在一起。
- 在 source range 決策上，今天採用的是「短期可操作性優先」版本，而不是 issue 文件原先預設的固定 IP / 受控 CIDR 前提。
- 下一步應進 Step 2，切清楚 metadata SSH key、OS Login 與 project 預設幫忙三種路徑，決定今天要用哪種方式做最小登入驗證。

#### 目前狀態

- 已完成

### Step 2 確認登入驗證路徑

#### 這一步要驗證什麼

- 補完 Terraform access path 後，還需要哪些登入身分條件才能完成一次最小 SSH 驗證，以及這些條件哪些屬於 Terraform 內、哪些屬於 Terraform 外。

#### 預計採取的動作

- 先用 issue 文件與 GCP 實際登入路徑切開 metadata SSH key、OS Login 與 project 預設幫忙三種情況。
- 這一步預設由 AI 與使用者協作：我先收斂最小判斷框架，再由你決定今天登入驗證要走哪條路。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始
