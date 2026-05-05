# Lessons AGENTS.md

## 用途

`learning/lessons/` 存放 repo-backed lesson 記錄。

使用本檔處理 lesson 的進入條件、mode routing、標準檔案與 active-turn routing。標準檔案細則放在 `rules/`，mode 擴充規格放在 `plugins/`，依當前階段按需讀取。

## 進入條件

進入本檔前，先由 `learning/AGENTS.md` 完成 prework decision。

lesson 適用於：

- WeaMind 專案內的實際對照
- YAML、manifest、workflow、文件或 debug sequence 的 repo-backed 理解
- QA、command drill、implementation、report、note、flashcards 的內部學習紀錄

純通用概念預習走 `learning/prework/AGENTS.md`。

## Lesson Mode

每日計畫若進入 lesson，應先明示 `Lesson mode`。合法值與讀取順序以 `learning/lessons/plugins/lesson-modes.md` 為準。

常見 routing：

- `normal`：讀本檔、相關 `rules/`，建立常態 lesson 時再讀 `lesson-template.md`。
- `command-heavy`：讀本檔後，再讀 `learning/lessons/plugins/command-heavy-mode.md`。
- `implement-heavy`：讀本檔後，再讀 `learning/lessons/plugins/implementation/AGENTS.md`、`implement-heavy-mode.md`、`implement-heavy-lesson-template.md`。

`01-outline.md` 負責鏡像當天已決定的 mode 與實際流程順序。

## 標準結構

每個 lesson 使用獨立資料夾：

`learning/lessons/YYYY-MM-DD-slug/`

`slug` 使用英文小寫與連字號，描述今天在專案裡真正學到的主題。

常態 lesson 預設建立：

1. `01-outline.md`
2. `02-qa.md`
3. `04-report.md`
4. `05-note.md`

有操作練習時加入：

5. `03-command.md`

implement-heavy mode 使用該 mode 專用骨架，通常包含 `06-implementation.md`，並預設不建立 `03-command.md`。

## Rules Routing

依 active file 讀取對應規則：

- `01-outline.md`：讀本檔的「Outline Rules」與 `lesson-template.md`。
- `02-qa.md`：讀 `rules/qa.md`。
- `03-command.md`：讀 `rules/command.md`；command-heavy mode 另讀 `learning/lessons/plugins/command-heavy-mode.md`。
- `04-report.md`：讀 `rules/report-note.md`。
- `05-note.md`：讀 `rules/report-note.md`。
- `## Flashcards`：lesson 收尾後再讀 `.github/prompts/generate-flashcards.prompt.md` 統一生成或精修。
- `06-implementation.md`：讀 `learning/lessons/plugins/implementation/implementation-guide.md`。

## Outline Rules

`01-outline.md` 用來規劃今天 lesson 的主題、範圍與執行順序。

建議包含：

1. 今日主題
2. 這次要解的專案問題
3. 外部預習是否需要與理由
4. 要對照的 repo 檔案
5. 建議學習順序
6. 今日 command / implementation 練習定位
7. 文件分工
8. Why / How 題
9. 完成標準

若當天計畫已指定 command-heavy 或 implement-heavy mode，`01-outline.md` 要寫明 mode、流程順序、驗收訊號與邊界。

## 預設流程

normal lesson 預設流程：

1. 用 `01-outline.md` 定義主題與範圍。
2. 用 `02-qa.md` 把 repo-backed 觀念骨架對清楚。
3. 若有操作練習，用 `03-command.md` 驗證系統輸出與判讀。
4. 過程中的延伸問答與暫時結論整理進 `05-note.md` 的 `## Notes`。
5. lesson 結束後，用 `04-report.md` 收斂真正學到的內容。

當天 mode 文件可以改變流程順序；`01-outline.md` 應把該決策落成當天的執行提醒。

## Active Continue

若 lesson 已在進行中，使用者只說「continue」或「繼續」，先看目前 active file：

- 停在 `02-qa.md`：依 `rules/qa.md` 繼續下一個主問題、引導點或收斂。
- 停在 `03-command.md`：依 `rules/command.md` 進入下一輪單一 command drill，等待使用者選擇、操作與回報。
- 停在 `06-implementation.md`：依 implementation guide 找目前 Step，收斂下一個具體動作。
- 互動部分完成後：再進 `04-report.md` 收斂。

## 內容原則

- 聚焦 WeaMind 的實際路徑、設計理由、trade-off 與 debug sequence。
- 優先保留三個月後仍值得複習的 repo-specific 理解。
- 讓 command、QA、note、report 各自承擔自己的工作，避免同一份檔案膨脹成第二份總結。

## 維護方式

每次完成一份 lesson 後：

1. 先依 `.privatedocs/12週計畫.md` 與 active phase plan 判斷正式進度。
2. 視需要更新 active phase plan 的 execution tracking。
3. 視需要更新 `.privatedocs/28day-progress.md`，只記錄使用者實際學到並能解釋的內容。
4. 視需要更新 `.privatedocs/ai-memories.md`，保留 AI 接手需要的高階摘要。

## Self-Check

建立或更新 lesson 後，確認：

- mode 與讀取文件符合 `learning/lessons/plugins/lesson-modes.md`
- 檔案結構符合本檔與對應 template
- active file 的細部規則已讀取對應 `rules/`
- `04-report.md` 保留給 lesson 收尾，不在互動開始前預寫成標準答案
- `05-note.md` 的 `Notes` 依實際互動內容回填；`Flashcards` 保留到 lesson 收尾時用 `.github/prompts/generate-flashcards.prompt.md` 統一處理
