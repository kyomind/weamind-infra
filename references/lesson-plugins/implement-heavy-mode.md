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

本檔只補充五件事：

1. implement-heavy lesson 的骨架預設應一次建立 6 份檔案。
2. implement-heavy lesson 的重心如何移到 `06-implementation.md`。
3. `06-implementation.md` 的初始化與自檢規則。
4. `07-implementation-note.md` 的初始化與自檢規則。
5. implement-heavy mode 專用 template 應從哪裡讀。

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
6. `07-implementation-note.md`

這裡和常態 lesson 最大的差異是：

1. `06-implementation.md` 與 `07-implementation-note.md` 不再是少見特例，而是 mode 內建的一部分。
2. `07-implementation-note.md` 與 `06-implementation.md` 完全綁定；它不是獨立 phase，只承接 `06` 過程中的 implementation-specific 補充觀察。
3. implement-heavy mode 預設不建立 `03-command.md`；實作前提、驗證與觀察證據直接留在 `06-implementation.md` 的各個 step 閉環裡。
4. 檔案先建立，不等於每份都要預先寫滿；真正的內容仍依互動與實作結果回填。

建立骨架時：

1. `01-outline.md`、`06-implementation.md`、`07-implementation-note.md` 應優先參考 `references/lesson-plugins/implement-heavy-lesson-template.md`。
2. `02-qa.md`、`04-report.md`、`05-note.md` 仍沿用 `learning/lessons/lesson-template.md` 的常態模板。

---

## 節奏調整

implement-heavy mode 的重點不是把 QA 或 command 刪掉，而是把 lesson 主體改成 implementation-first。

建議節奏：

1. 若今天需要 prework，仍先完成 prework。
2. 進入 lesson 後，先用 `01-outline.md` 明確宣告今天套用了 implement-heavy mode，並寫明流程順序、實作邊界、驗收訊號、回退點。
3. 互動主體預設先進 `06-implementation.md`，逐輪記錄改動、結果與判讀。
4. 在 `06-implementation.md` 與 `07-implementation-note.md` 這個 implementation 階段，預設採協作模式，不採邊做邊考的節奏。AI 應先說清楚這一步在驗證什麼、為什麼現在做、看到什麼輸出要怎麼判讀，再由使用者執行並回報結果。
5. 在每一步真正執行前，AI 都應先給 1 到 3 句簡短前情說明，至少交代這一步的目的、它位於哪個階段、成功或失敗大致各代表什麼；不要只丟指令而不交代脈絡。
6. implement 階段若需要提問，重點也應是為了確認操作前提、判讀現象或補足決策資訊，不是把 `02-qa.md` 的答題模式搬進來。
7. 若 `06` 過程中出現 implementation-specific 補充觀察，同步整理到 `07-implementation-note.md`。
8. 只有在實作主體完成後，才回 `02-qa.md` 做 post-implementation QA，用短版定位題收斂理解。
9. `05-note.md` 繼續承接一般 lesson 延伸問答與卡片素材。
10. `04-report.md` 仍在互動完成後再收斂。

補充原則：

1. implement-heavy mode 一旦套用，預設就是 implementation-first；這不是臨時例外，而是 mode 本身的正式流程。
2. `06` / `07` 階段預設採協作模式，不把實作主體做成答題測驗；短版 QA 收斂留到實作後的 `02-qa.md`。
3. implement 階段的每一步都應先有簡短前情說明，再進入指令或操作本身。
4. `01-outline.md` 應明確寫出今天套用了這個 mode，讓 AI 不需要自行猜測。
5. implement-heavy mode 改的是 lesson 內部流程，不影響是否需要 prework 的上層判斷。

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

## 驗證證據的例外規格

若今天明確屬於 implement-heavy mode，實作前後的驗證證據預設直接留在 `06-implementation.md` 的各個 step 閉環裡，不另外拆成 `03-command.md`。

常見用途：

1. 實作前確認現況是否與假設一致。
2. 實作後驗證 YAML / resource / 行為是否真的生效。
3. 補一段最小可複習的證據鏈，讓 `04-report.md` 不只靠印象收斂。

原則：

1. 驗證指令與關鍵輸出直接留在對應 step，不要再平行長出第二份 command transcript。
2. 若某個 step 需要多個指令一起看，仍以單一 step 的同一個閉環承接，不再拆到獨立檔案。
3. implement-heavy mode 裡的驗證仍重要，但它服務的是 `06-implementation.md` 的每個 step 收斂，不是另一條主線。

---

## `06-implementation.md` 的初始化規格

`06-implementation.md` 是 implement-heavy mode 的核心檔案。

建立骨架時，至少應先寫出：

1. 這份文件的角色。
2. 今日實作主題。
3. 今日實作順序。
4. 驗收訊號與回退點。
5. 2 個以上的 implementation step 骨架。

每個 step 建議固定包含：

1. `#### 這一步要驗證什麼`
2. `#### 預計操作`
3. `#### 實際輸出 / 操作結果`
4. `#### AI 判讀與收斂`
5. `#### 目前狀態`

命名原則：

1. implement-heavy mode 預設使用 `Step 1`、`Step 2` 這種線性命名，不使用 `Round 1`、`Round 2`。
2. `step` 比 `round` 更符合實作主線的節奏，因為步數不一定固定，且通常是線性推進而不是有限回合。

初始化原則：

1. 可以先寫驗證目標與預計操作。
2. `實際輸出 / 操作結果`、`AI 判讀與收斂`、`目前狀態` 在還沒真的動手前，不應預寫成已完成結果。
3. 若今天還沒開始第一輪，狀態就寫 `未開始`，不要假裝已驗證。
4. 若今天已知存在風險或回退步驟，應在檔案前段先寫清楚，不要等出事後才補。

自檢規則：

1. 這份檔案是否真的以「每個 step 的改動閉環」為主，而不是變成第二份 command transcript。
2. 是否先寫清楚驗收訊號與回退點，而不是只列要改什麼。
3. 是否避免在初始化時預寫不存在的輸出、結論或成功狀態。
4. 若今天已有多個 step，是否每個 step 都能看出「目標、動作、結果、判讀、狀態」。

---

## `07-implementation-note.md` 的初始化規格

`07-implementation-note.md` 用來承接實作專屬補充，不和 `05-note.md` 混在一起。

它和 `06-implementation.md` 的關係應固定如下：

1. `06-implementation.md` 是主戰場。
2. `07-implementation-note.md` 是 `06` 的 companion file，不是獨立 phase。
3. 若內容不是 implementation-specific，優先回 `05-note.md`，不要塞進 `07`。

它預設承接三類內容：

1. 實作前已知邊界與風險。
2. 實作過程中冒出的關鍵觀察與設計修正。
3. 實作後仍待驗證，但不適合塞回單一 step 的補充理解。

邊界原則：

1. 一般 lesson 討論與延伸問答仍優先放 `05-note.md`。
2. 只有直接影響實作邊界、驗收、風險、設計取捨或下一步決策的關鍵討論，才放進 `07-implementation-note.md`。
3. 若某段內容雖然重要，但不是 implementation-specific，仍應回到 `05-note.md`，不要因為它「重要」就全部塞進 `07`。
4. `07-implementation-note.md` 應以真正的 note 形式撰寫：一個主題一個 `##` 標題，下面直接展開內容；不要先用固定分區把檔案切成骨架式欄位。

初始化原則：

1. 建立骨架時不需要先預建固定 H2 區塊；等真正出現 implementation-specific 主題後，再以對應主題名稱新增 `##` 標題。
2. 不要一開始就把 `04-report.md` 的結論預抄進來。
3. 不要把一般 lesson 延伸問答先塞進這裡；若內容不是 implementation-specific，優先回 `05-note.md`。
4. 不要把大段原始輸出直接倒進這裡；這份檔案是補充理解，不是原始紀錄倉庫。

自檢規則：

1. 初始化時是否沒有預寫不必要的固定分區與結論。
2. 實際回填後，內容是否真的屬於 implementation-specific，而不是一般 QA 延伸。
3. 是否避免和 `06-implementation.md` 重複貼同一段操作記錄。
4. 若某段內容已足夠成為 lesson-level 收斂，是否應改回 `04-report.md`，而不是一直留在這裡。

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
3. 再讀本檔，套用 implement-heavy mode 的正式流程、6 檔骨架與 06 / 07 初始化規則。
4. 建骨架時再讀 `references/lesson-plugins/implement-heavy-lesson-template.md`，建立 implement-heavy 專用骨架。
5. `02-qa.md`、`04-report.md`、`05-note.md` 的共通骨架，仍回 `learning/lessons/lesson-template.md`。

一句話原則：常態規則留在 `README.md`，實作型 lesson 的重心與 06 / 07 規格留在本檔，按需揭露。
