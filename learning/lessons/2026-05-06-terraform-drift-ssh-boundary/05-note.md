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

### project metadata 的 SSH key 到底是在 VM 外處理，還是 VM 內處理

- 比較精準的答案是：這條路分成控制面與客體 OS 兩段，不是完全只在 VM 外，也不是 project 自己在「外部」把 SSH 驗證做完。
- 在 metadata-based SSH 模型下，project metadata 或 instance metadata 裡存的是公開金鑰條目，不是完整的 key pair；private key 仍留在發起連線的 client 端，例如你的本機 `~/.ssh/gcp`。
- `gcloud compute ssh`、Console 或 API 這一層，做的是控制面操作：建立或上傳 public key、更新 project metadata / instance metadata，並找到要連哪台 VM。
- 真正把 metadata 變成 Linux 可登入狀態的，是 VM 內的 guest agent / guest environment。Google 的官方文件明確說明：未啟用 OS Login 的 VM 會把 SSH key 存在 project / instance metadata，而 guest agent 會處理 metadata-based SSH；官方也提醒直接手改 VM 內的 `authorized_keys` 可能被 guest agent 覆寫。
- 這表示 metadata key 不是停留在 project 這個抽象層就完成驗證，而是 VM 內的 guest agent 會透過 metadata server 讀到這些 key，然後更新本機帳號或授權狀態，最後真正的 SSH 握手與 public key 驗證仍發生在 VM 的 sshd / OS 層。
- 如果改走 OS Login，模型又不同：官方文件說啟用 OS Login 後，instance 的 guest agent 會忽略 metadata 裡的 SSH key，改由 VM 從 OS Login 服務取得與 Google 身分綁定的 SSH key 與 POSIX 帳號資訊。
- 所以今天比較準確的口頭模型是：project metadata 不是「在 VM 外直接完成登入」，而是「在控制面保存 project-level public key 規則，然後由 VM 內的 guest agent 落成 OS 層可登入狀態」。

### 從 VM 內的 `authorized_keys` 截圖可以怎麼理解

- 這次進 VM 後查看 `~/.ssh/authorized_keys`，看到檔案裡有兩段 `# Added by Google`，下面各自對應一把 SSH public key，這是很強的 runtime 驗證訊號。
- 第一個重點是：SSH key 沒有只停留在 project metadata 或 instance metadata 這種控制面設定裡，而是真的已經被同步到 VM 內使用者層級的 `authorized_keys`。
- 第二個重點是：`# Added by Google` 這個標記很符合官方對 guest agent / metadata-based SSH 的描述。比較合理的解釋不是你手動編輯了這個檔案，而是 guest agent 根據 metadata 規則，把 key 落成到 VM 內的授權檔。
- 第三個重點是：如果這兩把 key 和你先前在 project metadata 裡看到的兩條 `kyo` key 對得上，那就能更有力地支持目前的登入路徑確實受 project metadata 影響，而且最後會在 VM 內變成真實可用的 `authorized_keys` 條目。
- 這也幫我們把「驗證是在 VM 外還是 VM 內完成」講清楚：控制面可以在 VM 外更新 metadata，但最後真正接受 SSH public key 驗證的地方，仍然是 VM 內的 sshd / OS 層；`authorized_keys` 就是最後落地點的直接證據。
- 不過這張圖也有一個邊界要記住：它能很強地證明 metadata-based SSH 已進入 VM 內的 OS 授權層，但單看 `authorized_keys` 本身，通常還不能百分之百區分某條 key 最初是來自 project metadata 還是 instance metadata，因為 guest agent 可能會把多個 metadata 來源整合後一起寫進來。
- 所以這張圖最精準的收斂不是「它單獨證明一定是 project metadata」，而是「它證明 metadata-based SSH 沒有停在控制面，而是真的被 guest agent 落成 VM 內的授權狀態」；再結合前面查到的 project metadata 內容，才形成對 project-level path 的更強歸因。

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

### 除了 `ssh-keys` 之外，instance metadata 常見還會放什麼

- `ssh-keys` 只是最常見的一種，不是 `metadata` 的全部。Terraform provider 也明確把它描述成「metadata key/value pairs」，只是其中某些預先定義 key 會被 GCE 或 guest agent 賦予特殊功能。
- 最常見的第一類是啟動與關機腳本，例如 `startup-script`、`shutdown-script`。這些 key 的值通常是 script 內容，許多 Linux 映像會在開機或關機時讀這些 metadata 並執行。
- 第二類是 SSH / 存取模型切換，例如 `enable-oslogin`、`block-project-ssh-keys`、`ssh-keys`。這些 key 直接影響 VM 接受哪種 SSH identity source，以及要不要繼承 project-level key。
- 第三類是 metadata server 與 guest environment 相關設定，例如 `disable-legacy-endpoints`、`disable-https-mds-setup`、`enable-https-mds-native-cert-store`。這些比較偏平台與安全層，控制的是 VM 怎麼安全地讀 metadata server。
- 第四類是 guest / inventory 類功能，例如 `enable-guest-attributes`、`enable-os-inventory`。這些不是登入設定，而是讓 VM 或平台可以發布少量狀態、OS inventory 等資訊。
- 第五類是使用者自訂 metadata。官方文件明確說明你可以建立自己的 key/value，讓 VM 啟動後從 metadata server 讀取，例如 `app-env=prod`、`config-version=v3` 這類不敏感、小型、低頻更新的設定。
- 比較實務的口頭模型是：instance metadata 很常被拿來放「VM 啟動時需要知道、而且 GCE / guest agent / startup script 會直接讀的設定」，不只 SSH key。
- 但有個安全邊界一定要記住：官方文件明講，只要程序能查 metadata URL，就能讀到 metadata server 裡的值；所以 metadata 不適合放真正的敏感祕密。

### ⭐️Terraform 的 `metadata` 映射到 GCP provider / API，到底代表 VM 的什麼

- 在 Terraform 的 `google_compute_instance` 裡，`metadata = { ... }` 不是一個任意本地 map；它會被 provider 轉成 Compute Engine instance resource 的 metadata key/value，送到 GCP API，成為這台 VM 的執行個體中繼資料。
- 官方文件對 VM metadata 的定義很清楚：每台 VM 都有 metadata server，Compute Engine 會把專案、可用區、執行個體等不同範圍的 metadata 以 key/value 形式維護在那裡，而 VM 內可以直接查詢這些值。
- 所以從 API / 平台角度看，instance metadata 代表的不是「這台 VM 的硬體規格」那一類核心屬性，而是「這台 VM 與其 guest OS / guest agent / startup scripts 可讀取的附加控制資料」。
- 這些資料**有些只是描述性或自訂設定，有些則是行為開關**。像 `ssh-keys` 會影響 guest agent 如何佈建 SSH 存取，`enable-oslogin` 會切換登入模型，`startup-script` 則會在 OS 啟動流程中被執行。
- 如果用更白話的方式講，`machine_type`、`boot_disk`、`network_interface` 這些欄位是在描述「GCP 要建立什麼 VM」；而 `metadata` 更像是在描述「**⭐️這台 VM 起來後，平台和 guest environment 還要帶給它哪些設定、提示或控制訊號**」。
- 這也解釋了為什麼 metadata 既能用來放 `ssh-keys`，也能用來放 `startup-script` 或自訂 key：它本質上是 VM 的 control/config channel，不是只屬於 SSH 的專用欄位。
- 另外還要記住 scope：你現在在 `main.tf` 寫的這個 `metadata` 是 instance-level，所以它代表的是這台 VM 專屬的 metadata；它和 project metadata 是同一套 metadata 機制，但 scope 不同。
- 這題最短的口頭收斂可以講成：Terraform 的 `metadata` 就是把一組 VM 專屬的 key/value 設定送進 Compute Engine 的 instance metadata，讓 GCP 控制面、metadata server、guest agent 和 VM 內腳本在執行時可以讀到並據此採取動作。

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

### 後半段隔離實驗與依賴關係收斂

- 後續關於 destroy / apply 後的 `gcloud compute ssh`、移除 Terraform instance metadata `ssh-keys`、raw `ssh -i ~/.ssh/gcp`、`known_hosts` 與 project metadata 查詢的完整實驗，已另整理到 `terraform/gcp-free-tier-vm/docs/ssh-metadata-isolation-experiments.md`。
- 這樣 Note 先保留 lesson 主軸需要的最小口頭模型；較長的驗證過程、反例與依賴關係收斂則放到獨立參考文件中。

## Flashcards

<!-- lesson 收尾後再統一生成 -->
