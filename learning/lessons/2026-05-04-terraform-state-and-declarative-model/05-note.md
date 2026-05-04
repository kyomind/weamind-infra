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

### 命題 1：Terraform 在 `plan` 時，怎麼把 `state`、config 和 real world 對起來？

- 短版解答：Terraform 不會只看本地 `.tf` 檔，也不會只看 `state`。它會把 **config、state，以及 provider 從真實平台查回來的現況** 一起拿來比對，最後算出 diff。
- `state` 提供的是「這個 resource 對應到真實世界裡哪一個對象」；provider 查到的現況則提供「這個對象現在變成什麼樣子」；config 則提供「我現在想要它變成什麼樣子」。
- 也因為這樣，`plan` 的本質不是單純讀設定檔，而是一次 **以 state 為定位、以 provider 為觀察、以 config 為目標** 的變更決策。
- 這也是為什麼看到 unexpected diff 時，不能只怪 `.tf` 寫錯，也要懷疑 real world 是否被手動改過，或 provider 查回來的狀態和想像不同。

### 什麼是 refresh？

- 短版解答：`refresh` 可以先理解成 Terraform 在做變更判斷前，**重新去看真實世界現在長什麼樣子**。
- 它不是只拿本地 config 和舊 `state` 硬比，而是會透過 provider 重新讀取真實資源狀態，讓 Terraform 知道現在 real world 和自己原本記得的狀態有沒有落差。
- 所以在心智模型上，可以先把三者這樣分：
	- `state`：這個 resource 對應的是誰
	- `refresh`：這個對象現在實際變成什麼樣子
	- `config`：我希望它最後變成什麼樣子
- 也因為有這一步，Terraform 才比較有機會在 `plan` 階段看見 drift、unexpected diff 或其他和真實世界脫鉤的地方。
- 一句話收斂：**`refresh` 是 Terraform 在規劃變更前，透過 provider 重新讀取真實資源狀態的觀察步驟。**

### 什麼是 unexpected diff，常見情況有哪些？

- 短版解答：`unexpected diff` 指的是你在跑 `terraform plan` 時，看到了**原本沒預期會出現的變更**。也就是說，你以為 config、state 和 real world 應該已經對齊了，但 Terraform 還是算出差異。
- 它不一定代表 Terraform 壞掉，也不一定代表 `.tf` 一定寫錯；更常見的是三者之間有某一層其實沒有你想像中那麼一致。
- 常見情況通常有幾類：
	- **real world 被手動改過**：例如在雲端 console 直接改了 VM、disk、tag、firewall 等設定
	- **state 已經舊了或和現況脫鉤**：Terraform 還以為資源長這樣，但真實世界已經變了
	- **provider 讀回來的值和你以為的不一樣**：有些欄位會被 API 正規化、補預設值，或回傳形式和設定檔不完全一樣
	- **某些欄位本來就不是穩定可比的值**：例如時間戳、順序、平台自動補出的 metadata，可能讓 diff 看起來一直存在
	- **resource schema 或 provider 版本變動**：升級 provider 後，某些欄位的行為、預設值或 diff 規則改了
- 所以看到 unexpected diff 時，第一步不是立刻改 `.tf`，而是先問三件事：
	- 是不是 real world 被手動改過？
	- 是不是 provider 讀回來的狀態和我想像不同？
	- 這個欄位到底是 in-place change、replacement，還是其實只是雜訊？

### 命題 2：什麼情況 Terraform 會 in-place update，什麼情況會 recreate？

- 短版解答：這不只看 Terraform 本身，而是看 **provider 對那個 resource schema 的定義**。有些欄位允許原地修改，有些欄位一改就會被視為必須重建。
- 所以 `state` 很重要，但有 `state` 不代表所有變更都能安全 update。`state` 只能幫你先定位到對象；真正是 update 還是 recreate，**仍要看該 resource 的 lifecycle 規則**。
- 這也是為什麼明天看 `terraform plan` 時，除了看有沒有 diff，還要看 **diff 對應的是 in-place change 還是 replacement**。
- 若這一層沒意識到，就很容易把「Terraform 有看懂這個資源是誰」和「Terraform 一定能原地修改它」誤當成同一件事。

## Flashcards

- Terraform 的 `state` 為什麼不是單純 cache？ #DevOps #card
	- 它的核心角色是資源身份對應表
	- 用來維持 Terraform resource 和真實雲端資源 ID 的 mapping
	- 沒有它，`plan` / `apply` 就難以穩定判斷該 `update`、`create` 還是 `destroy + recreate`

- Terraform 做變更前，最先要回答的是什麼？ #DevOps #card
	- 不是先回答資源 spec 長怎樣
	- 而是先回答「這個宣告到底在管理誰」
	- 所以 identity mapping 比資源外觀更先決

- Terraform 和 Kubernetes 都是宣告式，但最大差異是什麼？ #DevOps #card
	- Kubernetes 依靠 controller 持續 reconcile
	- Terraform 依靠 `state` 與明確的 `plan` / `apply` 週期做人為 reconcile
	- 兩者都描述 desired state，但 lifecycle 不同

- 為什麼 `terraform/` 不應和 `manifests/` 混成同一種 deploy source？ #DevOps #card
	- `manifests/` 是目前 WeaMind cluster runtime 的 deploy source
	- `terraform/` 是 Terraform 能力與可執行 IaC 資產
	- 兩者管理的層級、工具鏈與 reconcile 模型不同

- 最小 IaC workflow 的證據不能只有 `.tf` 檔，還要有什麼？ #DevOps #card
	- 至少要有一次完整的 `terraform plan`
	- 至少要有一次完整的 `terraform apply`
	- 還要有可讀的 Terraform 檔案骨架與 state / 變更觀察證據

- W9 為什麼還要核對 Free Tier 規格，而不只看 VM 有沒有建出來？ #DevOps #card
	- 因為要證明建出的不是隨便一台 VM
	- 要確認它有對齊這週的驗收邊界
	- 例如 `region`、`e2-micro`、HDD、disk size、`STANDARD` network tier

- Terraform 能控制的最大資源範圍，真正受限於什麼？ #DevOps #card
	- 受目標平台是否有穩定 API 限制
	- 受 Terraform provider 是否有完整實作限制
	- 也受資源本身是否適合宣告式管理限制

- 為什麼 drift 麻煩的地方不只是不同步？ #DevOps #card
	- 因為它會讓 Terraform 在下一次 `plan` / `apply` 做出錯誤決策
	- 風險在於誤改、誤建或高風險重建
	- 所以 drift 本質上是決策可信度問題
