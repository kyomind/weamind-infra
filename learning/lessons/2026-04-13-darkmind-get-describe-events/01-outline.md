# 2026-04-13 Darkmind Get Describe Events Outline

## 今日主題

- 啟用 `darkmind` 練習環境，先把 `kubectl get`、`kubectl describe`、`kubectl get events --sort-by=.lastTimestamp` 這三種觀察方式練成固定套路。

## 這次要解的專案問題

1. 在 Darkmind 的壞 Pod 情境裡，第一輪為什麼通常先用 `get` 看狀態，而不是直接跳進 `logs` 或 `exec`。
2. `describe` 和 `events` 都會碰到 Kubernetes 層的資訊，但它們各自更適合回答哪一種問題。
3. 為什麼 Day 1 要先建立健康基準，再進壞情境，而不是一開始就只盯著錯誤 Pod。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：今天主題是 repo 內既有 Darkmind lab 的 command drill，難點在操作順序、證據判讀與最小縮圈，不在外部通用概念補課。

## 要對照的 repo 檔案

1. `darkmind/README.md`
2. `darkmind/namespace.yaml`
3. `darkmind/healthy.yaml`
4. `darkmind/scenarios/image-pull-error.yaml`
5. `.privatedocs/六週版學習計畫.md`

## 建議學習順序

1. 先做 `02-qa.md` 的 3 題短 QA，對齊今天要驗證的層次與第一步判斷原則。
2. 再做 `03-command.md`，以 5 輪微情境完成 Day 1 的 setup、第一層觀察、`describe` 證據、`events` 時間序列與 cleanup。
3. 若 command 過程中冒出延伸問題，先記到 `05-note.md`，不要把 QA 或 command 拉太寬。
4. 最後回到 `04-report.md`，收斂今天真正練熟的觀察套路。

## 今日 command 練習

- 今天建立 `03-command.md`。
- 這不是 command 先於 QA 的例外日；仍先做短 QA，再進 5 輪 command drill。
- 今天的 5 輪重點是固定套路，不追求情境廣度：建立基準、用 `get` 找第一層線索、用 `describe` 看 Pod 細節、用 `events` 補時間序列、最後清理 lab。

## 文件分工

1. `01-outline.md`：規劃今天的 Day 1 範圍與順序。
2. `02-qa.md`：記錄今天的短 QA、回答摘要與修正。
3. `03-command.md`：記錄 5 輪 command drill 的選擇、輸出、判讀與一句話收斂。
4. `04-report.md`：收斂今天真正學到的 command drill 結論。
5. `05-note.md`：承接延伸問答、暫時結論與之後可長出的卡片素材。

## 這次要追問的 Why / How 題

1. 為什麼 Day 1 先用 `get`、`describe`、`events` 這種 Kubernetes 視角工具，而不是一開始就碰 `logs`。
2. 為什麼 `kubectl get events --sort-by=.lastTimestamp` 在排查時不是附屬資訊，而是時間序列證據。
3. 為什麼健康基準對 command drill 很重要，不能只會在錯誤狀態下看輸出。

## 這份 lesson 的完成標準

1. 能建立並清理 `darkmind` 練習環境。
2. 能說出 `get`、`describe`、`events` 各自在 Day 1 的主要用途與證據層次。
3. 能完成 5 輪 command drill，並在每輪說出自己正在驗證哪一層。
4. 能用一段 1 到 2 分鐘的口頭敘述，講清楚今天的基本排查順序。
