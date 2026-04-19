# WeaMind CI To K8s Flow

這份文件只整理 WeaMind 目前真實存在的最小路徑，不把尚未存在的自動化腦補進來。

它的角色偏向「現況證據與邊界確認」，不是 W8 實作時的主要施工藍圖。

若 W8 要做 CD 設計或最小實作，這份文件主要負責回答：現在已經有什麼、還沒有什麼；真正的實作方向與方案邊界則應回到 `references/w8-cd-minimum-spec.md`。

## 先說結論

- WeaMind app repo 目前有 `CI` 與 `publish-ghcr` 這兩段自動化。
- 它會把新 image 推到 `ghcr.io/kyomind/weamind`。
- infra repo 的 Deployment 會引用 `ghcr.io/kyomind/weamind:latest`。
- 但目前沒有證據顯示「push 到 GHCR 後，Kubernetes 會自動 rollout」。
- 所以現況更準確地說是：有 CI 與 image publishing，但沒有完整 CD。

## 實際證據在哪裡

### App repo：CI 與 image publishing

- `references/weamind-app-ci.yml`
- `references/weamind-app-publish-ghcr.yml`

這兩份是從 app repo 帶回來的 workflow 快照，用來理解真正的 build / push 路徑。

### Infra repo：K8s 如何引用 image

- `manifests/deployment.yaml`

目前 Deployment 直接寫：

```yaml
image: ghcr.io/kyomind/weamind:latest
imagePullPolicy: Always
```

## 最小流程

1. 開發者 push code 到 app repo 的 `main`。
2. `CI` workflow 先跑品質檢查、型別檢查、測試與 Docker build validation。
3. 若 `CI` 成功，`publish-ghcr.yml` 被 `workflow_run` 觸發。
4. workflow build Docker image，push 到 `ghcr.io/kyomind/weamind`。
5. 產出至少兩種 tag：
   - `latest`
   - `sha-<short_sha>`
6. infra repo 的 Deployment 一直引用 `ghcr.io/kyomind/weamind:latest`。
7. 只有在 Pod 後續真的被重建、rollout 或 restart 時，node 才會重新去拉 image。

## 為什麼這不算完整 CD

因為目前沒有看到這些證據：

- 沒有 GitHub Actions 在 image push 完後自動對 K8s 做 `kubectl set image`
- 沒有 GitHub Actions 自動做 `kubectl rollout restart`
- 沒有 Argo CD / Flux 這類 GitOps controller
- 沒有 Helm / Kustomize release automation

所以不能說「push 到 GHCR 後，叢集就會自動更新」。

更準確的說法是：

- `latest` 只是讓 Deployment 指向同一個 tag
- `imagePullPolicy: Always` 只是讓 Pod 在重新建立時傾向重新拉取
- 它們都不會主動觸發現有 Pod 自動換版本

## 這份 reference 的用途

- 幫助在 infra repo 內理解 app repo 的 CI / image publishing 證據
- 讓 W5 的 CI/CD lesson 可以直接對照真實 workflow，而不是只看抽象說明
- 在 W8 實作時，作為「現況證據」文件使用，而不是直接拿來當施工規格
- 後續若要學「K8s 到底什麼時候會真的拉到新 image」，可以直接從 Deployment 與 rollout 行為往下追

## 後續最值得補的題目

1. 若 `ghcr.io/kyomind/weamind:latest` 已更新，但現有 Pods 不變，會發生什麼事？
2. 在 WeaMind 現況下，最可能的更新動作是手動 `rollout restart`、重新套用 Deployment，還是其他流程？
3. 若未來要補成真正的 CD，應該由 GitHub Actions 直接 deploy，還是由 GitOps 工具接手？
