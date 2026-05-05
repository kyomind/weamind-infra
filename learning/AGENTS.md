# Learning AGENTS.md

## 用途

`learning/` 是 WeaMind infra 學習工作的入口層。

使用本檔選擇目前的學習路徑，然後讀取下一份 relevant rule file：

- `learning/prework/AGENTS.md`：外部概念預習與 lesson 後 homework 型補強。
- `learning/lessons/AGENTS.md`：repo-backed lesson、QA、command drill、implementation、note、report。
- `learning/lessons/lesson-template.md`：建立常態 lesson 骨架時使用。

## Routing Model

每個新的學習操作都從這裡開始。

順序如下：

1. 判斷這次是在延續既有工作、建立 prework，還是進入 lesson。
2. 若是新主題，先判斷使用者是否需要外部概念預習。
3. prework 或 homework 是當前路徑時，讀 `prework/AGENTS.md`。
4. 使用者已準備好進入 repo-backed lesson 時，讀 `lessons/AGENTS.md`。
5. 需要建立常態 lesson 骨架時，再讀 `lessons/lesson-template.md`。

## Prework Decision

判斷是否需要 prework 時，同時看兩個軸：

1. repo 是否已有足夠的專案證據支撐今天主題。
2. 使用者是否有足夠的概念骨架，可以有效使用這些證據。

專案證據包含 README、manifests、架構文件、incident notes、references、既有 lesson records。

概念骨架代表使用者已能說明基本機制，並把它拿來和本 repo 對照。

### Route To Prework

當主題需要先建立外部概念骨架，再進入 repo 對照時，讀 `learning/prework/AGENTS.md`。

常見訊號：

- 使用者缺基本機制或詞彙
- 主題涉及多方案比較或外部服務流程
- 主題需要先理解 controller、驗證流程、networking、IaC 或平台概念
- 直接進 VS Code lesson 會大幅變成通用概念解釋

判斷不清楚時，先問一個短 readiness question：

- 你現在是只差專案對照，還是連基本概念都還沒骨架？
- 今天主題裡，你最不確定的是 repo 怎麼做，還是它底層到底在做什麼？
- 若現在直接進 lesson，你預期自己會卡在概念還是卡在專案細節？

### Route To Lesson

當使用者已能進入 repo-backed comparison、QA、command drill、implementation work 或 report / note update 時，讀 `learning/lessons/AGENTS.md`。

常見訊號：

- 使用者已有基本概念骨架
- 主要工作是把概念對回 WeaMind manifests、docs、commands、debug sequence 或 implementation evidence
- 主題只需要在 lesson 中補少量背景提醒

## Post-Lesson Homework

若 lesson 已完成或接近完成，但還剩一小塊通用概念缺口，可以在 `learning/prework/` 建立 homework 型 prework。

這份 homework 應明確標示為 lesson 後補強，聚焦 lesson 中浮現的概念缺口，並依 `learning/prework/AGENTS.md` 處理命名與結構。

## Continue Requests

當使用者只說「continue」或「繼續」時，先確認目前學習位置：

1. 讀 `.privatedocs/12週計畫.md` 判斷當前 phase。
2. 讀 active phase plan：Phase 2 用 `.privatedocs/Phase2三週計畫.md`；Phase 1 歷史脈絡用 `.privatedocs/六週版學習計畫.md`。
3. 若有進行中的 lesson，先讀該 lesson 的 `02-qa.md`。
4. 依未完成工作 route 到目前 active 的 prework 或 lesson file。

## Self-Check

建立 prework 或 lesson 檔案後，對照：

- 本檔
- 實際 route 到的第二層 `AGENTS.md`
- 新建常態 lesson 骨架時，對照 `learning/lessons/lesson-template.md`

修正結構問題後，再開始互動 lesson 或交付 prework。
