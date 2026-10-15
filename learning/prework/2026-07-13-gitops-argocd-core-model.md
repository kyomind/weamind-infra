# 2026-07-13 GitOps and Argo CD Core Model

## Prework 內容

### 今日焦點

- 主題：GitOps 的最小概念骨架與 Argo CD 核心模型
- 範圍：GitOps 的 pull model 本質、和 push-based CD 的差異、Argo CD 的 Application / syncPolicy / selfHeal / prune 是什麼、Sealed Secrets 怎麼讓 Secret 安全進 Git；不進入 Argo CD 安裝指令、不展開 Flux 比較、不展開多 cluster 管理
- 目標：把「我聽過 GitOps 但其實不知道它本質上哪裡不同」補成「我能白話講清楚 GitOps 的 pull model、Argo CD 的核心元件、以及為什麼它和之前做的 push-based CD 根本不同」
- 時間：控制在 45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的節奏是：上午先完成這份 prework，下午回到 VS Code 做 WeaMind 的 repo-backed implement-heavy lesson（實際安裝 Argo CD + Sealed Secrets）。
- 我目前的真實狀態是：已經了解 CI/CD 的基本概念，也做過 push-based CD（GitHub Actions 觸發 kubectl apply），但對 GitOps 的 pull model、Argo CD 的 Application CRD、syncPolicy 這些名詞其實沒有清晰骨架。
- 今天請優先幫我建立 GitOps 的本質理解與 Argo CD 的核心運作模型，不要先跳進安裝步驟或 YAML 細節。

### 今天一定要學會的最小骨架

1. GitOps 的關鍵不是「用 Git」，而是「pull model」——controller 在 cluster 內部持續拉取 Git 中的期望狀態，並自動對齊 cluster 實際狀態。
2. Push-based CD（如 GitHub Actions kubectl apply）和 GitOps 的根本差異：push 是外部觸發一次性的部署，pull 是內部 controller 持續 reconcile。
3. Argo CD 的 Application CRD 是「把哪個 Git repo 的哪個 path 同步到哪個 cluster 的哪個 namespace」的宣告。
4. syncPolicy 控制自動同步行為：automated（自動同步）、selfHeal（偵測到 drift 時自動修復）、prune（Git 中刪掉的資源也在 cluster 中刪除）。
5. Sealed Secrets 的核心是 asymmetric encryption：cluster 中有 private key（controller 持有），開發者用 public key（kubeseal CLI）加密 Secret，加密後的 SealedSecret 可以安全放進 Git，只有目標 cluster 能解密。

### 建議教學順序

1. 先用白話講 GitOps 的 pull model 本質：它不是「把 CI/CD pipeline 搬到 Git 裡」，而是「cluster 內部有一個 controller 持續看著 Git，發現不一樣就自己修正」。
2. 再對比 push vs pull 的具體差異：觸發者（外部 CI vs 內部 controller）、持續性（一次 vs 持續 reconcile）、drift detection（沒有 vs 內建）。
3. 接著講 Argo CD 的三層核心概念：Application（宣告期望來源與目標）、syncPolicy（控制同步行為）、reconcile loop（每 3 分鐘比對 Git 與 cluster 狀態）。
4. 解釋 syncPolicy 的三個關鍵選項：selfHeal 的風險（手動緊急修復會被蓋掉）、prune 的風險（誤刪 Git 資源會連 cluster 一起刪）。
5. 最後講 Sealed Secrets 的安全模型：為什麼加密後的 Secret 可以放心進 Git、controller 怎麼在 cluster 內解密、和 External Secrets Operator 的定位差異（Sealed Secrets 是加密後存 Git，ESO 是從外部 secret manager 拉）。

如果我卡住，請優先用更具體的例子（例如：GitHub Actions 推一次 vs Argo CD 每 3 分鐘自己檢查一次）來對比，不要直接丟術語表。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 用一句話說清楚 push-based CD 和 GitOps（pull model）的根本差異。
  7. 我今天下午回到 VS Code 做 implement 時，應該注意的 2 個設計前提或風險點。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

> 原定 2026-07-13，實際完成於 2026-10-15。外部 AI 五個步驟的理解測驗皆通過；實作能力尚待 lesson 驗證。

### 今日學到什麼

- GitOps 的核心不是「用 Git」，而是持續 reconciliation：Git 保存 desired state，cluster 內的 controller 持續比較期望與實際狀態，依同步政策決定是否修正。
- Push-based CD 與 GitOps 差在三點：部署主導權（外部 pipeline 連 API Server vs cluster 內 controller 拉 Git）、持續性（一次性 workflow vs 持續運作）、drift detection（需另做 vs 內建）。
- Argo CD 三層模型：Application（source：repo / revision / path；destination：cluster / namespace；syncPolicy）、syncPolicy（automated / selfHeal / prune）、reconciliation loop（Git 預設約 2～3 分鐘刷新，也可由 webhook 或資源事件更快察覺，不能簡化成「每 3 分鐘 `kubectl apply` 一次」）。
- selfHeal 風險：直接改 Deployment 而沒改 Git，緊急 hotfix 可能被蓋回去。prune 風險：誤刪 infra repo 中的資源宣告並 merge，cluster 裡受管資源也會被刪，所以 infra PR review 等同基礎設施變更審查。
- Sealed Secrets：用目標 cluster 的 public key 經 `kubeseal` 加密，SealedSecret 進 Git，Argo CD 只負責同步，真正解密並建立原生 Secret 的是 Sealed Secrets controller（持有 private key）。預設 strict scope 綁定 Secret 名稱與 namespace。
- Sealed Secrets vs ESO：前者把加密後的 Secret 存 Git；後者 Git 只存引用設定，controller 從 Vault / AWS Secrets Manager 等外部系統拉取，更適合已有集中式 secret manager、需要統一權限與輪替的環境。

### 已能白話講清楚什麼

- GitHub Actions 也能自動部署，但 workflow 跑完就結束；GitOps 的差別在於部署責任交給持續運作的 controller，而不是「有沒有自動化」。
- 只裝 Argo CD 不會管理任何東西，必須用 Application 告訴它期望狀態來自哪裡、要部署到哪裡。
- selfHeal 處理「cluster 偏離 Git」，prune 處理「Git 已不宣告但 cluster 仍存在」，兩者差異來源不同、風險也不同。
- 只保存 SealedSecret YAML 不等於可重建：private key 遺失且沒有原始 Secret 來源時，就只能重新產生密碼再重新加密。GitOps 的配置可重建，不等於完整災難復原。

### 目前還卡住什麼

- 已修正的偏差：一開始把 Argo CD 的權限範圍理解成「infra repo 內部」。正確分層是：Git repo 定義期望狀態來源，AppProject 約束 Application 的來源與部署範圍，Kubernetes RBAC 控制 ServiceAccount 的實際 API 權限。GitOps 能減少 CI 持有 cluster 部署權限的需求，但 Argo CD 預設不是最小權限。
- 尚未實作驗證：
  1. 獨立建立正確的 Application（repo / path / destination）。
  2. 分辨 Synced / OutOfSync / Healthy / Degraded。
  3. 實測 selfHeal、prune 的行為與例外。
  4. Sealed Secrets 金鑰備份、復原與重新解密。
  5. Argo CD 與 Sealed Secrets controller 的部署順序與相依關係。

### 今日最重要的觀念

- GitOps 的本質是持續維持 desired state，不是執行一次部署命令。
- Application 是宣告管理關係的 CRD，真正持續執行的是 controller。
- 偵測 drift 不等於自動修復 drift，要看 syncPolicy。
- GitOps 把變更審查（PR）和部署執行（controller sync）分開。
- Sealed Secrets 保護 Git 中的機密，但不取代 private key 保護、備份與 Secret 的 RBAC / 儲存加密。

### Push-based CD vs GitOps 一句話差異

- Push-based CD 是外部 pipeline 在觸發時主動部署一次；GitOps pull model 是 cluster 內的 controller 持續取得 Git 的期望狀態，透過 reconciliation 維持兩者一致。

### 下午 implement 前要注意的前提或風險

1. 接管既有資源時，先確認所有權與同步政策：WeaMind 目前的流程是 `publish-release.yml` 開 infra PR、人工 merge，再手動 `make deploy`（`kubectl apply -f manifests/`）。導入 Argo CD 後，Application 要指向正確的 repo / path，也不能再有其他流程同時管理同一批資源；確認 prune 不會刪到 Service、PVC 等重要資源，selfHeal 不會和 HPA 等合法的動態控制衝突。順序上先看 diff、手動 sync，再依序開 automated、selfHeal，最後才評估 prune（高風險資源可用 `Prune=false` 或 `Prune=confirm`）。
2. Sealed Secrets 的金鑰生命週期與相依：controller 和 CRD 要先就緒；用正確 cluster 的 public key 加密，Secret 名稱與 namespace 要符合 scope；private key 要有備份與復原方式，備份檔不可進 Git 或 CI logs。驗收不能只看能不能加密部署，還要確認怎麼復原。
