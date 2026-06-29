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

- 今天最大的收穫不是記住各種 YAML 寫法，而是建立「Scheduler 如何思考 Node Placement」的心智模型。
- Scheduler 不是直接挑一台 Node，而是先 Filter 出符合條件的 Candidate Nodes，再對候選 Node 做 Score，最後才 Binding 到實際 Node。
- `nodeSelector` 是最簡單的硬性 Node label 篩選器。Pod 會宣告自己只接受符合特定 `key=value` label 的 Node；如果沒有 Node 符合，Pod 就會維持 Pending。
- `nodeSelector` 的限制是只能表達簡單的 `key=value` 與 AND 條件，不能表達 OR、NOT、Exists、In、NotIn 等更彈性的規則。
- Node Affinity 可以視為 `nodeSelector` 的進階版，可以用 `In`、`NotIn`、`Exists`、`DoesNotExist` 等條件描述 Node 選擇。
- Node Affinity 中最重要的差別是 `required` 和 `preferred`。`requiredDuringSchedulingIgnoredDuringExecution` 是硬性要求，不符合就不能排；`preferredDuringSchedulingIgnoredDuringExecution` 是軟性偏好，Scheduler 會盡量滿足，但不保證。
- 今天也釐清了 Taint / Toleration 和 `nodeSelector` / Node Affinity 不是同一種東西。`nodeSelector` / Node Affinity 是 Pod 在說「我要去哪裡」；Taint 是 Node 在說「我不要誰進來」。
- Toleration 不是指定目的地，而是讓 Pod 有資格進入帶有對應 taint 的 Node。它像門禁卡，不像導航。
- GPU Node 情境最能說明這組工具的分工：Label 描述 Node 身分，Taint 保護 GPU Node 不被一般 Pod 誤用，Toleration 讓 AI Pod 有資格進 GPU Node，而 `nodeSelector` 或 Node Affinity 才真正指定 AI Pod 要去 GPU Node。
- 回到 WeaMind，目前 line-bot Pod 只是要固定跑在 worker node，沒有 GPU、spot node、high-memory node 或特殊資源保護需求，所以使用 `nodeSelector` 是簡單且合理的選擇。沒有必要為了 Kubernetes 有更多功能，就加入 Node Affinity 或 Taint / Toleration。

### 已能白話講清楚什麼

- Scheduler 的排程可以先用「先 Filter，再 Score」理解。不是一開始就直接挑 Node，而是先排除不合格的 Node，再從剩下的候選 Node 裡挑最適合的一台。
- `nodeSelector` 是 Pod 主動指定自己要去哪類 Node，語意是硬性條件；如果沒有 Node 符合，Pod 會 Pending。
- Node Affinity 比 `nodeSelector` 更有彈性，可以表達更複雜的條件，而且分成硬性要求 `required` 和軟性偏好 `preferred`。
- `required` 是一定要遵守；沒有符合的 Node 就不排。`preferred` 是最好符合，但不是一定要符合。
- Taint 是 Node 保護自己，表示「沒有對應資格的 Pod 不要進來」。
- Toleration 是 Pod 宣告自己可以容忍某個 taint，因此有資格進入那類 Node；但有資格進入不等於一定會被排到那台 Node。
- 真正指定 Pod 去哪裡的是 `nodeSelector` 或 Node Affinity，不是 Toleration。
- GPU Node 的完整設計通常不是只靠一個機制，而是 Label、Taint、Toleration、`nodeSelector` / Node Affinity 各自負責不同角色。
- WeaMind 現在使用 `nodeSelector: nodepool=worker`，本質上就是在描述「line-bot Pod 要去 worker」，這和今天學到的 Pod 指定目的地模型一致。

### 目前還卡住什麼

- 概念已經建立起來，但還需要把今天的判斷轉換成實際 YAML 閱讀能力，尤其是 `nodeSelector`、Node Affinity、Toleration 在 manifest 裡的實際位置與結構。
- Node Affinity 的 YAML 結構比 `nodeSelector` 複雜很多。目前已理解 `required` 和 `preferred` 的語意，但還需要熟悉 `nodeSelectorTerms`、`matchExpressions`、`operator`、`values` 這些欄位。
- 未來學 Pod Affinity / Anti-Affinity 時，需要另外建立一套「Pod 與 Pod 之間關係」的思考方式，避免和今天的 Pod-to-Node placement 混在一起。

### 今日最重要的觀念

- Scheduler 先 Filter，再 Score；Node placement 的第一個問題是哪些 Node 可以成為 Candidate。
- `nodeSelector` 是最簡單的硬性 Node label 篩選；沒有符合的 Node，Pod 就會 Pending。
- Node Affinity 是 `nodeSelector` 的進階版，其中 `required` 和 `preferred` 的差異比單純記 `In` / `Exists` 更重要。
- Taint 保護 Node，Toleration 給 Pod 進入資格；它們不是指定目的地。
- 真正指定 Pod 去哪裡的是 `nodeSelector` 或 Node Affinity。
- GPU Node 常見完整設計是：GPU Node 有 Label 和 Taint；AI Pod 有 Toleration 加上 `nodeSelector` 或 Node Affinity。這樣才能同時避免一般 Pod 誤用 GPU，並確保 AI workload 真的排到 GPU Node。

### 帶回 repo 內對照的問題

1. 目前 WeaMind 的 Deployment 中使用 `nodeSelector: nodepool=worker`，這是否正是在描述「Pod 指定目的地」？如果拿掉它，在 control-plane 可排程的前提下，line-bot Pod 是否可能被 Scheduler 排到 control-plane？
2. 如果未來 WeaMind 新增 AI 推論服務，應該如何設計 GPU worker label、GPU node taint、AI Pod toleration，以及 `nodeSelector` 或 Node Affinity，才能同時讓一般 line-bot 不誤用 GPU、AI 推論一定使用 GPU，並讓 YAML 維持容易維護？
