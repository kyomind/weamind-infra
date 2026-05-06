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

- 目前 `Step 1` 到 `Step 3` 都已完成；若要繼續，下一步應改接 access / bootstrap 邊界收斂或隔離驗證，而不是重跑前面的 apply / SSH 指令。

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
- 先確認本機已有可用的 SSH public key，且目前 shell 使用者名稱可直接拿來當這次 VM 的 Linux login name。
- 再確認目前沒有既存的 `terraform.tfvars`，因此新建一份本地 `terraform.tfvars` 作為這次 lesson 的實際輸入來源。
- 這份本地 `terraform.tfvars` 只放最小必要值：working project、`ssh_source_ranges = ["0.0.0.0/0"]`、本次 SSH username，以及本機 `gcp.pub` 的絕對路徑。
- 登入身分方案最後收斂成 instance metadata SSH key，而不是 `OS Login`；理由是這條路最短，也最符合今天「把 access path 明寫進 IaC」的 lesson 目標。
- 本地 `terraform.tfvars` 建好後，直接執行一次 `terraform plan`，驗證 SSH firewall、instance metadata 與本地輸入值是否已接成同一條路徑。

#### 結果

- `terraform plan` 成功展開，代表本地 `terraform.tfvars`、SSH firewall 與 instance metadata SSH key 設定已能一起被 Terraform 正常讀取。
- plan 目前預計建立 4 個資源：3 條 firewall（HTTP、HTTPS、SSH）與 1 台 VM。
- plan 也已清楚顯示：VM 會帶有 `allow-ssh` tag，並在 metadata 中寫入這次指定的 `ssh-keys` 值，代表「這台 VM 接受哪把 public key」已經被明示在 IaC 裡。
- 這一步仍屬於配置與 plan 層驗證；真正的 SSH runtime 驗證，要等 apply 完成後再用 `gcloud compute ssh` 檢查。

#### AI 判讀與收斂

- Step 2 已完成：今天的登入路徑已明確收斂成 `instance metadata SSH key + gcloud compute ssh`，而不是依賴 project 預設或擴張到 `OS Login` / IAM。
- 本地 `terraform.tfvars` 是合理的這一步，因為它讓這次 lesson 的實際輸入值可重跑、可 review，而且又不會進版控。
- 最重要的判讀點不是「本機有一把叫做 gcp 的 key」，而是 plan 已經明示這台 VM 會接受這把 public key。
- 下一步若要往下走，就應進 apply；因為現在配置層與 plan 層的 access path 都已經接起來了。

#### 目前狀態

- 已完成

### Step 3 Apply 與第一次 SSH 驗證

#### 這一步要驗證什麼

- 目前已在 plan 中成立的 access path，是否能在 apply 後真的落成可用的 VM，並讓使用者以至少一條可工作的 SSH path 成功登入；若 helper 行為混入，也要把驗到的是哪條路徑切清楚。

#### 預計採取的動作

- 先由使用者執行一次 `terraform apply`，讓 VM、3 條 firewall 與 metadata SSH key 真正建立到 GCP。
- apply 完成後，先觀察 outputs，特別是 `instance_name`、`instance_zone` 與 `external_ip` 是否已出現。
- 接著用 `gcloud compute ssh` 做第一次 runtime 驗證，確認指定的 SSH username 與本機 private key 是否真的能登入這台 VM。
- 若第一次驗證混入 `gcloud` helper 行為，再補做更受控的第二輪驗證，把 project metadata 路徑和 Terraform key path 分開。
- 這一步我建議由你來執行 apply 和 SSH 驗證，因為學習價值主要在親手觀察 Terraform 與 GCP 的實際回應；我負責一起判讀結果與收斂下一步。

#### 實際執行內容

- 本次由使用者實作
- 使用者先執行 `terraform apply`，並在 approval prompt 輸入 `yes`。
- Terraform 依序建立 3 條 firewall：`allow-http`、`allow-https`、`allow-ssh`。
- 接著 Terraform 建立 `google_compute_instance.free_tier_vm`，整體 apply 成功完成。
- apply 結束後，outputs 已成功回傳 `external_ip`、`instance_name`、`instance_zone`、`machine_type` 與 `project_id`。
- 使用者接著執行 `gcloud compute ssh kyo@free-tier-vm`。
- `gcloud` 發現預設的 `~/.ssh/google_compute_engine` / `.pub` 不存在，因此自動生成一組新的本機 SSH key pair。
- 之後 `gcloud` 顯示 `Updating project ssh metadata...done.`，並在 key propagation 後成功登入 VM。
- 後續又補做兩次更受控的驗證：一次是 `gcloud compute ssh ... --ssh-key-file=/Users/kyo/.ssh/gcp`，一次是直接 `ssh -i /Users/kyo/.ssh/gcp kyo@<external-ip>`；兩次都成功。

#### 結果

- `terraform apply` 成功建立 4 個資源：3 條 firewall 與 1 台 VM。
- 這次 apply 的結果與前一步 plan 一致，代表 access path 的 IaC 宣告已真正落到 GCP 控制面。
- outputs 中已看到具體 `external_ip`，代表這台 VM 已有可供後續 SSH 驗證使用的對外位址。
- 第一次 runtime SSH 驗證成功，證明 VM 可達、22 port 可用，而且至少有一條可工作的 SSH identity path。
- 補做的兩次受控驗證也成功，代表指定的 `~/.ssh/gcp` key path 同樣可用；其中 raw `ssh -i /Users/kyo/.ssh/gcp ...` 是目前最乾淨的證據。

#### AI 判讀與收斂

- 這一步現在可以正式收斂成完成：network layer、VM tag、instance metadata SSH key 與 VM 本體都已經真正建立成功，不再只是 plan 上的預期。
- 但第一次 `gcloud compute ssh` 成功的路徑，比原本想像的更複雜：它混入了 `google_compute_engine` 預設 key 與 project metadata 更新行為。
- 補做受控驗證後，現在可以更準確地說：SSH reachability 與可操作性已成立，而且 Terraform 管理的 `~/.ssh/gcp` 這條 key path 也有足夠強的成功證據。
- 若要再往下走，下一步應改做 access / bootstrap 邊界收斂，或進一步設計隔離實驗，而不是再重複 apply / SSH 本身。

#### 目前狀態

- 已完成
