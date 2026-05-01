# 2026-05-01 WeaMind CD Minimum Skeleton Report

## 今日主題

- 以 WeaMind 既有 release 與 infra 邊界為基礎，完成第一版可驗收的 CD 最小 skeleton。

## 狀態

- 已完成。

## QA 收斂了什麼

- 這次 QA 沒有重做設計題，而是回到 implementation 之後真正留下的三個判斷軸：第一版 CD 到底打通到哪裡、為什麼 merge 後仍保留人工 deploy、以及 `GH_TOKEN` / `WEAMIND_INFRA_PR_TOKEN` / fine-grained token 之間的層次關係。
- 在自動化邊界上，已正式收斂成 **release -> infra PR**，而不是 release 後直接改 cluster。這讓 app repo 的 release 只負責提出 infra 變更，不直接碰 runtime state。
- 在 deploy 邊界上，已正式收斂成 merge 後維持人工觸發，但把操作入口標準化成 `make deploy` / `make rollback`，而不是每次靠記憶手打長指令。
- 在 auth 與命名邊界上，已能分清楚 secret 名稱、runtime 環境變數名稱與實際 token 類型不是同一層；`GH_TOKEN` 在這次是工具慣例入口，`WEAMIND_INFRA_PR_TOKEN` 則是 repo 內的用途型命名。

## 使用者原本卡住什麼

- 一開始真正的卡點，不是「不知道要不要做 CD」，而是這個第一版到底要收在哪個邊界才算既完成、又不過度自動化。
- 在 implementation 過程中，另一個實際卡點是跨 repo automation 的認證想像還不夠精確，容易把「有 token」直接等同於「git push 一定會成功」。
- 在學習收尾階段，則卡在幾個名稱容易混淆：`GITHUB_TOKEN`、`GH_TOKEN`、`WEAMIND_INFRA_PR_TOKEN`、fine-grained token 看起來都像 token，但它們其實分別代表不同層級的東西。

## 今日真正留下來的核心收穫

- 今天真正完成的，不只是把方案講清楚，而是把 WeaMind 第一版 CD 的最小可運作路徑做出來：app repo 發生正式 release 後，能自動對 `weamind-infra` 提出 image version update PR。
- 這條路徑的價值在於，它把 release automation 與 cluster runtime state 刻意切開，讓 app 端只能推進到「提出 infra 變更」，不能直接把新版本送進叢集。
- 我也把 merge 後的人工作業面正式標準化了：deploy 不是模糊地「做一些 kubectl」，而是 `apply + rollout status`；rollback 也不是泛稱，而是明確對應 `kubectl rollout undo`。
- 另外，這次真實 runtime 驗證也留下了一個很有價值的 debug 教訓：`gh repo clone` 成功，不代表 target repo 內的 `git push` 認證已經完整安裝；這就是後來需要 `gh auth setup-git` 的原因。

## 學完後已能講清楚什麼

- 能用短版答案講清楚 WeaMind 第一版 CD 的完整邊界：自動化只到 release -> infra PR，merge 後 deploy 仍由人透過 `make deploy` 觸發。
- 能講清楚為什麼 infra repo 應追完整 release version，而不是 `latest`、minor 或 major tag：因為第一版要讓 Git 明確記錄正式 deploy source。
- 能講清楚這次跨 repo PR 的實作本質：不是抽象的「跨 infra 溝通」，而是 app repo workflow 取得 target repo 工作目錄後，用正常 Git 流程改檔、push branch、開 PR。
- 能講清楚 `GH_TOKEN` 與 `WEAMIND_INFRA_PR_TOKEN` 的命名分工：前者偏工具慣例入口，後者偏 repo / 用途語意。

## 仍待補強什麼

- merge 後的 deploy / rollback 雖然已有標準入口，但目前仍停在人工觸發，還沒有做 merge 後自動 apply 或更完整的 rollout 觀測自動化。
- 目前的跨 repo 寫入權限做法，對第一版來說已經合理，但若之後這條路徑變成長期核心基礎設施，仍可再評估是否升級成 GitHub App 等更正式的機器身份方案。
- `06-implementation.md` 這次在 step 編號上留下了一些迭代痕跡，之後若要把 lesson 再整理得更乾淨，可以補做一次文件衛生清理。

## 下一步

- 先用這份 lesson 的 flashcards 穩住三個最值得複習的邊界：自動化停點、merge 後人工 deploy 邏輯、以及 token / env var / tool 慣例的分層。
- 若之後要繼續往前推 CD，可以優先從 `docs/todo-weamind-cd-future-optimizations.md` 挑一條做下一版，例如 merge 後 deploy automation、觀測命令補強或 auth 治理升級。
- 若只是日常操作，現階段就把這版路徑當成正式工作流：release 後看 infra PR、merge 後用 `make deploy`，需要回退時用 `make rollback`。
