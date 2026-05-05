# 2026-05-05 Terraform GCP Free Tier VM Minimum Apply Report

## 今日主題

用 Terraform 在 GCP 上完成一版符合 Free Tier 邊界的最小 VM 練習，並留下可驗收的 IaC workflow 證據。

## 狀態

已完成。今天已走完整個最小 Terraform IaC workflow：preflight gate、`.tf` 骨架、`plan`、`apply`、post-apply 檢查、state 閱讀，以及最後的 `destroy`。

## QA 收斂了什麼

- 今天最先要分清楚的，不是 HCL 寫得對不對，而是 Terraform CLI、gcloud auth、project、billing、API 這些 preflight gate 是否已經通過。
- 第一版 Terraform 骨架先收斂成 provider、variables、compute instance、必要 firewall 與 outputs，是因為今天的目標是留下最小可驗證 IaC workflow 證據，不是一次展開完整網路或 IAM 設計。
- 用來證明這台 VM 沒偏離 Free Tier 邊界的最小證據，至少包含：`machine_type = e2-micro`、`zone = us-east1-b`、disk `size = 25` / `type = pd-standard`、external network tier `STANDARD`，以及 apply 後真的拿到 external IP。
- 也已能用自己的話區分 HCL、plan、apply、state 四者的角色：HCL 是目標狀態宣告，plan 是差異預覽，apply 是執行變更，state 則是 Terraform 用來記錄真實資源狀態與資源對應關係的依據。

## 使用者原本卡住什麼

- 一開始卡在平台與工具層，不是卡在 HCL：本機沒有 Terraform / gcloud，gcloud 也還沒登入。
- project 選擇也不是直線成功：一個 project 有服務條款申訴風險，另一個 project 因 billing 不存在而無法啟用 Compute Engine API，最後才收斂到可用 project。
- 進到 Terraform 後，還額外踩到兩種典型操作卡點：一次是在錯誤目錄執行 `terraform plan`，導致 `No configuration files`；另一次則驗證到必要 variable 若沒先提供，Terraform 會在互動模式下要求手動補值。

## 今日真正留下來的核心收穫

- 你不只看到 Terraform 設定怎麼寫，還真的把一台 Free Tier 邊界內的 GCP VM 建起來，再完整銷毀一次，留下了從宣告到回收的閉環經驗。
- 你把 `plan`、`apply`、`state` 三者的角色明確分開了：HCL 是想要的樣子，plan 是 Terraform 打算怎麼做，state 是 Terraform 目前認為雲端已經長成什麼樣子。
- 你也驗證了兩層不同的真實性：先用 `gcloud` 看 post-apply 資源是否真的存在，再用 `terraform state show` 看 Terraform 如何記錄這些真實資源。
- 對 Terraform 操作面來說，今天另外留下兩個很實用的感覺：互動式 variable 補值在手動練習時很方便，但不適合自動化；destroy 畫面中的 `-> null` 可以直接理解成該資源與相關 output 即將被移除。

## 學完後已能講清楚什麼

- 可以講清楚這個 repo 目前 HCL 的使用範圍，只集中在 `terraform/gcp-free-tier-vm/` 這包 Terraform 練習，而不是整個 infra repo 都用 HCL。
- 可以講清楚 `versions.tf`、`provider.tf`、`variables.tf`、`main.tf`、`outputs.tf` 各自的角色，以及值如何從 variable 流進 provider、resource，再流到 output。
- 可以講清楚為什麼 `output "project_id"` 會出現在 plan / apply / state 裡，以及這和「會不會被 commit」是兩件不同的事。
- 可以講清楚 `terraform plan` 最後那句關於 `-out` 的 note 在提醒什麼，也能解釋為什麼不用 `-out` 時，`apply` 會重新計算一次。
- 可以講清楚第一次讀 state 時不要逐欄硬看，而是先分成 HCL 宣告值、雲端回填值、Terraform 識別欄位三類來讀。

## 仍待補強什麼

- 今天的練習仍停在本地 state，還沒有進入 remote state、state locking、多人協作與 state 安全策略。
- 這份骨架仍是單資源、單目錄、單環境版本，還沒有進入 module 化、環境拆分、workspace 或 reusable pattern 設計。
- 今天也刻意沒有展開 network / IAM / service account 的 production-grade 設計，因此之後若要轉進面試或實戰，還需要把「最小版本」和「正式版本」的邊界再講得更清楚。

## 下一步

- 若只看今天 lesson 本身，這次最小 Terraform IaC workflow 已完整收尾。
- 下一個自然延伸主題，會是把今天的本地單人練習往更真實的 Terraform 協作面推進，例如 remote state、state locking、變數供應策略與自動化環境差異。
- 若維持 Phase 2 的 interview / debug 導向，也可以把今天這次完整流程改寫成更短的面試回答版本，練習在 1 到 2 分鐘內講清楚你到底做了什麼、怎麼驗證、卡在哪裡、怎麼收斂。
