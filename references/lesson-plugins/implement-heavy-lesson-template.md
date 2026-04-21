# Implement-Heavy Lesson Template

> 用途：只在今天已明確套用 implement-heavy mode 時使用。
> 使用方式：先讀 `learning/README.md`、`learning/lessons/README.md`、`implement-heavy-mode.md`，確認今天真的屬於 implement-heavy mode，再用本檔建立 mode 專用骨架。
> 原則：本檔只提供 implement-heavy 骨架，不重寫 mode 的判斷條件與自檢規則。

---

## 建議建立的檔案

implement-heavy mode 預設直接建立六份檔案：

1. `01-outline.md`
2. `02-qa.md`
3. `04-report.md`
4. `05-note.md`
5. `06-implementation.md`
6. `07-implementation-note.md`

其中：

1. `01-outline.md`、`06-implementation.md`、`07-implementation-note.md` 優先使用本檔模板。
2. `02-qa.md`、`04-report.md`、`05-note.md` 仍沿用 `learning/lessons/lesson-template.md` 的常態模板。
3. `07-implementation-note.md` 與 `06-implementation.md` 完全綁定；它不是獨立 phase，只承接 `06` 過程中的 implementation-specific 補充觀察。

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
2. 若 `06` 過程中出現 implementation-specific 補充觀察，同步整理到 `07-implementation-note.md`。
3. 只有在實作主體完成後，再回 `02-qa.md` 做 post-implementation QA 與定位收斂。
4. 若需要最小操作驗證，直接把證據留在 `06-implementation.md` 的對應 step。
5. 過程中的一般 lesson 延伸問答仍整理進 `05-note.md`。
6. 最後回 `04-report.md` 做整體收斂。

## 文件分工

1. `01-outline.md`：宣告今天套用 implement-heavy mode，並寫清楚流程、邊界、驗收與回退點。
2. `02-qa.md`：記錄 post-implementation QA 的短版定位題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的內容。
4. `05-note.md`：記錄一般 lesson 延伸問答、暫時結論與卡片整理。
5. `06-implementation.md`：記錄今天的主要實作 step，包含必要的驗證證據。
6. `07-implementation-note.md`：只承接 `06` 過程中的 implementation-specific 關鍵觀察與決策討論。

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
- `07-implementation-note.md` 與本檔綁定，只承接本檔過程中的 implementation-specific 補充觀察。

## 今日實作主題

-

## 今日實作順序

1.
2.
3.

## 驗收訊號與回退點

### 驗收訊號

-

### 回退點

-

### Step 1

#### 這一步要驗證什麼

-

#### 預計操作

```bash

```

#### 實際輸出 / 操作結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 2

#### 這一步要驗證什麼

-

#### 預計操作

```bash

```

#### 實際輸出 / 操作結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始
</template example 06-implementation.md>

---

## `07-implementation-note.md` 模板

<template example 07-implementation-note.md>
# YYYY-MM-DD Lesson Title Implementation Notes

> 這份檔案與 `06-implementation.md` 綁定，只承接 `06` 過程中的 implementation-specific 關鍵觀察與決策討論。

<!-- 初始化時可保持空白；真正出現 implementation-specific 主題後，再用 `##` 標題逐條新增 note。 -->

## 某個與實作決策直接相關的主題

- 在這個 H2 下直接整理與實作邊界、驗收、風險或取捨有關的關鍵觀察。
</template example 07-implementation-note.md>
