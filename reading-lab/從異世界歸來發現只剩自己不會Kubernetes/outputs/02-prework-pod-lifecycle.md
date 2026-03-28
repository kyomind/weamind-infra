# Pod 生命週期補強版

## Prework 內容

### 今日焦點

- 主題：Pod 與生命週期
- 範圍：Pod phase、restart policy、init container、probe 與 Pod 穩定運行的關聯
- 目標：先把 Pod 自己在生命週期中的狀態與機制搞懂，再回頭看 debug 工具與 deployment 行為
- 時間：控制在 45 到 60 分鐘

### 這份 outline 要怎麼用

這份文件是給外部 ChatGPT 類服務做今天的純知識預習。

直接把這份 outline 貼給外部 AI 即可，不需要另外補很多背景。

它今天的任務是：

1. 先幫我建立 Pod 生命週期的最小理解骨架。
2. 用白話方式講清楚 Pod phase、container state、restart policy 各自回答什麼問題。
3. 說明 init container 為什麼存在，以及它和主容器的先後關係。
4. 補清楚 readiness probe 與 liveness probe 和 Pod 穩定運行的關係。
5. 用少量問題確認我是否真的有聽懂。
6. 最後產出一份可以帶回 VS Code 的學習報告。

今天先專注在通用知識，不進入 WeaMind repo 的 YAML 細節，也不先延伸到 StatefulSet、Job、CronJob 或大量 YAML 寫作。

### 今天一定要學會的 4 件事

1. Pod phase 是 Kubernetes 對 Pod 整體生命週期的高階狀態，不等於 container 內部每個細節。
2. restart policy 是 Pod 層級對 container 終止後的重啟規則，不是 Deployment rollout 策略。
3. init container 是主容器啟動前的前置步驟，適合做依賴檢查或初始化工作。
4. probe 是 Pod 進入穩定服務狀態後的健康判斷機制，和 phase、restart、init container 彼此相關但不相同。

### 建議教學順序

1. 先用白話講 Pod phase 是在描述什麼。
2. 再講 restart policy 與 container 重啟的關係。
3. 接著補 init container 的定位。
4. 再把 readiness / liveness probe 放回 Pod 生命週期裡。
5. 最後用 2 到 3 個小問題確認理解。

如果我卡住，請先換一個更簡單的說法或例子，再讓我重述一次。

### 學完後請產出學習報告

請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。

這份報告請至少包含以下內容：

1. 今日主題與學習範圍。
2. 我今天學到什麼。
3. 我已經能用白話講清楚什麼。
4. 我還卡住什麼。
5. 今天最重要的 3 到 5 個觀念整理。
6. 我回到 VS Code 後，應該拿去和 GitHub Copilot 對照 repo 的 2 個問題。

如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

## 學習報告

### 今日學到什麼

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 VS Code 的問題

1.
2.
