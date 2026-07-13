# 2026-07-13 GitOps + Argo CD Basics Outline

## 今日主題

- 在 WeaMind K3s cluster 上安裝 Argo CD 與 Sealed Secrets，將現有的手動 `kubectl apply` 部署升級為 GitOps pull model。

## 今日套用的 lesson mode

- implement-heavy mode

## 為什麼今天要套用 implement-heavy mode

1. 今天主體是操作 cluster（Helm install Argo CD、建立 Application CRD、密封 Secret），不是 QA 對照或 command drill。
2. 驗收標準是 Argo CD UI 顯示 Synced + Healthy，以及 SealedSecret 正確解密進 cluster，這些都是實作結果，不是問答。
3. `docs/gitops-implementation-checklist.md` 已是現成的實作腳本，適合直接轉成 `06-implementation.md` 的 step 閉環。

## 這次要解的專案問題

1. 目前部署仍依賴人工 `make deploy`（kubectl apply），PR merge 後無人自動同步。
2. 沒有 drift detection — 如果有人手動 `kubectl edit` 改資源，不會被偵測或修復。
3. `weamind-secret` 不在 Git 中，每次部署需人工額外 apply，無法被 Argo CD 一併管理。

## 這份 lesson 是否需要外部預習

- 需要
- 原因：使用者對 GitOps 的 pull model、Argo CD 的 Application CRD / syncPolicy、Sealed Secrets 的加解密模型尚無清晰骨架。prework 已建立於 `learning/prework/2026-07-13-gitops-argocd-core-model.md`。

## 要對照的 repo 檔案

1. `manifests/` — 全部 7 個 YAML（現有部署資源）
2. `docs/gitops-implementation-checklist.md` — 實作腳本與踩坑點
3. `.privatedocs/secrets/secret.yaml` — 現有 Secret（Argo CD 管不到的原檔）
4. `Makefile` — 現有 deploy/rollback 入口（實作後需調整）
5. `docs/WeaMind實作CD討論與實踐.md` — W8 CD 設計決策背景
6. `docs/todo-weamind-cd-future-optimizations.md` — push → GitOps 演進路線規劃

## 今日實作邊界

1. 安裝 Argo CD（Helm），不設定 ingress / SSO / RBAC 進階。
2. 建立單一 Application CRD 指向 `manifests/`，啟用 auto-sync + selfHeal + prune。
3. 安裝 Sealed Secrets controller + CLI，將 `weamind-secret` 密封後放進 Git。
4. 不做 kustomize overlays、不做多環境、不做 Image Updater。

## 驗收訊號與回退點

### 驗收訊號

1. Argo CD UI 中 `weamind` Application 顯示 Synced + Healthy。
2. `weamind-secret` 由 SealedSecret controller 在 cluster 中自動建立，Pods 正常 Running。
3. 修改 `manifests/deployment.yaml` 的 replica 數 push 後，Argo CD 在 3 分鐘內自動 sync 回正確值（selfHeal 驗證）。

### 回退點

1. 若 Argo CD 安裝有問題：`helm uninstall argocd -n argocd`，現有資源不受影響（Argo CD 還沒接管前它們是 standalone）。
2. 若 Application CRD sync 出錯：刪除 Application CRD，退回 `make deploy` 手動模式。
3. 若 SealedSecret 解密失敗：刪除 `manifests/sealed-secret.yaml`，手動 apply 原版 Secret 即可恢復。

## 建議學習順序

1. 先用 `06-implementation.md` 做主要實作與每個 step 的閉環記錄。
2. 若 `06` 過程中出現 implementation-specific 補充觀察或設計取捨，同步整理到 `05-note.md`。
3. 只有在實作主體完成後，再回 `02-qa.md` 做 post-implementation QA 與定位收斂。
4. 若需要最小操作驗證，直接把證據留在 `06-implementation.md` 的對應 step。
5. 過程中的一般 lesson 延伸問答與實作補充都整理進 `05-note.md`。
6. 最後回 `04-report.md` 做整體收斂。

## 文件分工

1. `01-outline.md`：宣告今天套用 implement-heavy mode，並寫清楚流程、邊界、驗收與回退點。
2. `02-qa.md`：記錄 post-implementation QA 的短版定位題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的內容。
4. `05-note.md`：記錄一般 lesson 延伸問答、實作補充與暫時結論；Flashcards 保留到 lesson 收尾後統一生成。
5. `06-implementation.md`：記錄今天的主要實作 step，包含必要的驗證證據。

## 這份 lesson 的完成標準

1. Argo CD 成功接管 `manifests/` 全部資源，Application 顯示 Synced + Healthy。
2. SealedSecret 正確解密，`weamind-secret` 由 controller 自動管理。
3. 使用者能在 QA 中白話講清楚 push-based CD 和 GitOps pull model 的根本差異，以及 selfHeal / prune 的 trade-off。
