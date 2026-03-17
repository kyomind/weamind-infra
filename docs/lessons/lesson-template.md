# Lesson Template

> 用途：建立新 lesson 時，直接用這份模板產生當天 lesson 的檔案骨架。
> 使用方式：規則、判斷條件與正式格式一律以 `README.md` 為準；本檔只提供骨架，不重複維護規則。

---

## 建議建立的檔案

### 必備

1. `01-outline.md`
2. `02-qa.md`
3. `04-report.md`
4. `05-note.md`

### 視需要加入

1. `03-command.md`

---

## `01-outline.md` 模板

<template example 01-outline.md>
# YYYY-MM-DD Lesson Title Outline

## 今日主題

- 用一句話寫今天 lesson 的主題。

## 這次要解的專案問題

1.
2.
3.

## 這份 lesson 是否需要外部預習

- 需要 / 不需要
- 原因：

## 要對照的 repo 檔案

1.
2.
3.

## 建議學習順序

1.
2.
3.
4.

## 今日 command 練習

- 若今天沒有 command 練習，這裡可留一句簡短說明。
- 若今天有 command 練習，預設寫它要驗證哪個問題，以及它如何接在 QA 之後。
- 若今天要改成 command 先於 QA，必須順手寫明為什麼這次要例外。

## 文件分工

1. `01-outline.md`：規劃今天學習順序。
2. `02-qa.md`：記錄今天的專案問題、回答摘要與修正。
3. `03-command.md`：記錄今天的指令、觀察目標、輸出判讀與操作手感。
4. `04-report.md`：收斂今天真正學到的內容。
5. `05-note.md`：記錄延伸問答、暫時結論與卡片整理。

## 這次要追問的 Why / How 題

1.
2.
3.

## 這份 lesson 的完成標準

1.
2.
3.
</template example 01-outline.md>

---

## `02-qa.md` 模板

<template example 02-qa.md>
# YYYY-MM-DD Lesson Title QA

> 原則：每題都先回到 repo 檔案、YAML 或既有 SOP，不直接背名詞。

## Q1

### 題目


### 對照檔案

-
-

### 使用者回答摘要

- 待回答

### AI 修正與補充

- 待補

### 狀態

- 未開始
</template example 02-qa.md>

若使用者在作答時明確卡住，才在該題補上一個可選的 `### 拆題` 區塊，用 2 到 3 個更小的引導點協助作答；完成後仍要收斂回原本那一題的完整答案。

需要更多題目時，直接往下加 `## Q2`、`## Q3`。

---

## `03-command.md` 模板

<template example 03-command.md>
# YYYY-MM-DD Lesson Title Command

## 今日指令練習目標

1.
2.

## 這次要驗證的路徑或問題

1.
2.

## 今天要看的資源

1.
2.
3.

---

## Command 1

### 要驗證的問題

-

### 三個可選指令

```bash

```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

-

### AI 判讀與修正

-

### 一句話收斂

-

### 狀態

- 未開始

---

## Command 2

### 要驗證的問題

-

### 三個可選指令

```bash

```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

-

### AI 判讀與修正

-

### 一句話收斂

-

### 狀態

- 未開始

---

## 最後收斂

### 今天用哪些指令看懂了什麼

-
-

### 練習後還不順手的地方

-

### 補充

- 視需要補最小上下文即可。
</template example 03-command.md>

若今天沒有 command 練習，就不要建立這份檔案。

若今天有 command 練習，預設應保留「三個可選指令 → 使用者先判斷 → 實際執行並貼回輸出 → AI 判讀與收斂」這個節奏；不要在模板外再額外補一大段預設提示詞。

---

## `04-report.md` 模板

<template example 04-report.md>
# YYYY-MM-DD Lesson Title Report

## 今日主題


## 狀態

這份 report 已建立骨架，等待依今天實際問答回填。

## QA 收斂了什麼

- 待補

## 使用者原本卡住什麼

- 待補

<!-- 若當天沒有 command drill，刪去以下整節 -->
## 今日 command 練習收斂

- 待補

## 今日真正留下來的核心收穫

- 待補

## 學完後已能講清楚什麼

- 待補

## 仍待補強什麼

- 待補

## 下一步

- 待補
</template example 04-report.md>

> `今日 command 練習收斂` 是 optional section，若當天沒有 command drill，整節刪掉即可，不要留「無」或「N/A」。

---

## `05-note.md` 模板

<template example 05-note.md>
# YYYY-MM-DD Lesson Title Notes

## 學習注意事項

### 外部預習回帶重點

-

### 今天進 lesson 前先記住的邊界

-

### 待驗證的 repo 對照點

-

### 暫時不在今天展開的點

-

## Notes

### 1. 問題或延伸主題標題

使用者在 lesson 中追問了什麼，或這一段補充是因為哪個卡點出現。

這裡記錄的重點是：

- 一則一則的延伸問答或補充說明
- 目前已知、但還沒正式收斂進 `04-report.md` 的暫時結論
- 之後複習時仍有價值的補充脈絡

避免寫法：

- 不要把整份 note 寫成第二份 lesson 摘要
- 不要用「暫存結論 / 延伸問題 / 可重用說法」這類大綱式欄位去取代逐則 note

一句話收斂：`05-note.md` 應以「一件事情記一則」為主，而不是再做一份總整理。

## Flashcards

- 這一區在初始化時就先建立，避免後續補寫時結構漂移。
- 卡片內容以最終保留版為主，不要把所有候選草稿都堆進來。
- 若要輸出 Logseq 閃卡，格式請直接遵循 `README.md` 中的唯一正式規格。

- 若目前還沒有卡片內容，可先留一行：`- 待補`

- probe 的兩種用途怎麼區分？ #DevOps #card
  - `liveness probe` 在看容器是否還活著
  - `readiness probe` 在看 Pod 是否已準備好接流量
</template example 05-note.md>

補充規則：

1. `05-note.md` 固定只允許三個 H2：`學習注意事項`、`Notes`、`Flashcards`。
2. `學習注意事項` 與 `Notes` 內部都要用 H3 分組，不要把所有條列直接平鋪在 H2 底下。
3. `學習注意事項` 用來放外部預習回帶重點、lesson 邊界、待驗證的 repo 對照點、今天暫不展開的點。
4. `Flashcards` 是否回填內容，依 lesson 實際需要決定；但區塊本身一開始就先建立。

卡片格式與 note 的使用規則，正式版本一律以 `README.md` 為準。

---

## 開 lesson 時的最小流程

1. 先看 `README.md`。
2. 再用這份模板建立當天需要的檔案。
3. 依 lesson 實際進行狀況回填內容。
