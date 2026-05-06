# 2026-05-06 Terraform Drift SSH Boundary Note

## 學習注意事項

### 今天的 lesson 邊界

- 今天採 implement-heavy mode，主體放在 `06-implementation.md`，先做 access path，再做邊界收斂，最後才視時間進 drift。
- 今天不把 lesson 擴成新的完整 GCP IAM / IAP / OS Login 設計題，也不展開完整主機初始化流程。
- 若提到 SSH 可達性，必須明確區分「Terraform 保證」和「project / network 既有狀態剛好讓它可用」。
- 若提到改善方向，優先維持 W9 的 20/80 範圍：最小可操作、可講清楚、可回到 repo。

### 今天要刻意記住的口頭模型

- `Terraform` 先負責把基礎設施與 access prerequisite 寫清楚，不等於它必須包辦所有作業系統初始化與服務配置。
- `SSH access` 解的是「人能不能安全地進去機器」；bootstrap / config management 解的是「進去之後怎麼把機器變成可持續運作的服務主機」。
- `state` 與 drift 的價值，不只在於看差異，而在於分辨目前看到的行為到底是 IaC 內的預期、IaC 外的偶然，還是已經偏離預期。

### 今天的實作優先順序

- 先把最小 SSH access path 補明確，並盡量留下一次登入驗證。
- 然後把 access / bootstrap 責任分界講清楚。
- 只有前兩項完成，才做最小 drift 對照。

## Notes

### `terraform validate` 是什麼

- `terraform validate` 用來檢查目前目錄下的 Terraform 設定是否在語法、區塊結構、參數型別與 provider schema 層面成立。
- 它回答的問題是：這份 Terraform configuration 合不合法、能不能被 Terraform 正常理解；它不回答雲端資源最後能不能真的建成功。
- 以今天這一步來說，`terraform validate` 通過，代表我們新增的 `allow_ssh` firewall、`ssh_source_ranges` 變數與相關引用在配置層是有效的。

### `terraform validate` 怎麼用

- 最常見用法是在 Terraform 專案目錄直接執行 `terraform validate`。
- 常見搭配順序是：先 `terraform fmt`，再 `terraform validate`，之後才進 `terraform plan`。
- 一個實用的口頭模型是：`validate` 檢查「配置是否合法」，`plan` 檢查「這份合法配置實際會改什麼」，`apply` 才是「真的把變更打到雲端」。

### `terraform validate` 的邊界

- 它不會替你完成 runtime 驗證，所以就算 `validate` 通過，也不代表 SSH 一定能登入、GCP auth 一定正常、或 provider 呼叫雲端 API 一定成功。
- 它也不等於安全檢查；例如把 `ssh_source_ranges = ["0.0.0.0/0"]` 寫進變數檔，對 Terraform 來說仍可能是合法配置。
- 所以今天的 lesson 裡，`validate` 是 Step 1 的配置層驗證，不是整個 VM access path 的最終驗收。

### 這次的 `ssh_source_ranges` 決策

- issue 文件原本偏向固定 IP 或受控 CIDR，因為那是較穩妥的長期運行前提。
- 但以你目前這台機器的用途來看，沒有固定 IP，而且不一定長期運行，所以這次可以接受先把 `ssh_source_ranges` 寫成 `0.0.0.0/0`，優先換取可操作性。
- 這代表今天的 lesson 決策不是「最安全的預設」，而是「在短期、個人、非長期運行前提下，先讓 access path 成立」。
- 後面若這台機器轉成長期使用，再回頭把 SSH source range 收斂回固定 IP、VPN exit IP、IAP 或其他較受控方案。

### `OS Login` 是什麼

- `OS Login` 是 GCP 的一種 VM 登入模型：不是把 SSH public key 直接寫進 instance metadata，而是把登入權限交給 Google 帳號、IAM 權限和 OS Login 機制來管理。
- 用白話講，metadata SSH key 比較像「把這把公鑰直接掛到這台 VM 上」；`OS Login` 比較像「這個 Google 身分是否被允許登入這台 VM」。
- 它的好處是使用者與權限管理比較集中，也比較適合多人或較長期的環境；代價是會把 lesson 擴到 IAM、project / instance metadata 與登入模型，不符合今天想走的最小路徑。
- 所以今天沒有要實作 `OS Login`，不是因為它不好，而是因為它超出這次 lesson 的最小範圍。

### `instance metadata`、`project metadata`、`gcloud compute ssh` 的差別

- `instance metadata` 是把登入相關資訊直接掛在單一 VM 身上；若某台 VM 的 metadata 裡有指定 SSH key，代表這台 VM 自己知道要接受哪把 key。
- `project metadata` 是把登入相關資訊掛在整個 project 層；若 VM 沒特別關閉或覆蓋這條路，它可能會繼承 project 層的 SSH key 或其他 metadata 設定。
- `gcloud compute ssh` 不是 metadata 儲存位置，而是登入工具；它會幫你處理 SSH 指令、主機資訊，某些情況下也可能協助把 key 放進 metadata 或配合 `OS Login` 流程完成登入。
- 所以這三者不是同一層：`instance metadata` 與 `project metadata` 是「設定放在哪裡」，`gcloud compute ssh` 是「你用什麼方式發起登入」。
- 若用最白話的口頭模型來記：instance metadata 是單機規則，project metadata 是整個 project 的共用規則，`gcloud compute ssh` 則是幫你走登入流程的 CLI 工具。

### 為什麼本機有 `gcp` SSH key pair，不代表所有 GCP VM 天生都能用

- 你本機有 `~/.ssh/gcp` / `~/.ssh/gcp.pub`，只代表你手上有一組可用的 SSH key pair；它不自動代表所有現在或未來的 GCP VM 都會接受這把 key。
- 一台 VM 是否接受這把 key，關鍵不在「key 名字叫不叫 gcp」，而在它的登入路徑是否把這把 public key 納入可接受來源。
- 常見的可接受來源有三種：instance metadata、project metadata，或 `gcloud compute ssh` / `OS Login` 在登入流程中幫你建立對應的登入條件。
- 也就是說，這把 key 不是「整個 GCP 天生通用」；比較精準的說法是：只要某台 VM 的登入模型會讀到這把 public key，或登入流程會幫你把它掛上去，你就能用它登入。
- 反過來說，若未來新建的 VM 沒有讀 project metadata、沒有 instance metadata key、沒有啟用或正確設定 `OS Login`，那就算你本機還有同一把 `gcp` key，也不保證能直接登入。
- 今天選 metadata SSH key 這條路的價值就在這裡：我們不是假設這把 key 對所有 VM 自動通用，而是把「這台 VM 接受哪把 public key」明確寫進 IaC。

### `terraform.tfvars` 是否會進 git

- 目前 `terraform/gcp-free-tier-vm/.gitignore` 已明確包含 `terraform.tfvars`，所以我原本的打算就是：若建立本地 `terraform.tfvars`，它應該留在本機，不進版控。
- 這也是比較合理的做法，因為 `terraform.tfvars` 往往會放真實 project ID、本機路徑、SSH 使用者名稱，甚至其他不適合公開 commit 的值。
- repo 內保留 `terraform.tfvars.example`，作用是提供欄位樣板；真正的 `terraform.tfvars` 則是你的本地執行設定。

### `terraform.tfvars`、metadata 與 SSH 登入是怎麼接起來的

- `terraform.tfvars` 裡的值不是只留在本地檔案裡；在 `plan` / `apply` 時，Terraform 會先把這些值代入 HCL，最後把具體結果送給 GCP API。以今天這段設定來說，真正送出去的是一條 VM metadata：`ssh-keys = 使用者名稱:public key`。
- 神奇感的來源不在 Terraform，而在 GCE 對 `ssh-keys` metadata 的既有語意。Terraform 只是把這條規格送出去；GCE 的 guest environment 看到這個 metadata 後，會把它當成「哪個 Linux 使用者要接受哪把 public key」的登入規則。
- 所以你後續能用指定的 `ssh_username` 登入，不是因為 Terraform 自己懂 SSH，而是因為它把 GCE 認得懂的登入規則寫進了 VM metadata。

### GCP 會不會同時建立 SSH 用的 Linux 使用者

- 比較精準的說法不是「GCP API 直接建立一個帳號」，而是：VM 內的 guest agent / guest environment 會根據 metadata 登入規則，準備對應使用者可接受的 SSH key 狀態。
- 在常見的 GCE Linux 映像上，若 metadata 裡出現 `ssh-keys = 使用者名稱:public key`，系統通常會確保對應的 Linux 使用者能拿這把 key 登入；若該使用者原本不存在，會在登入模型處理過程中被建立或被準備好。
- 所以真正做事的是 VM 內的 guest environment，而不是 Terraform 本身；Terraform 負責宣告，GCP 控制面負責把 metadata 帶到 VM，guest environment 再把它落成 OS 層的可登入狀態。

### VM tag 和 firewall rule 的關係

- 在這次 GCP 設定裡，firewall rule 不是直接綁某一台 VM，而是綁在某個 network 上，再用 `target_tags` 指定「哪些帶有這個 tag 的 VM 會吃到這條規則」。
- 所以 `allow-ssh` rule 之所以會作用在這台 VM 上，不是因為 rule 知道 VM 名字，而是因為 VM 本身帶了 `allow-ssh` tag。
- 如果 VM 沒帶 `allow-ssh` tag，這條 firewall rule 仍然會存在，但它不會套到這台 VM 身上；結果就是 rule 在控制面存在，VM 仍可能無法從 22 port 被連入。
- 這也是為什麼 firewall 要做成獨立資源：它代表的是 network policy，不是 VM 內部屬性。VM 描述的是工作負載本身；firewall 描述的是流量如何被允許進出。兩者分開，才有辦法讓同一條規則套到多台 VM，也能讓同一台 VM 同時吃到多條規則。

### 為什麼只有 SSH 額外抽成 `ssh_source_ranges`

- `allow_http` 和 `allow_https` 目前沒有額外抽變數，是因為在這個 lesson 的最小範圍裡，它們被視為相對穩定的公開入口：就是對外服務用的 80 / 443，而且目前預期就是直接對外開放。
- SSH 不一樣。SSH 是 operator access path，風險邊界和環境差異都比較大：有時候要固定 IP，有時候要 `0.0.0.0/0`，有時候之後會改成 VPN / IAP。所以它比 HTTP / HTTPS 更需要保留可調整的 seam。
- 換句話說，不是 HTTP / HTTPS 不能抽成變數，而是以今天這份 lesson 來說，真正有變動壓力、也最值得保留彈性的，是 SSH source range。
- 若未來這包 Terraform 要往更通用或更長期的方向發展，HTTP / HTTPS 的 source ranges 當然也可以一起抽成變數；只是那不屬於今天的最小 lesson 目標。

### 這次第一次 SSH 成功，實際驗到的是哪條路徑

- 這次第一次成功的 `gcloud compute ssh`，不是單純驗到 Terraform 寫進 instance metadata 的那把 `~/.ssh/gcp.pub`。
- 從輸出來看，`gcloud` 發現預設的 `~/.ssh/google_compute_engine` key pair 不存在，所以它先在本機新建了一組 key。
- 接著 `gcloud` 又顯示 `Updating project ssh metadata...done.`，這代表它把新的 public key 更新到了 project metadata。
- 所以這次成功登入，證明的是 VM 可達、22 port 可用、SSH 模型可工作，而且 project metadata 路徑也可用；但它沒有單獨證明「只有 Terraform 管理的 instance metadata key 生效」。
- 若要驗 Terraform 管理的那條 key path，本次 lesson 之後應再用 `gcloud compute ssh --ssh-key-file=/Users/kyo/.ssh/gcp` 或直接 `ssh -i /Users/kyo/.ssh/gcp ...` 做一次更乾淨的驗證。

## Flashcards

<!-- lesson 收尾後再統一生成 -->
