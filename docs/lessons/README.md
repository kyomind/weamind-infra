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
2. `report.md`：這次學完後，再回填的學習紀錄與收斂結果。

範例：

- `docs/lessons/2026-03-10-weamind-traffic-path/outline.md`
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

---

## 維護方式

每次新增或完成一份 lesson 後：

1. 視需要更新 `.privatedocs/28day-progress.md`。
2. 更新 `.privatedocs/ai-memories.md`，讓後續接手知道 lessons 已建立與目前進度。

目前已建立的 lesson：

- `2026-03-10-weamind-traffic-path/`
	- `outline.md`
	- `report.md`