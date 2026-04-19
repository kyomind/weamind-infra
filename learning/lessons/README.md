# Lessons README

## 用途

`learning/lessons/` 用來存放 VS Code 內部學習記錄。

這份 README 是 `learning/` 底下的第二層規則檔。

它有一個前提：你已經先讀過 `learning/README.md`，而且已經完成「今天是否需要 prework」的判斷。

只有在下面兩種情況，本檔才應被打開：

1. 今天已判斷不需要 prework，現在要直接進 lesson。
2. 今天的 prework 已完成，現在要進入 repo 內 lesson。

若還沒完成這個判斷，應先回到 `learning/README.md`，而不是直接在這裡開始建 lesson。

這裡只記錄兩種內容：

1. GitHub Copilot 在 repo 內帶著使用者做的專案對照。
2. 與 WeaMind 實際架構、YAML、流量路徑、debug sequence 直接相關的學習整理。

純通用知識預習仍放在 `learning/prework/`，這裡只放 repo 內對照與驗收。

一句話區分：

- prework 是外部預習。
- lessons 是內部對照與驗收。

---

## 和 prework 的分工

本檔只負責 lesson 內部規格，不負責決定今天要不要 prework。

那個判斷屬於 `learning/README.md` 的責任。

`learning/prework/` 負責：

1. 外部 ChatGPT 類服務的每日預習大綱。
2. 純知識骨架與白話理解。
3. 不直接綁定 repo 實況的概念預習。

`learning/lessons/` 負責：

1. WeaMind 專案內的實際對照。
2. 為什麼這個 repo 這樣設計。
3. 流量路徑、trade-off、debug 故事。
4. 面試時要能講出來的專案特定說法。

因此這份 README 的預設前提是：

1. 上層流程判斷已完成。
2. 現在已確定要進入 `learning/lessons/`。
3. 接下來才輪到本檔定義 lesson 本身的結構與節奏。

---

## 和 lesson-template 的分工

`lesson-template.md` 是常態 lesson 的骨架工具，不是第二份規則手冊。

兩者分工應固定如下：

1. `README.md` 負責規則、流程、判斷條件與欄位邊界。
2. `lesson-template.md` 只負責快速建立常態 lesson 的檔案骨架與最小範例。

因此：

1. 若問題是「今天該不該建 `03-command.md`」、「QA 能不能先放答題引導」、「`05-note.md` 初始化能先放什麼」，應以本檔為準。
2. 若問題是「今天新 lesson 要先開哪些檔案」、「每份檔案最小空殼長什麼樣」，才看對應 template：常態 lesson 看 `lesson-template.md`，implement-heavy mode 看 `reference/lesson-plugins/implement-heavy-lesson-template.md`。
3. 模板裡若出現較長的規則段落，應優先檢查是否其實該搬回本檔，而不是讓 template 自己長成第二份 README。

一句話原則：README 管規則，template 管骨架。

補充原則：若某天有明確的例外節奏，例如 command-heavy mode 或 implement-heavy mode，優先採獨立補充文件做按需揭露，不把短期例外直接堆回本檔。

mode 的合法 enum、決策來源與 plugin 索引，統一以 `reference/lesson-plugins/lesson-modes.md` 為準。

---

## 何時應新增 lesson

遇到下面情況，就應新增一份 lesson：

1. 今天在 VS Code 內有完成一段專案特定的學習。
2. 已把通用概念對到實際 YAML、架構或操作。
3. 有形成一段值得回顧的 why、trade-off 或 debug sequence。
4. 已經判斷今天不需要外部預習，或外部預習已完成，現在要進入 repo 內對照。

如果今天只有純知識預習、沒有碰 repo，通常不需要在這裡新增 lesson。

建立新 lesson 時，入口順序如下：

1. 先看本檔，確認今天已經進入 lesson，而不是還停在 prework 判斷。
2. 再看當天計畫的 `Lesson mode`；合法值與對應入口以 `reference/lesson-plugins/lesson-modes.md` 為準。
3. 若 `Lesson mode` 是 `normal`，改讀 `lesson-template.md`；若是 `implement-heavy`，改讀 `reference/lesson-plugins/implement-heavy-mode.md` 與 `reference/lesson-plugins/implement-heavy-lesson-template.md`。

---

## 這份 README 的責任邊界

本檔負責：

1. lesson 的進入條件。
2. lesson 目錄結構。
3. lesson 內部固定流程。
4. 每一份檔案的分工與寫法。

本檔不負責：

1. 判斷今天是否需要 prework。
2. prework 的命名與段落規則。
3. learning 整體入口導覽。

如果問題是「現在應不應該先做 prework」，請回 `learning/README.md`。

如果問題是「prework 該怎麼寫」，請看 `learning/prework/README.md`。

---

## 開始前檢查

正式開始 lesson 前，建議至少確認：

1. 今天是否已先在 `learning/README.md` 完成流程判斷；若需要 prework，應先完成 prework，再進入 lesson。
2. lesson 檔案結構是否符合本檔與對應骨架；常態 lesson 看 `lesson-template.md`，implement-heavy mode 看 `reference/lesson-plugins/implement-heavy-lesson-template.md`。
3. 若當天計畫已明確指定 command-heavy mode，是否已另外讀取 `reference/lesson-plugins/command-heavy-mode.md`，而不是把例外規格混在本檔內一起看。
4. 若當天計畫已明確指定 implement-heavy mode，是否已另外讀取 `reference/lesson-plugins/implement-heavy-mode.md`，並同步讀取 `reference/lesson-plugins/implement-heavy-lesson-template.md`。
5. 若當天計畫沒有指定 mode，內部流程是否仍是 QA → command → report；若當天計畫已指定 mode，`01-outline.md` 是否已把這個決策與實際流程順序寫成提醒。
6. `03-command.md` 若存在，是否真的符合 command drill 的節奏，而不是單純指令清單。
7. `04-report.md` 是否保留回填空間，而不是一開始就預寫完整答案。
8. 若這次是新建 lesson 骨架，`05-note.md` 是否仍符合初始化狀態：只有 `學習注意事項` 可以先有內容，`Notes` 與 `Flashcards` 必須保持空白，最多只留 HTML comment 這類特殊註記作為佔位。

---

## 標準結構

每個 lesson 都應使用獨立資料夾，格式如下：

`learning/lessons/YYYY-MM-DD-slug/`

`slug` 使用英文小寫與連字號，描述今天在專案裡真正學到的主題，而不是抽象大分類。

範例：

- `2026-03-10-weamind-traffic-path`
- `2026-03-11-pod-to-vm-and-endpoints`
- `2026-03-12-ingress-debug-sequence`

每份 lesson 預設建立這四份檔案：

1. `01-outline.md`
2. `02-qa.md`
3. `04-report.md`
4. `05-note.md`

若當天主題需要搭配 `kubectl` 或其他實作指令練習，再另外加：

5. `03-command.md`

若當天計畫已明確指定 implement-heavy mode，請直接改讀 `reference/lesson-plugins/implement-heavy-mode.md` 與 `reference/lesson-plugins/implement-heavy-lesson-template.md`，並一次建立 `01-07` 全部七份檔案。

範例：

- `learning/lessons/2026-03-10-weamind-traffic-path/01-outline.md`
- `learning/lessons/2026-03-10-weamind-traffic-path/02-qa.md`
- `learning/lessons/2026-03-10-weamind-traffic-path/03-command.md`
- `learning/lessons/2026-03-10-weamind-traffic-path/04-report.md`
- `learning/lessons/2026-03-10-weamind-traffic-path/05-note.md`

implement-heavy mode 的正式流程與 `06` / `07` 規則，不在本節展開，改由上述兩份 plugin 文件維護。

---

## 檔案分工

### `01-outline.md`

用途：規劃今天 lesson 的主題、範圍與執行順序。

建議包含：

1. 今日主題。
2. 這次要解的專案問題。
3. 要對照的 repo 檔案。
4. 建議學習順序。
5. 要追問的 Why / How 題。
6. 這份 lesson 的完成標準。

補充原則：

1. 常態 lesson 預設把流程寫成「先 QA，再 command，最後回 report 收斂」。
2. 若當天計畫已指定 command-heavy mode 或 implement-heavy mode，`01-outline.md` 應把這個決策與今天的實際流程順序明確寫出來，作為 lesson 內部提醒，而不是重新做決定。
3. 重點是交代今天要先解哪些問題，以及 command drill 或 implementation 要驗證哪條路徑，不需要把流程寫得過細。

### `02-qa.md`

用途：記錄今天的專案對照題、使用者回答摘要與 AI 修正。

建議包含：

1. 3 到 5 題小範圍題目。
2. 每題對應的 repo 檔案或操作目標。
3. 使用者回答摘要。
4. AI 修正或補充。
5. 每題狀態，例如：未開始、進行中、已完成。

若今天明確屬於 command-heavy mode，QA 的短版定位題規格請另外參考 `reference/lesson-plugins/command-heavy-mode.md`，不要把那套例外節奏當成常態規則。

格式建議：

1. 每題用 `## Q1`、`## Q2` 這種層級。
2. 題內欄位用 `### 題目`、`### 對照檔案`、`### 使用者回答摘要` 這類 H3。
3. 每題預設都要有一個 `### 答題引導` 區塊，作為答題引導。
4. 避免大量單行粗體欄位，讓整份 QA 更穩定、好掃讀。
5. 題目應盡量小、具體、可直接對照 repo，不要把一題寫成一整個章節。
6. 在 `### 答題引導` 區塊裡，若題目本身有明確順序，使用 ordered list；若只是提醒要回答哪些重點，使用一般 bullet list。
7. 在 `### AI 修正與補充` 這個區塊裡，AI 應只把新結論中的少數「關鍵句」或「關鍵詞」加粗，方便之後複習時快速掃到重點；不要把整段結論或連續多句話大面積加粗。
8. 若 AI 回答中出現 `kubectl` 指令、Pod 狀態、欄位名、資源名、環境變數名或其他技術術語，應優先使用 inline code 標示，例如 `events`、`CrashLoopBackOff`、`POSTGRES_HOST`、`kubectl logs --previous`，讓自然語言與術語更容易分開掃讀。

提問風格原則：

1. QA 預設採低壓引導式提問，不以高壓猜題為目標。
2. 先給完整主問題，再搭配 `### 答題引導` 提供答題引導，讓使用者一開始就知道這題應回答哪些面向或應依什麼順序回答。
3. 這個引導不是為了暴露答案，而是為了降低答題邊界的不確定性；引導應聚焦在回答面向、順序或比較軸線，不要直接把結論寫出來。
4. 答題引導是 QA 的預設結構，不需要等使用者說「太難了」才補上。
5. 引導做完後，仍必須再收斂回原本那題的完整答案，不要讓整份 lesson 只剩零碎子題。
6. QA 因為範圍通常比 command drill 大，可以保留一定程度的引導，幫助使用者先抓到題目邊界；但不要在主問題剛拋出時就把答案路徑鋪得過滿。
7. 若 QA 過程中出現額外追問，但它不屬於當前主問題的最小完成範圍，且獨立性較高或偏延伸補充，應優先整理進 `05-note.md`；`02-qa.md` 只保留完成該題所需的最小結論，避免 QA 膨脹成第二份 note。
8. 若 lesson 停在 `02-qa.md`，而使用者只說「continue」或「繼續」，預設是回到當前 QA 互動回合：繼續下一個主問題、同一題的下一個引導點，或同一題的收斂，不是直接代寫後面所有題目。

答題引導原則：

1. QA 題目預設就應搭配 `### 答題引導`，不再以「使用者卡住後才補引導」為前提。
2. `### 答題引導` 的功能是提供答題引導，不是把 QA 改寫成選擇題。
3. QA 預設不使用選擇題；選擇題式三選一保留給 `03-command.md` 的 command drill。
4. AI 應提供 2 到 4 個子題或回答面向，不另開新 Q 編號。
5. 若題目本身有明顯先後順序，使用 ordered list；若只是提醒應涵蓋哪些重點，使用一般 bullet list。
6. 子題設計應回答「這題要答到哪些部分」或「可以依什麼順序回答」，而不是直接把標準答案先寫出來。
7. 小題全部完成後，再把答案收斂回原本那一題的完整結論。
8. 建立 lesson 骨架時，預設就應為每一題先寫出最小的 `### 答題引導`，不再等互動過程中才補。

### `03-command.md`

用途：記錄指令練習，但重點是讓之後複習時能快速看懂「當時在驗證什麼、看到了什麼、因此能下什麼結論」，不是把整段互動逐字存檔。

建立原則：

1. 先判斷今天主題是否真的需要 command drill；若不需要，則不要建立 `03-command.md`。
2. 若今天決定需要 command drill，建立 lesson 骨架時就應一次把整份 `03-command.md` 的主要題目骨架先建好，而不是等互動進行到哪一輪才只補哪一輪。
3. 這裡所說的「先建好題目骨架」，預設是先寫出今天預計的 2 到 4 輪情境、每輪要驗證的問題，以及候選指令區塊。若今天明確是 command-heavy mode，請另外讀 `reference/lesson-plugins/command-heavy-mode.md` 的增量規格。
4. 若 lesson 一開始已判斷今天主題不適合 command drill，就不要為了形式完整而保留空白或半成品的 `03-command.md`。

建議包含：

1. 今日指令練習目標。
2. 這次要驗證的路徑或問題。
3. 每一輪 command 的最小閉環：問題、指令、關鍵輸出、AI 判讀、一句話收斂、狀態。
4. 最後收斂：今天用哪些指令看懂了什麼。
5. 哪些地方還不順手。

操作節奏：

1. AI 先給一個明確情境，說清楚這一輪要驗證什麼。
2. 預設直接給 3 個可選指令，讓使用者先做判斷；只有在題目非常單純或明顯不適合時，才不使用三選一。這 3 個候選指令在即時互動中也應直接用同一個 `bash` code block 呈現，不要改寫成一般條列或行內文字。
3. 使用者先選一個指令，直接到真實環境執行，然後把看到的輸出與自己的選擇理由一起回覆。
4. AI 根據輸出與使用者理由，協助判讀、修正，最後收斂成一句可複習的結論。

引導原則：

1. command drill 本身已經透過情境與三選一提供了基本引導，因此 AI 不應再額外加上「建議先走哪條最省力路線」或過度縮小判斷空間。
2. 若使用者先選了不夠精準但仍合理的指令，應優先保留這個試錯與修正過程，因為這本身就是 command drill 的一部分。
3. command drill 的收斂重點是判讀與修正，不是預先替使用者排除所有錯誤選項。
4. 若 command drill 過程中出現額外追問，但它不屬於當輪最小閉環的必要部分，且獨立性較高或偏延伸補充，應優先整理進 `05-note.md`；`03-command.md` 只保留完成當輪判讀所需的最小結論。
5. 若 lesson 停在 `03-command.md`，而使用者只說「continue」或「繼續」，預設是進入下一輪單一 command drill 互動：AI 先給情境與候選指令，等待使用者選擇、操作與回報；不直接補完剩餘 command 項目，也不假設使用者已完成操作。

補充原則：

1. `03-command.md` 的練習預設應由使用者親手操作，不應只由 AI 代跑後就記成已完成。
2. `03-command.md` 預設應以「一輪觀察、一個閉環」來寫；若某個結論需要兩個指令一起看，可併成同一輪，但不要把整天過程混成一大段流水帳。
3. 若今天已決定要做 command drill，預設應在初始化時先把所有預計輪次都建成骨架，再於互動中逐輪回填，不採「做到哪一輪才新長出哪一輪」的方式。
4. 若今天是 command-heavy mode，輪次密度、切分方式與 QA 短版定位題規格，請另外參考 `reference/lesson-plugins/command-heavy-mode.md`。
5. 每一輪若需要保留當時的情境、三個選項或 AI 給的最小提示，應直接放進該輪 command 區塊內，不另外插一層獨立的互動題區塊。
6. `03-command.md` 裡的指令與輸出都統一使用 `bash` code block，不再混用 `text` 或其他標記。
7. `03-command.md` 的首要目標是降低複習阻力，因此只保留關鍵輸出與必要上下文；若原始輸出很長，預設只摘錄最有判讀價值的 3 到 8 行。
8. 若某輪真正有價值的是「原本怎麼誤判、後來怎麼修正」，可以在該輪補一小段「常見誤解 / 這輪釐清了什麼」，但不要把它寫成第二份 QA。
9. 若 AI 為了驗證環境而代跑指令，應明確標示那只是輔助驗證，不等於使用者已完成 command drill。
10. command drill 的最小完成條件，預設是使用者至少親手完成一輪最小操作、貼回輸出，並說出自己的選擇理由。
11. 在 `### AI 判讀與修正` 這個區塊裡，AI 應主動把「關鍵句」、「關鍵詞」或「判讀口訣」加粗，讓之後回看時能先掃到最有價值的判讀；但同樣不要把整段全面加粗。
12. 若 AI 判讀中出現 `kubectl` 指令、狀態名、事件欄位、資源欄位、container / probe / env key 等技術術語，也應優先使用 inline code 標示，避免和一般敘述混在一起。

### `04-report.md`

用途：在 lesson 結束後收斂今天真正學到的內容，是 `02-qa.md` 與 `03-command.md`（若有）的 lesson-level 結論頁。

建議包含（順序固定，跟執行流程一致）：

1. 今日主題。
2. 狀態。
3. QA 收斂了什麼（不重述 QA 題目細節，只留理解結論）。
4. 使用者原本卡住什麼。
5. 今日 command 練習收斂（**optional**，若當天有做 command drill 才補；用能力收斂語句，不是操作記錄）。
6. 今日真正留下來的核心收穫。
7. 學完後已能講清楚什麼。
8. 仍待補強什麼。
9. 下一步。

補充原則：

1. `04-report.md` 預設在 lesson 結束後集中回填。
2. 若對話過程中已出現穩定結論，也可以邊做邊補，但不應在 lesson 一開始就預寫標準答案。
3. 最終仍應在 lesson 收尾時重新整理一次，避免 report 只剩零散過程筆記。
4. report 不應重述 QA 的題目細節；QA 收斂段落只保留「做完 QA 之後理解到什麼」。
5. 「今日 command 練習收斂」是 optional section：沒有 command drill 時，直接略去這節，不要留「無」或「N/A」。
6. QA 在前，command 在後，不要對調。
7. 若 lesson 仍停在 `QA` 或 `command` 階段，而使用者只說「continue」或「繼續」，不應直接跳進 `04-report.md` 自動補完；只有在互動部分已完成，或使用者明確要求整理時，才進入 report 收斂。

### `05-note.md`

用途：承接 lesson 中途冒出的延伸問答、補充說明、暫時結論與卡片整理。

固定結構：

1. `## 學習注意事項`
2. `## Notes`
3. `## Flashcards`

適合放的內容：

1. 使用者的延伸提問與 AI 的補充回答。
2. 目前已知但尚未正式收斂進 `04-report.md` 的暫時結論。
3. 不適合塞進單一 Q/A 題目，但之後複習會有價值的補充說明。
4. 最後保留的卡片整理內容。

補充原則：

1. `05-note.md` 預設應在建立 lesson 時一起建立，不再視為 optional。
2. 原因不是每次一開始就一定有大量 note，而是它很適合承接中途延伸問題、暫時結論與最後的卡片整理，先建好骨架比較穩定。
3. 一件事情記一則，不要把 `05-note.md` 寫成第二份 lesson 摘要。
4. `學習注意事項` 與 `Notes` 內部都要用 H3 分組，不要把所有條列直接平鋪在 H2 底下。
5. `學習注意事項` 用來放外部預習回帶重點、lesson 邊界、待驗證的 repo 對照點、今天暫不展開的點。
6. 初始化 `05-note.md` 時，只有 `學習注意事項` 可以先回填外部預習內容；`Notes` 與 `Flashcards` 兩個 H2 區塊一開始必須留空，等 QA、command 或 lesson 過程中真的出現延伸問答、暫時結論與卡片素材後，再往裡面補。
7. 初始化時，`Notes` 與 `Flashcards` 可以只保留模板中的 HTML comment 這類特殊註記作為佔位；這種註記只是提示「這裡之後會長內容」，不算真正已回填內容。
8. `Notes` 用來放 lesson 過程中的延伸提問、補充解釋與尚未進 `04-report.md` 的暫時結論；不要在初始化時就先把外部學習摘要、骨架提示或預設結論放進去。
9. 若某段內容原本來自 QA 中途的額外追問，而且它不影響當前主題的最小驗收，預設應把詳細展開放進 `Notes`，不要把 `02-qa.md` 撐成過長的追問紀錄。
10. 若某段內容原本來自 command drill 中途的額外追問，而且它不影響當輪操作的最小閉環，預設也應把詳細展開放進 `Notes`，不要把 `03-command.md` 撐成第二份 QA 或第二份 note。
11. `Flashcards` 固定保留在檔案內，但初始化時必須留空；除了模板中的佔位註記外，不應先填入真正卡片。只有在 lesson 過程中真的整理出卡片後，才開始填寫。
12. `Flashcards` 的詳細生成規則、格式細節與精修原則，交由 `.github/prompts/generate-flashcards.prompt.md` 維護；本檔只保留 lesson 結構本身需要知道的最小規則。

---

## 預設流程

lesson 的執行順序，預設採 QA → command → report 收斂。

若當天計畫已指定某個 mode，則以該 mode 文件定義的流程為準；`01-outline.md` 只負責把這個決策落成 lesson 內的執行提醒，不負責重新判斷。

1. 先由 `learning/README.md` 決定是否進 lesson。
2. 一旦確定進入 lesson，才在這裡使用 QA → command → report。

常見流程：

1. 先用 `01-outline.md` 定義今天的主題與範圍。
2. 預設先做 `02-qa.md`，把最小觀念骨架對清楚。
3. 若當天有操作練習，再進入 `03-command.md`，用實際操作把剛剛的骨架對回系統輸出。
4. 若當天有延伸問題、暫時結論或卡片素材，過程中同步整理進 `05-note.md`。
5. lesson 結束後，把重點收斂進 `04-report.md`。

若今天有外部預習，仍是外部先、內部後；進入內部後，常態流程才是 QA → command → report。

---

## Flashcards

`05-note.md` 內的 `## Flashcards` 是 lesson 內固定保留的區塊，但詳細卡片規則不再放在本檔展開。

若要生成、精修或補齊卡片，請改用：

- `.github/prompts/generate-flashcards.prompt.md`

一句話原則：本檔負責 lesson 結構與檔案分工；卡片的提取、格式與精修策略交給專用 prompt。

---

## 內容原則

### 原則 1：只記專案特定知識

如果一段內容放到任何 Kubernetes 專案都成立，那多半比較適合留在外部預習或一般筆記，不一定要放這裡。

### 原則 2：重點是 Why 與實際路徑

lesson 應優先回答：

1. WeaMind 實際怎麼走。
2. 為什麼這樣設計。
3. 出問題時怎麼查。

### 原則 3：command 記錄以複習友善為優先

尤其是 `03-command.md`，應優先追求：

1. 一眼看出每輪在驗證什麼。
2. 一眼看出哪個輸出最關鍵。
3. 一眼看出這輪最後收斂的結論。

若一份 command 記錄需要重新讀完整段對話才看得懂，就代表格式還不夠成熟。

### 原則 4：不要把 lessons 寫成完整教科書

每份 lesson 應聚焦單一主題，讓之後複習時能快速抓到當天的重點與脈絡。

### 原則 5：report 不預先寫答案

`04-report.md` 不應在學習前就填入完整內容。

正確做法是：

1. 先用 `01-outline.md` 引導對話與學習。
2. 對話結束後，再把這次真正學到的重點寫進 `04-report.md`。
3. `04-report.md` 應反映這次互動實際發生了什麼，而不是先寫好標準答案。

---

## 維護方式

每次新增或完成一份 lesson 後：

1. 視需要更新 `.privatedocs/28day-progress.md`，記錄這次實際學到什麼。
2. 視需要更新 `.privatedocs/ai-memories.md`，只保留 AI 接手需要的高階摘要。
3. 正式進度先以 `.privatedocs/12週計畫.md` 判斷當前 phase，再以該 phase 的詳細計畫之「當前執行追蹤」區為準。

---

## 新對話如何接手

如果使用者在新對話裡只說「繼續」，不要直接按日期往後推。

接手原則：

1. 先看 `.privatedocs/12週計畫.md`，確認目前在哪一個 phase。
2. 再看該 phase 的詳細計畫之「當前執行追蹤」：Phase 1 用 `.privatedocs/六週版學習計畫.md`，Phase 2 用 `.privatedocs/Phase2三週計畫.md`。
3. 再看當前 lesson 的 `02-qa.md`，確認是否還有未完成的小題。
4. 需要補範圍時再看 `01-outline.md`；要收斂已學內容時再看 `04-report.md`。

一句話原則：先看 12 週總計畫，再看當前 phase 詳計畫；執行層則先看 `02-qa.md`。
