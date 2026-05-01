# Implement-Heavy Lesson Template

> 用途：只在今天已明確套用 implement-heavy mode 時使用。
> 使用方式：先讀 `learning/README.md`、`learning/lessons/README.md`、`references/lesson-plugins/implementation/implement-heavy-mode.md`，確認今天真的屬於 implement-heavy mode，再用本檔建立 mode 專用骨架。
> 原則：本檔只提供 implement-heavy 骨架，不重寫 mode 的判斷條件與自檢規則。

---

## 建議建立的檔案

implement-heavy mode 預設直接建立五份檔案：

1. `01-outline.md`
2. `02-qa.md`
3. `04-report.md`
4. `05-note.md`
5. `06-implementation.md`

其中：

1. `01-outline.md`、`06-implementation.md` 優先使用本檔模板。
2. `02-qa.md`、`04-report.md`、`05-note.md` 仍沿用 `learning/lessons/lesson-template.md` 的常態模板。

---

## `01-outline.md` 模板

<template example 01-outline.md>
# YYYY-MM-DD Lesson Title Outline

## 今日主題

- 用一句話寫今天 lesson 的主題。

## 今日套用的 lesson mode

- implement-heavy mode

## 為什麼今天要套用 implement-heavy mode

1.
2.

## 這次要解的專案問題

1.
2.
3.

## 這份 lesson 是否需要外部預習

- 需要 / 不需要
- 原因：

## 要對照的 repo 檔案

1. `path/to/file.yaml`
2. `path/to/another-file.md`
3. `path/to/one-more-file.txt`

## 今日實作邊界

1.
2.
3.

## 驗收訊號與回退點

### 驗收訊號

1.
2.

### 回退點

1.
2.

## 建議學習順序

1. 先用 `06-implementation.md` 做主要實作與每個 step 的閉環記錄。
2. 若 `06` 過程中出現 implementation-specific 補充觀察或設計取捨，同步整理到 `05-note.md`。
3. 只有在實作主體完成後，再回 `02-qa.md` 做 post-implementation QA 與定位收斂。
4. 若需要最小操作驗證，直接把證據留在 `06-implementation.md` 的對應 step。
5. 過程中的一般 lesson 延伸問答與實作補充都整理進 `05-note.md`。
6. 最後回 `04-report.md` 做整體收斂。

## 文件分工

1. `01-outline.md`：宣告今天套用 implement-heavy mode，並寫清楚流程、邊界、驗收與回退點。
2. `02-qa.md`：記錄 post-implementation QA 的短版定位題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的內容。
4. `05-note.md`：記錄一般 lesson 延伸問答、實作補充、暫時結論與卡片整理。
5. `06-implementation.md`：記錄今天的主要實作 step，包含必要的驗證證據。

## 這份 lesson 的完成標準

1.
2.
3.
</template example 01-outline.md>

---

## `06-implementation.md` 模板

<template example 06-implementation.md>
# YYYY-MM-DD Lesson Title Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

-

## 今日實作順序

1.
2.
3.

## 使用提醒

1. step 數量不設上限；若後續發現某一步過大，應直接往下拆成新的 `Step N`，不要勉強維持少量大步驟。
2. `06-implementation.md` 不需要在每一輪對話後即時逐字更新。若某個 step 會經過多輪討論、試錯或策略收斂，可以先在互動中推進，等到出現較大的進展、形成一段可複習的證據鏈，或該 step 結尾時，再把主要結果擇要回填。
3. 若某個 step 目前只完成設計稿或查詢草案，`實際執行內容` 可以先完整保留操作稿；`結果` 應明寫尚未實作驗證，`AI 判讀與收斂` 也只應收斂到是否已可進入實作，不應提前寫成已驗證完成。
4. 每個 step 的 `實際執行內容` 第一個 bullet，應先標記這次主要由誰實作，例如：`本次由 AI 實作`、`本次由使用者實作`；若屬於明確分段協作，也可以寫成 `本次由 AI 與使用者協作`。

## Session 開場提醒

- `06-implementation.md` 的實際帶法不要寫死在模板裡；開場規則、step 推進與提問邊界改讀 `references/lesson-plugins/implementation/implementation-guide.md`。

## 驗收訊號與回退點

### 驗收訊號

-

### 回退點

-

### Step 1

#### 這一步要驗證什麼

-

#### 預計採取的動作

- 待回填

#### 實際執行內容

- 本次由 AI / 使用者 / AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 2

#### 這一步要驗證什麼

-

#### 預計採取的動作

- 待回填

#### 實際執行內容

- 本次由 AI / 使用者 / AI 與使用者協作實作
- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

補充：若今天的主線超過 2 個步驟，直接繼續往下新增 `Step 3`、`Step 4`、`Step 5`。每個 step 盡量只承接一個主要驗證點或一組緊密相關的操作，避免單一步驟過大。

補充：回填 step 時，優先保留主要決策、關鍵操作、代表性證據、結果與 AI 收斂，不需要把每次中間來回或所有試錯細節完整照錄。
</template example 06-implementation.md>
