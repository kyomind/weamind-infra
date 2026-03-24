# 2026-03-24 K8s Debug Tools Follow-up

## 今日焦點

- 主題：Debug 工具篇補強 homework
- 範圍：Pod conditions、container state、`logs --previous` 的時間切面、`kubectl exec` 的邊界，以及精簡容器映像下的 debug 限制
- 目標：把今天 lesson 中已碰到、但還沒完整展開的通用知識補齊，讓之後做真正的 debug 操作時，對工具與狀態的關係更穩
- 時間：控制在 30 到 45 分鐘

## 這份 outline 要怎麼用

這份文件雖然放在 `learning/prework/`，但定位不是正式課前預習，而是今天 lesson 後的輕量補強 homework。

把這份 outline 直接貼給外部 ChatGPT 類服務即可，不需要另外補很多背景。

它今天的任務是：

1. 用白話補清楚 Pod conditions、container state、events 三者在 `kubectl describe pod` 裡各自回答什麼問題。
2. 解釋 `CrashLoopBackOff`、`Last State`、`Restart Count`、`logs`、`logs --previous` 彼此之間的關係。
3. 補清楚 readiness probe、liveness probe、`Ready`、`ContainersReady` 之間的最小因果關係。
4. 解釋 `kubectl exec` 為什麼是「Pod 入口、container 執行」，以及它在 debug 上的邊界。
5. 補一個實務觀念：為什麼在 slim / production image 裡，常見的 debug 工具可能不存在；遇到 `command not found` 或 exit code `127` 時，應怎麼正確判讀。
6. 用少量例子幫我把「工具不存在」和「網路真的失敗」這兩種情況分開。
7. 最後產出一份可帶回 VS Code 的短版學習報告。

今天仍然不要延伸成 Kubernetes 全科總複習，也不要進 repo 細節；重點是把今天 lesson 中碰到的通用概念補完整。

## 今天一定要學會的 5 件事

1. `Events`、`Conditions`、container `State` 在 `describe pod` 裡是三種不同層次的訊息，不要混成一塊。
2. `CrashLoopBackOff` 不只是 Pod 壞掉，而是 container 反覆啟動又失敗；這時 `logs --previous` 的價值通常高於只看目前這一輪的 `logs`。
3. readiness probe 與 liveness probe 處理的是不同問題：一個在問能不能接流量，一個在問要不要重啟。
4. `kubectl exec` 很適合做 Pod 內部最小驗證，但它不能自動證明外部 LB / Ingress / webhook routing 都正常。
5. 在精簡容器映像裡看到 `wget: not found`、`nc: not found`、exit code `127`，第一個判讀應是工具不存在，而不是直接判成連線失敗。

## 建議教學順序

1. 先切開 `describe pod` 裡的 `Events`、`Conditions`、container `State` 各自回答什麼。
2. 再講 `CrashLoopBackOff`、`Last State`、`Restart Count`、`logs`、`logs --previous` 如何形成一條時間線。
3. 接著補 readiness / liveness 與 `Ready` / `ContainersReady` 的關係。
4. 然後補 `kubectl exec` 的定位與邊界。
5. 最後用 1 到 2 個精簡容器缺少 debug 工具的例子，說明怎麼避免誤判。

如果我卡住，請先用更白話的例子，不要一開始就用太多 Kubernetes 術語。

## 學完後請產出學習報告

這份 homework 不一定要很長，但請至少整理出一份可回帶的短版報告。

若我今天不想正式回報，也至少請幫我整理成之後可自行複習的摘要；若我要帶回 VS Code，再直接把完整報告貼給 GitHub Copilot 即可。

報告建議包含：

1. 今日補強主題與範圍。
2. 我今天補學到什麼。
3. 我已經能更清楚講出什麼。
4. 我還模糊的地方。
5. 今天最重要的 3 到 5 個補充觀念。
6. 我回到 VS Code 後，可再和 GitHub Copilot 對照的 1 到 2 個問題。
