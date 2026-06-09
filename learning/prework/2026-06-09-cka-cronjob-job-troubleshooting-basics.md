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

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 CKA 題庫或 repo 內對照的問題

1.
2.
