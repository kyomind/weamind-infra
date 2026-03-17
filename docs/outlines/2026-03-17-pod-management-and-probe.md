# 2026-03-17 Pod Management And Probe

## 今日焦點

- 主題：Pod 管理與 Probe
- 範圍：liveness probe、readiness probe、nodeSelector、rollout restart / rollout status / logs 的最小理解骨架
- 目標：先把今天會用到的通用概念與名詞邊界釐清，再回到 WeaMind repo 對照 Deployment 設定與實際操作
- 時間：控制在 45 到 60 分鐘

## 這份 outline 要怎麼用

這份文件是給外部 ChatGPT 類服務做今天的純知識預習。

把這份 outline 直接貼給外部 AI 即可，不需要另外補一大段提示詞。

它今天的任務是：

1. 先幫我建立 liveness probe 與 readiness probe 的最小理解骨架。
2. 用白話方式講清楚 nodeSelector 在 Pod 排程裡扮演什麼角色。
3. 補上 rollout restart、rollout status、logs 這三類常見操作各自在看什麼。
4. 補最小執行鏈：Pod 建立後，Scheduler 先決定節點，再由該 node 上的 kubelet 協調 container runtime 啟動 container。
5. 用少量問題確認我是否真的有聽懂。
6. 最後產出一份可以帶回 VS Code 的學習報告。

今天先專注在通用知識，不進入 WeaMind repo 的 YAML 細節，也不先做 kubectl 實作題。

## 今天一定要學會的 5 件事

1. liveness probe 與 readiness probe 的用途不同，前者偏向判斷容器是否該被重啟，後者偏向判斷 Pod 是否該接流量。
2. probe 失敗後系統反應不同，不能把兩者都理解成單純的健康檢查。
3. nodeSelector 的作用是限制 Pod 可以被排到哪些 node，不是用來決定容器內部怎麼啟動。
4. rollout restart、rollout status、logs 各自的觀察目標不同，不能把它們混成同一種「看部署狀態」指令。
5. 要把兩條鏈分開記：

管理鏈：Deployment → ReplicaSet → Pod

執行鏈：Pod 建立後 → Scheduler 決定 node → kubelet 協調 runtime 啟動 container

## 建議教學順序

1. 先用白話講 probe 是在解什麼問題，再分開講 liveness 與 readiness。
2. 再講 probe 失敗後會發生什麼，避免只背定義。
3. 接著講 nodeSelector 與排程的基本關係。
4. 再補 rollout restart、rollout status、logs 的使用情境差異。
5. 最後補管理鏈與執行鏈的對照，確認我不會把 Deployment 管理責任和 Scheduler / kubelet 執行責任混在一起。
6. 用 2 到 3 個小問題做理解確認。

如果我卡住，請先換一個更簡單的說法或例子，再讓我重述一次。

## 學完後請產出學習報告

請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。

這份報告請至少包含以下內容：

1. 今日主題與學習範圍。
2. 我今天學到什麼。
3. 我已經能用白話講清楚什麼。
4. 我還卡住什麼。
5. 今天最重要的 3 到 5 個觀念整理。
6. 我回到 VS Code 後，應該拿去和 GitHub Copilot 對照 repo 的 2 個問題。

如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。