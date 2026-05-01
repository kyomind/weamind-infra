# 2026-05-01 Release-to-Infra Auth Debug Note

## 用途

- 這份 note 專門記錄 WeaMind 第一版 release-to-infra PR 流程在真實 runtime 驗證時遇到的認證問題、修正方式與命名釐清。
- 主 note 只保留短索引，避免 `05-note.md` 持續膨脹。

## 第一次失敗時發生了什麼

- WeaMind release `v1.2.2` 觸發 `publish-release.yml` 後，GHCR build/push 已成功完成。
- 失敗點出現在 `Open infra version PR` 這一步，也就是跨 repo script 要把 branch push 到 `kyomind/weamind-infra` 的時候。
- 具體錯誤訊息是：`fatal: could not read Username for 'https://github.com': No such device or address`。

## 失敗的真正原因

- 問題不是 repo 不存在，也不是 branch name 或 manifest path 寫錯。
- 問題也不是第一時間就能斷定是 token 權限不足。
- 真正的問題是：`gh repo clone` 雖然能成功 clone target repo，但進到新的工作目錄後，`git push` 仍需要一個 git credential helper 可理解的 HTTPS 認證來源。
- 換句話說，workflow 裡雖然已經有 token，但這顆 token 還沒有被正確安裝到 git push 這一層。

## 修正方式

- 在 `scripts/open_infra_version_pr.sh` 的 clone 完成並 `cd` 進 target repo 後，補上：
- `gh auth setup-git`
- 這一步會把目前流程裡可用的 `GH_TOKEN` 設成 git 可用的認證來源，讓後續 `git push` 能走 HTTPS 認證。

## 這個修正為什麼合理

- 這個修正是合理的，因為它補的剛好就是壞掉的那一層：不是改 workflow 邏輯，不是改 token 類型，也不是放大權限，而是補齊 git push 所需要的認證安裝。
- 它也符合第一版的最小修正原則：
- 不需要改成 SSH push。
- 不需要重寫成另一套 GitHub API commit / PR 流程。
- 不需要在 workflow YAML 裡再塞一段更醜的手工 credential 設定。
- 更精確地說，`gh auth setup-git` 不是萬用咒語；它只是對「目前這個以 `gh` CLI + HTTPS push 為核心的設計」來說，合理的最小補洞。
- 如果未來改成 GitHub App、改 checkout 方式、或 runner 環境不同，仍然要重新檢查認證鏈，而不是無條件照抄這個修法。

## `GH_TOKEN` 到底是什麼

- 你的理解是合理的，但要分兩層看。
- `GH_TOKEN` 本身是環境變數名稱，不是某一種 token 類型的正式名稱。
- 在這次 WeaMind workflow 裡，`GH_TOKEN` 這個環境變數實際承載的值，是 `secrets.WEAMIND_INFRA_PR_TOKEN`。
- 而 `WEAMIND_INFRA_PR_TOKEN` 這個 secret 目前裝的，是你後來建立並覆蓋進去的 fine-grained personal access token。
- 所以更精確的說法是：
- `GH_TOKEN` 是流程裡拿來傳遞認證的變數名。
- 這個變數裡目前放的實際憑證，是我們建立的 fine-grained token。
- 因此如果只說「`GH_TOKEN` 就是 fine-grained token」，語意上不夠精確；但如果你是想表達「這個變數現在實際指向的就是那顆 fine-grained token」，那這個理解是對的。

## 實務收斂

- 在這次流程裡，最不容易混淆的說法是：
- workflow 透過 `GH_TOKEN` 這個環境變數，把 `WEAMIND_INFRA_PR_TOKEN` secret 的值傳給 `gh` CLI 與 git 認證流程。
- 而目前那個 secret 的值，是一顆只授權 `weamind-infra` 的 fine-grained token。