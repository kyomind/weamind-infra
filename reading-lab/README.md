# reading-lab

這是一本書或一篇長文的學習工作區。

如果你在新的對話裡要接手這個工作區，先讀這份 README，再讀對應來源資料夾底下的 `README.md` 與 `outputs/README.md`。這樣就能先知道這個來源在做什麼、哪些內容可以同步、哪些內容只是本地素材。

這裡的原則很簡單：

1. 每一個來源都必須有自己的獨立子資料夾。
2. 原始素材放 `sources/`，這層只做本地收集，不同步到 Git。
3. 整理後可以同步的內容放 `outputs/`，例如總綱、分題 prework、學習報告與整理稿。
4. 歷史但不再主用的內容放 `archive/`，例如舊草稿、被新版取代的整理稿、臨時實驗版。
5. 之後如果再來第二本書或另一篇長文，只要新增另一個來源子資料夾，不需要改整體架構。

## 和 learning 的關係

`reading-lab/` 是獨立於正常 lesson 流程之外的工作區。

它可以沿用 `learning/` 裡的一些共通寫法，例如 prework 的模板感、段落分工、回填區設計，但它本身不是 `learning/lessons/` 的一部分，也不需要跟著 lesson 的 QA / command / report 節奏走。

最準確的理解是：

1. `learning/` 負責正式的學習流程與 lesson 規格。
2. `reading-lab/` 負責把外部素材整理成可同步、可回帶、可歸檔的內容。
3. 兩者可以共用格式習慣，但彼此是平行的，不是從屬關係。

如果你只是要處理 reading-lab 裡的書或長文，通常不需要先進 `learning/README.md`；直接從這份 README 進入對應來源就夠了。

## 目前來源

1. 從異世界歸來發現只剩自己不會Kubernetes

## 目錄約定

每個來源建議長這樣：

- `reading-lab/<source-name>/sources/`
- `reading-lab/<source-name>/outputs/`
- `reading-lab/<source-name>/archive/`

其中 `source-name` 可以直接用書名，也可以用較短的 slug，只要同一本來源前後一致即可。

## 各層用途

1. `sources/`：原始素材，只做本地保留。
2. `outputs/`：可同步的整理結果。
3. `archive/`：已退役但想保留的舊內容，通常不再往前發展。

## 新對話的接手順序

當你開新對話要繼續處理 reading-lab 裡的內容時，建議順序如下：

1. 先讀這份 `reading-lab/README.md`。
2. 再讀對應來源資料夾的 `README.md`。
3. 如果要看可同步成果，再讀該來源的 `outputs/README.md`。
4. 如果有具體素材，再進 `sources/`。

這樣就足夠理解這個工作區的差別架構，不需要再另外寫一份主題提示詞重複說明。
