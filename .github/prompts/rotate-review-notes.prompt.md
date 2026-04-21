---
description: "Rotate review/notes.md into the next numbered notes-XX.md archive, add a rotation date, reset notes.md to the review template, and verify the result."
---

# Rotate Review Notes

## 任務目標

把目前的 `review/notes.md` 封存成下一個序號的 `review/notes-XX.md`，在封存檔加入本次整理日期，然後把 `review/notes.md` 重設成 `review/rules.md` 定義的初始化模板。

這個 prompt 只處理 review notes rotate，不負責回答複習問題，也不負責整理內容。

## 核心規則

1. 使用 zh-TW。
2. 只處理 `review/notes.md` 與 `review/notes-XX.md`。
3. 新檔案序號一律用兩位數：
   - 若目前沒有 `notes-XX.md`，從 `01` 開始
   - 若已有舊檔，使用目前最大序號加 `1`
4. 先複製，再修改封存檔；不要先清空 `notes.md`。
5. 封存檔的第三行必須加入：
   - `整理日期：YYYY-MM-DD`
6. `review/notes.md` 重設後，內容必須回到 `review/rules.md` 定義的初始化模板。
7. 完成前一定要做檢查；若檢查失敗，直接停止並說明失敗點。

## 輸入與前提

執行前先確認：

1. `review/notes.md` 存在
2. `review/` 目錄存在
3. `review/notes.md` 第一行是 H1

若任一項不成立，停止並回報原因，不要繼續。

## 停止條件

遇到下面情況直接停止：

1. `review/notes.md` 不存在
2. `review/` 不存在
3. `review/notes.md` 是空檔
4. 無法判斷第一行 H1
5. 無法安全判斷下一個序號
6. 複製後內容與原檔不一致
7. 最後檢查失敗

## 執行步驟

### 步驟 1：確認來源檔

讀取 `review/notes.md`，記住：

1. 第一行 H1 內容
2. 原始全文內容

若第一行不是 Markdown H1，停止。

### 步驟 2：決定下一個封存檔名

只搜尋 `review/` 目錄下符合 `notes-XX.md` 的檔案。

規則：

1. 只接受兩位數序號
2. 找出目前最大值
3. 下一個檔名使用最大值加 `1`
4. 若完全沒有舊檔，使用 `review/notes-01.md`

### 步驟 3：先複製 `notes.md`

把 `review/notes.md` 原樣複製成新的 `review/notes-XX.md`。

複製後立刻檢查：

1. 新檔存在
2. 在加入日期前，新檔內容和原始 `review/notes.md` 完全一致
3. 新檔第一行 H1 與原檔相同

若不一致，停止。

### 步驟 4：在封存檔加入整理日期

只修改新的 `review/notes-XX.md`。

插入規則：

1. 保留原本第一行 H1
2. 第二行留空
3. 第三行加入 `整理日期：YYYY-MM-DD`
4. 第四行留空
5. 第五行開始接原本內容的其餘部分

日期使用執行當天的本地日期。

### 步驟 5：重設 `review/notes.md`

把 `review/notes.md` 重設成下面這個初始化模板：

```md
# Lesson 複習筆記

<!-- Review mode notes will be appended here. Each H2 is one user question. -->
```

不要保留：

1. 舊內容
2. 日期行
3. 其他補充段落

### 步驟 6：最後檢查

至少確認下面幾件事：

1. `review/notes-XX.md` 已建立
2. `review/notes-XX.md` 第一行仍是原本 H1
3. `review/notes-XX.md` 第三行是 `整理日期：YYYY-MM-DD`
4. `review/notes-XX.md` 其餘內容仍保留原始筆記
5. `review/notes.md` 已回到初始化模板

若任一項不成立，停止並回報。

## 完成回報

完成時使用短格式回報：

```text
已完成：rotate review notes
封存檔：review/notes-XX.md
重設檔案：review/notes.md
整理日期：YYYY-MM-DD
```

若有額外補充，只能補：

```text
檢查：封存檔已建立，notes.md 已重設為初始化模板
```
