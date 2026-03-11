# Lessons README

## 用途

`docs/lessons/` 用來存放「VS Code 內部學習記錄」。

這裡只記錄兩種內容：

1. GitHub Copilot 在 repo 內帶著使用者做的專案對照。
2. 與 WeaMind 實際架構、YAML、流量路徑、debug sequence 直接相關的學習整理。

這裡不放純通用知識整理。純知識預習仍放在 `docs/outlines/`。

---

## 和 outlines 的分工

`docs/outlines/` 負責：

1. 外部 ChatGPT 類服務的每日預習大綱。
2. 純知識骨架與白話理解。
3. 不直接綁定 repo 實況的概念預習。

`docs/lessons/` 負責：

1. WeaMind 專案內的實際對照。
2. 為什麼這個 repo 這樣設計。
3. 流量路徑、trade-off、debug 故事。
4. 面試時要能講出來的專案特定說法。

一句話區分：

- outlines 是外部預習。
- lessons 是內部對照與驗收。

---

## 何時應新增 lesson

遇到下面情況，就應新增一份 lesson：

1. 今天在 VS Code 內有完成一段專案特定的學習。
2. 已把通用概念對到實際 YAML、架構或操作。
3. 有形成一段值得回顧的 why、trade-off 或 debug sequence。

如果今天只有純知識預習，沒有碰 repo，通常不需要在這裡新增 lesson。

---

## 目錄結構

每個 lesson 都應使用獨立資料夾，格式如下：

`docs/lessons/YYYY-MM-DD-slug/`

資料夾內至少放兩份文件：

1. `outline.md`：這次 internal learning 要怎麼進行。
2. `qa.md`：這次 internal learning 的小題清單、回答摘要與修正。
3. `report.md`：這次學完後，再回填的學習紀錄與收斂結果。

範例：

- `docs/lessons/2026-03-10-weamind-traffic-path/outline.md`
- `docs/lessons/2026-03-10-weamind-traffic-path/qa.md`
- `docs/lessons/2026-03-10-weamind-traffic-path/report.md`

---

## 命名規則

lesson 資料夾格式：

`YYYY-MM-DD-slug`

例如：

- `2026-03-10-weamind-traffic-path`
- `2026-03-11-pod-to-vm-and-endpoints`
- `2026-03-12-ingress-debug-sequence`

規則：

1. 日期放前面。
2. `slug` 使用英文小寫與連字號。
3. `slug` 要描述今天在專案裡真正學到的主題，而不是抽象大分類。

---

## 每份 lesson 建議結構

### `outline.md` 建議包含：

1. 今日主題
2. 這次要解的專案問題
3. 要對照的 repo 檔案
4. 建議學習順序
5. 要追問的 Why / How 題

### `report.md` 建議包含：

1. 今日主題
2. 這次對話實際學了什麼
3. 使用者原本卡住什麼
4. 對話中釐清的關鍵點
5. 學完後已能講清楚什麼
6. 仍待補強什麼

### `qa.md` 建議包含：

1. 3 到 5 題小範圍題目
2. 每題對應的 repo 檔案或操作目標
3. 使用者回答摘要
4. AI 修正或補充
5. 每題狀態，例如：未開始、進行中、已完成

格式建議：

1. 每題用 `## Q1`、`## Q2` 這種層級。
2. 題內欄位用 `### 題目`、`### 對照檔案`、`### 使用者回答摘要` 這類 H3。
3. 避免大量單行粗體欄位，讓整份 QA 更穩定、好掃讀。

不是每份都要完全一樣，但應保持「專案特定、可回帶、可面試」這三個特性。

---

## 內容原則

### 原則 1：只記專案特定知識

如果一段內容放到任何 Kubernetes 專案都成立，那多半比較適合留在外部預習或一般筆記，不一定要放這裡。

### 原則 2：重點是 Why 與實際路徑

lesson 應優先回答：

1. WeaMind 實際怎麼走。
2. 為什麼這樣設計。
3. 出問題時怎麼查。

### 原則 3：不要把 lessons 寫成完整教科書

每份 lesson 應聚焦單一主題，讓之後複習時能快速抓到當天的重點與脈絡。

### 原則 4：report 不預先寫答案

`report.md` 不應在學習前就填入完整內容。

正確做法是：

1. 先用 `outline.md` 引導對話與學習。
2. 對話結束後，再把這次真正學到的重點寫進 `report.md`。
3. `report.md` 應反映這次互動實際發生了什麼，而不是先寫好標準答案。

### 原則 5：先做小題，再寫 report

`qa.md` 是 internal lesson 的主操作區。

建議流程：

1. 先用 `outline.md` 定義今天的主題與範圍。
2. 再用 `qa.md` 逐題進行 3 到 5 題小練習。
3. 全部 Q/A 跑完後，最後才把重點收斂進 `report.md`。

題目應盡量小、具體、可直接對照 repo。不要把一題寫成一整個章節。

---

## 維護方式

每次新增或完成一份 lesson 後：

1. 視需要更新 `.privatedocs/28day-progress.md`，記錄這次實際學到什麼。
2. 視需要更新 `.privatedocs/ai-memories.md`，只保留 AI 接手需要的高階摘要。
3. 正式進度仍以 `.privatedocs/五週版學習計畫.md` 的「當前執行追蹤」區為準。

---

## 新對話如何接手

如果使用者在新對話裡只說「繼續」，不要直接按日期往後推。

接手原則：

1. 先看 `.privatedocs/五週版學習計畫.md` 的「當前執行追蹤」。
2. 再看當前 lesson 的 `qa.md`，確認是否還有未完成的小題。
3. 需要補範圍時再看 `outline.md`；要收斂已學內容時再看 `report.md`。

一句話原則：進度先看主計畫，執行先看 `qa.md`。