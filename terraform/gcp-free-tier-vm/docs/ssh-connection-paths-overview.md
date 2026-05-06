# GCE Linux VM SSH 連線方式與路徑總整理

日期：2026-05-06

## 為什麼再寫第三份

前兩份文件分別處理了：

1. 這次實際驗證時，`gcloud compute ssh` 與 Terraform key path 如何互相交錯
2. metadata、guest agent、OS Login 與本機使用者建立之間的邊界

但如果把時間拉回「從零開始設計一台新的 GCE Linux VM，要怎麼建立 SSH 連線」，更需要一份**總覽型**文件。

這份文件的目的不是記錄這次實驗細節，而是整理：

1. 從頭開始時，究竟有哪些 SSH 連線手段
2. 每一種手段的真正登入路徑是什麼
3. 它們各自依賴哪些前提
4. 哪些路徑適合用來做乾淨驗證，哪些比較偏方便操作

## 先講最核心的模型

一條 GCE Linux VM 的 SSH 連線，至少同時包含四層：

1. **Network path**：封包能不能到 VM 的 SSH 服務
2. **Identity source**：VM 接受哪個 username + key，或接受哪個 Google identity
3. **VM-side account provisioning**：VM 內誰把這個身分同步成可登入的本機帳號
4. **Client entry method**：你是用 raw `ssh`、`gcloud compute ssh`，還是 browser SSH 進去

所以「連線方式」不能只看你打哪個指令。

更準確地說，一條連線路徑其實是：

> 某種 client entry method + 某種 identity source + 某種 VM 內帳號建立機制 + 某種 network reachability

## 這份整理的範圍

本文聚焦在 **GCE Linux VM 的標準 SSH 存取模型**。

本文會涵蓋：

1. metadata-based SSH
2. OS Login
3. raw `ssh`
4. `gcloud compute ssh`
5. Console / Browser SSH

本文不展開：

1. serial console
2. IAP tunnel 的細節
3. 自訂 startup script 自己建立帳號再手動管 `authorized_keys` 的非主流模型

原因不是它們不存在，而是這份 repo 的 lesson 與前兩份文件主要都在整理 **GCE 原生支援的標準 SSH 路徑**。

## 先分兩大身分模型

如果從原理看，GCE Linux VM 的 SSH 主要可分成兩大類。

### A. Metadata-based SSH

這一類的核心是：

1. SSH 公鑰放在 **instance metadata** 或 **project metadata**
2. VM 內的 **guest agent** 讀取 metadata
3. guest agent 建立或管理本機 Linux 帳號與 `authorized_keys`

這一類裡，登入身分通常長得像：

```text
kyo:ssh-ed25519 AAAA...
```

也就是 username 與 public key 一起存在 metadata 裡。

### B. OS Login

這一類的核心是：

1. VM 啟用 OS Login
2. VM 不再依賴 metadata 裡的 SSH key 當主要登入來源
3. Google identity 與 IAM 決定你能不能登入
4. OS Login 的 POSIX account 資訊決定 VM 內的 username / UID / GID / home directory

在這個模型下，真正的登入主體是你的 Google identity，不是單純 metadata 中的一段 `kyo:ssh-key` 字串。

## 如果從實務角度整理，最值得分開理解的 6 條路徑

如果不追求數學上所有排列組合，而是整理成實作、debug、面試都最好用的版本，可以把常見 SSH 路徑收成下面 6 條。

## 路徑 1：raw SSH + instance metadata key

範例：

```bash
ssh -i ~/.ssh/gcp kyo@EXTERNAL_IP
```

前提：

1. VM 有對外可達的 network path
2. TCP `22` 已開放到你的來源
3. VM 的 **instance metadata** 含有 `kyo:PUBLIC_KEY`
4. VM 未啟用 OS Login，且 guest agent 正常

真正登入路徑：

1. Terraform 或其他控制面工具把 `kyo:PUBLIC_KEY` 寫進 **instance metadata**
2. guest agent 讀到這筆 metadata
3. guest agent 在 VM 內建立或管理 `kyo` 帳號與其 `authorized_keys`
4. 你用本機 private key 直接對 external IP 發 SSH

這條路的特性：

1. 最乾淨
2. 最適合證明「instance metadata 這條路本身成立」
3. 最不會混入 `gcloud` helper 行為

最適合的用途：

1. 驗證 Terraform 寫入的 instance metadata key path 是否真的成立
2. 做最小可歸因的 runtime proof

## 路徑 2：raw SSH + project metadata key

範例：

```bash
ssh -i ~/.ssh/google_compute_engine kyo@EXTERNAL_IP
```

前提：

1. VM 有對外可達的 network path
2. TCP `22` 已開放到你的來源
3. 專案層的 **project metadata** 含有 `kyo:PUBLIC_KEY`
4. VM 沒有阻擋 project metadata SSH key
5. VM 未啟用 OS Login，且 guest agent 正常

真正登入路徑：

1. 公鑰存在 project metadata
2. guest agent 讀取 project metadata
3. guest agent 在 VM 內建立或管理 `kyo` 帳號與 `authorized_keys`
4. 你直接用 raw `ssh` 登入

這條路的特性：

1. 作用範圍比較大，因為 project metadata 可能影響多台 VM
2. 容易被 `gcloud compute ssh` 自動寫入或更新
3. 比較不適合拿來做「單台 VM、單一路徑」的乾淨驗證

最適合的用途：

1. 臨時操作
2. 同一專案多台 VM 的快速登入
3. 知道自己正在用 project-scope 身分來源時的維運場景

## 路徑 3：`gcloud compute ssh` + 自動 helper + project metadata

範例：

```bash
gcloud compute ssh kyo@VM_NAME
```

前提：

1. 你已安裝並登入 `gcloud`
2. VM 有可用的 network path
3. 你的 Google 身分有權限讓 `gcloud` 補齊可接受的 SSH 身分來源
4. VM 未阻擋這條路徑

真正登入路徑：

1. `gcloud` 檢查本機預設 key，例如 `~/.ssh/google_compute_engine`
2. 若沒有，`gcloud` 可能自動生成一把
3. `gcloud` 可能把公鑰寫進 project metadata
4. guest agent 讀到 metadata 後建立或管理本機帳號
5. `gcloud` 再完成 SSH 連線

這條路的特性：

1. 最方便
2. 最容易成功
3. 但最容易混入 helper 行為，導致你搞不清楚究竟是 instance metadata、project metadata，還是其他輔助路徑在生效

最適合的用途：

1. 先把機器連上
2. 一般操作與快速登入

不適合的用途：

1. 證明某一條特定 Terraform-managed key path 是否獨立成立

## 路徑 4：`gcloud compute ssh` + 明確指定 key file + metadata-based SSH

範例：

```bash
gcloud compute ssh kyo@VM_NAME --ssh-key-file=~/.ssh/gcp
```

前提：

1. VM 接受 metadata-based SSH
2. 指定的 public key 已經被 instance metadata 或 project metadata 接受
3. network path 正常

真正登入路徑：

1. `gcloud` 使用你指定的本機 key pair
2. 視情況，`gcloud` 仍可能補 metadata 或更新 metadata
3. VM 仍透過 guest agent 接受這把 key 對應的 username
4. SSH 登入成功

這條路的特性：

1. 比預設 `gcloud compute ssh` 更接近你原本設計的 key path
2. 但仍可能混入 `gcloud` 的 metadata helper 行為
3. 乾淨度介於 raw `ssh` 與預設 `gcloud compute ssh` 之間

最適合的用途：

1. 平常操作時想沿用 `gcloud` 的便利性
2. 同時希望盡量對準自己指定的 key pair

## 路徑 5：Console / Browser SSH + metadata-based SSH

範例入口：

1. Google Cloud Console 的 SSH 按鈕
2. Browser-based SSH session

前提：

1. VM 可從該管理入口到達
2. 該 VM 仍採 metadata-based SSH，而非 OS Login-only
3. Console helper 能成功補齊或使用 metadata 路徑

真正登入路徑：

1. Browser / Console 端產生或持有暫時性金鑰
2. 將 username + public key 寫進 metadata，通常會帶到期時間
3. guest agent 根據 metadata 建立或管理對應本機帳號
4. Browser SSH 連線進入 VM

這條路的特性：

1. 最適合臨時救援與人工操作
2. 不適合當成 IaC path 的乾淨驗證
3. 容易因為平台幫你做太多事情而模糊真正的責任邊界

最適合的用途：

1. 緊急登入
2. 教學 demo
3. 不想在本機先準備 SSH client 細節的快速操作

## 路徑 6：OS Login 路徑

可能入口：

1. `gcloud compute ssh`
2. Console / Browser SSH
3. 匯入 OS Login key 後搭配標準 SSH 流程

前提：

1. VM 已啟用 OS Login
2. 你的 Google identity 具備對應的 IAM 權限，例如 `roles/compute.osLogin` 或 `roles/compute.osAdminLogin`
3. OS Login 使用的 SSH key 已存在於你的 Google account / OS Login profile，或由工具在流程中代為處理

真正登入路徑：

1. 你的 Google identity 經 IAM 驗證是否可登入
2. OS Login 使用 POSIX account 資訊決定 username / UID / GID / home directory
3. VM 端依 OS Login 整合設定接受這個登入請求
4. metadata 裡的 SSH keys 不再是主要登入來源

這條路的特性：

1. 最適合多人、多專案、正式管理
2. 身分模型最乾淨，因為它把 SSH access 納入 IAM
3. 跟 metadata-based SSH 是不同世界，不能混為一談

最適合的用途：

1. 正式環境
2. 多使用者權限治理
3. 想把登入權限和 Google IAM 統一起來的場景

## 把 6 條路徑再壓縮成一張表

| 路徑 | 常用入口                                | 主要身分來源                      | VM 內誰處理帳號             | 乾淨度   | 適合用途                          |
| ---- | --------------------------------------- | --------------------------------- | --------------------------- | -------- | --------------------------------- |
| 1    | raw `ssh`                               | instance metadata                 | guest agent                 | 最高     | 驗證單台 VM 的 Terraform key path |
| 2    | raw `ssh`                               | project metadata                  | guest agent                 | 中       | 共用型 metadata 登入              |
| 3    | `gcloud compute ssh`                    | 常由 helper 補進 project metadata | guest agent                 | 低       | 快速登入與日常操作                |
| 4    | `gcloud compute ssh --ssh-key-file`     | 指定 key，仍可能混 helper         | guest agent                 | 中高     | 便利性與可控性折衷                |
| 5    | Browser SSH                             | 多半由 console helper 補 metadata | guest agent                 | 低       | 臨時救援與 demo                   |
| 6    | `gcloud` / Console / 其他 OS Login 流程 | OS Login + IAM                    | OS Login POSIX account 模型 | 另類乾淨 | 正式環境與權限治理                |

## 如果今天是一台新的 VM，從頭開始該怎麼選

可以這樣選。

### 目標 A：我想做最小 Terraform 驗證

首選：**路徑 1**

原因：

1. 最能隔離 instance metadata
2. 最能證明 Terraform 寫進去的 key path 自己成立
3. 最不容易被 `gcloud` helper 汙染

### 目標 B：我只想方便連上去

首選：**路徑 3**

原因：

1. `gcloud compute ssh` 最省事
2. 工具會幫你補很多細節
3. 但不要拿它直接當成乾淨的架構證明

### 目標 C：我想保留 `gcloud` 便利性，但又希望盡量沿用我指定的 key

首選：**路徑 4**

原因：

1. 你可以指定 key file
2. 比預設 `gcloud compute ssh` 更可控
3. 但仍要記得它可能還會動 metadata

### 目標 D：我要正式管理多位使用者

首選：**路徑 6**

原因：

1. OS Login 把 SSH access 收回到 IAM
2. 比 metadata 手工管理更適合正式環境
3. 使用者生命週期和權限模型更一致

## 回到這次 lesson，最重要的理解應該是什麼

這次 lesson 最重要的理解不是「到底哪個指令能連上」。

真正重要的是：

1. **同一個 `ssh` 成功事件，背後可能有不同的 identity path。**
2. **`gcloud compute ssh` 成功，不代表你驗到的是 Terraform 原本宣告的那條 instance metadata 路徑。**
3. **如果你要做設計驗證，應優先選 raw `ssh` + 明確指定 key 這種可歸因路徑。**
4. **如果你要做正式治理，應優先考慮 OS Login，而不是繼續擴張 metadata-based SSH。**

## 一句話版本

> GCE Linux VM 的 SSH 連線，不是單純分成「用 `ssh` 還是用 `gcloud`」；更本質的分法是「你走 metadata-based SSH 還是 OS Login」，而不同 client 入口只是把你帶進這兩大身分模型中的其中一條路。若要做最乾淨的 Terraform 驗證，應優先用 raw `ssh` 驗 instance metadata；若要做正式權限治理，應優先用 OS Login。
