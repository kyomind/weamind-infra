# 2026-05-01 WeaMind CD Minimum Skeleton Note

## 學習注意事項

- 今天優先把 deploy source 與 infra repo version state 落成可驗收 skeleton，不把 deploy-to-cluster 自動化一起攤開。
- 若過程中冒出 token 權限、跨 repo PR automation、merge 後 apply、GitOps controller 或 rollback 進階設計，先記在這裡，不讓 `06-implementation.md` 的主線失焦。
- 若最後只能完成設計稿或 skeleton，也要明確標示哪一步仍未做 runtime 驗證。

## Notes

### Infra PR 是否需要展開 app 改動摘要

- 第一版不需要在 infra version update PR 內直接展開 app 層的功能改動摘要。
- 對這類 infra PR 來說，最小必要資訊通常只要包含：變更檔案、image tag 由哪個版本更新到哪個版本、以及對應的 release。
- 若需要讓 reviewer 往回追 app 層脈絡，比較好的做法不是重寫 app 改動摘要，而是附上 release reference。
- 以 WeaMind 現況來說，附上 release 頁面連結就是一個合理且低成本的做法，例如：https://github.com/kyomind/WeaMind/releases/tag/v1.2.1
- 若未來 release governance 變重，或有多人跨層 review，infra PR 再擴充成附 release notes 連結，會比直接在 PR body 複製 app 變更摘要更乾淨。

### 問題：跨 repo 發 PR 的重點，是不是其實在 CI 裡先拿到 target repo 的工作目錄

- 使用者提問：原來跨 repo 發 PR 的重點應該是在第二步。權限是一部分，但更核心的是在這個 CI 流程裡 clone 或 check out `weamind-infra`，之後只要權限允許，就能在那個 repo 上做修改、push branch、開 PR。這算不算常見的跨 infra 溝通方式。
- AI 回答：對第一版來說，這個理解是對的，而且比「先討論 token 類型」更接近實作本質。
- 更精確地說，這不是抽象的「跨 infra 溝通」，而是很常見的「一個 workflow 對另一個 repo 提出變更」模式：先在 CI 內拿到 target repo 的工作目錄，修改目標檔案，然後用正常的 Git 流程送出 branch 與 PR。
- 以 WeaMind 這次的情境來說，具體就是：app repo 的 release workflow 取得 `weamind-infra` 的工作目錄，更新 `manifests/deployment.yaml` 的 image，push 一個 branch，再對 `weamind-infra` 開 PR。
- 權限仍然重要，但它比較像這條路徑的通行證；真正的機制本身，仍然是「在 target repo 裡做一次正常的 Git 變更提案」。
- **這種做法在 GitHub Actions、config repo、GitOps 相關流程中都很常見**，因為它有幾個第一版很實用的優點：容易理解、容易 debug、所有變更都留在 target repo 的 PR 歷史裡，而且 review 邊界清楚。
- 更成熟或更大規模的做法當然存在，例如 `repository_dispatch`、另一個專職 workflow、GitHub App，或 image automation controller；但對 WeaMind 第一版來說，直接 clone target repo、改檔、push branch、開 PR，是最常見也最容易落地的起手式之一。

## Flashcards

<!-- 待 lesson 過程中回填 -->
