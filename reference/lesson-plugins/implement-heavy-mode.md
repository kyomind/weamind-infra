# Implement-Heavy Mode

## 用途

這份文件只處理 lesson 流程中的 implement-heavy mode 例外規格。

它不是 lessons 的常態 README，而是按需讀取的補充說明。

適用情境：

1. 今天的 lesson 主體明確不是 command drill，而是真的要改 manifest、cluster 設定或其他 repo / infra 實作。
2. 今天的主要驗收不是「有沒有看懂某個輸出」，而是「改動是否成功、風險是否可控、回退點是否清楚」。
3. `06-implementation.md` 會成為 lesson 的主戰場，而 `02-qa.md`、`03-command.md` 退回前後定位與驗證角色。

若今天不是這種 mode，則不需要讀本檔。

---

## 和 Lessons README 的分工

`learning/lessons/README.md` 仍是 `learning/lessons/` 的主規則檔。

本檔只補充四件事：

1. implement-heavy lesson 的骨架預設應一次建立 `01-07` 全部七份檔案。
2. implement-heavy lesson 的重心如何移到 `06-implementation.md`。
3. `06-implementation.md` 的初始化與自檢規則。
4. `07-implementation-note.md` 的初始化與自檢規則。

換句話說：

1. prework 是否需要，仍由 `learning/README.md` 判斷。
2. lesson 的常態檔案責任，仍以 `learning/lessons/README.md` 為準。
3. 只有當天已判定為 implement-heavy mode，才把本檔當成額外增量規則來讀。

---

## 預設骨架

若今天明確屬於 implement-heavy mode，建立 lesson 骨架時預設直接建立：

1. `01-outline.md`
2. `02-qa.md`
3. `03-command.md`
4. `04-report.md`
5. `05-note.md`
6. `06-implementation.md`
7. `07-implementation-note.md`

這裡和常態 lesson 最大的差異是：

1. `03-command.md` 在 implement-heavy mode 下也預設先建立，因為它常用來承接實作前後的驗證。
2. `06-implementation.md` 與 `07-implementation-note.md` 不再是少見特例，而是 mode 內建的一部分。
3. 檔案先建立，不等於每份都要預先寫滿；真正的內容仍依互動與實作結果回填。

---

## 節奏調整

implement-heavy mode 的重點不是把 QA 或 command 刪掉，而是把 lesson 主體移到 implementation rounds。

建議節奏：

1. 若今天需要 prework，仍先完成 prework。
2. 進入 lesson 後，先用 `01-outline.md` 寫明今天為什麼是 implement-heavy，以及實作邊界、驗收訊號、回退點。
3. `02-qa.md` 只保留 implementation 前後真的需要的最小定位題，不再把 QA 當成主體。
4. 互動主體預設先進 `06-implementation.md`，逐輪記錄改動、結果與判讀。
5. `03-command.md` 用來承接實作前檢查、實作後驗證，或補最小觀察證據；它不是今天的主戰場。
6. `05-note.md` 繼續承接一般 lesson 延伸問答；`07-implementation-note.md` 專門承接實作專屬觀察。
7. `04-report.md` 仍在互動完成後再收斂。

補充原則：

1. 若今天真的要讓 implementation 先於 QA 或 command，仍應在 `01-outline.md` 明寫原因。
2. implement-heavy mode 改的是重心，不是要把 lessons README 的常態規則全部推翻。

---

## QA 的例外規格

若今天明確屬於 implement-heavy mode，`02-qa.md` 仍應保留，但改成 implementation 前後的短版定位題。

建議調整為 2 到 3 題，角色是先對齊：

1. 這次實作到底要改哪個邊界。
2. 這次成功與失敗要看什麼訊號。
3. 若結果不如預期，第一個回退或縮圈方向是什麼。

原則：

1. QA 仍存在，但不要把大塊概念展開放回這裡。
2. QA 應服務 implementation，不應和 `06-implementation.md` 搶主體。
3. 若某段延伸問答已超出這次改動的最小定位需求，優先放進 `05-note.md`。

---

## Command 的例外規格

若今天明確屬於 implement-heavy mode，`03-command.md` 的角色改為實作前後驗證，而不是主要學習主體。

常見用途：

1. 實作前確認現況是否與假設一致。
2. 實作後驗證 YAML / resource / 行為是否真的生效。
3. 補一段最小可複習的證據鏈，讓 `04-report.md` 不只靠印象收斂。

原則：

1. `03-command.md` 可以比常態 lesson 更短，但不應完全退化成雜亂指令清單。
2. 若今天完全沒有需要額外 command 驗證的段落，也可以只保留最小骨架，並在 outline 或 command 檔內明講今天為何未展開。
3. command 在 implement-heavy mode 裡不是主體，但仍可能是收尾驗證的重要證據。

---

## `06-implementation.md` 的初始化規格

`06-implementation.md` 是 implement-heavy mode 的核心檔案。

建立骨架時，至少應先寫出：

1. 這份文件的角色。
2. 今日實作主題。
3. 今日實作順序。
4. 驗收訊號與回退點。
5. 2 到 4 輪 implementation round 骨架。

每一輪建議固定包含：

1. `#### 這一輪要驗證什麼`
2. `#### 預計操作`
3. `#### 實際輸出 / 操作結果`
4. `#### AI 判讀與收斂`
5. `#### 目前狀態`

初始化原則：

1. 可以先寫驗證目標與預計操作。
2. `實際輸出 / 操作結果`、`AI 判讀與收斂`、`目前狀態` 在還沒真的動手前，不應預寫成已完成結果。
3. 若今天還沒開始第一輪，狀態就寫 `未開始`，不要假裝已驗證。
4. 若今天已知存在風險或回退步驟，應在檔案前段先寫清楚，不要等出事後才補。

自檢規則：

1. 這份檔案是否真的以「每輪改動閉環」為主，而不是變成第二份 command transcript。
2. 是否先寫清楚驗收訊號與回退點，而不是只列要改什麼。
3. 是否避免在初始化時預寫不存在的輸出、結論或成功狀態。
4. 若今天已有多輪實作，是否每輪都能看出「目標、動作、結果、判讀、狀態」。

---

## `07-implementation-note.md` 的初始化規格

`07-implementation-note.md` 用來承接實作專屬補充，不和 `05-note.md` 混在一起。

它預設承接三類內容：

1. 實作前已知邊界與風險。
2. 實作過程中冒出的關鍵觀察與設計修正。
3. 實作後仍待驗證，但不適合塞回單一 round 的補充理解。

建立骨架時，建議先放：

1. `## 實作前邊界`
2. `## 實作中觀察`
3. `## 後續待驗證`

初始化原則：

1. 這三個 H2 可以先建立，但內文預設保持空白，最多只留 HTML comment 這類佔位註記。
2. 不要一開始就把 `04-report.md` 的結論預抄進來。
3. 不要把一般 lesson 延伸問答先塞進這裡；若內容不是 implementation-specific，優先回 `05-note.md`。
4. 不要把大段原始輸出直接倒進這裡；這份檔案是補充理解，不是原始紀錄倉庫。

自檢規則：

1. 初始化時是否只有段落骨架與必要佔位，沒有預寫結論。
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
3. 再讀本檔，套用 implement-heavy mode 的 7 檔骨架與 06 / 07 初始化規則。
4. 建骨架時同步參考 `learning/lessons/lesson-template.md` 裡的 implement-heavy 增量模板。

一句話原則：常態規則留在 `README.md`，實作型 lesson 的重心與 06 / 07 規格留在本檔，按需揭露。
