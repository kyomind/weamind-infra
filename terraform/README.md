# Terraform

這個目錄放的是 Terraform 相關資產。

它的定位不是單純的參考文件區，而是讓這個 repo 明確表達：除了 Kubernetes manifests 與操作文件之外，這個專案也會用 Terraform 管理或練習基礎設施宣告。

## 目錄邊界

- 這裡放可執行的 Terraform 設定、對應的操作說明，以及未來可能成為正式 infra 一部分的 Terraform 資產。
- 這裡不放純學習筆記；純規格、驗收邊界與 lesson 相關內容，仍應留在 `references/` 與 `learning/`。
- 這裡也不等於目前的 Kubernetes deploy source；現階段正式部署 WeaMind 到 cluster 的來源仍是 `manifests/`。

## 目前內容

- `gcp-free-tier-vm/`：Phase 2 W9 的最小 Terraform 練習，目標是用 Terraform 建出一台符合 Free Tier 條件的 GCP VM。
- `gcp-e2-micro-tw/`：台灣區低成本 `e2-micro` VM 練習，目標是用 Terraform 建出一台付費區域 VM，並刻意關閉監控 agent 與自動備份相關擴張。

## 未來方向

若之後這個 repo 真的開始用 Terraform 管理較長期的基礎設施，例如 worker 節點、網路或 cluster 外圍資源，相關設定可以直接放在這個目錄底下，而不需要另外再開新的總類別。

一句話原則：`terraform/` 代表這個 repo 的 Terraform 能力與資產；`references/` 與 `learning/` 則負責解釋它們。
