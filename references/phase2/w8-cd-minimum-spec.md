# WeaMind CD Minimum Spec

這份文件整理 Phase 2 / W8 會反覆用到、但不需要每次都讀的最小 CD 規格。

它不是週計畫，也不是立即執行指令稿。

它的角色是：當 W8 要做 CD 設計對照、最小實作或 skeleton 驗收時，提供一份穩定、可公開、可對照的 reference。

與 `references/weamind-ci-to-k8s-flow.md` 的分工應明確切開：

- `references/weamind-ci-to-k8s-flow.md` 負責描述目前真實存在的流程證據
- 本文件負責收斂 W8 實作時應採用的方案邊界與最小落地方向

## 先說結論

WeaMind 目前的真實狀態是：

- 有 CI
- 有 image publishing
- 但還沒有完整 CD

W8 的最低目標不是把整套 production CD 一次做完，而是把 deployment version、repo 邊界與最小自動化方向定清楚。

## 現況基線

目前 app repo 已有兩條已知路徑：

- main push 後，CI 成功再 publish 到 GHCR
- release tag 發佈正式版本 image

main push path 的 `sha-<short_sha>` tag 應該和實際 checkout / build 的 commit 一致。

因為 `publish-ghcr.yml` 是由 `workflow_run` 觸發，`GITHUB_SHA` 代表的是 default branch 的最後 commit，不一定等於剛通過 CI 的 commit。這條路徑若要保持可追溯性，tag 應該從 `github.event.workflow_run.head_sha` 計算，讓 checkout ref、image 內容與 `sha-<short_sha>` tag 指向同一個 commit。

目前 infra repo 的 Deployment 仍直接引用：

```yaml
image: ghcr.io/kyomind/weamind:latest
imagePullPolicy: Always
```

這代表 image 可以更新，但 cluster 端的 deployment state 仍沒有以 Git 明確記錄正式版本。

## 什麼不算完整 CD

以下幾件事目前都還沒有證據存在：

- image push 後自動更新 Deployment image
- 自動 rollout restart
- 自動 apply 到 cluster
- GitOps controller 自動同步版本

因此現在更準確的說法是：registry 會更新，但現有 Pods 不會因此自動換版。

## 正式 deploy source 應該是什麼

第一版應收斂為：

- 正式 deploy source 應該是完整 release version tag

不應收斂為：

- latest
- minor tag，例如 1.1
- major tag，例如 1

原因很直接：完整 release version 比較可追溯、可溝通，也比較好回滾。

## Repo 邊界

app repo 應負責：

- build image
- publish image
- 定義什麼是正式可部署版本

infra repo 應負責：

- 宣告 cluster 目前要跑哪個版本
- 保存 deployment state 的 Git 歷史
- 決定何時把這個版本套進 cluster

第一版不建議讓 app repo 直接拿 cluster credentials 去改叢集。

## 最小自動化鏈路

W8 最推薦先理解並驗收的鏈路是：

1. app repo 建立正式 release
2. release workflow build 並 push 對應 image
3. app repo 自動更新 infra repo 的 image version
4. infra repo 再決定是否要自動 deploy 到 cluster

這條路的重點不是一步到位全自動，而是先把 artifact 與 deployment state 的責任邊界切清楚。

## 第一版最推薦方案

若只考慮 WeaMind 目前規模與 W8 的學習目標，第一版最推薦的是：

- app repo release 成功後，自動開 PR 到 infra repo
- PR 只更新 Deployment image 的完整 release version

這個方案的優點是：

- repo 邊界清楚
- 可人工審核
- 版本可追溯
- 未來仍可自然升級成更完整 deploy automation

## W8 驗收時至少要能回答什麼

1. WeaMind 為什麼現在不算完整 CD
2. 為什麼正式 deploy version 不該追 latest
3. app repo 與 infra repo 各自應負責什麼
4. `workflow_run` 觸發的 publish workflow 為什麼應該用 `workflow_run.head_sha` 產生 `sha-<short_sha>` tag
5. 第一版最合理的自動化鏈路是什麼
6. rollback 與 release 邊界應該怎麼講

## 這份 reference 的用途

- 當 W8 做 CD 設計對照時，作為穩定方案邊界參考
- 避免把 deploy source、repo 邊界、最小自動化鏈路全部塞在週計畫裡
- 讓計畫檔只保留節奏、進度、實作目標與短版驗收標準
