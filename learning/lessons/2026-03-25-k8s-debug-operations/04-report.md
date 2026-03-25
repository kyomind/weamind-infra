# 2026-03-25 K8s Debug Operations Report

## 今日主題

把 W3 Day 1 的分層框架與 W3 Day 2 的工具選擇，整合成 W3 Day 3 的故障情境操作順序。

## 狀態

QA 已完成，等待 command drill 回填後做最後收束。

## QA 收斂了什麼

- 已把 `404`、`CrashLoopBackOff`、app 內部依賴錯誤這三類情境分回不同的第一輪排查層級，而不是再把所有問題都混成同一種「服務壞掉」。
- 已能用 WeaMind 的真實案例說明：`/health=200` 不是只代表服務活著，還能和 `Ingress` 的 `host + path / Prefix` 規則一起用來進一步縮小嫌疑範圍。
- 已能把 `CrashLoopBackOff` 拆成兩輪證據：先看 `describe pod` 拿 Kubernetes 視角，再看 `logs` / `logs --previous` 拿 app 視角。
- 已能區分外部流量路徑問題與 `Pod` 到 VM 依賴問題的第一輪證據入口，知道真正的分界點不是 `Pod` 是否 `Running`，而是請求有沒有進到 app，以及 app 自己有沒有留下依賴錯誤證據。
- 已把 Q4 收成一條最小 debug sequence：先看 `path` 是否一致，再看 app `logs`，最後才在需要時進 container 做內部驗證。

## 使用者原本卡住什麼

- 一開始較容易只做到「大方向分層」，但還沒把已知成功訊號拿來做更強的縮圈。
- 對 `CrashLoopBackOff` 雖然知道要看兩種工具，但一開始還沒完全把兩輪證據各自回答的問題分開。
- 對 `Running`、`Ready` 的判讀邊界仍在建立中，容易把它們誤當成整條系統都正常的保證。
- 對 Q4 這種總結題，一開始容易發散成很多可能性，還需要更具體的情境才能把 sequence 收斂得夠線性。

## 今日 command 練習收斂

- 待 command drill 完成後回填。

## 今日真正留下來的核心收穫

- debug 的關鍵不是把所有工具都打一遍，而是先選一個最能縮小範圍的第一輪證據入口。
- 已知成功的訊號和失敗訊號一樣重要，因為真正的縮圈常常來自「哪些部分已經被證明是通的」。
- 在 WeaMind 這個專案裡，Kubernetes 只是多了外層入口與 `Pod` lifecycle 的觀察層；一旦已確認請求進到 app，後面的排錯主線其實會逐漸靠近單機版常見的「先看 `path` / app `logs`，再看設定與依賴」思路。

## 學完後已能講清楚什麼

- 我已能講清楚 `404`、`CrashLoopBackOff`、依賴錯誤這三類情境在 WeaMind 裡各自比較合理的第一輪排查順序。
- 我已能講清楚為什麼 `health=200` 和 `Pods Running/Ready` 只是幫我排除部分問題，而不是直接證明 webhook 路徑與應用行為都正確。
- 我已能講清楚 `describe pod`、`logs`、`logs --previous`、`kubectl exec -it` 在 debug sequence 中各自站在哪一輪。
- 我已能講清楚單機版和 K8s 版在 app / log / 依賴排錯上的共通主線，以及 K8s 多出來的外層分流成本。

## 仍待補強什麼

- 還需要透過 command drill 把今天的分層判斷轉成更穩定的實際操作手感。
- 之後若有真實異常 `Pod`，仍值得再練一次 `describe pod` 與 `logs --previous` 的實際輸出判讀。

## 下一步

- 進入 `03-command.md`，從 `Command 1` 開始，把今天的 debug sequence 落到最小操作。
