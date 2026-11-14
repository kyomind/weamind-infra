# Prework AGENTS.md

## 用途

`learning/prework/` 用來存放「每日外部預習 prework」。

補充：在少數情況下，這裡也可以承接 lesson 結束後才補建的輕量 homework；這類檔案仍放在 `learning/prework/`，但內文必須明確標示它是課後補強，不是正式課前預習。

這份 AGENTS.md 是 `learning/` 底下的第二層規則檔。

它有一個前提：你已經先讀過 `learning/AGENTS.md`，而且已經做完「今天是否需要 prework」的判斷。

只有在已確認今天需要外部預習時，才應該打開這份 AGENTS.md。

這些檔案不是給 repo 內 AI 直接教學用的，而是給外部 ChatGPT / TradeGPT 類型的對話服務使用。

目的是把每天的純知識預習先外包出去，減少在 repo 內協作時閱讀長篇通用教學內容的負擔。

每份 prework 通常會在同一份文件中同時放兩件事：前半段是要貼給外部 AI 的教學任務，後半段是學完後要帶回 repo 內的學習報告回填區。前者負責建立理解骨架，後者負責把結果收斂成可保存的紀錄。

在實際內容裡，前半段與後半段之間通常會再加一句簡短邊界說明，提醒外部 AI 先完成教學，再回到報告模板。

格式骨架請看 [prework-template.md](prework-template.md)；這份 AGENTS.md 只保留規則與流程。

之後再把預習結果帶回 repo 內，由 AI 協作負責：

1. 對照 WeaMind 專案實際檔案。
2. 做 YAML 觀察與 kubectl 操作。
3. 做 Why、trade-off、debug sequence 追問。
4. 做每日驗收與追問式練習。

## CKA 邊界

`learning/prework/` 可以保留既有的 CKA 取向 prework，因為它們是 WeaMind 學習計畫與概念補強的歷史紀錄；但這不代表新的純 CKA 考試資料仍應放在本 repo。

- 純 CKA 刷題、題庫紀錄、考試技巧、筆記整理與 CKA 專用 prompts，統一放在獨立的 `CKA-Notes` repo：`https://github.com/kyomind/CKA-Notes`。
- 只有當使用者明確要先補一個通用概念，之後再回來對照 WeaMind manifests、docs、commands 或 debug sequence 時，才在本目錄建立新的 prework。
- CKA 題目可以作為這類 prework 的明確輸入，但不能只因為 repo 內有歷史 CKA prework，就自行推導下一個考試主題。
- 若需求只有考試解題、刷題紀錄或整理 CKA notes，應改到 `CKA-Notes` 處理，不要在這裡建立平行副本。

## 與 lesson 的先後順序

要不要做 prework，由 `learning/AGENTS.md` 的 Prework Decision 判斷（含 readiness 問句）；本檔只在判斷完成後使用。lesson 收尾後若仍有一小塊通用缺口，也可以回到本檔建立 homework 型補強。

---

## 這份 AGENTS.md 的責任邊界

本檔負責：

1. prework 的命名規則。
2. prework 的段落骨架。
3. 外部預習的交付形式。
4. prework 與 lesson 的銜接方式。
5. lesson 後 homework 型補強檔應如何放在 `prework/` 中。

本檔不負責：

1. learning 入口導覽。
2. lesson 內部的 QA / command / report 規格。
3. 今天是否真的需要外部預習的上層判斷。

如果現在還在判斷是否要 prework，請回 `learning/AGENTS.md`。

如果現在已確定要進 lesson，請改看 `learning/lessons/AGENTS.md`。

格式骨架則請改看 `prework-template.md`。

---

## 命名規則

每日 prework 檔名一律使用這種格式：

`YYYY-MM-DD-slug.md`

例如：

- `2026-03-09-ingress-basics.md`
- `2026-03-10-ingress-debug-story.md`
- `2026-03-12-deployment-pod-management.md`

規則：

1. 日期一定放前面，使用西元年與兩位數月份、日期。
2. `slug` 使用英文小寫與連字號。
3. `slug` 應描述「今天外部 AI 要教的核心主題」，不要取太泛。
4. 一天原則上一份 prework；若真的拆成兩份，第二份應在 slug 上明確區分。

若是 lesson 收尾後補建的 homework，也仍沿用同一套命名規則；建議在 slug 中加入 `followup`、`review` 或 `homework` 這類可辨識字樣，例如：

- `2026-03-24-k8s-debug-tools-followup.md`
- `2026-03-24-k8s-debug-tools-homework.md`

---

## 這些大綱要解決什麼問題

外部 AI 適合做的事情是：

1. 講通用知識。
2. 幫使用者建立最小理解骨架。
3. 用白話方式說明基本概念。
4. 用少量問題確認是否理解。

所以每份 prework 的核心目的，是把外部 AI 的教學任務、範圍與節奏寫清楚，讓它自然聚焦在「純知識預習」與「最小理解骨架」，而不是自行延伸到專案細節。

---

## 何時需要新增一份 prework

遇到下面情況，就應新增當天 prework：

1. 當天主題有明顯的純知識預習需求。
2. 使用者會先到外部 AI 進行預習。
3. 當天內容若直接在 repo-backed lesson 中長篇講解，閱讀負擔太高。

如果當天主要是：

1. 對照實際 manifests。
2. 跑 kubectl 指令。
3. 看 describe / logs / events。
4. 做專案特定 debug。

那就不一定需要 prework，可以直接進 repo-backed lesson。

另外，若今天雖然已直接完成 repo-backed lesson，但在收尾時發現仍有一小塊通用骨架值得補齊，也可以新增一份 homework 型 prework。這種情況的重點不是「回頭重做今天 lesson」，而是把今天已碰到、但還沒完整展開的通用知識交給外部 AI 輕量補學。

---

## 新 prework 應如何產生

在新的對話裡，如果要產生 prework，repo 內 AI 協作應遵守這個流程：

1. 先確認上層流程判斷已完成，也就是今天已確定需要 prework。
2. 若有 active plan，對照它確認今天日期、主題與學習範圍；沒有時以使用者指定的主題為準。
3. 判斷今天有哪些內容屬於「純知識預習」，哪些內容應保留到 repo 內做專案對照。
4. 在 `learning/prework/` 建立新檔，檔名依 `YYYY-MM-DD-slug.md`。
5. 內容必須明確寫出：
   - 今天要學什麼
   - 這份 prework 要怎麼用
   - 今天要建立的最小理解骨架
   - 建議教學順序
   - 學完後要產出的學習報告格式
6. prework 建立後，預設應先停在 prework 階段，等使用者完成外部預習後，回到 root `AGENTS.md` 的 Learning Workflow 進入設計討論；使用者開口要 lesson 時才進入 `learning/lessons/`。
7. 正式開始外部預習前，應再快速自檢一次，確認內容仍符合本檔的結構與輕量原則。
8. 寫完後，若有必要，更新 `.privatedocs/ai-memories.md`，記錄新的 prework 已建立。

若這份檔案其實是 lesson 收尾後補建的 homework，流程上可直接從「判斷有哪些內容屬於通用補強、適合交給外部 AI」開始，但仍應遵守同一套命名、輕量與輸出原則，並在檔案前言清楚寫明它是課後補強 homework。

---

## 內容原則

### 原則 1：先學骨架，不先考試

prework 的目標不是讓外部 AI 一開始就考使用者，而是先幫使用者聽懂今天最需要的基礎。

### 原則 1.5：保持輕量

prework 應盡量短、小、直接。目標是讓外部預習控制在 45 到 60 分鐘左右，而不是把 prework 寫成一份需要花 2 小時執行的微型課程。

能少一個 section 就少一個 section，能少一組要求就少一組要求，只保留真正必要的骨架、限制和輸出。

### 原則 2：只教今天要用到的知識

不要讓外部 AI 把主題擴展成 Kubernetes 全科總複習。

### 原則 3：用正向邊界引導

prework 應優先寫清楚今天的教學任務、範圍、節奏與輸出。當責任被定義得夠清楚時，外部 AI 自然較容易維持聚焦，不需要堆疊太多負向限制語句。

### 原則 4：專案細節留在 repo 內對照

repo 路徑、資源名稱、具體 YAML、CI/CD workflow、TLS 資源名稱等，應由 repo 內 AI 協作對照實際檔案處理。外部 AI 這裡只需要理解背景與概念脈絡。

### 原則 5：最後一定要產出可回帶的學習報告

每份 prework 最後都應要求外部 AI 產出：

1. 一份完整的學習報告，而不是只在對話中簡短回答「今天學到什麼」
2. 今日重點摘要
3. 白話版理解
4. 目前卡住處
5. 帶回 repo 內做專案對照的問題

---

## 與 repo-backed lesson 的分工

外部 AI 負責：

1. 名詞理解
2. 白話解釋
3. 最小骨架建立
4. 輕量理解確認

repo 內 AI 協作負責：

1. 對照實際 manifests 與文件
2. 指出專案特定設計選擇
3. 帶操作題與 debug 題
4. 追問 Why、trade-off、debug sequence
5. 視需要更新 `.privatedocs/ai-memories.md`

---

## 目前範例

範例 prework：

- `2026-03-09-ingress-basics.md`
- `2026-03-24-k8s-debug-tools-followup.md`（lesson 收尾後補建的 homework 型補強範例）

模板：

- `prework-template.md`

之後新增 prework 時，應先看這份 AGENTS.md，再參考既有範例，但不要機械複製內容；應根據當天主題調整最小骨架與教學順序。
