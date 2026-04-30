# 2026-04-30 WeaMind CD Current State and Boundaries Report

## 今日收斂

- 今天不是在重學 `CD` 名詞，而是把上午 prework 的三層骨架正式對回 WeaMind 目前真的有的 workflow、image tag 策略、`Deployment` 宣告方式與兩個 repo 的責任邊界。
- 今天已經把三個核心問題收斂清楚：WeaMind 為什麼還不算完整 `CD`、正式 deploy source 應該追哪種版本、以及 app repo 與 infra repo 的最小分工應該怎麼切。

## 狀態

- 已完成

## 使用者原本卡住什麼

- 雖然已經能直覺說出 WeaMind 有 `CI`、會 publish image、`Deployment` 也有在用 image，但還沒有把這幾段正式拆成 artifact、deployment config、deployment state 三層來看。
- 對 `imagePullPolicy: Always` 的理解接近正確，但還容易滑向「registry 的 `latest` 變了，apply 後就會自動吃到新版本」這種過度簡化。
- 對 version tag 也已經有方向感，但還沒有完全把 `latest`、`sha-<short_sha>`、完整 release version、minor、major 各自的用途與穩定性切乾淨。
- 對 app repo 與 infra repo 的責任邊界，已碰到核心，但還需要更明確地把「版本產出責任」和「deployment state 控制權」分開。

## WeaMind 現況為什麼還不算完整 CD

- WeaMind 目前已經有 `CI` 與 image publishing：`CI` 先做檢查與驗證，之後由 publish workflow build 並 push image 到 `GHCR`。
- 但 infra repo 這邊的 [manifests/deployment.yaml](manifests/deployment.yaml) 目前仍直接追 `ghcr.io/kyomind/weamind:latest`，Git 裡沒有正式記錄「cluster 現在要採用哪個 release version」。
- `imagePullPolicy: Always` 只保證新 Pod 建立時會重新拉 image，不保證 registry 裡的 `latest` 一更新，既有 Pod 就會自動換版，也不保證單純重新 apply 相同 manifest 就一定 rollout。
- 所以現在真正缺的不是 artifact，也不是完全沒有 deployment config，而是 artifact 產出後，沒有一條正式定義好的鏈路，把版本更新帶進 deployment config，再可靠地套進 deployment state。

## 正式 deploy source 應該追哪種版本

- 第一版正式 deploy source 應該追完整 release version，例如 `1.1.4`，而不是 `latest`、minor tag 或 major tag。
- `latest` 是 mutable tag，語意太模糊，Git 很難清楚記錄某個環境到底採用了哪個正式版本。
- `sha-<short_sha>` 雖然可追到 commit，適合 debug 與追 build 來源，但它比較像工程內部識別，不是最適合人類溝通的正式部署版本。
- minor tag 與 major tag 雖然比 `latest` 更有語意，但它們仍然會前移；真正穩定、可回滾、可精準溝通的版本點，仍然是完整 release version。

## app repo 與 infra repo 的責任邊界

- app repo 應負責 build image、publish image，以及定義什麼是正式可部署版本。
- infra repo 應負責宣告 cluster 目前要跑哪個版本、保存 deployment state 的 Git 歷史，並決定何時把這個版本真正 deploy 進 cluster。
- 因此第一版最合理的邊界，不是讓 app repo 直接拿 cluster credentials 改叢集，而是讓 app repo 在 release 成功後，只把正式版本變更送到 infra repo。
- 這樣可以把 artifact 產出責任與 deployment state 控制權切開，也能保住 repo 邊界、權限分工與 production 版本採用決策的可追溯性。

## 明天 implement 前的最小方向

- 明天最小可落地方向，應該是只讓完整 release version 進入正式 `CD` 鏈路。
- 最小鏈路可收成為：app repo 發佈正式 release、release workflow push 對應 image tag、接著自動對 infra repo 開 PR，只更新 `Deployment` 所採用的完整版本。
- 這個 PR 先經 review / merge，再由 infra repo 這一側決定後續是人工 apply，還是由 infra-side workflow 負責 deploy。
- 第一版先做到「release -> infra repo version PR」就已經很有價值，因為它先把正式 deploy source、repo 邊界與 deployment state 的 Git 記錄建立起來；是否要把 merge 後自動 deploy 也一併串起來，可以放在下一步再收。

## 今日真正留下來的核心收穫

- 我今天真正收穫的不是更多 `CI/CD` 術語，而是把 WeaMind 當前狀態拆成可驗證的三層：artifact 已經會產出，deployment config 仍然沒有正式版本化，deployment state 也還沒有被這條版本鏈路可靠接起來。
- 我也把 deploy source 的判準講準了：不是「哪個 tag 看起來比較常用」就選哪個，而是要看它是否 immutable、可追溯、可回滾、可清楚溝通。
- 另外一個關鍵收穫是，第一版 `CD` 的價值不在於自動化越多越好，而是在於先把 app repo 與 infra repo 的責任邊界立住，讓正式版本採用流程可被 review、追蹤與解釋。

## 學完後已能講清楚什麼

- 能用 WeaMind 目前的 workflow 與 manifest 證據，說清楚它為什麼現在是 `CI` + image publishing，而還不是完整 `CD`。
- 能講清楚 `imagePullPolicy: Always` 保證什麼、不保證什麼，並說明為什麼 `latest` 不適合作為正式 deploy source。
- 能把 `latest`、`sha-<short_sha>`、完整 release version、minor、major 的用途與穩定性分開講。
- 能說清楚 app repo 與 infra repo 的責任邊界，並提出「release 後自動開 infra PR」這條第一版最合理的最小方向。

## 仍待補強什麼

- 今天刻意沒有展開明天 implement 需要的 workflow 細節，例如 token 權限、PR automation 寫法、merge 後 deploy 觸發點與 rollback 細節。
- `latest` / `sha` 路徑與正式 release 路徑目前仍是兩條分開的 publish workflow；它們為什麼可接受、什麼時候值得優化成一次 build 多處 reuse，今天只收在 note，還沒有變成主線設計題。
- 若之後要把第一版 `CD` 講得更完整，還可以再補一輪：infra repo merge 後是人工 deploy、workflow deploy，還是逐步走向更接近 GitOps 的模式。

## 下一步

- 先以今天收斂好的說法，進入明天 implement 所需的最小設計：release 成功後如何自動更新 infra repo 的 image version。
- implement 時優先驗證的不是「能不能一次做完整自動 deploy」，而是「完整 release version 能不能可靠地進到 infra repo 的 deployment state」。
- 若明天實作順利，再決定 infra repo merge 後的 deploy 機制要先人工保守處理，還是加上最小 automation。
