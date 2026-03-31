---
description: "Generate or refine one lesson's flashcards from completed QA, command drill, notes, and report, then update lesson progress context."
---

# Generate lesson flashcards

## 任務目標

根據單一已完成或接近完成的 lesson，整理或精修 `05-note.md` 內的 `## Flashcards`，讓這份 lesson 最值得長期複習的內容留下來。

這個 prompt 的核心工作，是把 lesson 過程中已經成熟的理解收成卡片，而不是把整份 lesson 改寫一遍。

優先處理的是：

1. 已在 QA 中被修正並收斂的判斷軸
2. command drill 中已釐清的工具邊界、證據邊界與 debug sequence
3. `05-note.md` 的 `## Notes` 中已成熟、適合長期複習的補充理解

`04-report.md` 的角色是最後校對，確保卡片和這份 lesson 的最終收斂一致。

卡片格式與 lesson 規格以：

- `learning/lessons/README.md`
- `learning/lessons/lesson-template.md`

為準。

## 什麼叫做好結果

好的 flashcards 應同時具備這些特徵：

- 只保留 lesson 真正沉澱下來、三個月後仍值得複習的內容
- 每張卡片只承載一個概念，邊界清楚
- 能幫使用者更快重講 Why、How、trade-off、debug sequence
- 內容與 lesson 最終收斂一致，不和 `04-report.md` 打架
- 回頭看卡片時，不需要重新讀完整份 lesson 才知道它在說什麼

## 核心參考

這份 prompt 預設一次只處理單一 lesson，並依照下面順序建立判斷：

### 主要來源

1. `02-qa.md`
2. `03-command.md`（若存在；不存在屬正常情況）
3. `05-note.md` 的 `## Notes`

### 校對來源

1. `04-report.md`

### 輔助理解來源

1. `01-outline.md`
2. `learning/lessons/README.md`
3. `learning/lessons/lesson-template.md`

重點不是平均地從每份檔案抽句子，而是判斷哪裡已經出現真正成熟的理解。

## 核心規則

1. 一次只處理單一 lesson。
2. 先確認 lesson 的主要內容已經有足夠收斂，再決定是否生成或更新卡片。
3. 優先從 `02-qa.md`、`03-command.md`（若存在）、`05-note.md` 的 `## Notes` 抽取成熟內容。
4. 用 `04-report.md` 檢查卡片是否和最終收斂一致。
5. 每張卡片只放一個概念，背面保留最小必要上下文。
6. 保留仍然可用的舊卡片，只更新真正值得精修或補齊的地方。
7. 卡片要偏向「可重講的穩定理解」，而不是對話過程中的臨時修補。
8. 卡片預設整理在 `05-note.md` 的 `## Flashcards`，不另外建立專屬卡片檔。
9. 優先保留三個月後仍值得複習的高含金量內容，不要把所有糾正細節都拆成卡片。

## 何時停止

遇到下面情況，直接停止並說明原因：

1. 無法判斷要處理哪一份 lesson
2. lesson 不存在
3. `05-note.md` 不存在
4. `02-qa.md` 不存在
5. `04-report.md` 尚未完成，且無法作為最終校對依據
6. lesson 內容仍停留在初始化骨架，尚未出現足夠成熟的卡片素材
7. 現有 `## Flashcards` 已經足夠完整可用，沒有明顯補強空間

## 執行方式

### 步驟 1：確認目標 lesson

優先依據：

1. 使用者明確指定的 lesson
2. 目前正在處理、且內容已明顯完成的 lesson

若最後不是單一明確候選，就停止。

### 步驟 2：讀取必要文件

至少讀取：

- `<lesson>/02-qa.md`
- `<lesson>/04-report.md`
- `<lesson>/05-note.md`
- `learning/lessons/README.md`
- `learning/lessons/lesson-template.md`

若存在，也讀取：

- `<lesson>/03-command.md`

`03-command.md` 是 optional。若這份 lesson 沒有 command drill，缺少這個檔案是正常情況，不應因此判定 lesson 異常，也不需要為了生成卡片而停止。
- `<lesson>/01-outline.md`

### 步驟 3：判斷哪些內容值得做成卡片

優先保留這幾類內容：

1. 在 `02-qa.md` 的 `AI 修正與補充` 中已經收斂出的判斷軸
2. 在 `03-command.md` 中已經釐清的工具分工、證據邊界與最小 sequence
3. 在 `05-note.md` 的 `## Notes` 中已經被整理成穩定短版理解的內容
4. 與 WeaMind 實際架構、設計取捨、debug sequence 直接相關的 lesson 特定知識

特別有價值的卡片通常來自：

1. 常見誤解的澄清
2. Why / How / trade-off 的短版答案
3. 能幫使用者快速縮圈的 debug 判斷式
4. 工具或證據之間的責任邊界
5. 容易遺忘，但一旦記住就很有複利的理解

### 步驟 4：更新 `05-note.md` 的 `## Flashcards`

若 `## Flashcards` 仍是初始化空白狀態，直接補入卡片。

初始化空白狀態指的是：

1. `## Flashcards` 底下沒有真正卡片
2. 只有 HTML comment、`暫無` 或其他佔位文字

若已存在部分卡片：

1. 保留仍然成熟可用的卡片
2. 補齊缺少的重要卡片
3. 合併明顯重複、但其實在講同一個概念的卡片
4. 用更穩、更短、更好重講的版本取代明顯偏散或偏碎的舊卡片

卡片寫法應符合 `learning/lessons/README.md` 的規則：

1. `Flashcards` 區塊內直接放 bullet list Markdown
2. 每張卡片只放一個概念
3. 第一行是卡片正面，結尾加分類標籤與 `#card`
4. 分類標籤預設依內容選 `#DevOps` 或 `#English`；若未來需要其他分類，再依實際內容補充
5. 第二行起用縮排 bullet 作為卡片背面
6. 背面保留最小必要上下文，讓單張卡片獨立看也能理解
7. 背面一律寫成短版重點句或片語，句尾不要加句點
8. 背面預設控制在最多 5 行內，只有真的必要時才略微放寬
9. `Flashcards` 區塊內直接放卡片條列，不另外用 H3 分組卡片批次

格式範例：

```md
- liveness probe 失敗會發生什麼？ #DevOps #card
	- Pod 會被 `kubelet` 重啟
	- 它處理的是「容器是否還活著」，不是「是否已準備接流量」
```

### 步驟 5：確認整體一致性

更新卡片後，再回頭確認：

1. 卡片是否和 `04-report.md` 的最終收斂一致
2. 是否把過程性細節誤當成熟卡片留下來
3. 是否把同一個概念拆成多張近義重複卡
4. 是否漏掉這份 lesson 最值得複習的核心理解

### 步驟 6：回報結果

完成時使用以下格式：

```text
已完成：<lesson> 的 generate-flashcards
已更新：<lesson>/05-note.md
校對依據：<lesson>/04-report.md
```

若有重要補充，可再加一行：

```text
補充：新增 <n> 張卡片，並精修 <n> 張既有卡片
```

## 完成前檢查

1. 卡片主要來自 `02-qa.md`、`03-command.md`（若存在）、`05-note.md` 的 `## Notes`
2. `04-report.md` 只用來校對最終收斂，而不是整份直接拆卡
3. 卡片保留 lesson 特定價值，而不是泛化成空泛 Kubernetes 常識
4. 每張卡片都能獨立成立，且一眼看出它在回答什麼
5. 沒有把同一個觀念用近義說法重複做成多張卡
6. 更新後的 `05-note.md` 仍符合 `learning/lessons/README.md` 的卡片格式
7. 卡片集中在 `05-note.md`，沒有額外分出第二份卡片檔
