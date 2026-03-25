# 2026-03-25 K8s Debug Operations Outline

## 今日主題

把 W3 Day 1 的分層判讀與 W3 Day 2 的工具選擇真正接起來：今天要練的不是再多認識一個工具，而是拿到具體故障情境後，能排出第一步、第二步、第三步，並說清楚每一步在驗證哪一層。

## 啟用條件

這份 lesson 以前兩天的 debug arc 已完成為前提。

目前 W3 Day 1 與 Day 2 已完成，因此今天可以直接進入操作篇。

## 這次要解的專案問題

1. 拿到一個 WeaMind 故障敘述時，怎麼先把它分到較像外層 routing、Kubernetes 資源狀態、app 內部錯誤，或 Pod 到 VM 依賴連線問題。
2. 為什麼 debug 操作篇的核心不是背指令，而是先選對第一個證據入口，再決定下一步。
3. 同樣是 404、timeout、CrashLoopBackOff、連不到 PostgreSQL，第一輪較值得先驗證的東西為什麼不同。
4. 怎麼把一輪觀察收斂成可重講的 debug sequence，而不是只留下零碎指令。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：W3 Day 1 已完成 debug 骨架，W3 Day 2 已完成工具語意；今天主要是把兩者整合成故障情境下的操作順序，不需要再先做純知識型 prework。

## 要對照的 repo 檔案

1. `manifests/deployment.yaml`
2. `manifests/service.yaml`
3. `manifests/ingress.yaml`
4. `README.md`
5. `PROGRESS.md`
6. `docs/LINE-Webhook-切換流程.md`

## 建議學習順序

1. 先做 `02-qa.md`，把今天的幾個故障情境先分層，確認第一輪證據入口與下一步方向。
2. 再做 `03-command.md`，用最小 command drill 練習把情境、工具選擇、輸出判讀與下一步串成閉環。
3. 過程中把容易混淆的邊界補進 `05-note.md`，特別是「看到 Pod Ready 不代表哪一層一定沒問題」。
4. 最後回 `04-report.md` 收斂今天真正學到的 debug 操作骨架。

## 今日 command 練習

今天建立 `03-command.md`。

重點不是大量執行指令，而是練三件事：先判斷故障更像哪一層、選一個第一輪較划算的指令、根據輸出決定下一步，而不是每次都把 `describe`、`logs`、`exec` 全部打一遍。

## 文件分工

1. `01-outline.md`：規劃今天學習順序與 W3 Day 3 的邊界。
2. `02-qa.md`：記錄今天的故障情境題、回答摘要與修正。
3. `03-command.md`：記錄今天的情境、指令選擇、關鍵輸出、AI 判讀與下一步。
4. `04-report.md`：在 lesson 結束後收斂今天真正學到的內容。
5. `05-note.md`：整理易混淆邊界、可重用的 debug sequence 與延伸提醒。

## 這次要追問的 Why / How 題

1. 為什麼 debug 操作不該變成固定指令清單，而要先根據最強異常訊號選第一個觀察點。
2. 為什麼同樣是外部請求失敗，`404`、`timeout`、`500` 常代表不同層次的第一輪假設。
3. 為什麼 Pod `Running` 且 `Ready=True`，仍然不能直接排除 Ingress、LB、webhook path 或外部依賴問題。
4. 為什麼一輪好的 debug 操作最後要收斂成「我先看了什麼、看到什麼、所以接下來往哪裡查」。

## 這份 lesson 的完成標準

1. 能把至少 3 種 WeaMind 故障情境分到較合理的第一輪排查層級。
2. 能說出每個情境第一輪較適合先拿哪種證據，以及為什麼不是先用其他工具。
3. 能完成至少 3 輪最小 command drill，並把每輪輸出收斂成一句 debug 結論。
4. 能用自己的話講出一條最小 debug sequence，而不是只列出零碎指令。
