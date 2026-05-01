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

## Flashcards

<!-- 待 lesson 過程中回填 -->
