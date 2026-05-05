# WeaMind IaC Minimum Spec

這份文件整理 Phase 2 / W9 會反覆用到、但不需要每次都讀的最小 IaC 規格。

它不是週計畫，也不是 production-grade Terraform 設計文件。

它的角色是：當 W9 要做 Terraform prework、最小練習與 IaC 驗收時，提供一份穩定、可公開、可對照的 reference。

## 先說結論

W9 的最低目標不是把 Terraform 學到專精，而是完成一版可實作、可解釋、可面試重講的最小 IaC 經驗。

第一版應收斂成：

- 理解 core workflow：plan / apply / destroy
- 理解 provider / resource / state 的最小角色分工
- 以 https://kucw.io/blog/gcp-free-tier/ 那篇教學中的 Free Tier VM 條件為規格，用 Terraform 建出一台等價的 GCP VM
- 至少知道這台 VM 的 access path 怎麼成立，不能停在「VM 建出來了，但沒有 SSH 方案」
- 能講清楚 Terraform 與 Kubernetes manifest 的相似與不同

## W9 的範圍邊界

W9 在 Phase 2 裡的定位是：

- Terraform 獨立於 WeaMind 主線
- 用 GCP Free Tier 做最小實作，且目標不是隨便建一台 VM，而是盡量對齊既有教學中的 Free Tier VM 規格
- 重點是 IaC workflow 與 state / drift 概念，不是完整雲端平台設計

第一版不追求：

- production-grade remote state 架構
- 完整 module 設計
- 多環境 workspace 策略
- 大量 provider / resource 覆蓋
- Google 帳號、billing、project 開通等平台 bootstrap 流程自動化

但第一版也不應漏掉一個太基本的現實問題：若目標 VM 預設會被人登入或操作，至少要補清楚 SSH access 是靠什麼成立。

## 本週要對齊的 VM 規格

W9 的 VM 目標，不是自行隨機發明，而是對齊這篇教學的核心免費條件：

- region 為 `us-west1`、`us-central1`、`us-east1` 其中之一
- machine type 為 `e2-micro`
- boot disk 使用標準 HDD，而非 SSD
- boot disk 大小控制在 Free Tier 邊界內
- network 設定避免多餘的付費選項

更精準地說，W9 要驗收的是：在前置帳號與 project 都已就緒的前提下，是否能用 Terraform 產生一台和教學手動建立結果等價的 VM。

## 教學規格內化版

W9 不應只停留在「看過那篇文章」，而要把文章中真正和 VM 建立有關的規格內化成這份 reference。

第一版先固定對齊下面這組規格：

| 項目                         | W9 要對齊的規格                              | 說明                                                         |
| ---------------------------- | -------------------------------------------- | ------------------------------------------------------------ |
| Project 前提                 | 已存在可用 project                           | 不把 project / billing bootstrap 算進這次 Terraform 實作範圍 |
| Region                       | `us-west1`、`us-central1`、`us-east1` 三選一 | 這是 Free Tier 條件的一部分                                  |
| Zone                         | 從選定 region 下挑一個 zone                  | 不是免費與否的核心，但建立 VM 時仍要明確指定                 |
| Machine type                 | `e2-micro`                                   | 這是最核心的免費條件之一                                     |
| Boot disk type               | Standard persistent disk / HDD               | 不使用 SSD                                                   |
| Boot disk size               | 20GB 起步，最高不超出 Free Tier 邊界         | 文章建議 20GB 已足夠                                         |
| Boot image                   | 穩定、常見的 Linux 映像即可                  | W9 重點不是測不同映像，而是跑通 IaC 與免費規格               |
| External IP                  | 允許存在                                     | 文章的手動流程本身就是建立可 SSH 的外網 VM                   |
| HTTP traffic                 | 可開                                         | 若要對齊文章手動流程，可保留                                 |
| HTTPS traffic                | 可開                                         | 若要對齊文章手動流程，可保留                                 |
| Network tier                 | `STANDARD`                                   | 避免落到較高費用設定                                         |
| Backup                       | 關閉                                         | 避免額外費用                                                 |
| Ops Agent / Monitoring Agent | 關閉                                         | 避免額外費用或偏離最小練習目標                               |

## 手動教學到 Terraform 的對照方式

把文章轉成 Terraform 規格時，第一版至少要能一一對上這些概念：

| 教學裡的手動設定              | W9 實作時要落成的 Terraform 意圖                     |
| ----------------------------- | ---------------------------------------------------- |
| 選 region                     | 在 Terraform 中明確指定 region / zone                |
| 選 e2-micro                   | 在 VM 資源中明確指定 machine type                    |
| 把開機磁碟改成標準永久磁碟    | 在 boot disk 設定中明確使用標準 HDD 類型             |
| 把大小壓在免費邊界內          | 在 disk size 中明確寫出安全值                        |
| 勾 HTTP / HTTPS               | 以 firewall rule 或對應網路設定明確表達              |
| 把 network tier 改成 Standard | 在 external access / network 設定中明確指定 Standard |
| 關掉備份                      | 不建立額外 backup 類資源或功能                       |
| 取消 Ops Agent                | 不啟用額外監控 agent 相關設定                        |

## W9 做完後至少要能檢查什麼

不只要能 `apply` 成功，還要能用一份簡單 checklist 自證這台 VM 沒偏掉：

- region 是否落在 Free Tier 允許範圍內
- machine type 是否真的是 `e2-micro`
- boot disk type 是否真的是標準 HDD
- boot disk 大小是否仍在安全範圍內
- network tier 是否真的是 `STANDARD`
- 是否沒有額外 backup / monitoring 類設定混進來

## Terraform 參數對照草稿

這一段不是完整實作稿，而是 W9 實作時的最小對照表。

目的只有一個：讓你知道文章裡的手動欄位，第一版大致會落到哪些 Terraform 設定。

| 要對齊的規格   | Terraform 第一版大致落點                       | 說明                                               |
| -------------- | ---------------------------------------------- | -------------------------------------------------- |
| Project        | provider 的 `project`                          | 先假設 project 已存在                              |
| Region         | provider 的 `region`                           | 先固定在 Free Tier 允許範圍內                      |
| Zone           | VM 資源的 `zone`                               | 建 VM 時仍要指定 zone                              |
| VM 名稱        | `google_compute_instance.name`                 | 任意，但應明確命名                                 |
| Machine type   | `google_compute_instance.machine_type`         | 需固定為 `e2-micro`                                |
| Boot image     | `boot_disk.initialize_params.image`            | 第一版選常見 Linux 映像即可                        |
| Boot disk type | `boot_disk.initialize_params.type`             | 應對齊標準 HDD，例如 `pd-standard`                 |
| Boot disk size | `boot_disk.initialize_params.size`             | 用明確數值控制在安全範圍                           |
| VPC network    | `network_interface.network`                    | 第一版可直接使用 default network，避免範圍膨脹     |
| External IP    | `network_interface.access_config`              | 要有外網 IP，通常需要這個 block                    |
| Network tier   | `network_interface.access_config.network_tier` | 應明確指定 `STANDARD`                              |
| HTTP / HTTPS   | `google_compute_firewall` + instance tags      | 以 firewall rule 對 80/443 開放，不靠 Console 勾選 |
| Target tags    | `google_compute_instance.tags`                 | 讓 firewall rule 能精準套到這台 VM                 |
| SSH / metadata | `metadata` 或 `metadata_startup_script`        | 視第一版是否需要 SSH key / startup script 而定     |

## VM access 的最小驗收線

若 W9 的 VM 還保留「人會登入這台機器」這個前提，第一版至少要能回答下面三件事：

- SSH 入口是否存在：例如 22 port 是否有對應 firewall 規則，或是否明確決定只走 IAP / 其他受控入口
- SSH 身分是怎麼成立：例如 instance metadata / project metadata 的 SSH key，或 OS Login / IAM
- 這件事由誰負責：Terraform 只先負責把 access path 建起來，還是連 Linux 使用者建立也一起 bootstrap

第一版的最低可接受版本，可以只是：

- 補一條最小 SSH firewall rule
- 明確採一種 access 方案，例如 metadata SSH key 或 OS Login
- 實際驗證 `gcloud compute ssh` 或等價方式能登入

更進一步但不是第一優先的延伸，才是：

- 建立個人 Linux 帳號
- 做較完整的使用者 / sudo / dotfiles bootstrap
- 把主機初始化與套件安裝做成 startup script 或 Ansible

也就是說，W9 第一版至少要把「能登入」做出來；至於「登入後主機長什麼樣」則可以留給後續 bootstrap 工具處理。

## 第一版資源輪廓

若只以 W9 的最小目標來看，第一版通常不需要很多資源。

大致上應可收斂成：

- 一個 `google_compute_instance`
- 視需要加入一到兩個 `google_compute_firewall`

第一版不必急著補：

- 自建 VPC
- 自建 subnetwork
- service account / IAM 精細化
- module 化
- startup automation 複雜腳本

也就是說，W9 的重點應是先把「免費條件 + Terraform 基本循環」跑通，而不是過早把 GCP 基礎設施設計整套展開。

## W9 implementation sketch 應長什麼樣子

第一版實作完成後，Terraform 檔案至少應該能讓人看出下面這種結構：

- provider：指定 project / region
- variables：至少把 zone、instance name、disk size 這類容易調整的值抽出來
- compute instance：承接 machine type、boot disk、network interface、network tier
- firewall rules：若要對齊文章中的 HTTP / HTTPS 勾選，應明確把 80 / 443 用 rule 表達出來

如果最後 Terraform 檔案裡看不出這幾層，而是只有一個模糊的大資源塊，那通常代表 implementation 仍不夠可讀，也不利於 W9 的驗收與面試重講。

## 最小概念骨架

W9 至少要能穩定分開這幾件事：

- `provider`：Terraform 怎麼連到外部平台
- `resource`：Terraform 實際宣告與管理的基礎設施物件
- `plan`：比對目前狀態與宣告內容後，預計要做的變更
- `apply`：真正把變更套出去
- `state`：Terraform 用來追蹤受管資源與目前已知狀態的核心資料
- `drift`：真實世界的資源狀態和 Terraform 期待狀態出現脫鉤

## 與 Kubernetes manifest 的最小對照

第一版最重要的對照不是語法，而是 state 與 lifecycle：

- 兩者都屬於宣告式
- Kubernetes 偏向把 desired state 交給 controller 持續 reconcile
- Terraform 依賴 state 來知道自己管理過哪些資源，以及下一次該改什麼
- 若 runtime 被手動改動，Terraform 比較容易直接遇到 drift 問題

## 第一版最小實作目標

W9 的最小實作應至少留下這些證據：

- 一次完整的 `plan`
- 一次完整的 `apply`
- 一台符合教學 Free Tier 條件的 GCE VM
- 至少一條可說清楚並可驗證的 SSH access path
- 一次對 state / 資源變更的實際觀察
- 至少一段可用來講 drift 或手動修改風險的說明

這裡的重點不是資源本身多複雜，而是你真的走過一次 IaC 基本循環。

## 第一版最小風險邊界

W9 至少要能講出這幾類風險：

- 手動改雲端資源後，Terraform state 與真實狀態脫鉤
- secret / credential 不應直接粗暴寫進設定
- remote state 與共享協作有風險，但本階段只要知道問題輪廓，不要求完整解法

## W9 驗收時至少要能回答什麼

1. Terraform 為什麼需要 state
2. plan / apply 各自回答什麼問題
3. Terraform 與 Kubernetes manifest 都是宣告式，但差異在哪裡
4. drift 為什麼麻煩
5. 你這次是否真的用 Terraform 建出一台符合教學規格的 Free Tier VM，以及你如何確認它沒有偏離免費條件

## 這份 reference 的用途

- 當 W9 做 prework、最小練習與 drift 收斂時，作為穩定範圍邊界參考
- 避免把 Terraform 核心骨架、state / drift 邏輯與 Phase 2 的取捨原則全部塞在週計畫裡
- 讓計畫檔只保留節奏、進度、實作目標與短版驗收標準
