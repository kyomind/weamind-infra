# 2026-05-06 Terraform Drift SSH Boundary Report

## 今日主題

- 以 implement-heavy 方式補齊 `terraform/gcp-free-tier-vm/` 的最小 SSH access path，並用後續隔離實驗切清楚 instance metadata、project metadata 與 `gcloud compute ssh` 之間的依賴關係。

## 狀態

- 已完成主要驗收

## QA 收斂了什麼

- `terraform validate`、`terraform plan`、`terraform apply` 與多輪 runtime SSH 驗證都已完成，表示最小 access path 已落成可用閉環。
- 已能把 SSH 成功事件拆成不同層次來看：network path、identity source、guest agent 的本機帳號佈建，以及 client entry method。
- 已釐清 `gcloud compute ssh` 成功不等於 Terraform 的 instance metadata `ssh-keys` 一定在發揮作用。
- 已透過後續實驗確認：目前環境中 project metadata 裡確實已有 `kyo` 的 SSH key，足以支撐新 VM 的登入。

## 使用者原本卡住什麼

- 原本 Terraform 只把 VM 與 HTTP/HTTPS firewall 建起來，沒有把 SSH access prerequisite 明確寫進 IaC，因此無法說清楚 SSH 成功到底是 IaC 保證，還是 project 預設剛好幫忙。
- 一開始也把 `gcloud compute ssh`、instance metadata、project metadata 與 OS Login 混成同一層，很難精準回答「這次登入到底成功在哪一條路」。

## 今日真正留下來的核心收穫

- 已把最小 SSH access path 補成明確 Terraform 規格：`allow-ssh` tag、SSH firewall、可調整的 `ssh_source_ranges`。
- 已成功用 Terraform 的 instance metadata `ssh-keys` 建立一條可被 IaC 明示的單機登入路徑。
- 但後續隔離實驗也證明：在目前這個環境裡，project metadata 這條路已經足夠強，會蓋過對 instance metadata 的單獨觀察。
- 因此，今天真正學到的不只是「SSH 可以連」，而是「同一個 SSH 成功事件背後可能有不同的 identity path，必須分開歸因」。

## 學完後已能講清楚什麼

- 為什麼 `terraform validate`、`plan`、`apply` 與 runtime 驗證各自回答不同問題。
- 為什麼 SSH firewall / tag 屬於 network layer，而 `ssh-keys`、project metadata、OS Login 屬於 identity / access model 層。
- 為什麼 `gcloud compute ssh` 比 raw `ssh` 更方便，但也更容易混入 helper 行為，讓驗證失去單一路徑歸因。
- 為什麼 destroy / apply 後名稱不變時，`gcloud compute ssh kyo@free-tier-vm` 仍可用；它依賴的是 name-based control-plane 查找，而不是固定 IP。
- 為什麼在目前環境裡，移除 Terraform 的 instance metadata `ssh-keys` 後，SSH 仍然成功：因為 project metadata 已存在 `kyo` 的 key，guest agent 仍可據此建立登入能力。

## 仍待補強什麼

- 目前還沒有做最嚴格的純化驗證；若要把 instance metadata 與 project metadata 完全分開，下一步應改成清 project metadata 或阻斷 project metadata key。
- 還沒把今天的 access path 收斂成正式環境的長期治理方案；若未來要走多人或長期維運，應再比較 OS Login、project metadata 與 instance metadata 的治理取向。
- access / bootstrap 邊界雖已開始收斂，但還沒延伸到完整的主機初始化與長期配置管理。

## 下一步

- 若只以今天 lesson 為界，這裡已足夠收尾，可進 QA 或口頭複述。
- 若要繼續做更嚴格隔離驗證，下一步應改做 project metadata 層的實驗，而不是再重複 instance metadata 移除。
- 若要回到工程主軸，可再把今天的學習收斂成「project metadata 與 instance metadata 在實務上怎麼選」的短版結論。
