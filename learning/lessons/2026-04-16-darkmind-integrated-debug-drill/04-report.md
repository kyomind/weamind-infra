# 2026-04-16 Darkmind Integrated Debug Drill Report

## 今日主題

- 用 `darkmind` 的既有壞情境，把 W6 Day 1 到 Day 3 練過的工具與判讀順序收斂成較完整的排查 sequence。

## 狀態

已完成 QA、3 題整合情境與一輪口頭收斂；今天的主線已從工具操作收斂成較完整的排查 sequence。

## QA 收斂了什麼

- 收斂了第一步的目標不是直接找完整答案，而是先做高槓桿縮圈。
- 收斂了 `get`、`describe`、`events`、`logs`、`rollout`、`exec` 各自更適合回答哪一層問題，而不是把它們當成固定清單輪流打。
- 收斂了 Day 1 到 Day 3 真正要串起來的不是單一指令，而是幾個轉折點：先辨認異常類型，再切 Pod 內 / Pod 外，再選對應證據工具，最後決定要深入診斷還是先恢復服務。

## 使用者原本卡住什麼

- 原本較容易把工具本身當主題，還沒有完全把它們放回「先縮圈、再分流、再處理」的整體排查骨架。
- 原本對 `port-forward` 的定位仍有些殘留重量，今天進一步收斂成它只是局部驗證工具，而不是整條排查主線。
- 原本對 rollout 類問題和 Pod 類問題的切點雖然已大致理解，但還需要更多 deployment 層與 Pod 層的對照，才能更直覺分開。

## 今日 command 練習收斂

- 用 `kubectl get pods` 加 `kubectl describe pod`，把 image pull 類問題縮圈到「container 根本還沒成功啟動，卡在 image 下載 / back-off」這一層。
- 用 `kubectl logs --previous`，直接回答 crash loop 情境裡上一輪 container 到底吐了什麼、怎麼死的。
- 用 `kubectl rollout status` 加 `kubectl rollout history`，把單顆 Pod 壞掉和 deployment rollout 交接失敗分開，確認這是 deployment 層問題；並補充 `describe deployment` 才是更完整的失敗證據入口。

## 今日真正留下來的核心收穫

- 今天真正留下來的不是三組指令，而是一條較完整的實務排查路徑：先從外部症狀出發，再進 cluster 做第一輪縮圈，之後才決定走 image / crash / rollout 哪一條分支。
- 這條路徑的核心不是把所有工具都打一遍，而是問「現在哪一種證據最便宜、最能縮小範圍、最符合當下這個錯誤型態」。
- 也進一步收斂了 `port-forward` 的邊界：它適合做局部 debug 驗證，但不該取代正式流量判讀，也不常是 production 緊急恢復時的優先手段。

## 學完後已能講清楚什麼

- 能用自己的話講出一條口頭排查 sequence：先看外部症狀，再用 `get` / `describe` / `events` 縮圈，接著視錯誤型態決定要不要走 `logs --previous`、`rollout`、`exec` 或局部驗證。
- 能講清楚 image pull、crash loop、bad rollout 這三類情境為什麼不能套同一條固定指令順序。
- 能講清楚有些問題雖然最後表現在 Pod，但真正切點仍可能在 Deployment、Service 或 Ingress。

## 仍待補強什麼

- 口頭收斂時還需要再把某些描述壓得更準。例如外部症狀不只 `4xx` / `5xx`，也常包含 timeout、connection refused、routing mismatch、功能結果錯誤。
- 口頭敘述裡仍偶爾會把 `logs` 與 `exec` 的用途混在一起；更穩的說法應是：先用 `logs` 看 app / process 輸出，只有在需要 container 內部視角時才進 `exec`。
- rollout 類問題目前已能用 `status` / `history` / `describe deployment` 切開，但還需要再多做一輪，讓「deployment 層失敗」的判讀更直覺。

## 下一步

- 可把今天這條排查 sequence 再壓成一版更短、更像面試回答的 1 分鐘稿。
- 若之後回收 W6，最值得再練一次的是：同一個症狀下，如何快速判斷要先看 Pod、Deployment、Service 還是 Ingress。
