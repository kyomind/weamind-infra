# reading-lab

這是一本書或一篇長文的學習工作區。

這裡的原則很簡單：

1. 每一個來源都必須有自己的獨立子資料夾。
2. 原始素材放 `sources/`，這層只做本地收集，不同步到 Git。
3. 整理後可以同步的內容放 `outputs/`，例如總綱、分題 prework、學習報告與整理稿。
4. 歷史但不再主用的內容放 `archive/`，例如舊草稿、被新版取代的整理稿、臨時實驗版。
5. 之後如果再來第二本書或另一篇長文，只要新增另一個來源子資料夾，不需要改整體架構。

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
