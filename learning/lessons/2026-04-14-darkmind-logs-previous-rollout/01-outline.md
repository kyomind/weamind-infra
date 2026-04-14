# 2026-04-14 Darkmind Logs Previous Rollout Outline

## 今日主題

- 用 `darkmind` 的 `crash-loop` 與 `bad-rollout` 情境，把 Day 1 的 Kubernetes 觀察鏈往下推到 app logs 與 Deployment rollout 控制面。

## 這次要解的專案問題

1. 當 Pod 問題已經不是 image pull，而是 container 反覆退出時，為什麼這時候該把重心移到 `kubectl logs` 與 `kubectl logs --previous`。
2. `kubectl logs` 和 `kubectl logs --previous` 各自回答什麼問題，兩者不能互相取代的原因是什麼。
3. 當問題層級從單一 Pod 拉高到 Deployment rollout 卡住時，為什麼要改用 `kubectl rollout` 系列指令，而不是一直盯著單顆 Pod。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：今天主題延續 W6 Day 1 的 command drill，難點在 evidence-based 排查順序與指令判讀，不在新的通用概念補課。

## 要對照的 repo 檔案

1. `darkmind/README.md`
2. `darkmind/scenarios/crash-loop.yaml`
3. `darkmind/scenarios/bad-rollout-01-good.yaml`
4. `darkmind/scenarios/bad-rollout-02-bad.yaml`
5. `.privatedocs/六週版學習計畫.md`

## 建議學習順序

1. 先做 `02-qa.md` 的 3 題短 QA，對齊今天的觀察邊界：app log、previous log、Deployment rollout。
2. 再做 `03-command.md` 的 6 輪微情境：建立基準、套用 crash-loop、看當前 log、看 previous log、建立 good rollout 基準、處理 bad rollout。
3. 若 command drill 中冒出較大的延伸問題，先記到 `05-note.md`，不要讓 QA 或 command 失焦。
4. 最後回到 `04-report.md`，收斂今天真正練熟的 log / rollout 排查骨架。

## 今日 command 練習

- 今天建立 `03-command.md`，採 command-heavy workshop 的 6 輪微情境。
- 這不是 command 先於 QA 的例外日；仍先做短 QA，再進 command drill。
- 今天的 command 重點是把兩條觀察鏈分清楚：`crash-loop` 用 `logs` / `logs --previous`，`bad-rollout` 用 `rollout status` / `history` / `undo`。

## 文件分工

1. `01-outline.md`：規劃今天 Day 2 的範圍與順序。
2. `02-qa.md`：記錄今天的短 QA、回答摘要與修正。
3. `03-command.md`：記錄 6 輪 command drill 的選擇、輸出、判讀與一句話收斂。
4. `04-report.md`：在互動完成後收斂今天真正學到的 log / rollout 結論。
5. `05-note.md`：承接延伸問答、暫時結論與後續可長出的卡片素材。

## 這次要追問的 Why / How 題

1. 為什麼 image pull 類問題常看不到有用 app logs，但 crash loop 類問題反而很需要 `logs`。
2. 為什麼 `kubectl logs --previous` 對 CrashLoopBackOff 特別有價值，它補的是哪一段證據。
3. 為什麼 rollout 卡住時，`kubectl rollout status`、`history`、`undo` 比單純看 Pod log 更能回答 Deployment 層級的問題。

## 這份 lesson 的完成標準

1. 能說出 `logs`、`logs --previous`、`rollout status`、`rollout history`、`rollout undo` 各自在 Day 2 的主要用途。
2. 能完成 6 輪 command drill，並在每輪說出自己正在驗證哪一層。
3. 能把 `crash-loop` 與 `bad-rollout` 兩種問題分別接回正確的排查鏈，而不是混用指令。
4. 能用 1 到 2 分鐘口頭講清楚：app crash 類問題和 rollout 類問題各自第一步應看什麼。
