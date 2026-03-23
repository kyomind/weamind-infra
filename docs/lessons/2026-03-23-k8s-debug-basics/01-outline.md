# 2026-03-23 K8s Debug Basics Outline

## 今日主題

把 W3 Day 1 正式落到 repo 內：先用 WeaMind 的實際流量路徑、manifests 與既有踩坑紀錄，建立一套可對回專案的 debug 判讀框架。

## 啟用條件

這份 lesson 以外部預習完成為前提。

目前外部預習已完成，因此今天可以直接進入 repo 內 QA。

## 這次要解的專案問題

1. 在 WeaMind 的真實架構裡，外部請求從 LINE 進來後，實際會經過哪幾層，哪些檔案能對回這條路徑。
2. 如果今天看到 Pending、ImagePullBackOff、CreateContainerError、CrashLoopBackOff，這個 repo 裡哪些設定最值得優先懷疑。
3. 在 WeaMind 的真實踩坑故事裡，哪些案例比較像外層路徑問題，哪些比較像 Pod / app 內層問題。
4. 今天要怎麼把「狀態判讀」和「工具操作」切開，避免 Day 1 就把 describe / logs / exec 全部混進來。

## 這份 lesson 是否需要外部預習

- 需要，而且已完成。
- 原因：今天的價值不在直接背 repo 細節，而是先把 Pod 狀態、排查方向與 debug 骨架建立起來，再回到 WeaMind 檔案對照，這樣 QA 才不會變成零碎名詞問答。

## 要對照的 repo 檔案

1. `README.md`
2. `PROGRESS.md`
3. `manifests/deployment.yaml`
4. `manifests/service.yaml`
5. `manifests/ingress.yaml`
6. `docs/LINE-Webhook-切換流程.md`

## 建議學習順序

1. 先做 `02-qa.md`，把外部預習中的 debug 骨架正式對回 WeaMind 的真實流量路徑與 manifests。
2. 接著把 Pod 常見異常狀態與 repo 中的 image、ConfigMap、Secret、probe、Service / Ingress 設定對起來。
3. 再收斂至少一個 WeaMind 真實案例，確認它落在 debug 骨架的哪一段。
4. 最後把今天的外部預習摘要與 repo 對照結論收進 `05-note.md`，並準備銜接 Day 2 的工具篇。

## 今日 command 練習

今天不建立 `03-command.md`。

原因是 W3 Day 1 的任務是先把判讀框架與 repo 對照釘穩，而不是提早展開工具操作。`describe`、`logs`、`logs --previous`、`exec` 的工具語意與最小操作，留到 Day 2 再正式展開。

## 文件分工

1. `01-outline.md`：規劃今天學習順序與 W3 Day 1 的邊界。
2. `02-qa.md`：記錄今天的專案問題、回答摘要與修正。
3. `04-report.md`：在 lesson 結束後收斂今天真正學到的內容。
4. `05-note.md`：整理外部預習摘要、repo 對照補充與後續銜接點。

## 這次要追問的 Why / How 題

1. 為什麼在 WeaMind 裡，外部請求進不來與 Pod 自己異常，會是兩條不同的第一輪排查路徑。
2. 為什麼看到 CrashLoopBackOff 時，可以先把優先注意力放到 Pod / app 內層，而不是繼續從 DNS / LB 往外查。
3. 為什麼 `CreateContainerError (invalid UTF-8)` 這種案例，能直接說明 Pod 狀態其實是在提示「壞在哪個階段」。
4. 為什麼 Hetzner LB health check 未帶 Host header 的 404，比較像外層流量路徑問題，而不是 app 本身壞掉。

## 這份 lesson 的完成標準

1. 能用 WeaMind 的實際元件名稱講出外部請求進入 line-bot Pod 的最小路徑。
2. 能把至少三種 Pod 常見異常狀態對回 repo 裡最值得優先懷疑的設定位置。
3. 能把至少一個 WeaMind 真實案例對回今天的 debug 骨架，說出它為什麼比較像外層或內層問題。
4. `02-qa.md` 至少完成 4 題，且有把外部預習結論正式對回 repo。
