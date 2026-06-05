# 2026-06-05 Node Placement Rules

## Prework 內容

### 今日焦點

- 主題：Kubernetes nodeSelector、Node Affinity、Taint / Toleration 如何組合使用
- 範圍：Pod-to-Node placement、硬性條件、軟性偏好、特殊 node 保護；不包含 Pod Affinity / Anti-Affinity
- 目標：建立「指定 Pod 去哪裡」和「保護特殊 Node 不被誤用」的設計判斷骨架
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的背景是：我已經理解 Taint / Toleration 只是讓 Pod 可以進入有 taint 的 Node，不代表一定會被排到那台 Node。請接著教我 Kubernetes 如何把 `nodeSelector`、Node Affinity、Taint / Toleration 組合成完整的 Node placement 策略。
- 請先聚焦 Pod 和 Node 的關係，不要展開 Pod Affinity / Anti-Affinity。後者是 Pod 和 Pod 的關係，之後再獨立學。

### 今天一定要學會的最小骨架

1. `nodeSelector` 是最簡單的硬性 Node label 篩選：Pod 只能被排到符合所有 key/value 的 Node。
2. Node Affinity 是 `nodeSelector` 的進階版，可以用 `In`、`NotIn`、`Exists` 等更彈性的條件描述 Node 選擇。
3. `requiredDuringSchedulingIgnoredDuringExecution` 是硬性條件；不符合就不能排。
4. `preferredDuringSchedulingIgnoredDuringExecution` 是軟性偏好；Scheduler 會盡量滿足，但不保證。
5. Taint / Toleration 是特殊 Node 的門禁：Taint 保護 Node，Toleration 讓 Pod 有資格進入，但不指定目的地。
6. 當需求同時包含「一般 Pod 不要進特殊 Node」和「特殊 workload 必須去特殊 Node」時，通常要同時使用 Taint / Toleration 與 `nodeSelector` 或 Node Affinity。

### 建議教學順序

1. 先用 Scheduler 候選 Node 的角度複習：排程規則如何把 Node 納入或排除候選名單。
2. 講 `nodeSelector` 的能力與限制：簡單、硬性、只能做 key/value AND 條件。
3. 講 Node Affinity 和 `nodeSelector` 的差別，特別是 `required` 與 `preferred` 的語意。
4. 講 Taint / Toleration 在組合策略裡的角色：保護特殊 Node，不是指定 workload 目的地。
5. 用 GPU Node 情境拆成兩個需求：
   - 一般 Pod 不要誤用 GPU Node。
   - AI workload 必須被排到 GPU Node。
6. 示範為什麼 GPU 情境常需要 label / affinity 加上 taint / toleration，而不是只用其中一種。
7. 最後用 WeaMind 作對照：目前只是 line-bot Pod 要固定去 worker，所以 `nodeSelector` 已經是輕量且合理的選擇。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 repo 內後，應該拿去做專案對照的 2 個問題。
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

### 帶回 repo 內對照的問題

1.
2.
