# Implement-Heavy Mode

## 用途

這份文件只處理 lesson 流程中的 implement-heavy mode 例外規格。

它不是 lessons 的常態 README，而是按需讀取的補充說明。

適用情境：

1. 今天的 lesson 主體明確不是 command drill，而是真的要改 manifest、cluster 設定或其他 repo / infra 實作。
2. 今天的主要驗收不是「有沒有看懂某個輸出」，而是「改動是否成功、風險是否可控、回退點是否清楚」。
3. `06-implementation.md` 會成為 lesson 的主戰場，而 `02-qa.md` 退回實作後定位與驗證收斂角色。

若今天不是這種 mode，則不需要讀本檔。

---

## 和 Lessons README 的分工

`learning/lessons/README.md` 仍是 `learning/lessons/` 的主規則檔。

本檔只補充三件事：

1. implement-heavy lesson 的骨架預設應一次建立 5 份檔案。
2. implement-heavy lesson 的主體如何移到 `06-implementation.md`。
3. implement-heavy mode 與 `02-qa.md`、`04-report.md` 的流程關係。

換句話說：

1. prework 是否需要，仍由 `learning/README.md` 判斷。
2. lesson 的常態檔案責任，仍以 `learning/lessons/README.md` 為準。
3. 只有當天已判定為 implement-heavy mode，才把本檔當成額外增量規則來讀。

---

## 預設骨架

若今天明確屬於 implement-heavy mode，建立 lesson 骨架時預設直接建立：

1. `01-outline.md`
2. `02-qa.md`
3. `04-report.md`
4. `05-note.md`
5. `06-implementation.md`

這裡和常態 lesson 最大的差異是：

1. `06-implementation.md` 不再是少見特例，而是 mode 內建的一部分。
2. implement-heavy mode 預設不建立 `03-command.md`；實作前提、驗證與觀察證據直接留在 `06-implementation.md` 的各個 step 閉環裡。
3. 檔案先建立，不等於每份都要預先寫滿；真正的內容仍依互動與實作結果回填。

建立骨架時：

1. `01-outline.md`、`06-implementation.md` 應優先參考 `references/lesson-plugins/implementation/implement-heavy-lesson-template.md`。
2. `02-qa.md`、`04-report.md`、`05-note.md` 仍沿用 `learning/lessons/lesson-template.md` 的常態模板。

---

## 節奏調整

implement-heavy mode 的重點不是把 QA 或 command 刪掉，而是把 lesson 主體改成 implementation-first。

`06-implementation.md` 的 session 開場方式、step 推進、提問邊界、驗證證據寫法與回填原則，應改讀 `references/lesson-plugins/implementation/implementation-guide.md`；本檔只保留 mode 層規則，不再承擔 `06` 的細部帶法。

建議節奏：

1. 若今天需要 prework，仍先完成 prework。
2. 進入 lesson 後，先用 `01-outline.md` 明確宣告今天套用了 implement-heavy mode，並寫明流程順序、實作邊界、驗收訊號、回退點。
3. 互動主體預設先進 `06-implementation.md`，由 implementation guide 定義每個 step 的帶法與回填節奏。
4. `06` 過程中的 implementation-specific 補充觀察或設計取捨，視需要整理到 `05-note.md`。
5. 只有在實作主體完成後，才回 `02-qa.md` 做 post-implementation QA，用短版定位題收斂理解。
6. `04-report.md` 仍在互動完成後再收斂。

節奏補充：

1. implement-heavy mode 一旦套用，預設就是 implementation-first；這不是臨時例外，而是 mode 本身的正式流程。
2. `06` 階段預設採協作模式，不把實作主體做成答題測驗；短版 QA 收斂留到實作後的 `02-qa.md`。
3. `01-outline.md` 應明確寫出今天套用了這個 mode，讓 AI 不需要自行猜測。
4. implement-heavy mode 改的是 lesson 內部流程，不影響是否需要 prework 的上層判斷。

---

## QA 的例外規格

若今天明確屬於 implement-heavy mode，`02-qa.md` 仍應保留，但改成 post-implementation QA，也就是實作完成後才進入的短版收斂題。

建議調整為 2 到 3 題，角色是先對齊：

1. 這次實作到底要改哪個邊界。
2. 這次成功與失敗要看什麼訊號。
3. 若結果不如預期，第一個回退或縮圈方向是什麼。

原則：

1. QA 仍存在，但不要把大塊概念展開放回這裡。
2. QA 應服務 implementation，不應和 `06-implementation.md` 搶主體。
3. 若某段延伸問答已超出這次改動的最小定位需求，優先放進 `05-note.md`。
4. QA 的價值是把這次實作鎖成可口述的理解，不是把實作過程再考一次。
5. implementation 尚未完成前，不應提前切進 `02-qa.md`；否則 QA 會失去「用完成結果做收斂」的價值。
6. post-implementation QA 預設仍採「AI 發問、使用者回答」的互動形式，不改成 AI 直接代寫答案。
7. 題目應以誘發使用者思考與收斂口述能力為目的，難度保持低壓、可回答，但仍要逼近這次實作真正的邊界與取捨。
8. 若使用者回答方向正確，AI 應先幫忙收斂與修正，再視需要追問；不要把 QA 做成連續出題或猜謎。

---

## `06-implementation.md` 的定位

`06-implementation.md` 是 implement-heavy mode 的主戰場，但它的初始化欄位、step 形狀、回填時機與自檢規則，應分別由下列文件承接：

1. 骨架長相：`references/lesson-plugins/implementation/implement-heavy-lesson-template.md`
2. 實際帶法：`references/lesson-plugins/implementation/implementation-guide.md`

本檔只保留 mode 層原則：今天的主體在 `06`，而不是在 `02-qa.md` 或 `03-command.md`。

---

## 不變的部分

即使今天是 implement-heavy mode，下列常態規則仍然不變：

1. 是否需要 prework，仍先回 `learning/README.md` 判斷。
2. `04-report.md` 仍在互動完成後再收斂，不預先代寫。
3. `05-note.md` 仍保留一般 lesson 的延伸問答、暫時結論與卡片素材。
4. 真正的 lesson 完成標準，仍應回到能否把這次變更、驗收與 trade-off 講清楚。

---

## 使用方式

若今天判定為 implement-heavy mode，建議讀取順序為：

1. 先讀 `learning/README.md`，確認今天確實要進 lesson，且 prework 判斷已完成。
2. 再讀 `learning/lessons/README.md`，確認 lesson 的通用結構與檔案分工。
3. 再讀本檔，套用 implement-heavy mode 的正式流程、5 檔骨架與 06 初始化規則。
4. 建骨架時再讀 `references/lesson-plugins/implementation/implement-heavy-lesson-template.md`，建立 implement-heavy 專用骨架。
5. `02-qa.md`、`04-report.md`、`05-note.md` 的共通骨架，仍回 `learning/lessons/lesson-template.md`。

一句話原則：常態規則留在 `README.md`，實作型 lesson 的重心與 06 規格留在本檔，按需揭露。
