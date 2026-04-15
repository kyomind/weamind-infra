# 2026-04-15 Darkmind Exec Port Forward Readiness Fail Outline

## 今日主題

- 用 `darkmind` 的 healthy baseline 與 `readiness-fail` 情境，把 Day 1 到 Day 2 的觀察鏈再往下推一層，練清楚 `exec`、`port-forward`、`readiness`、`Service endpoints` 之間的邊界。

## 這次要解的專案問題

1. 當 Pod 呈現 `Running` 但 `0/1 Ready` 時，為什麼不能直接把它當成「app 可正常對外服務」，又為什麼這時候 `exec` 仍可能有價值。
2. `kubectl exec` 和 `kubectl port-forward` 各自回答什麼問題，兩者為什麼不是互相取代的工具。
3. 當問題落在 readiness probe 時，為什麼除了 Pod 狀態外，還要把 `Service endpoints` 一起拉進排查鏈。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：今天主題延續 W6 Day 1 到 Day 2 的 command drill，難點在 `Running`、`Ready`、`exec`、`port-forward`、`endpoints` 的證據邊界，而不是新的通用概念補課。

## 要對照的 repo 檔案

1. `darkmind/README.md`
2. `darkmind/healthy.yaml`
3. `darkmind/scenarios/readiness-fail.yaml`
4. `.privatedocs/六週版學習計畫.md`

## 建議學習順序

1. 先做 `02-qa.md` 的 3 題短 QA，對齊今天要分清楚的三條線：container 內部、local tunnel、Service 流量收斂。
2. 再做 `03-command.md` 的 5 輪 command drill：建立健康基準、用 `exec` 看 healthy pod、用 `port-forward` 驗證 healthy service、套用 `readiness-fail`、對照 `exec` 與 `port-forward` 在壞情境下各自給出的證據。
3. 若 command drill 中冒出較大的延伸問題，先記到 `05-note.md`，不要讓 QA 或 command 失焦。
4. 最後回到 `04-report.md`，收斂今天真正練熟的 readiness / exec / port-forward 排查骨架。

## 今日 command 練習

- 今天建立 `03-command.md`。
- 這不是 command 先於 QA 的例外日；仍先做短 QA，再進 command drill。
- 今天的 command 重點不是多跑指令，而是練出兩個穩定區分：`exec` 比較像看 container 內部視角，`port-forward` 比較像臨時打通本機到 Pod 或 Service 的連線；當 readiness fail 時，還要把 `endpoints` 一起看，才能回答「能不能被 Service 收進流量」。

## 文件分工

1. `01-outline.md`：規劃今天 Day 3 的範圍與順序。
2. `02-qa.md`：記錄今天的短 QA、回答摘要與修正。
3. `03-command.md`：記錄 5 輪 command drill 的選擇、輸出、判讀與一句話收斂。
4. `04-report.md`：在互動完成後收斂今天真正學到的 readiness / exec / port-forward 結論。
5. `05-note.md`：承接延伸問答、暫時結論與後續可長出的卡片素材。

## 這次要追問的 Why / How 題

1. 為什麼 `Running` 不等於 `Ready`，而 `Ready` 又和 Service 流量有直接關係。
2. 為什麼 `kubectl exec` 能回答「container 裡面發生什麼」，卻不能直接回答「叢集內其他流量是不是能正常打進來」。
3. 為什麼 `kubectl port-forward` 很方便，但它常常繞過了 Service / Ingress 正常流量路徑，所以不能直接當成「線上流量正常」的證據。

## 這份 lesson 的完成標準

1. 能說出 `exec`、`port-forward`、`readiness probe`、`endpoints` 各自在 Day 3 的主要用途。
2. 能完成 5 輪 command drill，並在每輪說出自己正在驗證哪一層。
3. 能講清楚為什麼 `Running` 但 `0/1 Ready` 的 Pod，可能 `exec` 得進去、container 也在跑，但仍不應被視為可正常對外服務。
4. 能用 1 到 2 分鐘口頭講清楚：當 readiness fail 時，`exec`、`port-forward`、`describe`、`endpoints` 各自回答什麼問題。
