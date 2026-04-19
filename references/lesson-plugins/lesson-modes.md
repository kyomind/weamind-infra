# Lesson Modes

## 用途

這份文件定義 lesson mode 的合法 enum、決策來源，以及各 mode 對應要讀的 plugin 文件。

它不是某一種 mode 的細則文件，而是 lesson mode 的上位索引。

---

## 決策來源

lesson 是否套用某個 mode，應由當天計畫先明示。

`01-outline.md` 的角色是把這個已決定的 mode 寫成 lesson 內部的執行提醒，不作為 mode 決策來源。

一句話原則：計畫決定 mode，outline 只鏡像這個決策。

---

## 合法 Enum

目前合法的 `Lesson mode` 值如下：

1. `not-applicable`
2. `normal`
3. `command-heavy`
4. `implement-heavy`

---

## 各值說明

### `not-applicable`

用於當天不是 lesson，而是 prework、整理日或其他不進入 lesson 流程的情境。

### `normal`

用於常態 lesson。

預設流程仍是 `QA -> command -> report`。

讀取文件：

1. `learning/lessons/README.md`
2. `learning/lessons/lesson-template.md`

### `command-heavy`

用於 command drill 明顯比 QA 更密、更主體的 lesson。

讀取文件：

1. `learning/lessons/README.md`
2. `references/lesson-plugins/command-heavy-mode.md`
3. `learning/lessons/lesson-template.md`

### `implement-heavy`

用於 implementation-first 的 lesson。

讀取文件：

1. `learning/lessons/README.md`
2. `references/lesson-plugins/implement-heavy-mode.md`
3. `references/lesson-plugins/implement-heavy-lesson-template.md`
4. `learning/lessons/lesson-template.md`

---

## 使用規則

1. 每日計畫若進入 lesson，應先明示 `Lesson mode`。
2. 若當天是 prework，`Lesson mode` 應寫 `not-applicable`。
3. 若當天計畫沒有明示 mode，AI 不應自行猜測 command-heavy 或 implement-heavy。
4. 若未來新增 mode，先更新本檔，再更新對應 plugin 文件與 README 入口說明。
