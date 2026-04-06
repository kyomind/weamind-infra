# 2026-04-06 CI Image Pipeline Skeleton Note

## 學習注意事項

### 今日 lesson 邊界

- 今天主題是 WeaMind 的 CI workflow、publish 到 GHCR、Deployment image 引用方式，以及目前為什麼還不算完整 CD。
- 今天不展開 GitHub Actions 的所有語法細節，也不展開完整 GitOps 或 Argo CD / Flux 實作。
- 今天也不把焦點放在 app repo 內部程式碼，而是只收斂從 workflow 到 Deployment 的最小鏈路。

### 今天要特別觀察的 repo 事實

- CI workflow 同時包含程式品質檢查與 Docker build validation。
- publish workflow 是由 CI 的 workflow_run 觸發，且只在成功條件成立時才會 push image。
- Deployment 目前引用 ghcr.io/kyomind/weamind:latest。
- imagePullPolicy: Always 只影響 Pod 重新建立時的拉 image 行為，不會主動觸發 rollout。

### 今天不展開的項目

- 未來若要補成真正 CD，該選 GitHub Actions 直推 K8s 還是 GitOps 工具，今天只點到為止。
- image tag strategy 的更完整版本管理設計，今天只收斂到 latest 與 sha-short tag。

## Notes

<!-- 待 lesson 過程中補充 -->

## Flashcards

<!-- 待 lesson 過程中補充 -->
