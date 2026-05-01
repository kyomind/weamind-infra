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

### 問題：Fine-grained token 為什麼是目前比較推薦的做法

- 使用者觀察：`Fine-grained personal access token` 看起來是 GitHub 目前比較推薦的做法，想知道它是不是現在較好的實踐，以及好在哪裡。
- AI 回答：以這次 WeaMind 的第一版跨 repo PR 自動化來說，答案大致是「是」，因為它比傳統 PAT 更容易把權限縮到剛好夠用。
- 最核心的差別在於：fine-grained token 可以把權限縮到特定 repo，甚至只開少數幾個 repository permissions；不像傳統 PAT 常常是一次拿到較寬的 scope，再用「人記得不要亂用」來補治理。
- 以這次場景來說，我們只需要讓 app repo 的 workflow 對 `weamind-infra` 做三件事：clone、push branch、建立或更新 PR。fine-grained token 很適合把權限鎖成只覆蓋這三件事，例如只給 `Contents: Read and write` 與 `Pull requests: Read and write`，而且 repo 只選 `weamind-infra`。
- 它比較好的地方，不是單純「比較新」，而是更符合最小權限原則：若 secret 洩漏，影響面也比較容易被限制在單一 repo、單一用途，而不是連其他 repo 或其他 GitHub 能力一起暴露。
- 但更精確地說，fine-grained token 是「目前這個階段比較好的預設」，不代表它永遠是最終型態。若之後要把這條路做成更正式的多 repo automation、多人治理、可審計機器身分，GitHub App 往往會比 PAT 更進一步。
- 因此對 WeaMind 第一版來說，較合理的評價是：fine-grained token 是比沿用現成 CLI 憑證、或使用傳統寬 scope PAT 更好的實踐；它不是最重的治理方案，但作為第一版的正式收斂點，已經相當合理。

### 問題：Fine-grained token、classic PAT、GitHub App 在這次情境下怎麼選

- 使用者追問：若放在 WeaMind 這次「app repo release 後對 infra repo 提出 version update PR」的情境裡，`fine-grained token`、`classic PAT`、`GitHub App` 這三種做法應該怎麼看。
- AI 回答：可以把它們理解成三種不同重量級的授權方案，不是單純誰新誰舊，而是看目前場景需要多窄的權限、多少治理、以及願不願意承受設定成本。
- `Fine-grained token`：最適合 WeaMind 第一版目前這種單一路徑、單一 target repo、動作可明確縮小的場景。它的優點是設定成本不高，但已能把 repo 與權限範圍縮得很窄；缺點是本質上仍然是 PAT，機器身份與審計能力不如 GitHub App。
- `Classic PAT`：通常不是這次情境的優先答案。它能做事，但 scope 往往較粗，容易為了完成一條小路徑就把權限開得偏大。若是歷史包袱或某些 GitHub 功能限制，classic PAT 仍可能出現，但作為新的第一版實作選擇，通常不如 fine-grained token 合理。
- `GitHub App`：權限治理、機器身份、可審計性通常都更好，也更像較長期、較正式的解法。它特別適合多 repo、自動化規模更大、多人協作、或明確需要把「人類 token」與「系統身份」徹底分開的場景。
- 但對 WeaMind 這次第一版來說，GitHub App 的成本目前仍偏高，因為它會把注意力從「先把 release -> infra PR 路徑做通」轉移到 app 建立、安裝範圍、權限設定、私鑰管理與 token 取得流程。
- 所以若只看這次的實際需求，較合理的排序通常是：第一版先用 fine-grained token 把路做通；classic PAT 不作為優先選項；若之後這條路真的變成長期核心基礎設施，再評估升級成 GitHub App。
- 一句話收斂：在 WeaMind 這次情境裡，fine-grained token 是目前最平衡的第一版答案；classic PAT 偏舊且容易過權；GitHub App 更正式，但現階段重量較重。

### 問題：release-to-infra PR 第一次跑通時，實際卡在什麼地方

- 詳細失敗緣由、修正方式與 `GH_TOKEN` / fine-grained token 命名釐清，另見 `references/phase2/w8-release-to-infra-auth-debug.md`。
- 主 note 只保留結果：第一次卡在 target repo 的 git push 認證安裝，後續以 `gh auth setup-git` 補齊後成功建立 `weamind-infra` PR #4。

### 問題：為什麼不直接在 workflow / script 裡一路使用 `WEAMIND_INFRA_PR_TOKEN`

- 使用者提問：既然 secret 本來就叫 `WEAMIND_INFRA_PR_TOKEN`，那 workflow 與 script 是否直接一路使用這個名稱就好，何必再另外映射成 `GH_TOKEN`。
- AI 回答：如果只看「少一層命名」，直接用 `WEAMIND_INFRA_PR_TOKEN` 確實比較直覺；但若考慮工具邊界，我仍偏向保留現在這種做法：secret 名稱維持 repo / 用途語意，進到 runtime 時再映射成 `GH_TOKEN`。
- 理由是：`WEAMIND_INFRA_PR_TOKEN` 這個名字比較像業務語意，說明這顆 secret 是「給 WeaMind release-to-infra PR 用的 token」；而 `GH_TOKEN` 則是 `gh` CLI 與相關認證流程熟悉的慣例入口，屬於工具語意。
- 這樣分開後，邊界會更清楚：repo 層面知道這顆 secret 是做什麼的，script / CLI 層面則只依賴一個標準化的 `GH_TOKEN` 入口。
- 如果未來要換 secret 名稱、換 token 來源，甚至改成其他 credential provider，script 本身也比較不需要跟著改成 repo-specific 命名。
- 但反過來說，使用者的直覺也不是錯的：若整個流程都只服務這一條單一路徑，而且不打算重用 script，把 `WEAMIND_INFRA_PR_TOKEN` 直接傳進 script 也可以，只是那樣會讓 script 更直接依賴 repo-specific 命名。
- 一句話收斂：我會偏向「secret 名稱保留業務語意，runtime 變數採工具慣例」；不是因為一定更高級，而是因為這樣比較容易分清楚 repo 邊界與 CLI 邊界。

### 問題：`GH_TOKEN` 這個名字是不是我們自己臨時取的

- 使用者整理：這次 script 裡大量使用 `gh` CLI，而 `gh` CLI 很常需要 token 當成 GitHub API 與認證的入口，所以我們才按照常見慣例把 runtime 環境變數命名為 `GH_TOKEN`。
- AI 確認：這個理解是對的，而且比「只是想把名字縮短」更精確。
- 更準確地說，`GH_TOKEN` 不是我們這次流程裡臨時發明的命名，而是因為 script 內部確實在使用 `gh` CLI，所以順著它常見的 token 慣例入口去接。
- 也因此，這個命名應該被理解成「工具導向」而不是「業務導向」：重點不是 token 服務哪一條業務流程，而是這支 script 內有一個主要工具叫 `gh`，它需要一個穩定、熟悉的 token 入口。
- 若今天這支 script 沒有使用 `gh` CLI，而是改成純 `git`、`curl` GitHub API，或其他工具鏈，那 runtime 環境變數名稱就不一定還會叫 `GH_TOKEN`，因為那時候依賴的工具慣例可能已經不同。
- 所以更完整的說法是：我們現在用 `GH_TOKEN`，不是因為這條流程天生就該叫這個名字，而是因為目前這支 script 的主要 GitHub 操作工具是 `gh` CLI。

## Flashcards

<!-- 待 lesson 過程中回填 -->
