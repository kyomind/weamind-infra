# 2026-03-24 K8s Debug Tools Outline

## 今日主題

把 W3 Day 1 的 debug 分層框架往前推一步：今天不重講整條排查故事，而是把 `kubectl describe pod`、`kubectl logs`、`kubectl logs --previous`、`kubectl exec -it` 放回 WeaMind 的真實情境，釐清它們各自是在看哪一層、拿哪種證據。

## 啟用條件

這份 lesson 以前一天的 debug 概念篇已完成為前提。

目前 W3 Day 1 已完成，因此今天可以直接進入工具篇。

## 這次要解的專案問題

1. 在 WeaMind 這個 repo 裡，`describe`、`logs`、`logs --previous`、`exec` 各自適合驗證哪一層、拿哪一種證據。
2. 同樣是 Pod 出問題時，為什麼不能固定只開一種工具，而要依異常訊號選擇更合適的第一個觀察點。
3. 遇到像 CrashLoopBackOff、CreateContainerError、外部請求 404 這些不同情境時，哪一個工具更適合作為第一輪證據入口。
4. `exec` 為什麼很有用，但又不應該被誤當成所有 debug 的第一步。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：今天主題主要是 repo 內工具語意、情境對照與最小操作，且已建立昨天的 debug 骨架，不需要再先做純知識型 prework。

## 要對照的 repo 檔案

1. `manifests/deployment.yaml`
2. `manifests/service.yaml`
3. `manifests/ingress.yaml`
4. `README.md`
5. `PROGRESS.md`
6. `docs/LINE-Webhook-切換流程.md`

## 建議學習順序

1. 先做 `02-qa.md`，把四個工具各自對回較適合的證據類型與使用情境。
2. 再把工具放回 WeaMind 既有案例，確認哪些情境比較適合先看 events、哪些適合先看 app log、哪些適合進 Pod 內確認。
3. 接著做 `03-command.md`，用最小 command drill 把工具選擇與判讀練熟。
4. 最後回 `04-report.md` 收斂：今天不是多記幾條指令，而是知道自己在不同情境下為什麼先用這個工具。

## 今日 command 練習

今天建立 `03-command.md`。

重點不是大量跑指令，而是讓每一輪都回答三件事：現在在驗證哪一層、這個工具會給我什麼證據、看到這個輸出後下一步應該往哪裡走。

## 文件分工

1. `01-outline.md`：規劃今天學習順序與 W3 Day 2 的邊界。
2. `02-qa.md`：記錄工具語意、使用情境與回答修正。
3. `03-command.md`：記錄今天的指令選擇、關鍵輸出、AI 判讀與一句話收斂。
4. `04-report.md`：在 lesson 結束後收斂今天真正學到的內容。
5. `05-note.md`：整理工具對照、延伸提醒與後續操作銜接點。

## 這次要追問的 Why / How 題

1. 為什麼 `describe` 比較像在看 Kubernetes 怎麼看這個 Pod，而不是在看 app 自己怎麼說。
2. 為什麼 `logs --previous` 對反覆重啟的 Pod 特別有價值，而一般穩定 Running 的 Pod 不一定需要它。
3. 為什麼 `exec` 很適合做 Pod 內最小驗證，但不能證明整條外部流量路徑都沒問題。
4. 為什麼工具選擇應該接在「先看最強異常訊號在哪一層」之後，而不是反過來用工具決定問題類型。

## 這份 lesson 的完成標準

1. 能說出 `describe`、`logs`、`logs --previous`、`exec` 各自較適合看什麼。
2. 能把這四個工具對回 WeaMind 中至少三種不同問題情境，而不是只背工具名稱。
3. 能完成至少 3 輪最小 command drill，並說出每一步在驗證哪一層。
4. 能清楚分開「問題判讀」與「工具操作」，避免把兩者混成同一件事。
