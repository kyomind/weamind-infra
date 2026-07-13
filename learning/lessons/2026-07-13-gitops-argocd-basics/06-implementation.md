# 2026-07-13 GitOps + Argo CD Basics Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 在 WeaMind K3s cluster 上安裝 Argo CD 與 Sealed Secrets，將部署從手動 kubectl apply 升級為 GitOps pull model。

## 今日實作順序

1. Helm 安裝 Argo CD
2. 建立 Application CRD，讓 Argo CD 接管 `manifests/`
3. 驗證 sync 行為與 selfHeal
4. Helm 安裝 Sealed Secrets controller
5. 密封現有 `weamind-secret`，commit 進 Git
6. 清理：調整 `Makefile`，確認 deploy 責任已移交

## 使用提醒

1. step 數量不設上限；若後續發現某一步過大，應直接往下拆成新的 `Step N 小標題`，不要勉強維持少量大步驟。
2. 新增一個 step 時，預設先只建立骨架：至少寫到 `#### 預計採取的動作`；`實際執行內容`、`結果`、`AI 判讀與收斂` 先維持待填，等這一步真的走完再回填。
3. 每個 step 的 `實際執行內容` 第一個 bullet，應先標記這次主要由誰實作，例如：`本次由 AI 實作`、`本次由使用者實作`；若屬於明確分段協作，也可以寫成 `本次由 AI 與使用者協作`。
4. `06-implementation.md` 的帶法、回填時機與例外情況，統一回 `learning/lessons/plugins/implementation/implementation-guide.md`，本模板只保留骨架直接需要的提醒。

## Session 開場提醒

- `06-implementation.md` 的實際帶法不要寫死在模板裡；開場規則、step 推進、提問邊界與回填原則改讀 `learning/lessons/plugins/implementation/implementation-guide.md`。

## 驗收訊號與回退點

### 驗收訊號

- Argo CD UI 中 `weamind` Application 顯示 Synced + Healthy
- `weamind-secret` 由 SealedSecret controller 自動建立
- selfHeal 驗證通過（手動改 replica → Argo CD 自動修復）

### 回退點

- `helm uninstall argocd -n argocd`
- 刪除 Application CRD 即退回手動 `make deploy`
- 刪除 `manifests/sealed-secret.yaml` + 手動 apply 原 Secret

### Step 1: Helm 安裝 Argo CD

#### 這一步要驗證什麼

- Argo CD controller 與 server 在 `argocd` namespace 中正常 Running。
- 能成功 port-forward 到 Argo CD UI 並用 admin 密碼登入。

#### 預計採取的動作

- helm repo add argo + repo update
- helm upgrade --install argocd argo/argo-cd --namespace argocd --create-namespace
- 取得 admin 密碼
- port-forward 測試 UI 可訪問

#### 實際執行內容

- 本次由 AI / 使用者 / AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 2: 建立 Application CRD 接管 manifests/

#### 這一步要驗證什麼

- Argo CD Application 成功指向 `manifests/`，sync 後所有現有資源顯示 Synced + Healthy，無 diff。

#### 預計採取的動作

- 建立 `manifests/argocd-app.yaml`（Application CRD）
- kubectl apply 該檔案
- 觀察 Argo CD UI 中的 sync 結果
- 確認 Synced + Healthy

#### 實際執行內容

- 本次由 AI / 使用者 / AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 3: 驗證 selfHeal 行為

#### 這一步要驗證什麼

- 手動修改 cluster 中的 replica 數後，Argo CD 在 3 分鐘內自動修復回 Git 宣告值。

#### 預計採取的動作

- 手動 kubectl scale deployment/weamind --replicas=1
- 等待 Argo CD detect drift
- 觀察 Argo CD 自動 sync 回 2 replicas
- 確認 Pod 數恢復為 2

#### 實際執行內容

- 本次由 AI / 使用者 / AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 4: Helm 安裝 Sealed Secrets controller

#### 這一步要驗證什麼

- Sealed Secrets controller 在 `kube-system` namespace 中正常 Running。

#### 預計採取的動作

- brew install kubeseal
- helm repo add sealed-secrets + repo update
- helm upgrade --install 到 kube-system
- 確認 controller pod Running

#### 實際執行內容

- 本次由 AI / 使用者 / AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 5: 密封 weamind-secret 並 commit

#### 這一步要驗證什麼

- `manifests/sealed-secret.yaml` 中無明文機密。
- git push 後 Argo CD 自動 sync，SealedSecret controller 自動建立 `weamind-secret`。
- Pods 保持 Running，LINE Bot 功能正常。

#### 預計採取的動作

- kubeseal 將 `.privatedocs/secrets/secret.yaml` 加密輸出為 `manifests/sealed-secret.yaml`
- git add + commit + push
- 觀察 Argo CD sync 結果
- 確認 cluster 中 `weamind-secret` 由 controller 自動建立

#### 實際執行內容

- 本次由 AI / 使用者 / AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 6: 清理與確認責任移交

#### 這一步要驗證什麼

- `make deploy` 已不再需要（或改為只留 rollout 觀察）。
- 後續 image update 流程確認：app repo release → auto-PR 改 image tag → merge → Argo CD auto-sync。

#### 預計採取的動作

- 決定 `Makefile` 是否保留 deploy target
- 確認後續更新流程不再需要人工 kubectl apply
- 用 Argo CD UI 或 `argocd app diff weamind` 確認無預期 diff

#### 實際執行內容

- 本次由 AI / 使用者 / AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始
