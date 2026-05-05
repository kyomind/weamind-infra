# Lessons

`learning/lessons/` 用來存放 repo-backed lesson 記錄。

這裡只放 repo 內對照與驗收：WeaMind 實際架構、YAML、流量路徑、debug sequence、QA、command drill、report 與 note。

純通用知識預習仍放在 `learning/prework/`。

## 文件分工

- `README.md`：說明這個目錄的用途、檔案分工與閱讀入口。
- `AGENTS.md`：lesson 內部 AI 工作規則、進入條件、檔案結構與互動節奏。
- `rules/`：QA、command、report、note 的按需細部規則。
- `plugins/`：command-heavy、implement-heavy 等 mode 擴充規格。
- `lesson-template.md`：常態 lesson 的檔案骨架與最小範例。

一句話區分：`AGENTS.md` 管 routing，`rules/` 管標準檔案細則，`plugins/` 管 mode 擴充，`lesson-template.md` 管骨架。

## 標準檔案

每份 lesson 預設使用獨立資料夾：

`learning/lessons/YYYY-MM-DD-slug/`

常態 lesson 通常包含：

- `01-outline.md`
- `02-qa.md`
- `04-report.md`
- `05-note.md`

若當天需要操作練習，才新增：

- `03-command.md`

若當天明確是 implement-heavy mode，請依 `learning/lessons/plugins/lesson-modes.md` 與 implementation plugin 文件建立對應骨架。

## 閱讀入口

進入 lesson 流程前，應先由 `learning/AGENTS.md` 完成「是否需要 prework」的判斷。

已確認要進 lesson 時，再讀本目錄的 `AGENTS.md` 取得 lesson 內部 routing；依 active file 再讀 `rules/` 內對應細則。
