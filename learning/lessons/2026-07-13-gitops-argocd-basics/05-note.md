# 2026-07-13 GitOps + Argo CD Basics Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- Argo CD 安裝後會建立 `argocd` namespace，不影響現有 `weamind` 和 `watchmind` 資源。
- Argo CD 接管現有資源時，若 Git 中的 manifest 與 cluster 現狀一致，會顯示 Synced 而非 OutOfSync；不會觸發重新部署。
- Sealed Secrets controller 預設安裝在 `kube-system`，加密後的 SealedSecret YAML 可以安全 commit 進 Git。

### Repo 對照文件與觀察點

- `manifests/argocd-app.yaml` — 新建的 Application CRD，觀察 syncPolicy 欄位
- `manifests/sealed-secret.yaml` — 新建的 SealedSecret，對照 `.privatedocs/secrets/secret.yaml` 原始內容
- `Makefile` — 實作後 deploy target 的定位是否調整

### 暫時不在今天展開的點

- Kustomize overlays（多環境抽象）
- Argo CD Image Updater（自動追蹤 image tag）
- Argo CD SSO / RBAC / Ingress 暴露
- External Secrets Operator（Sealed Secrets 的替代方案比較）
- Flux 作為 Argo CD 的替代方案

## Notes

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的出現延伸問答或暫時結論後再填。 -->

## Flashcards

<!-- 初始化與課程互動中保持空白；lesson 收尾後再用 generate-flashcards prompt 統一生成或精修。 -->
