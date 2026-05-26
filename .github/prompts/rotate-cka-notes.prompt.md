---
description: "Rotate cka/notes.md into the next numbered notes-XX.md archive, back up to raw/, add a rotation date, and reset notes.md."
---

# Rotate CKA Notes

## 任務目標

把目前的 `cka/notes.md` 封存成下一個序號的 `cka/notes-XX.md`，同時備份一份到 `cka/raw/`，在封存檔加入本次整理日期，然後把 `cka/notes.md` 重設成初始化模板。

`cka/raw/` 保留原始版本，`cka/notes-XX.md` 可以之後精簡。

## 核心規則

1. 使用 zh-TW。
2. 處理範圍：`cka/notes.md`、`cka/notes-XX.md`、`cka/raw/notes-XX.md`。
3. 新檔案序號一律用兩位數：
   - 若目前沒有 `notes-XX.md`，從 `01` 開始
   - 若已有舊檔，使用目前最大序號加 `1`
4. 先複製，再修改封存檔；不要先清空 `notes.md`。
5. 實際檔案操作優先使用 shell 指令（`cp`、`mv`）。
6. 複製到 `cka/raw/` 時保留原樣，不加日期行。
7. 封存檔的第三行必須加入 `整理日期：YYYY-MM-DD`。
8. 完成前一定要做檢查；若檢查失敗，停止並說明失敗點。

## 輸入與前提

執行前先確認：

1. `cka/notes.md` 存在且非空
2. `cka/` 目錄存在
3. `cka/raw/` 目錄存在；若不存在，建立它
4. `cka/notes.md` 第一行是 `# CKA Practice Notes`

若 1、2、4 不成立，停止並回報原因。

## 執行步驟

### 步驟 1：確認來源檔

讀取 `cka/notes.md`，確認第一行是 `# CKA Practice Notes`。若不是，停止。

### 步驟 2：決定下一個封存檔名

搜尋 `cka/` 目錄下符合 `notes-XX.md` 的檔案，找出最大序號加 `1`。若沒有舊檔，使用 `cka/notes-01.md`。

### 步驟 3：建立 raw 目錄（若不存在）

```bash
mkdir -p cka/raw
```

### 步驟 4：複製 notes.md 到封存檔與備份

```bash
cp cka/notes.md cka/notes-XX.md
cp cka/notes.md cka/raw/notes-XX.md
```

複製後檢查兩個新檔都存在且內容一致。

### 步驟 5：在封存檔加入整理日期

只修改 `cka/notes-XX.md`，在第一行後插入：

```
（空行）
整理日期：YYYY-MM-DD
（空行）
```

### 步驟 6：重設 notes.md

把 `cka/notes.md` 重設成：

```md
# CKA Practice Notes

```

只保留 H1 和一個空行。

### 步驟 7：最後檢查

確認：

1. `cka/notes-XX.md` 已建立，第三行是 `整理日期：YYYY-MM-DD`
2. `cka/raw/notes-XX.md` 已建立，內容為原始版本（無日期行）
3. `cka/notes.md` 已回到初始化模板

若任一項不成立，停止並回報。

## 完成回報

```text
已完成：rotate cka notes
封存檔：cka/notes-XX.md
原始備份：cka/raw/notes-XX.md
重設檔案：cka/notes.md
整理日期：YYYY-MM-DD
```
