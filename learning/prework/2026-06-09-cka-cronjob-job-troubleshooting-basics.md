# 2026-06-09 CKA CronJob Job Troubleshooting Basics

## Prework 內容

### 今日焦點

- 主題：CKA Troubleshooting 題中的 CronJob、Job 與 Pod 排查骨架
- 範圍：CronJob -> Job -> Pod 控制鏈、schedule、suspend、successful / failed Jobs、Pod template、logs、events、常見錯誤定位
- 目標：建立能面對 CronJob Issue 題型的最小概念與排查模型，不先背單一題目的修法
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做 CKA Troubleshooting 的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的背景是：我正在刷 KillerCoda CKA 題庫，已經做過 Pod、Service、Storage、Architecture / Installation / Maintenance 相關 prework。這份請專注在 Troubleshooting 題裡 CronJob / Job / Pod 的控制鏈與排查順序，不要展開成完整 batch processing 或 production 排程平台設計。

### 今天一定要學會的最小骨架

1. CronJob 不直接長期執行業務，而是按 schedule 建立 Job；Job 再建立 Pod 去跑一次性工作。
2. CronJob 問題要先分清楚：CronJob 沒有產生 Job、Job 沒有產生 Pod、Pod 產生但執行失敗，這三種故障層級不同。
3. `kubectl describe cronjob`、`kubectl get jobs`、`kubectl describe job`、`kubectl logs <pod>` 分別提供不同層級的證據。
4. `schedule`、`suspend`、`startingDeadlineSeconds`、`concurrencyPolicy`、`successfulJobsHistoryLimit`、`failedJobsHistoryLimit` 會影響 CronJob 行為，但 CKA 先掌握最常見的排查語意。
5. CronJob 的 Pod template 裡仍然可能有一般 Pod 問題，例如 image、command / args、env、service DNS、RBAC、volume mount。
6. CKA 修 CronJob 題時，常見節奏是先看控制鏈有沒有產物，再看 events / logs，最後只改造成問題的最小欄位並驗證下一次 Job / Pod 是否正常。

### 建議教學順序

1. 先用白話說明 CronJob、Job、Pod 三者的責任分工與控制鏈。
2. 比較三種故障層級：沒有 Job、沒有 Pod、Pod CrashLoopBackOff / Error。
3. 教我如何用 `get` / `describe` 從 CronJob 一路追到 Job 和 Pod，包含 label / owner reference 的基本方向。
4. 說明 CronJob spec 裡 CKA 常見欄位：schedule、suspend、jobTemplate、backoffLimit、restartPolicy。
5. 說明當 Pod 已經建立但失敗時，如何回到一般 Pod debug：describe、events、logs、logs --previous、command / args。
6. 最後整理一條 CKA CronJob troubleshooting 節奏：看 CronJob -> 看 Job -> 看 Pod -> 看 events / logs -> 修最小欄位 -> 等或手動觸發驗證。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 CKA 題庫或 repo 內後，應該拿去練習或對照的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

- 今天真正學到的不是 CronJob 指令，而是如何把 Kubernetes 控制鏈拆開來看，先定位故障發生在哪一層，再找對應證據，最後才修最小欄位。
- CronJob 不直接執行程式。它的責任是按 schedule 建立 Job；Job 的責任是保證任務完成；Pod 才是真正執行 container 的地方。
- Kubernetes CronJob 和 Linux cron 最大差異是中間多了 Job 這層。Linux cron 通常是時間到就直接跑 script；Kubernetes 則是 `CronJob -> Job -> Pod -> Container`。
- Job 的價值不是「再生一個 Pod」而已，而是追蹤任務是否成功、失敗後是否需要重試、是否已達到完成條件。Pod 是執行者，Job 是任務管理者。
- CronJob 題要先分清楚故障層級：CronJob 沒有產生 Job、Job 沒有產生 Pod、Pod 有產生但執行失敗。這三種狀況要看的證據不同。
- 不能一開始就看 logs，因為沒有 Pod 就沒有 logs。應先確認 Job 是否存在，再確認 Pod 是否存在，Pod 已經建立且失敗時才進入 `describe pod` 和 `logs`。
- 建立了 CKA CronJob troubleshooting 節奏：看 CronJob -> 看 Job -> 看 Pod -> 看 Events -> 看 Logs -> 修最小欄位 -> 驗證下一次執行。

### 已能白話講清楚什麼

- CronJob 的本質是排程器，不是執行器；它回答的是「時間到了嗎」，到了就建立 Job。
- Job 的本質是任務管理者，不是執行器；它回答的是「任務完成了嗎」，必要時會讓系統再建立 Pod 嘗試完成任務。
- Pod 才是真正執行程式的地方，container 的 stdout / stderr 也要到 Pod 層才有 logs 可以看。
- CronJob / Job / Pod 的責任切割可以整理成：CronJob 決定什麼時候做，Job 保證事情做完，Pod 執行程式。
- 排查 CronJob 題時，如果沒有 Job 就查 CronJob；沒有 Pod 就查 Job；Pod 壞掉就查 Pod；程式出錯才查 logs。

### 目前還卡住什麼

- Job 與 Pod 的重試邊界還需要實驗補手感，尤其是 `restartPolicy: Never`、`restartPolicy: OnFailure`、`backoffLimit` 之間的關係。
- OwnerReference 與 label 的關係還沒有深入理解。目前知道可以用 `kubectl get pods -l job-name=<job>` 找 Pod，但還沒有完整掌握 `CronJob -> Job -> Pod` 之間 owner reference 的物件關係。
- 手動驗證 CronJob 的技巧還沒實際操作，例如 `kubectl create job --from=cronjob/<cronjob-name> test-run` 這類做法知道用途，但還需要在 lab 裡跑過。

### 今日最重要的觀念

- CronJob 不執行工作，它只建立 Job。
- Job 不直接執行程式，它負責保證任務完成。
- Pod 才是真正執行程式的地方。
- CronJob 題一定先判斷控制鏈斷在哪一層：CronJob、Job，還是 Pod。
- 不要一開始就看 logs；先確認 Job 有沒有、Pod 有沒有，再決定下一步。

### 帶回 CKA 題庫或 repo 內對照的問題

1. 如果把 WeaMind 的天氣資料更新流程改成每天凌晨更新一次，`CronJob -> Job -> Pod` 各自應該負責什麼？如果 Pod 執行到一半 node 掛掉，誰會負責補救？
2. 在 CKA lab 中建立一個 `suspend: true` 的故障 CronJob，練習回答控制鏈斷在哪、第一個該看哪個指令、為什麼此時不該先看 logs。
