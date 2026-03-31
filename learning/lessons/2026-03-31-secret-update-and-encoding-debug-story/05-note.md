# 2026-03-31 Secret Update And Encoding Debug Story Note

## 學習注意事項

### 今日 lesson 邊界

- 今天主題是 WeaMind 內的 Secret 引用方式、更新影響與 `invalid UTF-8` debug story。
- 今天不展開 Secret at-rest 保護機制，例如 etcd encryption、RBAC 細節與外部 secret manager。
- 今天也不展開 volume mount 型 Secret 更新行為的完整比較，只先收斂 WeaMind 目前 `envFrom` 情境。

### 今天要特別觀察的 repo 事實

- `manifests/deployment.yaml` 目前用 `envFrom` 搭配 `secretRef`，不是逐 key `valueFrom`。
- `PROGRESS.md` 已正式記錄：人工撰寫 Secret 一律用 `stringData`，且曾發生 `CreateContainerError (invalid UTF-8)`。
- `.privatedocs/weamind/踩坑清單.md` 有保留更短版的問題、解法、根因，可用來壓成面試可講的 debug story。

### 今天不展開的項目

- Secret 不是加密，這題保留到後續補強或面試延伸。
- Ingress `tls` 與 Secret 的關係，不納入今天主線。

## Notes

### Secret 不是只是 YAML

- 使用者在 Q4 提出一個關鍵卡點：直覺上容易把 Secret 當作「YAML 裡的一段內容」，但更準確的理解是，YAML 只是宣告方式；真正的 Secret 是 `kubectl apply` 後存在 Kubernetes API server 裡的一個資源物件。
- 因此排查時要分開看兩件事：本地 YAML 是否已修改，以及叢集裡的 Secret 資源是否已更新成功。前者是編輯狀態，後者才是工作負載真正會引用到的狀態。

### 第一層怎麼確認 Secret 已更新到叢集

- 第一動作通常是先 `kubectl apply -f` 將 Secret YAML 套用到叢集。
- 套用後不能只憑終端成功訊息就結束，還要再看叢集裡的 Secret 物件。
- `kubectl describe secret` 適合先確認物件是否存在、名稱是否正確、基本 metadata 是否合理。
- `kubectl get secret -o yaml` 或 `kubectl get secret -o jsonpath=...` 更適合進一步對照目前叢集裡的內容是否已是預期值。
- 這一步的重點不是背哪個指令，而是建立「先確認資源已更新，再談 Pod 是否吃到新值」的排查順序。

### 進 Pod 看 env 的位置

- `kubectl exec` 進 Pod 看環境變數可以作為第二層或第三層的驗證手段，但不應該拿來取代第一層。
- 因為若 Secret 根本還沒正確更新到叢集，直接進 Pod 看 env 只會看到舊值，卻無法分辨是「資源沒更新」還是「Pod 沒重建」。
- 所以較穩的順序是：先看 Secret 物件，再看 Pod 是否為舊 Pod，最後才在需要時進 Pod 驗證實際環境變數。

## Flashcards

<!-- lesson 收尾後再整理卡片 -->
