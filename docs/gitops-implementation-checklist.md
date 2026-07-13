# GitOps 導入執行清單

## 環境背景

- K3s cluster（access via SSH tunnel → `127.0.0.1:6443`）
- Helm 已安裝，`kube-prometheus-stack` 在 `watchmind` namespace
- manifests 為扁平 raw YAML，單一 `weamind` namespace
- Secret 目前人工 apply，原始檔在 `.privatedocs/secrets/secret.yaml`

---

## 為什麼 GitOps：push vs pull 的核心差異

### 現狀（push-based）

```
merge → make deploy → kubectl apply → 結束
```

`kubectl apply` 是一次性動作，做完就沒了。如果之後有人手動改 cluster（`kubectl edit`、`kubectl set image`），偏離就發生了，而且**沒有人會發現、也沒有人會修正**。這個偏離叫做 **drift**。

### GitOps（pull-based）

```
merge → Argo CD 偵測 Git 變化 → 自動 sync → 持續對齊
```

Argo CD 每 3 分鐘做一次 reconcile：把 Git 裡的期望狀態和 cluster 實際狀態做比對。

- **drift detection**：一比對發現 Git 說 `replica=2` 但 cluster 跑 `5` → UI 紅字標示 `OutOfSync`，一眼就知道偏離了
- **selfHeal**（`selfHeal: true`）：不只告訴你偏離，還自動把 cluster 修回 Git 宣告的狀態（`replica=2`）

所以 push 是一次性部署，pull 是**持續對齊**。Git 是 source of truth，cluster 永遠被拉回 Git 的宣告。

---

## Task 1：安裝 Argo CD

### 1-1 Helm 安裝

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=ClusterIP
```

### 1-2 取得 admin 密碼

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### 1-3 測試 port-forward

```bash
kubectl port-forward -n argocd svc/argocd-server 8443:443
# 瀏覽器開 https://localhost:8443，admin / 上一步密碼
```

### 1-4 建立 Application CRD

另存為 `manifests/argocd-app.yaml`，內容：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: weamind
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/kyomind/weamind-infra
    targetRevision: main
    path: manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: weamind
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

```bash
kubectl apply -f manifests/argocd-app.yaml
```

### 1-5 驗證

- Argo CD UI 中 `weamind` Application 顯示 `Synced` + `Healthy`
- 確認現有資源（Deployment、Service、Ingress 等）都被 Argo CD 接管，沒有 diff

---

## Task 2：Sealed Secrets 導入

### 2-1 安裝 CLI

```bash
brew install kubeseal
```

### 2-2 安裝 Controller

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system
```

### 2-3 密封現有 Secret

```bash
kubeseal \
  --controller-namespace kube-system \
  --controller-name sealed-secrets \
  -f .privatedocs/secrets/secret.yaml \
  -o yaml > manifests/sealed-secret.yaml
```

### 2-4 Commit + 驗證

```bash
git add manifests/sealed-secret.yaml manifests/argocd-app.yaml
git commit -m "feat: add Argo CD Application + SealedSecret"
git push
```

- Argo CD 應在 3 分鐘內自動 sync，`weamind-secret` 出現於 cluster
- 確認 Pods 仍 `Running`，LINE Bot 功能正常

---

## Task 3：清理與切換

### 3-1 確認不再手動 deploy

- `make deploy` 改為只留 `rollout` / `rollback`（或直接移除 deploy target）
- deploy 責任從 `kubectl apply` 轉移到 Argo CD

### 3-2 後續 image 更新流程

- App repo release → auto-PR 更 `manifests/deployment.yaml` 的 image tag
- PR merge 後 Argo CD 自動 detect + sync（不再需要人工 `make deploy`）

---

## 潛在踩坑點

| 坑 | 對策 |
|---|---|
| Argo CD 無法連 GitHub private repo | 目前 `weamind-infra` 是 public，沒問題 |
| SealedSecret controller 還沒裝就先 seal | 確認 controller pod `Running` 再執行 `kubeseal` |
| Argo CD sync 時出現 `Secret` 的 diff（舊的 unnmanaged Secret） | 刪掉舊的手動 apply 的 `weamind-secret`，讓 SealedSecret controller 重建 |
| `selfHeal: true` 會把 `kubectl edit` 的手動改動還原 | 這是預期行為；若需手動改，先 disable auto-sync |
