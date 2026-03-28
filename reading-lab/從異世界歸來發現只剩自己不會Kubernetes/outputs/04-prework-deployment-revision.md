# Deployment 日常操作與 revision 心智模型

## Prework 內容

### 今日焦點

- 主題：Deployment 的日常操作
- 範圍：`scale`、`edit`、revision、`rollout history`、rollback
- 目標：把「平常怎麼改、怎麼看版本、怎麼回退」這條線補完整
- 時間：控制在 45 到 60 分鐘

### 這份 outline 要怎麼用

這份文件是給外部 ChatGPT 類服務做今天的純知識預習。

直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。

這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。

它今天的任務是：

1. 先幫我建立 Deployment 日常操作與 revision 的最小理解骨架。
2. 用白話方式講清楚 `scale`、`edit`、`rollout history`、rollback 分別偏向做什麼。
3. 說明為什麼只有 `spec.template` 的變更才會形成新的 revision。
4. 幫我理解 `replicas` 變更和 template 變更的差異。
5. 用少量問題確認我是否真的有聽懂。
6. 最後產出一份可以帶回 VS Code 的學習報告。

今天先專注在通用知識，不進入 GitOps、Argo CD、progressive delivery、canary、blue-green 等進階發布策略。

### 今天一定要學會的 4 件事

1. Deployment 的某些修改只是改期望數量，有些修改會真的形成新版 Pod 模板。
2. `replicas` 變更不一定產生新的 revision，但 `spec.template` 內的變更會。
3. `rollout history` 是在看 Deployment 的版本演進，不是在看 Pod 重啟歷史。
4. rollback 回的是 Deployment 模板版本，不是把所有 runtime 問題自動修好。

### 建議教學順序

1. 先用白話講 Deployment 操作時到底在改什麼。
2. 再講 `replicas` 與 `spec.template` 的差異。
3. 接著補 `rollout history` 與 rollback 的角色。
4. 最後把這些觀念放回版本演進心智模型。
5. 用 2 到 3 個小問題確認理解。

如果我卡住，請先換一個更簡單的說法或例子，再讓我重述一次。

### 學完後請產出學習報告

請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。

下面這一段是回填模板，不是新的教學主題。

這份報告請至少包含以下內容：

1. 今日主題與學習範圍。
2. 我今天學到什麼。
3. 我已經能用白話講清楚什麼。
4. 我還卡住什麼。
5. 今天最重要的 3 到 5 個觀念整理。
6. 我回到 VS Code 後，應該拿去和 GitHub Copilot 對照 repo 的 2 個問題。

如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

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

### 帶回 VS Code 的問題

1.
2.
