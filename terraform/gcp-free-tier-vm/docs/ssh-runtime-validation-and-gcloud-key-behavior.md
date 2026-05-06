# SSH 執行階段驗證與 gcloud 金鑰行為

日期：2026-05-06

## 為什麼寫這份筆記

在 W9 第三天的執行階段驗證過程中，SSH 登入成功了，但實際成功的路徑比原本 Terraform 設計的更微妙。

Terraform 套件明確配置了：

- TCP `22` 的 SSH 防火牆存取規則
- VM 標籤 `allow-ssh`
- instance metadata `ssh-keys = username:public_key`

然而，第一次成功的執行階段登入使用的是 `gcloud compute ssh kyo@free-tier-vm`，沒有加 `--ssh-key-file`。

這個細節很重要，因為 `gcloud compute ssh` 有它自己預設的 SSH 金鑰行為。

## 實際發生了什麼

觀察到的終端機輸出顯示這個順序：

1. 第一次呼叫 `gcloud compute ssh` 時沒有指定 instance 名稱，因使用方式錯誤而失敗。
2. 接著以 `gcloud compute ssh kyo@free-tier-vm` 呼叫。
3. `gcloud` 注意到它的預設金鑰對不存在：
   - `/Users/kyo/.ssh/google_compute_engine`
   - `/Users/kyo/.ssh/google_compute_engine.pub`
4. `gcloud` 在本地端生成了一組新的 RSA 金鑰對。
5. `gcloud` 印出 `Updating project ssh metadata...done.`
6. 金鑰傳播完成後，SSH 登入成功。

這表示第一次成功的登入並不是乾淨地證明 Terraform 管理的 `~/.ssh/gcp.pub` instance metadata 路徑是唯一有效的路徑。

它證明的是稍微不同的事情：

- TCP `22` 的網路可達性正常
- VM 接受 SSH 登入
- project 層級的 SSH metadata 路徑也有效
- `gcloud compute ssh` 可以成功引導它自己的預設金鑰路徑

## 為什麼 gcloud 生成了新金鑰

`gcloud compute ssh` 使用預設的 SSH 金鑰位置，除非你告訴它用別的。

預設情況下，它預期：

- 私鑰：`~/.ssh/google_compute_engine`
- 公鑰：`~/.ssh/google_compute_engine.pub`

如果這些檔案不存在，`gcloud` 會自動生成它們。

所以新建立的金鑰對並不代表 Terraform 被忽略了。

它代表的是這次特定的執行階段驗證指令使用了 `gcloud` 預設的 SSH 身份路徑，而不是之前準備好的 `~/.ssh/gcp` 金鑰對。

## 為什麼登入還是成功了

輸出中的關鍵行是：

`Updating project ssh metadata...done.`

這告訴我們 `gcloud` 在 **project metadata** 層級上傳或更新了 SSH 公鑰。

因為 VM 能夠繼承並使用該 project 層級的 SSH metadata，登入在傳播後就成功了。

換句話說，成功的路徑實際上是：

1. `gcloud compute ssh` 生成了 `google_compute_engine` 金鑰對
2. `gcloud` 將公鑰推送到 project SSH metadata
3. VM 繼承或接受了 project metadata SSH 金鑰
4. SSH 登入使用新的本地私鑰成功

## Terraform 在這次登入之前已經保證了什麼

在 `gcloud compute ssh` 指令之前，Terraform 已經保證了這些事情：

1. VM 存在
2. VM 有外部 IP
3. 明確的防火牆規則允許 TCP `22`
4. VM 帶有與該防火牆規則匹配的 `allow-ssh` 標籤
5. instance metadata 已經包含了所選使用者名稱和公鑰的明確 `ssh-keys` 條目

所以 Terraform 已經建立了一個有效的 SSH 存取設計。

但使用者選擇的執行階段指令透過 project metadata 引入了**第二條有效的登入路徑**。

## 這次執行階段驗證真正證明了什麼

成功的 SSH session 證明了：

- VM 從網路上可達
- SSH daemon 和 guest environment 正常運作
- 防火牆規則有效
- 至少有一條 SSH 身份路徑端對端運作正常

它**沒有**單獨證明這個更窄的主張：

- 「登入成功是因為使用了 Terraform 管理的 instance metadata 金鑰 `~/.ssh/gcp.pub`」

這個更窄的主張仍然需要更受控的驗證指令。

## 如何專門驗證 Terraform 管理的金鑰路徑

如果目標是證明 Terraform 配置的 instance metadata 金鑰路徑有效，使用以下受控方法之一。

### 選項 1：告訴 gcloud 使用哪個金鑰

```bash
gcloud compute ssh kyo@free-tier-vm --zone us-east1-b --ssh-key-file=/Users/kyo/.ssh/gcp
```

這保持了 `gcloud compute ssh` 的工作流程，但將它指向預期的金鑰對。

### 選項 2：對外部 IP 使用原生 ssh

```bash
ssh -i /Users/kyo/.ssh/gcp kyo@35.211.162.104
```

這對於隔離金鑰路徑更乾淨，因為它移除了 `gcloud` 的一些輔助行為。

## 這次事件中的 Instance metadata vs project metadata

這次事件很好地展示了兩者的差異：

- **instance metadata**：Terraform 明確將 `ssh-keys` 寫入這個 VM 自己的 metadata
- **project metadata**：`gcloud compute ssh` 在執行階段更新了 project 層級的 SSH metadata

因為兩者都可能被 VM 的登入模型接受，成功的 SSH session 可能發生而無法證明哪一個是決定性的，除非測試是受控的。

## 實用的學習重點

主要的學習重點不是「Terraform 失敗了」或「Terraform 無關緊要」。

更準確的結論是：

- Terraform 成功建立了一個具備 SSH 能力的 VM 存取路徑
- 第一次執行階段驗證使用了 `gcloud` 的預設金鑰管理行為
- 因此執行階段的成功證明了 SSH 可達性和可用性，但尚未證明專門使用了 Terraform 管理的金鑰路徑

## 面試用精簡版

你可以這樣解釋：

> 我用 Terraform 建立了 VM、SSH 防火牆規則和 instance metadata SSH 金鑰路徑。但當我第一次執行 `gcloud compute ssh` 而沒有指定 `--ssh-key-file` 時，`gcloud` 生成了它自己的預設金鑰對並更新了 project SSH metadata。所以那次成功的登入證明了 VM 可達且 SSH 正常運作，但它沒有將 Terraform 管理的 instance metadata 金鑰隔離為唯一有效的登入路徑。要證明這個更窄的論點，我會用明確指定的預期金鑰重新執行 SSH。

## 追加驗證結果（2026-05-06）

在第一次成功登入之後，又做了兩次更受控的 SSH 驗證，結果都成功。

### 驗證 A：指定 `gcp` key 的 `gcloud compute ssh`

執行指令：

```bash
gcloud compute ssh kyo@free-tier-vm --zone us-east1-b --ssh-key-file=/Users/kyo/.ssh/gcp
```

觀察到的重點：

1. 登入成功。
2. `gcloud` 仍然顯示 `Updating project ssh metadata...done.`。
3. 代表即使這次明確指定了 `~/.ssh/gcp`，`gcloud compute ssh` 仍然可能沿用它的 helper 行為，把指定公鑰更新到 project metadata，再等待傳播後登入。

這次驗證證明了兩件事：

- 指定的 `~/.ssh/gcp` key pair 本身可用。
- 但這條路徑仍然混有 `gcloud` 的 project metadata 更新行為，所以它比第一次更接近 Terraform 管理的 key path，卻還不是最乾淨的隔離驗證。

### 驗證 B：直接對 external IP 使用原生 `ssh`

執行指令：

```bash
ssh -i /Users/kyo/.ssh/gcp kyo@35.211.162.104
```

觀察到的重點：

1. 首次連線時出現 host authenticity 提示，加入 `known_hosts` 後登入成功。
2. 這次沒有 `gcloud` 幫忙生成金鑰。
3. 這次也沒有 `gcloud` 幫忙更新 project metadata。

這是目前最乾淨、最有說服力的一次驗證，因為它更直接地證明：

- Terraform 建出的 VM 與 SSH firewall 已經可用。
- VM 真的接受 `~/.ssh/gcp` 對應的登入身分。
- 這條登入成功不需要依賴 `gcloud compute ssh` 的額外 helper 行為。

換句話說，到這一步為止，已經有足夠強的證據支持：Terraform 寫進 VM 的 SSH 存取設計確實成立，而且 `~/.ssh/gcp` 這條路徑也確實可用。

## 本次環境下的可行連線方式盤點

以下整理的是「在這次實作結果與目前環境狀態下」可行或已驗證的連線方式。

### 1. `gcloud compute ssh` 使用預設 `google_compute_engine` key

範例：

```bash
gcloud compute ssh kyo@free-tier-vm
```

狀態：已驗證成功。

說明：

- 若 `~/.ssh/google_compute_engine` 不存在，`gcloud` 會自動生成。
- `gcloud` 也可能自動更新 project SSH metadata。
- 這條路徑最方便，但最容易混入 `gcloud` 的 helper 行為，因此不適合拿來單獨證明 Terraform 管理的 key path。

### 2. `gcloud compute ssh` 明確指定 `~/.ssh/gcp`

範例：

```bash
gcloud compute ssh kyo@free-tier-vm --zone us-east1-b --ssh-key-file=/Users/kyo/.ssh/gcp
```

狀態：已驗證成功。

說明：

- 這條路徑比預設 key 更接近 Terraform 原本設計的登入方案。
- 但從輸出可見，`gcloud` 仍可能更新 project metadata，所以它仍不是完全排除 helper 行為的驗證。

### 3. 原生 `ssh` 直接指定 `~/.ssh/gcp`

範例：

```bash
ssh -i /Users/kyo/.ssh/gcp kyo@35.211.162.104
```

狀態：已驗證成功。

說明：

- 這是目前最乾淨的驗證方式。
- 它直接使用 external IP、指定 private key，沒有 `gcloud` 幫忙生成新 key，也沒有 `gcloud` 幫忙補 metadata。
- 因此這條路徑最能證明 Terraform 配置出來的 SSH 存取路徑本身可用。

### 4. 原生 `ssh` 直接指定 `google_compute_engine`

範例：

```bash
ssh -i /Users/kyo/.ssh/google_compute_engine kyo@35.211.162.104
```

狀態：理論上可行，但本次未單獨驗證。

說明：

- 既然第一次 `gcloud compute ssh` 已把這把 key 推到 project metadata，若 project metadata 仍生效，這條路理論上也應該可用。
- 但因為本次沒有獨立執行，所以應標示為「推定可行」，不是「已驗證成功」。

## 到目前為止最準確的收斂

現在可以把這次實作的 SSH 結論壓成三句話：

1. Terraform 建出的 VM、SSH firewall、tag 與 metadata 設計本身是可工作的。
2. `gcloud compute ssh` 會引入它自己的 key 管理與 project metadata helper 行為，所以第一次成功登入不能直接當成單一路徑證明。
3. 在補做 `ssh -i /Users/kyo/.ssh/gcp ...` 之後，已經有足夠證據證明 Terraform 管理的 `~/.ssh/gcp` 這條 key path 本身也能成功登入。
