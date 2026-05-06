# SSH Metadata 隔離實驗與依賴關係收斂

日期：2026-05-06

## 為什麼另外寫這份

前面幾份文件已經分別整理了：

1. 第一次 runtime SSH 成功時，`gcloud compute ssh` 與 Terraform key path 如何交錯
2. guest agent、instance metadata、project metadata 與 OS Login 的關係
3. 從頭設計 GCE Linux VM SSH 時，常見有哪些連線方式與路徑

但在 lesson 後半段，又多做了幾輪更具體的隔離實驗：

1. destroy / apply 後，直接用 `gcloud compute ssh kyo@free-tier-vm` 是否仍然成功
2. 拿掉 Terraform 的 instance metadata `ssh-keys` 後，`gcloud compute ssh` 是否仍然成功
3. 清掉 `known_hosts` 後，raw `ssh -i ~/.ssh/gcp` 是否仍然成功
4. project metadata 裡到底存不存在 `kyo` 的 SSH key

這些內容已經超出 lesson note 應保留的最小口頭模型，所以集中整理到這份文件。

## 實驗 1：destroy / apply 後，仍可直接用同一條 `gcloud compute ssh`

操作概念：

1. destroy 現有 VM
2. apply 重建一台新的同名 VM
3. 不手動查 external IP，直接執行 `gcloud compute ssh kyo@free-tier-vm`

觀察結果：成功。

這代表：

1. `gcloud compute ssh` 在日常操作上更依賴 instance name / project / zone 這條 control-plane 查找路徑，而不是你手上是否記得舊 IP。
2. destroy / apply 導致 external IP 改變，本身不會破壞這種 name-based 的登入入口。
3. 但這只證明 `gcloud compute ssh` 的操作入口穩定，不等於它證明了 Terraform 的 instance metadata key path 是唯一有效路徑。

## 實驗 2：移除 Terraform 的 instance metadata `ssh-keys` 後，`gcloud compute ssh` 仍成功

操作概念：

1. 在 Terraform 中暫時移除 VM 的 `metadata.ssh-keys`
2. 保留 SSH firewall、VM 名稱與其他 access prerequisite
3. destroy / apply 重建新的同名 VM
4. 執行 `gcloud compute ssh kyo@free-tier-vm`

觀察結果：仍成功登入。

這一步的強結論是：

> 對目前這個環境而言，Terraform 明寫的 instance metadata `ssh-keys` 並不是 `gcloud compute ssh` 成功的必要條件。

也就是說，先前看到 `gcloud compute ssh` 成功時，不能再把它直接解讀成「一定是因為 Terraform 寫了 instance metadata key」。

## 實驗 3：raw `ssh -i ~/.ssh/gcp` 一開始失敗，但原因其實不是 key path 本身

第一次 raw SSH：

```bash
ssh -i /Users/kyo/.ssh/gcp kyo@35.211.162.104
```

觀察結果：失敗，訊息為 `REMOTE HOST IDENTIFICATION HAS CHANGED!` / `Host key verification failed.`

這次失敗的真正意義是：

1. 本機 `known_hosts` 裡對該 IP 仍保留舊主機的 host key 記錄
2. destroy / apply 後，現在對應這個 IP 的主機 host key 已不同
3. SSH 在主機身分驗證這一步就先把連線擋下來了

因此這次失敗**不能直接拿來證明** Terraform 的 `ssh-keys` 有效或無效。

它卡住的層次是：

1. host key verification

而不是：

1. VM 是否接受 `~/.ssh/gcp` 這把 key
2. `kyo` 使用者是否存在
3. instance metadata / project metadata 哪一條路正在生效

## 實驗 4：清掉 `known_hosts` 後，raw `ssh -i ~/.ssh/gcp` 仍然成功

操作概念：

1. 先用 `ssh-keygen -R <IP>` 清掉本機舊的 host key 記錄
2. 再重新執行 `ssh -i /Users/kyo/.ssh/gcp kyo@35.211.162.104`

觀察結果：成功登入。

這一步代表：

1. 在目前這個環境裡，`~/.ssh/gcp` 這把 private key 仍然可以登入新的 VM
2. 但因為 Terraform 的 instance metadata `ssh-keys` 已經移除了，所以這次成功更不可能再被歸因給 instance metadata 那條路
3. 因此，raw SSH 的成功反而進一步支持：這把 key 很可能是經由別的來源被 VM 接受，而最可疑的來源就是 project metadata

## 實驗 5：直接檢查 project metadata，發現確實有兩條 `kyo` 的 key

執行查詢：

```bash
gcloud compute project-info describe --format="value(commonInstanceMetadata.items.ssh-keys)"
```

觀察結果：project metadata 目前確實有兩條屬於 `kyo` 的 `ssh-keys` 條目。

這一步的意義非常關鍵，因為它把先前的推測變成更硬的事實：

1. `kyo` 的 SSH identity 不只是「可能存在於 project metadata」
2. 而是「現在確實存在於 project metadata」

也就是說，目前環境裡至少已有一條 project-level 的 `kyo` 登入來源。

## 目前最合理的完整解釋

把幾輪觀察合在一起，現在最合理的完整模型是：

1. 先前某次 `gcloud compute ssh` 或 `gcloud compute ssh --ssh-key-file=/Users/kyo/.ssh/gcp` 已把 `kyo` 的 key 寫進 project metadata。
2. 後續即使 Terraform 拿掉了 VM 自己的 instance metadata `ssh-keys`，新的同名 VM 仍會繼承 project metadata。
3. VM 內的 guest agent 會根據 project metadata 裡的 `kyo` key，建立或管理 `kyo` 的本機登入能力。
4. 因此：
   - `gcloud compute ssh kyo@free-tier-vm` 仍可成功
   - `ssh -i /Users/kyo/.ssh/gcp kyo@...` 在排除 `known_hosts` 阻礙後，也仍可成功

## 這組實驗真正證明了什麼

到這裡為止，可以比較有把握地說：

1. **Terraform 的 instance metadata `ssh-keys` 不是目前這個環境中唯一、也不是必要的 `kyo` 登入來源。**
2. **project metadata 這條路已經足夠強，足以讓新重建的 VM 在沒有 Terraform instance metadata key 的情況下，仍接受 `kyo` 的 SSH key。**
3. **只要 project metadata 還沒被清掉，後續任何 SSH 成功事件，都不應再直接歸因給 Terraform 的 instance metadata key path。**

## 這不代表 Terraform 的 `ssh-keys` 沒意義

要特別避免一個過度收斂：

> 既然 project metadata 也能讓 SSH 成功，那 Terraform 的 instance metadata `ssh-keys` 就沒意義。

這個說法不準。

更準確的是：

1. Terraform 的 instance metadata `ssh-keys` 仍然有意義，因為它代表一條可被 IaC 明示、可被單機控制、可被隔離驗證的登入路徑。
2. 只是目前這個環境已經被 project metadata 補強過，所以那條路徑不再是唯一可觀察來源。

## 如果還要再做更嚴格的下一步

若要把歸因再切得更乾淨，下一步不該再重複 SSH，而應改做以下其中一種：

1. 清掉 project metadata 裡的 `ssh-keys` 條目，再重新驗證
2. 在 VM 上明確阻斷 project metadata key，例如 `block-project-ssh-keys = true`
3. 用全新的 username / key 做對照，避免舊的 project metadata 污染

但對這次 lesson 來說，做到這一步其實已經足夠把依賴關係講清楚。

## 一句話版本

> 這組後續實驗證明：在目前這個環境中，`gcloud` 先前留下的 project metadata SSH key 已經足以讓新重建的 VM 接受 `kyo` 的登入，所以一旦 project metadata 存在，Terraform 的 instance metadata `ssh-keys` 就不再是唯一可觀察的成功來源；若不先清 project metadata，就不能再把後續 SSH 成功直接歸因給 Terraform 的單機 metadata 路徑。

## 延伸推論：如果一開始就是全新環境，project metadata 也是空的，會怎麼發展

基於前面的觀察，還可以做一個相當合理的延伸推論。

假設現在有一個全新的環境：

1. project metadata 裡還沒有任何 `ssh-keys`
2. Terraform 建出一台新的 Linux VM
3. 這台 VM 沒有 instance metadata `ssh-keys`
4. VM 仍採 metadata-based SSH，沒有改成 OS Login，也沒有阻斷 project metadata key

在這種情況下，第一次使用 `gcloud compute ssh` 去連這台 VM 時，在常見路徑下很可能會發生下面的事：

1. `gcloud` 檢查本機預設 SSH key
2. 如果沒有，就生成一把新的 key
3. `gcloud` 把對應 public key 寫進 project metadata
4. 這台 VM 透過 project metadata 接受這把 key，完成第一次登入

若這條路成立，後面就會出現一個很實務的效果：

1. project metadata 裡已經有可用的 SSH key
2. 同 project 下後續新建的 VM，只要也繼承 project metadata，而且沒有阻斷這條路，就可能直接接受同一把 key

也就是說，**project metadata 裡的 SSH key 很可能會從「打通第一台 VM 的臨時登入條件」，演變成「同 project 多台 VM 的共用登入來源」。**

這個推論跟本次實驗結果是相容的，因為我們已經在現有環境裡實際看到：

1. `gcloud compute ssh` 可以在沒有 Terraform instance metadata `ssh-keys` 的情況下成功
2. project metadata 裡確實已有 `kyo` 的 SSH key
3. 新重建的 VM 仍會接受那把 key

因此，若把情境換成「從零開始」，最合理的模型就是：

> 第一次 `gcloud compute ssh` 很可能會把 key 寫進 project metadata；而一旦 project metadata 裡有了這把 key，後續同 project 的新 VM 只要繼承這份 metadata，就也可能直接接受同一把 key。

### 這不代表一定 100% 如此

這個推論雖然合理，但仍然有幾個成立前提：

1. VM 必須走 metadata-based SSH，不是 OS Login
2. VM 不能阻斷 project metadata key
3. guest agent 要正常
4. 你的 GCP 身分要有權限讓 `gcloud` 更新 project metadata
5. network path 與 SSH firewall 必須正常

所以更準確的講法不是「project metadata 一定會自動變成共用登入來源」，而是：

> 在常見設定下，它很容易發展成共用登入來源。

## 實務上該怎麼選：project metadata 還是 instance metadata

從這組實驗可以再往前推一個更實務的問題：

> 如果 project metadata 這麼強，那在實務上到底該選 project metadata，還是 instance metadata？

最短的答案是：

1. 要方便、想同 project 多台 VM 共用登入來源，偏向 project metadata
2. 要邊界清楚、可歸因、可被 IaC 單機控制，偏向 instance metadata
3. 若是正式多人環境，通常會再往 OS Login 走

### 什麼情況比較適合 project metadata

project metadata 比較適合下面這些情境：

1. 單人或少數人操作
2. 同一個 project 會反覆建立很多台短命 VM
3. 你想要一把 key 直接用在多台機器
4. 你不想每台 VM 都各自配置一次 `ssh-keys`

它的優點是：

1. 一次寫入，多台 VM 可共用
2. 新 VM 起來之後很可能直接可登入
3. 跟 `gcloud compute ssh` 的自動化體驗很搭
4. 對頻繁 destroy / apply 的個人測試流程很順手

但代價也很明顯：

1. 影響範圍大
2. 很容易污染驗證
3. 不容易回答「到底是哪台 VM 自己接受了這把 key」
4. 不小心就會讓同 project 的其他 VM 一起受影響

所以 project metadata 更像是：

> 共用入口

### 什麼情況比較適合 instance metadata

instance metadata 比較適合下面這些情境：

1. 你想讓某台 VM 的登入路徑被明確寫在 IaC 裡
2. 你想做單機級別的可歸因驗證
3. 你不希望同 project 的其他 VM 自動繼承這把 key
4. 你想把 access path 跟該 VM 的生命週期綁在一起

它的優點是：

1. 邊界清楚
2. 最適合 lesson、debug、面試說明
3. 最容易回答「這台 VM 為什麼能登入」
4. 單機刪掉就一起消失，比較符合最小權限思路

但它的代價是：

1. 比較麻煩
2. 每台 VM 都要個別處理
3. 反覆建很多短命 VM 時，維護成本較高
4. 不像 project metadata 那樣一次設好就能共用很多台

所以 instance metadata 更像是：

> 單機入口

### 如果是正式環境，通常不會停在這裡

若是正式多人環境，通常不會長期把治理重心放在 metadata key 上，因為：

1. key 分散管理不易 audit
2. 權限回收較麻煩
3. 很難和 IAM 權限模型整合
4. 使用者一多就容易失控

所以正式環境通常會再往 OS Login 走，因為：

1. 可以用 IAM 管誰能登入
2. 權限生命周期比較清楚
3. 多人協作比較合理
4. audit、回收、治理都比較好做

### 這次 lesson 情境下的實際建議

如果回到這次 lesson 的情境：

1. 個人使用
2. 常常 destroy / apply
3. 同一個 project 反覆建立短命 VM
4. 比較在意操作順手

那 project metadata 其實很好用，而且很符合這種操作習慣。

但如果你的目標是：

1. 驗證 Terraform 到底保證了什麼
2. 把成功路徑講清楚
3. 做乾淨的 lesson / debug / interview 收斂

那就一定要把 project metadata 和 instance metadata 分開看，否則環境很快就會被共用路徑污染。

### 一句話收斂

> 要方便，選 project metadata；要邊界清楚，選 instance metadata；要正式治理，選 OS Login。
