# 2026-04-30 CD Core Model and Two-Repo Boundaries

## Prework 內容

### 今日焦點

- 主題：CD 的最小概念骨架，以及在「app repo + infra repo」分層下，CD 通常會怎麼切責任與實作方向
- 範圍：先建立 CD 是什麼、它和 CI / image publish 的邊界、為什麼有些流程還不算完整 CD，以及在雙 repo 結構下 deploy source、deployment state 與責任邊界的最小模型；不進入 WeaMind repo 細節、不展開 GitOps 工具比較、不展開 Helm / Argo CD / Flux 深水區
- 目標：把「我其實不知道 CD 到底是什麼」補成「我至少能用白話講清楚 CD 在解什麼問題，並能理解雙 repo 專案裡常見的最小設計方向」
- 時間：控制在 45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的節奏是：上午先完成這份 prework，下午回到 VS Code 做 WeaMind 的 repo-backed lesson，明天再進 implement。請把教學收斂在足以支撐今天下午 lesson 與明天實作的最小理解，不要把今天擴成工具大全或 production 深水區。
- 我目前的真實狀態是：有多年後端開發經驗，也理解 CI 的基本用途，但對 CD 的概念骨架其實不穩，尤其容易把 CI、image publish、deploy、environment state 混在一起。請把教學重點放在白話骨架，而不是預設我早就懂這些詞。
- 今天請優先幫我建立通用概念與雙 repo 模型，不要先跳進任何特定專案的 workflow 細節，也不要一開始就展開過多工具名詞或 production-grade 複雜方案。

### 今天一定要學會的最小骨架

1. CD 解的不是「把程式碼驗證通過」，而是把已經可部署的 artifact 接到實際環境變更，讓系統真的換到指定版本或指定狀態。
2. CI、image publish、CD 不是同一件事；有 CI 與 image publish，不代表一定已經有完整 CD。
3. 一條流程是否算完整 CD，關鍵不在於有沒有 registry，而在於 artifact 之後如何影響 deployment state，以及環境是否真的被更新。
4. 在雙 repo 結構下，app repo 與 infra repo 通常不該混成一個責任來源；一邊偏向產物與版本，另一邊偏向環境宣告與 deployment state。
5. deploy source、source of truth、artifact、deployment state 這幾個詞雖然相關，但不是同義詞；至少要能講出它們的最小差異。
6. CD 的第一版不一定追求全自動；「版本可追溯、責任邊界清楚、變更可 review」通常比一步到位全自動更重要。

### 建議教學順序

1. 先用白話講 CD 是怎麼從 CI 延伸出來的，它在整條交付鏈裡補的是哪一段缺口。
2. 再切清 CI、image publish、deploy、CD 彼此的邊界，特別說明為什麼 image 已經進 registry，仍然可能還不算完整 CD。
3. 接著講 deploy source、artifact、deployment state、source of truth 的最小差異，避免名詞混成一團。
4. 然後用一個抽象的雙 repo 模型來說明：app repo 通常負責什麼，infra repo 通常負責什麼，為什麼這樣切比較穩。
5. 最後補一版「常見最小實作方向」：例如 app repo 產出正式版本，更新 infra repo 中宣告的版本，再由 infra repo 決定如何把這個版本套進環境；這裡只要講高階骨架，不要展開具體工具實作。

如果我卡住，請優先用更白話的例子或類比重講一次，再讓我重述；不要直接丟很多術語或工具選型表。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 若把情境縮成「一個 app repo + 一個 infra repo」，我目前理解的最小 CD 鏈路是什麼。
  7. 我今天下午回到 VS Code 做 lesson 時，應該拿去和 GitHub Copilot 對照 repo 的 2 個問題。
  8. 如果明天要進 implement，我認為最需要先確認的 1 到 2 個設計前提是什麼。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

- CD 補上的缺口，不是再做一次 CI，而是把已經可部署的 artifact 接到實際環境變更，讓某個環境真的換到指定版本或指定狀態。
- `CI`、image publish、deploy、`CD` 不是同一件事。image push 到 registry，只代表 artifact 已存在且可被使用，不代表環境已經採用它。
- `artifact -> deployment config -> deployment state` 是今天最重要的三層模型：image 是可部署產物，deployment config 是環境宣告，deployment state 是環境目前真的跑的狀態。
- 在雙 repo 模型下，app repo 偏向產出版本與 artifact，infra repo 偏向宣告環境要採用哪個版本，以及保存 deployment state 的 Git 歷史。
- `GitOps` 是 `CD` 的一種實作策略，不等於 `CD` 本身；它的核心是把 Git 中的環境宣告當成 source of truth，並讓 cluster 持續對齊它。

### 已能白話講清楚什麼

- `CI` 讓 app repo 產出一個可以部署的 image，但 image 只是候選版本，不會自己改變環境。
- image push 到 registry 還不算完整 `CD`，因為若 deployment config 沒改、cluster 也沒更新，artifact 只是躺在 registry 裡。
- app repo 與 infra repo 的分工可以先收成一句話：app repo 產出可部署版本；infra repo 決定某個環境是否採用這個版本，以及要怎麼跑。
- 在 `GitOps` 模型下，source of truth 不是單一份 yaml，而是被 Git 管控的 infra repo 環境宣告；當 Git 和 cluster 不一致時，應以 Git 為準。

### 目前還卡住什麼

- `deploy source`、source of truth、deployment config 在抽象層面已理解，但還需要回到 WeaMind repo 裡，看哪些實際檔案分別扮演這些角色。
- 單 repo `CD` 與雙 repo `CD` 的差異已經有概念，但ยัง需要對回 WeaMind：哪些部署邏輯在 app repo、哪些在 infra repo、哪些目前仍是人工步驟。
- 明天 implement 前，還需要進一步確認 WeaMind 第一版是否真的要讓 infra repo 成為 deployment state 的 source of truth，以及第一版是否先採 review 後 deploy 的半自動路線。

### 今日最重要的觀念

- `CD` 的判斷標準不是有沒有 registry，而是 artifact 之後有沒有真正影響 deployment config 與 deployment state。
- `CD` 不一定等於全自動；第一版更重要的是版本可追溯、責任邊界清楚、變更可 review。
- `artifact`、deployment config、deployment state 是三層，不應混成同一件事。
- `GitOps` 是把 Git 當成環境 source of truth 的一種 `CD` 做法，不是所有 `CD` 的唯一形式。
- 在雙 repo 模型裡，infra repo 決定版本是否被某個環境正式採用。

### 我目前理解的最小 CD 鏈路

- app repo 的開發者 push code，`CI` 先跑測試與 build，再產出 container image 並 push 到 registry。
- 產出的正式版本成為可部署 artifact，接著由 infra repo 更新 deployment config 中要採用的 image version。
- infra repo 的變更經過 commit、PR、review、merge 後，再由 `CD` 機制把這份宣告套到 cluster。
- cluster rollout 完成後，deployment state 才真正更新成新的版本。
- 最短版可收成：app repo 產出 artifact，infra repo 採用 artifact，`CD` 把 infra repo 的宣告套到環境，最後讓環境狀態更新。

### 帶回 VS Code 的問題

1. 在目前 WeaMind 的 app repo 與 infra repo 裡，哪裡是 artifact 的產出點，哪裡是 deployment config，哪裡目前代表 production / K8s 環境想要的狀態？
2. 如果要做 WeaMind 的第一版最小 `CD`，image version 應該由 app repo workflow 自動開 PR 更新 infra repo，還是先由人手動更新 infra repo？兩者的 trade-off 是什麼？

### 明天 implement 前想先確認的設計前提

- WeaMind 的第一版 `CD` 是否要明確宣告 infra repo 是 deployment state 的 source of truth。
- 第一版 `CD` 是否先採可 review 的半自動流程，而不是一開始就全自動直上 production。
