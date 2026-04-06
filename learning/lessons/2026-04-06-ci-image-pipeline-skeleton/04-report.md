# 2026-04-06 CI Image Pipeline Skeleton Report

## 今日主題

把 WeaMind 從 app repo 的 `git push`、GitHub Actions、GHCR image，到 infra repo Deployment 之間的最小鏈路，收斂成可口述的專案答案。

## 狀態

已完成 QA 收斂，本次 lesson 不做 command drill。

## 今日最小收斂

1. WeaMind 的 CI 不是單純跑 lint，而是分成兩個 job：一個做 code quality、security、dependency 與 unit test 檢查，另一個驗證 Docker image 真的能成功 build。
2. publish 到 GHCR 不是直接綁 `push`，而是由 `CI` 的 `workflow_run` 觸發，並且只有在 main 分支上的成功 push 條件成立時，才真的 build and push image。
3. infra repo 目前透過 Deployment 直接引用 `ghcr.io/kyomind/weamind:latest`，`imagePullPolicy: Always` 只保證 Pod 重建時傾向重新拉 image，不保證 registry 一更新就自動 rollout 現有 Pods。
4. 因此 WeaMind 目前更準確的說法是：**有 CI、有 image publishing，但還沒有完整 CD**。

## 最短答題稿

WeaMind 目前的 app repo 會先透過 CI 做品質檢查、測試與 Docker build validation；CI 成功後，另一條 workflow 才會把 image push 到 GHCR。infra repo 的 Deployment 目前固定引用 `ghcr.io/kyomind/weamind:latest`，而且雖然用了 `imagePullPolicy: Always`，它也只會在 Pod 重建時重新拉 image，不會主動讓現有 Pods 自動換版。所以這套流程目前有 CI 與 image publishing，但還不能算完整 CD。

## 今日延伸結論

- 若要把這條鏈補成較擬真的 production 流程，正式 deploy version 比較不應該追 `latest`，而應該追 app repo 的正式 release version image。
- 和 WeaMind CD 設計、release tag、infra 邊界與落地方案相關的延伸討論，已整理到 [docs/WeaMind實作CD討論與實踐.md](docs/WeaMind實作CD討論與實踐.md)。
