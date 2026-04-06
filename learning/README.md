# Learning README

## 用途

`learning/` 是這個 repo 的公開學習系統入口。

這份 README 的責任不是把所有規則一次講完，而是先回答兩件事：

1. 你現在要進入的是哪一種學習流程。
2. 下一份應該往下讀的 README 是哪一份。

一句話定位：

- `learning/README.md` 負責總導覽與分流。
- `learning/lessons/README.md` 負責 lesson 內部規格。
- `learning/prework/README.md` 負責 prework 規格。

---

## 三層分工

### `learning/README.md`

這是入口層。

它負責：

1. 定義 `learning/` 底下有哪些學習空間。
2. 說明什麼情況應該走 `prework/`，什麼情況應該走 `lessons/`。
3. 規定閱讀順序要先看這份，再決定往下讀哪一份子 README。

它不負責：

1. lesson 檔案骨架細節。
2. prework 段落模板細節。
3. QA / command / report 的完整欄位規則。

### `learning/lessons/README.md`

這是 lesson 規格層。

它負責：

1. 進入 repo 內 lesson 之後的標準流程。
2. lesson 目錄結構與各檔案分工。
3. QA、command、report、note 的寫法與邊界。

### `learning/prework/README.md`

這是 prework 規格層。

它負責：

1. 外部預習何時需要建立。
2. prework 檔案怎麼命名與撰寫。
3. 外部預習應交付什麼，回來後如何銜接 lesson。

---

## 進入順序

只要是新的學習操作，一律先讀這份 `learning/README.md`，不要直接跳進 `lessons/README.md` 或 `prework/README.md`。

標準順序如下：

1. 先讀 `learning/README.md`。
2. 先判斷現在要做的是：進入既有 lesson、建立新 lesson、還是建立 prework。
3. 若是新主題，先判斷今天是否需要外部預習。
4. 只有在已判斷「需要外部預習」時，才往下讀 `prework/README.md`。
5. 只有在已判斷「直接進入 lesson」或「prework 已完成」時，才往下讀 `lessons/README.md`。
6. 只有在確定要建立新的 lesson 骨架時，才再往下讀 `lessons/lesson-template.md`。

一句話原則：先看入口 README，再依判斷結果逐層揭露下一份規則，不要一開始把三份 README 全部攤開。

---

## 兩條路徑

### 路徑 A：先做 prework

適用情況：

1. 今天主題先缺通用概念骨架。
2. 直接在 VS Code 內展開會太重。
3. 需要先把純知識部分交給外部 AI 處理。

路徑：

1. 先看這份 `learning/README.md`。
2. 確認今天需要 prework。
3. 再進 `prework/README.md`。
4. prework 完成後，再進 `lessons/README.md`。

### 路徑 B：直接進 lesson

適用情況：

1. 今天主題已經有足夠骨架。
2. 今天主要任務就是 repo 對照、QA 或 command drill。
3. 不需要先做外部預習。

路徑：

1. 先看這份 `learning/README.md`。
2. 確認今天不需要 prework。
3. 直接進 `lessons/README.md`。

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

## 這份 README 應怎麼用

### 當要開始一個新主題

先用這份 README 做流程判斷，不要一開始就建 lesson 或 prework。

### 當要建立新 lesson

先用這份 README 確認今天是否應直接進 lesson，確認後才去看 `lessons/README.md`，最後才看 `lessons/lesson-template.md`。

### 當要建立 prework

先用這份 README 確認今天真的需要 prework，確認後才去看 `prework/README.md`。

### 當 lesson 結束後想補一份 homework

先用這份 README 確認這不是新開主流程，而是 lesson 收尾後的補強；確認後仍去看 `prework/README.md`，並把檔案放在 `learning/prework/`，只是在說明中標示它是 homework。

### 當使用者只說「繼續」

這份 README 只負責提醒閱讀順序；正式進度錨點仍回到 `.privatedocs/六週版學習計畫.md`，再依當前情況進 lesson 或 prework。

---

## 子 README 的閱讀時機

1. `lessons/README.md`：只有在已決定進入 lesson 流程時才讀。
2. `prework/README.md`：只有在已決定需要外部預習時才讀。
3. `lessons/lesson-template.md`：只有在已決定新建 lesson 骨架時才讀。

如果還沒做完「今天是否需要 prework」這個判斷，就代表現在還不應往下讀子 README。
