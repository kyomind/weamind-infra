# 2026-03-24 K8s Debug Tools Note

## 學習注意事項

### 今日 lesson 邊界

- 今天要解的是工具語意與證據類型，不是把所有 debug 故事全部重講一次。
- 今天會延續昨天的分層框架，但重點是回答「當我懷疑這一層時，先開哪種工具比較划算」。
- 今天會做最小 command drill，但不是大量堆指令；每一輪都要能回到為什麼選這個工具。
- 今天先不展開 debug Pod、ephemeral container 或更進階的 troubleshooting workflow。

### 今日要刻意分開的兩件事

- 問題判讀：目前最強的異常訊號落在哪一層。
- 工具選擇：要用哪個工具先拿到對那一層最有價值的證據。

### 初始提醒

- `describe` 比較像在看 Kubernetes 對這個 Pod 的觀察，包括 events、條件、排程與重啟資訊。
- `logs` 比較像在看 container / app 自己輸出的內容。
- `logs --previous` 特別適合看已經重啟掉的上一個 container 留下的最後訊息。
- `exec` 比較像在 Pod 內做最小驗證，例如看環境變數、DNS 解析、HTTP 請求或連線測試。
- `exec` 很有用，但它不能自動證明外部 DNS、LB、Ingress 那一整段都沒問題。

## Notes

### 今天可優先觀察的工具對照

- 若問題比較像 Pending、排程卡住、image 拉不到、Secret / ConfigMap 注入失敗，`describe` 往往是高價值第一步，因為 events 通常會直接提示排程、拉 image 或建立 container 的失敗原因。
- 若問題比較像 app 已經啟動但回錯、噴 exception、反覆重啟，`logs` 或 `logs --previous` 常更直接，因為它們更靠近 app / process 本身的訊號。
- 若你已經想驗證 Pod 內部看到的世界，例如 `printenv`、`curl http://weamind-line-bot/health`、`nc 10.0.0.2 5433`，`exec` 才比較合理。

### 今天要避免的混淆

- 不要把 `describe` 當成 logs；它會告訴你 Kubernetes 事件，不一定告訴你 Python exception。
- 不要把 `logs` 當成萬能工具；如果 Pod 還沒成功建立，可能根本沒有你要看的 app log。
- 不要把 `exec` 當成固定起手式；有些外層流量問題根本不需要先進 Pod。

## Flashcards

- `kubectl describe pod` 比較像在看什麼？ #DevOps #card
	- Kubernetes 對這個 Pod 的觀察
	- 常見高價值內容有 events、排程結果、container state、重啟次數
	- 比較適合當成 Pod 狀態異常時的第一輪證據入口

- `kubectl logs` 比較像在看什麼？ #DevOps #card
	- container / app 自己吐出的執行期訊息
	- 比較適合看 exception、啟動過程、HTTP 請求紀錄
	- 它不是排程或 Service / Ingress 層事件的主要來源

- 什麼情況下 `kubectl logs --previous` 特別有價值？ #DevOps #card
	- Pod / container 反覆重啟時
	- 因為你想看上一個已經死掉的 container 最後留下什麼訊息
	- 這對 CrashLoopBackOff 類問題很常用

- `kubectl exec -it` 最適合做什麼？ #DevOps #card
	- 在 Pod 內做最小驗證
	- 例如環境變數、DNS、HTTP、TCP 連線、檔案存在與否
	- 它能證明 Pod 內部看到的狀態，但不能單獨證明整條外部流量路徑都正常
