# SSH Helper 與 Terraform Key Path 追問整理

日期：2026-05-06

## 為什麼另外寫這份

前一份文件已經收斂了這次 SSH 驗證的主線，但後續又浮現四個很值得分開談的問題：

1. 如果沒有先在 Terraform 裡準備 SSH key path，只開 22 port，`gcloud compute ssh` 的 helper 行為是否通常也能打通？
2. `gcloud` 的預設 `google_compute_engine` key pair 建立過一次之後，後面會怎麼被重用？
3. project metadata 到底能不能同時容納多組 SSH key？
4. 在目前這個環境已經被 `gcloud` helper 污染過之後，還能不能驗證「Terraform 自己的 instance metadata key path 有沒有獨立成立」？

這四題都比單純的 note 複雜，所以集中寫在這份 follow-up 文件。

## Q1：如果沒有先在 Terraform 裡準備 `ssh-keys`，只開 22 port，`gcloud compute ssh` 通常也能連嗎？

短答案：**很多情況下可以，但不能把它當成普遍保證。**

更精準地說，若下面幾個條件都成立，`gcloud compute ssh` 很可能就算沒有 Terraform 先寫好 instance metadata key，也能成功：

1. VM 的 22 port 已經可達
2. VM 的 guest agent / guest environment 正常
3. 你目前的 GCP 身分有權限更新 project metadata，或走 `OS Login` / 其他相容登入路徑
4. 這台 VM 沒有刻意阻擋 project metadata SSH key

也就是說，**22 port 打開是必要條件，但不是唯一條件。**

如果只有 22 port 打開，卻沒有任何可接受的 SSH 身分路徑，那還是連不上。`gcloud compute ssh` 的厲害之處不只是發送 SSH 指令，而是它常常會幫你補齊「登入身分」這一層，例如：

- 自動產生預設 key pair
- 把公鑰寫進 project metadata
- 或在別的登入模型下幫你完成前置流程

所以這題更準確的口頭模型是：

> 不是「只要 22 port 打開就一定能靠 `gcloud compute ssh` 連上」，而是「若 22 port 可達，且 `gcloud` 有辦法幫你建立或補齊 SSH 身分路徑，那它常常可以把登入打通」。

## Q2：如果預設 `google_compute_engine` key 已經存在，後面還會再生嗎？還會不會再散播到 project metadata？

短答案：

- **通常不會再生新的 key pair**
- **但仍可能檢查、重用，甚至更新 metadata**

比較常見的行為是這樣：

1. `gcloud compute ssh` 先看 `~/.ssh/google_compute_engine` 和 `.pub` 在不在
2. 如果在，通常直接重用
3. 之後它再決定要不要把這把公鑰補進 metadata、刷新 metadata，或沿用已存在的設定

所以你的直覺大方向是對的：

- VM 刪掉重建後，若本機那組預設 key 還在，`gcloud` 大多不會再生成新一把
- 它比較可能直接沿用同一把 key

但「project metadata 已經改過了，所以它就一定完全不碰」這一點不能說死。原因是：

- 它可能還是會做一致性檢查
- 它可能要確認這個 key 仍存在於 metadata
- 若使用者、過期時間、格式或 metadata 狀態有差異，仍可能再更新一次

所以比較穩的說法是：

> 預設 key pair 建好後，`gcloud` 通常會重用它，不太會每次重生；但 metadata 是否完全不再變動，要看當下 project / instance 狀態與 `gcloud` 的判斷。

## Q3：project metadata 可以同時容納幾組 key？是唯一一組，還是可以共存？

短答案：**可以共存，不是一次只能有一組。**

你目前的猜測是對的。

在傳統的 project metadata SSH key 模型下，`ssh-keys` 不是一個只能放單筆值的欄位，而是可以包含**多行條目**。概念上可以長成這樣：

```text
kyo:ssh-ed25519 AAAA...
alice:ssh-ed25519 BBBB...
bob:ssh-rsa CCCC...
```

所以：

- 預設 `google_compute_engine` 對應的 key 可以存在
- 你自己 `~/.ssh/gcp` 對應的 key 也可以存在
- 它們可以同時存在 project metadata 裡

這不是「二選一」的模型。

比較要注意的是：

1. project metadata 有總大小限制，不是無限大
2. `gcloud` 可能會對同一個 user / 同一把 key 做更新或去重，不一定每次都純 append
3. 真正能不能登入，還要看 VM 是否繼承這份 project metadata，以及 guest environment 是否接受它

所以對這題最實用的結論是：

> project metadata 在概念上是可以同時容納多組 SSH key 的；它不是單值欄位，也不是一次只能留一組唯一 key。

## Q4：既然後來 raw ssh 也成功了，能不能說 Terraform 設定本來就有用？如果現在 project metadata 已被改過，還能怎麼驗證？

短答案分兩層：

### 先回答第一層：能不能說 Terraform 設定有用？

**可以說「很有可能有用，而且現在已有強證據支持它有用」；但若你要追求最嚴格的單一路徑證明，當前環境已經被污染。**

為什麼說已有強證據？

因為 Terraform 明確做了這些事：

1. 建立了 VM
2. 建立了 SSH firewall
3. VM 帶了 `allow-ssh` tag
4. instance metadata 寫了 `ssh-keys = kyo:...gcp.pub...`

而且後來 raw ssh 用 `~/.ssh/gcp` 也成功了。

這已經是很強的正向訊號。

但問題在於：你後來又跑了這條：

```bash
gcloud compute ssh kyo@free-tier-vm --zone us-east1-b --ssh-key-file=/Users/kyo/.ssh/gcp
```

這條指令本身又把 `~/.ssh/gcp` 對應的公鑰散播到 project metadata 了。

所以從那一刻開始，後面的 raw ssh 成功就有兩種可能來源：

1. Terraform 寫進的 instance metadata key 生效
2. `gcloud` 後來補進 project metadata 的同一把 key 生效

也就是說，**現在已經很難只靠這個環境的當前狀態，完美區分是哪一條路在起作用。**

### 再回答第二層：那現在還能怎麼驗證？

可以，但要刻意設計「去污染」或「隔離」的驗證。

比較乾淨的做法有幾種。

#### 做法 A：把 project metadata 對這把 key 的影響排除掉

例如：

- 移除 project metadata 中對應的 SSH key 條目
- 或讓 VM 不接受 project metadata SSH key

一個很典型的隔離做法，是在 VM metadata 裡加入：

```text
block-project-ssh-keys = true
```

這樣 VM 就只會接受它自己的 instance metadata key，不再接受 project metadata 那條路。

若這時 raw ssh 仍然成功，就很能證明 Terraform 的 instance metadata key path 是獨立成立的。

#### 做法 B：在全新、乾淨的 VM / project 上重做一次

這是最乾淨但成本較高的方法：

1. 建一台全新 VM
2. 不先跑 `gcloud compute ssh`
3. 只用 Terraform 寫入 instance metadata key
4. 然後直接 raw ssh 驗證

這樣就沒有 helper 污染問題。

#### 做法 C：用不同使用者名稱或不同 key 做對照

例如：

- Terraform instance metadata 只寫 `kyo-tf` 對應某把 key
- project metadata 不含 `kyo-tf`

然後只測 `kyo-tf` 這條路，歸因會更清楚。

## 這四題的最短版總結

1. **沒有 Terraform 先準備 key path 時，`gcloud compute ssh` 常常還是可能打通，但那仰賴它的 helper 行為，不是單靠 22 port 就保證成功。**
2. **`google_compute_engine` 預設 key pair 建立過後通常會被重用，不太會每次重生；但 metadata 仍可能被檢查或更新。**
3. **project metadata 可以同時容納多組 SSH key，不是一次只能有一組。**
4. **現在這個環境已經被 `gcloud` helper 污染過，所以不能再把 raw ssh 的成功 100% 單獨歸因於 Terraform instance metadata；若要嚴格驗證，要做隔離測試。**

## 如果要把這件事收斂成下一個可操作問題

下一個最有價值的驗證題，不是再重複登入，而是：

> 要不要做一個「阻斷 project metadata，只留 instance metadata」的隔離實驗？

若要做，最值得試的是：

1. 在 VM metadata 加 `block-project-ssh-keys = true`
2. 保留 Terraform 寫入的 `ssh-keys`
3. 再用 raw ssh 驗證一次

這會讓你對 instance metadata 與 project metadata 的差別真正建立非常穩的手感。
