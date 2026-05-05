# DONE-implement-heavy-mode 設計討論紀錄

## 文件目的

這份文件用來整理這次關於 `implement-heavy-mode` 的設計討論。

這不是正式規則檔，也不是已生效的 workflow 變更紀錄。

它的角色是先把這次討論收斂成可回看的設計紀錄，讓之後真的要落成文件時，不需要再從零回想「當初到底想解什麼問題、打算怎麼改」。

補記：後續已正式落成 `learning/lessons/plugins/implementation/implement-heavy-mode.md`，並同步更新 `learning/lessons/README.md` 與 `learning/lessons/lesson-template.md`。本檔保留的是設計討論脈絡，不是最新規則本體。

再補記：這次討論之後，實際落地結果又往前推了一步，已不只是一份 mode 規格文件，而是連 mode enum、計畫層決策來源與 implement-heavy 專用 template 都已補齊。詳見下方「後續實際落地結果」。

## 討論背景

在目前 lessons 的常態規則裡，內部預設流程是：

- QA -> command -> report

這套預設對大多數 repo-backed lesson 很合適，尤其是：

- 先講清楚概念與架構
- 再用 command drill 做驗證
- 最後回 report 收斂

但使用者提出一個重要觀察：

- 有些 lesson 的主體不是 command-heavy，而是 implement-heavy
- 這種 lesson 很顯然需要先進行 implement
- 因此它和一般 lesson 的預設節奏不同，也不適合直接把例外規則硬塞回通用 README

這個觀察和先前 `command-heavy-mode.md` 的產生邏輯其實一致：

- 常態規則留在 `learning/lessons/README.md`
- 特殊節奏用獨立補充文件按需揭露

## 這次討論的核心問題

這次不是在問「lesson 裡可不可以實作」，而是在問：

- 當 lesson 的主體明確是 implement 時，預設文件結構與流程是否應有一套獨立外掛規格

更具體地說，這個問題至少牽涉四件事：

1. lesson 預設流程是否還是 `QA -> command -> report`
2. `02-qa.md` 在 implement-heavy 當天應縮成什麼樣子
3. `03-command.md` 是否仍是主文件，還是要退到次要驗證角色
4. `06-implementation.md`、`07-implementation-note.md` 這種檔案，是否應從「少見特例」提升成 implement-heavy 模式下的預設結構

## 這次對照的參考檔案

這次討論主要對照了三組內容。

### 1. command-heavy 外掛規格

- `learning/lessons/plugins/command-heavy-mode.md`

這份文件提供了重要的結構性參考：

- 例外規格不直接回寫常態 README
- 只在確定是某種特殊 lesson 節奏時才按需讀取
- 調整 QA 與主要操作檔的節奏，但不推翻整體 lesson 結構

也就是說，`implement-heavy-mode` 若真的成立，最合理的形式也應該是這種「外掛型補充文件」，而不是直接把所有例外堆回 `learning/lessons/README.md`。

### 2. lessons 的常態規則

- `learning/lessons/README.md`

這份 README 目前明確把 lesson 的常態預設寫成：

- QA 在前
- command drill 為必要時建立
- report 在互動後收斂

而且它也已經保留一個很重要的擴充原則：

- 若某天有明確例外節奏，優先採獨立補充文件做按需揭露

這表示從架構上看，`implement-heavy-mode` 是可以和現有 lessons 系統相容的，不需要推翻 lessons README，只需要新增一份和 `command-heavy-mode.md` 類似的補充規格檔。

### 3. 已有的 implement 類 lesson 樣本

- `learning/lessons/2026-04-01-lb-health-check-skeleton/01-outline.md`
- `learning/lessons/2026-04-01-lb-health-check-skeleton/02-qa.md`
- `learning/lessons/2026-04-01-lb-health-check-skeleton/03-command.md`
- `learning/lessons/2026-04-01-lb-health-check-skeleton/06-implementation.md`
- `learning/lessons/2026-04-01-lb-health-check-skeleton/07-implementation-note.md`

這份 lesson 很重要，因為它不是純 command-heavy，也不是純概念 lesson，而是真的在 lesson 中途進入 cluster 設定調整。

它提供了目前 repo 內最接近 implement-heavy lesson 的現成樣本。

## 從 2026-04-01 樣本看到的重點

`2026-04-01-lb-health-check-skeleton` 這份 lesson 顯示出一個很明顯的現象：

- 當天確實仍有 QA
- 也仍有 command drill
- 但真正的主體在後半段轉成 implementation rounds

也就是說，那天實際上出現了第三種節奏，不完全等於常態 lesson，也不完全等於 command-heavy：

- QA 負責先把設計與 incident 講清楚
- command 負責補最小觀察證據
- implement 才是真正改動系統的主戰場

而且 `06-implementation.md` 已經自然長出一套自己的節奏：

- 這一輪要驗證什麼
- 預計操作
- 實際輸出 / 操作結果
- AI 判讀與收斂
- 目前狀態

這表示 implement-heavy 並不是理論上的需求，而是 repo 裡已經出現過一次，只是目前還沒有被抽象成正式外掛規格。

## 目前討論後比較清楚的判斷

### 判斷 1：implement-heavy-mode 應該存在，而且適合走外掛模式

這點目前方向相當清楚。

理由是：

- 它確實和常態 lesson 有不同節奏
- 它也和 command-heavy mode 不同
- 但它又不是大到要推翻整個 lessons README

因此最自然的做法就是：

- 保留 `learning/lessons/README.md` 作為常態規則
- 新增一份 implement-heavy 的補充文件
- 只在當天確定屬於 implement-heavy lesson 時才按需讀取

### 判斷 2：它影響的不只是多一個檔案，而是整體 lesson 重心順序

使用者特別點出的關鍵是：

- implement-heavy lesson 很顯然地必須先進行 implement

這代表它不只是「多開一個 `06-implementation.md`」而已，而是可能需要改動：

- 什麼情況下 QA 應縮成 implementation 前定位題
- command 是否退成輔助驗證，而不是主體
- outline 應如何明寫這次為什麼要先 implement

也就是說，`implement-heavy-mode` 若成立，應改的是 lesson 預設重心，而不是只補一個額外附錄檔案。

### 判斷 3：它很可能仍保留 QA，但 QA 的角色會變

從 command-heavy mode 的規格可以看出一個有用模式：

- QA 仍存在
- 但 QA 改成短版定位題

implement-heavy 很可能也會需要類似處理，只是定位的內容會不同。

可能更接近：

1. 這輪 implement 想改哪個邊界
2. 為什麼先改這一層，而不是先做更多觀察
3. 成功或失敗後，下一輪要看哪個驗收訊號

也就是說，QA 不一定消失，但它的角色不再是展開一整塊概念，而是為 implement 提供前置座標。

### 判斷 4：`06-implementation.md` 與 `07-implementation-note.md` 很可能需要正式升格

目前在常態 lesson README 裡，標準結構仍以 `01-05` 為核心；`06-implementation.md` 和 `07-implementation-note.md` 只在個別 lesson 裡出現。

但若 implement-heavy-mode 要成為正式外掛，那這兩份檔案很可能要被明確定義為：

- implement-heavy 當天的預設增量結構

而不是繼續停留在「剛好那天有需要才長出來」。

## 目前還沒正式落下來的地方

下面這一節保留的是當時討論進行中的狀態。

後續實際已落地的結果，請以下方「後續實際落地結果」為準。

雖然方向已經清楚，但這次討論仍刻意停在「先討論、先不改」。

所以目前還沒有正式落檔的，是下面幾件事：

### 1. implement-heavy 外掛檔的正式名稱

目前討論中用的是：

- `implement-heavy-mode`

但還沒有正式決定最終檔名。

若要和現有命名風格一致，未來可能會變成類似：

- `implement-heavy-workshop.md`
- `implementation-heavy-mode.md`
- `implement-heavy-supplement.md`

這部分目前仍是開放的。

### 2. 內部預設流程是否要改成明寫的例外順序

command-heavy mode 目前仍維持：

- QA -> command -> report

而 implement-heavy 最值得討論的點是：

- 是否要明確寫成 `QA -> implementation -> command -> report`
- 或 `QA -> implementation -> report`，command 只在需要時補
- 或保留 `QA -> command -> report` 作為總體框架，但在 outline 明寫 implementation 才是主體

這一點目前尚未正式收斂。

### 3. 常態 README 要不要只加一句入口提示

因為 lessons README 已經有保留「例外節奏優先用獨立補充文件」的原則，所以之後若真的新增 implement-heavy 外掛，可能只需要在常態 README 補一句：

- 若當天主體是實作，請另讀 implement-heavy 補充文件

但這次討論刻意還沒進入實際改檔。

## 目前比較穩的設計方向

若未來真的要正式落成 implement-heavy-mode，依這次討論，較穩的方向大致會是：

1. 不改 lessons README 的主體結構，只加最小入口提示
2. 新增一份 implement-heavy 的補充文件，按需讀取
3. 在那份補充文件裡定義：
   - implement-heavy 的適用情境
   - QA 應如何縮成 implementation 前定位題
   - `06-implementation.md` 的節奏與閉環格式
   - `07-implementation-note.md` 的責任邊界
   - command 在 implement-heavy lesson 裡是主體、輔助，還是 optional
4. 以 `2026-04-01-lb-health-check-skeleton` 當成第一個主要參考樣本

## 這次討論後的狀態判斷

下面這段同樣保留的是當時討論收尾時的狀態，不是現在 repo 的最新結果。

目前可以說：

- 這個需求是成立的
- 方向也大致清楚
- 但還停在設計討論階段
- 尚未正式回寫任何 rules / README / supplement 檔

因此這份文件的定位不是「規則已上線」，而是：

- implement-heavy-mode 已被正式提出
- 已確認它適合沿用 command-heavy mode 的外掛模式
- 已找到 repo 內最好的既有樣本
- 下一步若要做，應進入規格落檔，而不是重新討論需求是否存在

## 後續實際落地結果

這份設計討論之後，repo 內實際又完成了幾件重要的收斂，這些已不再只是討論方向，而是正式規則的一部分。

### 1. implement-heavy mode 已正式落成

正式規則檔已建立為：

- `learning/lessons/plugins/implementation/implement-heavy-mode.md`

目前 implement-heavy 已不再只是概念補充，而是有明確流程、檔案角色、初始化規格與自檢條件的正式 plugin 文件。

### 2. implement-heavy 專用 template 已從常態 template 抽離

後續沒有把 `06-implementation.md` 與 `07-implementation-note.md` 長期留在 `learning/lessons/lesson-template.md`。

實際採用的做法是：

- 常態 template 回到 `01-05`
- implement-heavy 另有自己的專用骨架：`learning/lessons/plugins/implementation/implement-heavy-lesson-template.md`

這樣可避免一般 lesson 每次都被 `06` / `07` 的特殊骨架干擾。

### 3. `07-implementation-note.md` 已被正式定義成 `06` 的 companion file

後續已明確收斂：

- `06-implementation.md` 是主戰場
- `07-implementation-note.md` 只承接 `06` 過程中的 implementation-specific 補充觀察
- `07` 不是獨立 phase，也不取代 `05-note.md`

這個關係現在不只存在於討論裡，也已經寫進 mode 規格與 implement-heavy 專用 template。

### 4. mode 的決策來源已上移到計畫層

這次後續最重要的收斂之一是：

- lesson 是否套用某個 mode，不再由 `01-outline.md` 決定
- 正式決策來源改成當天計畫
- `01-outline.md` 只負責把這個決策寫成 lesson 內的執行提醒

也就是說，outline 現在是 reminder，不是 decision source。

### 5. lesson mode 的 enum 與上位索引已補齊

後續新增了：

- `learning/lessons/plugins/lesson-modes.md`

這份文件統一定義：

- 合法 enum
- mode 的決策來源
- 各 mode 對應要讀的 plugin 文件

目前合法的 `Lesson mode` 值已收斂為：

- `not-applicable`
- `normal`
- `command-heavy`
- `implement-heavy`

### 6. Phase 2 計畫已開始正式使用 `Lesson mode`

後續也同步回寫到：

- `.privatedocs/Phase2三週計畫.md`

目前每天的小節已加入固定的 `Lesson mode` 欄位，並明確使用上述 enum，讓 AI 在真正建立 lesson 前，就能先從計畫層知道今天是不是 normal、implement-heavy，或根本不進 lesson。

## 一句話總結

這次討論最大的收斂是：`implement-heavy-mode` 不是隨手補一個 `06-implementation.md` 就好，而是一種值得獨立成外掛規格的 lesson 例外節奏；而 `2026-04-01-lb-health-check-skeleton` 就是目前 repo 內最好的原型樣本。
