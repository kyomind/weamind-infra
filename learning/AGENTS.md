# Learning AGENTS.md

## 用途

`learning/` 是這個 repo 的公開學習系統入口。

這份 AGENTS.md 的責任不是把所有規則一次講完，而是先回答兩件事：

1. 你現在要進入的是哪一種學習流程。
2. 下一份應該往下讀的 AGENTS.md 是哪一份。

一句話定位：

- `learning/AGENTS.md` 負責總導覽與分流。
- `learning/lessons/AGENTS.md` 負責 lesson 內部規格。
- `learning/prework/AGENTS.md` 負責 prework 規格。

## AI 工作規則

以下章節是 `learning/` 的目錄局部工作規則。AI 只有在 root `AGENTS.md` 路由到本檔處理學習流程時，才應使用這些規則。

---

## 三層分工

### `learning/AGENTS.md`

這是入口層。

它負責：

1. 定義 `learning/` 底下有哪些學習空間。
2. 說明什麼情況應該走 `prework/`，什麼情況應該走 `lessons/`。
3. 規定閱讀順序要先看這份，再決定往下讀哪一份子 AGENTS.md。

它不負責：

1. lesson 檔案骨架細節。
2. prework 段落模板細節。
3. QA / command / report 的完整欄位規則。

### `learning/lessons/AGENTS.md`

這是 lesson 規格層。

它負責：

1. 進入 repo 內 lesson 之後的標準流程。
2. lesson 目錄結構與各檔案分工。
3. QA、command、report、note 的寫法與邊界。

### `learning/prework/AGENTS.md`

這是 prework 規格層。

它負責：

1. 外部預習何時需要建立。
2. prework 檔案怎麼命名與撰寫。
3. 外部預習應交付什麼，回來後如何銜接 lesson。

---

## 進入順序

只要是新的學習操作，一律先讀這份 `learning/AGENTS.md`，不要直接跳進 `lessons/AGENTS.md` 或 `prework/AGENTS.md`。

標準順序如下：

1. 先讀 `learning/AGENTS.md`。
2. 先判斷現在要做的是：進入既有 lesson、建立新 lesson、還是建立 prework。
3. 若是新主題，先判斷今天是否需要外部預習。
4. 只有在已判斷「需要外部預習」時，才往下讀 `prework/AGENTS.md`。
5. 只有在已判斷「直接進入 lesson」或「prework 已完成」時，才往下讀 `lessons/AGENTS.md`。
6. 只有在確定要建立新的 lesson 骨架時，才再往下讀 `lessons/lesson-template.md`。

一句話原則：先看入口 AGENTS.md，再依判斷結果逐層揭露下一份規則，不要一開始把三份 AGENTS.md 全部攤開。

---

## 兩條路徑

在判斷今天是否需要 prework 時，要分開看兩件事：

1. repo 內是否已有足夠的專案證據，可供後續 lesson 做對照。
2. 使用者是否已有足夠的前置知識骨架，可以直接進入 repo-backed lesson。

一句話原則：**專案資料足夠，不等於使用者前置知識足夠。**

所以 AI 不應只因為 repo 已經有 README、YAML、文件或 incident note，就直接判斷今天不需要 prework。

較穩的判斷順序是：

1. 先判斷今天的難點主要是在「通用機制本身」，還是「專案內對照與操作」。
2. 再判斷使用者是否可能缺今天需要的最小概念骨架。
3. 最後才判斷 repo 證據是否足夠支撐後續 lesson。

如果 AI 無法可靠判斷使用者前置知識是否足夠，應先問 1 到 2 個很短的確認問題，再決定是否進 prework，而不是直接假設不需要。

可優先使用這組短問題：

1. 你現在是只差專案對照，還是連基本概念都還沒骨架？
2. 今天主題裡，你最不確定的是 repo 怎麼做，還是它底層到底在做什麼？
3. 若現在直接進 lesson，你預期自己會卡在概念還是卡在專案細節？

### 路徑 A：先做 prework

適用情況：

1. 今天主題先缺通用概念骨架。
2. 直接在 VS Code 內展開會太重。
3. 需要先把純知識部分交給外部 AI 處理。
4. 今天的難點主要在理解通用機制本身，而不是專案對照。
5. 今天主題涉及多個方案比較、底層驗證方式、控制器角色、或和外部服務互動的基本原理。
6. 若不先做 prework，今天的 lesson 很可能先花大量篇幅補通用知識，無法立刻進入 repo 對照。

路徑：

1. 先看這份 `learning/AGENTS.md`。
2. 確認今天需要 prework。
3. 再進 `prework/AGENTS.md`。
4. prework 完成後，再進 `lessons/AGENTS.md`。

### 路徑 B：直接進 lesson

適用情況：

1. 今天主題除了 repo 證據足夠之外，使用者也已經有足夠的前置骨架。
2. 今天主要任務就是 repo 對照、QA 或 command drill。
3. 不需要先做外部預習。

補充判斷：

1. 若今天的難點主要在專案特定設計、YAML 對照、操作順序或 debug sequence，通常更適合直接進 lesson。
2. 若今天的難點主要在理解通用機制本身，例如某個控制器在做什麼、兩種驗證方式本質差在哪裡、某個流程如何和外部服務互動，則較應優先考慮 prework。

路徑：

1. 先看這份 `learning/AGENTS.md`。
2. 確認今天不需要 prework。
3. 直接進 `lessons/AGENTS.md`。

---

## lesson 收尾後的補強

有些日子雖然一開始判斷不需要 prework，直接進入了 lesson，但在 lesson 結束或收尾時，仍可能發現有一小塊通用知識值得補學。

這種情況可以補建一份輕量 homework。

原則如下：

1. 這不是新的第三條主流程，也不是獨立的新資料夾。
2. homework 仍然放在 `learning/prework/`。
3. 檔案內文必須明確寫出：這是一份 lesson 後的補強 homework，不是正式課前預習。
4. 內容應聚焦在今天 lesson 已碰到、但還沒完整展開的通用骨架，不要回頭重寫整份 lesson。
5. 若使用者之後真的完成這份 homework，可再視需要把學到的內容帶回 `learning/lessons/` 裡的 note、report 或後續 lesson。

一句話原則：prework 預設是課前外部預習；但若 lesson 收尾後發現有必要補一小塊通用知識，可以用 `learning/prework/` 承接一份明確標示為 homework 的補強檔。

---

## 這份 AGENTS.md 應怎麼用

### 當要開始一個新主題

先用這份 AGENTS.md 做流程判斷，不要一開始就建 lesson 或 prework。

### 當要建立新 lesson

先用這份 AGENTS.md 確認今天是否應直接進 lesson，確認後才去看 `lessons/AGENTS.md`，最後才看 `lessons/lesson-template.md`。

### 當要建立 prework

先用這份 AGENTS.md 確認今天真的需要 prework，確認後才去看 `prework/AGENTS.md`。

### 當 lesson 結束後想補一份 homework

先用這份 AGENTS.md 確認這不是新開主流程，而是 lesson 收尾後的補強；確認後仍去看 `prework/AGENTS.md`，並把檔案放在 `learning/prework/`，只是在說明中標示它是 homework。

### 當使用者只說「繼續」

這份 AGENTS.md 只負責提醒閱讀順序；正式進度應先回到 `.privatedocs/12週計畫.md` 判斷當前 phase，再讀該 phase 的詳細計畫（Phase 1 用 `.privatedocs/六週版學習計畫.md`，Phase 2 用 `.privatedocs/Phase2三週計畫.md`），之後才依當前情況進 lesson 或 prework。

---

## 子 AGENTS.md 的閱讀時機

1. `lessons/AGENTS.md`：只有在已決定進入 lesson 流程時才讀。
2. `prework/AGENTS.md`：只有在已決定需要外部預習時才讀。
3. `lessons/lesson-template.md`：只有在已決定新建 lesson 骨架時才讀。

如果還沒做完「今天是否需要 prework」這個判斷，就代表現在還不應往下讀子 AGENTS.md。
