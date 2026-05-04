# 2026-05-04 Terraform State and Declarative Model Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天先做 repo-backed 對照與短版驗收，不進 GCP 實作。
- `terraform/` 目前代表 Terraform 能力與可執行資產，不等於現行 WeaMind cluster 的 deploy source。
- 比較 Terraform 與 Kubernetes 時，先抓 `state`、reconcile 與 lifecycle，不要退化成語法比較。

## Notes

### Terraform 常見控制的資源範圍

- Terraform 不只用來開 VM。VM 只是最常見的入門案例之一。
- 最常見的第一層資源包括：VM / instance、network / VPC、subnet、firewall / security group、static IP、load balancer、DNS record、storage bucket、database instance。
- 再往上一層，Terraform 也常拿來控制 IAM、service account、secret manager 類資源、monitoring / alerting 資源，甚至部分 Kubernetes 物件或 SaaS 設定。
- 也就是說，Terraform 的常見範疇可以粗分成三類：
	- compute 與基礎網路
	- 雲端平台配套資源
	- 權限、整合與部分平台設定
- 對這個 repo 當前的 W9 來說，先聚焦在最小 compute 練習，也就是 GCP Free Tier VM，因為這最容易把 `provider`、`resource`、`state`、`plan` / `apply` 跑通。
- 若未來這個 repo 真的要把 Terraform 用到長期 infra，最可能先碰到的也不會只有 VM，而是 worker、network、load balancer、DNS、甚至 cluster 外圍基礎資源一起出現。

### 一句話收斂

- Terraform 的範圍不是「伺服器建立工具」，而是跨雲端與平台的基礎設施宣告工具；VM 只是其中最常見、也最容易拿來做第一個練習的資源。

### Terraform 能控制到哪裡，真正受限於什麼

- 不是只要某家雲端「理論上有這個資源」，Terraform 就一定能完整控制它。
- 真正的上限通常同時受三層限制：
	- **provider 背後是否有穩定 API**：如果目標平台根本沒有公開或可自動化的 API，Terraform 就很難管理。
	- **Terraform provider 有沒有把這些 API 做成可用的 resource / data source**：就算平台有 API，若 provider 沒實作、實作不完整，或只支援部分欄位，也不能完整管理。
	- **這個資源是否適合被宣告式描述**：有些東西 technically 可呼叫 API，但 lifecycle 太互動式、太即時、或狀態模型太混亂，就不一定適合用 Terraform 當主工具。
- 所以你剛剛的直覺其實是對的，但要修正成更完整的版本：**上限不是只受 HCL 描述能力限制，也不是只受雲端 API 限制，而是同時受目標平台 API、provider 實作品質，以及資源本身是否適合宣告式管理這三層一起限制。**
- HCL 本身比較像表達語言；真正決定「能不能管、能管到多細」的主因，通常是 provider 的 schema 與它背後接到的 API 能力。
