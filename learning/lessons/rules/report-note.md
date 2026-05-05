# Report And Note Rules

## 適用時機

讀取本檔處理：

- `04-report.md`
- `05-note.md` 的結構、`學習注意事項` 與 `Notes`
- `05-note.md` 裡 `## Flashcards` 的保留位置與格式

`## Flashcards` 在 lesson 收尾後才處理；產生或精修卡片時，另讀 `.github/prompts/generate-flashcards.prompt.md`。

## `04-report.md`

`04-report.md` 在 lesson 結束後收斂今天真正學到的內容，是 lesson-level 結論頁。

建議順序：

1. 今日主題
2. 狀態
3. QA 收斂了什麼
4. 使用者原本卡住什麼
5. 今日 command 練習收斂（有 command drill 時才放）
6. 今日真正留下來的核心收穫
7. 學完後已能講清楚什麼
8. 仍待補強什麼
9. 下一步

Report 寫作原則：

- 在 lesson 結束後集中回填。
- 過程中若出現穩定結論，可以先暫存，但最後仍重新整理。
- QA 收斂段落保留理解結論，不重述 QA 題目細節。
- command 收斂用能力語句，不寫成操作流水帳。
- lesson 停在 QA、command 或 implementation 階段時，先完成互動，再進 report 收斂。

## `05-note.md`

`05-note.md` 承接 lesson 中途的延伸問答、補充說明與暫時結論。

固定結構：

1. `## 學習注意事項`
2. `## Notes`
3. `## Flashcards`

適合放：

- 外部預習回帶重點
- lesson 邊界
- 待驗證的 repo 對照點
- 使用者延伸提問與 AI 補充
- 尚未收斂進 `04-report.md` 的暫時結論
- 收尾後產生的 flashcards

Note 寫作原則：

- 建立 lesson 時一起建立 `05-note.md`。
- 一件事情記一則。
- `學習注意事項` 與 `Notes` 內部用 H3 分組。
- 初始化時，`學習注意事項` 可以先有外部預習內容；`Notes` 與 `Flashcards` 保持空白或只放 HTML comment 佔位。
- QA、command、implementation 的額外追問若超出當前最小閉環，整理到 `Notes`。
- 課程互動中更新 `學習注意事項` 與 `Notes`；`## Flashcards` 保留到 lesson 收尾後統一處理。

## Flashcards

`## Flashcards` 固定保留在 `05-note.md`。

卡片整理原則：

- 課程互動中保持空白或保留既有卡片，不在互動中即時新增。
- lesson 收尾並完成 `04-report.md` 校準後，再用 `.github/prompts/generate-flashcards.prompt.md` 統一生成或精修。
- 卡片直接放在 `## Flashcards` 底下，用 bullet list Markdown。
- 每張卡片只放一個概念。
- 優先保留三個月後仍值得複習的 repo-specific 理解。
