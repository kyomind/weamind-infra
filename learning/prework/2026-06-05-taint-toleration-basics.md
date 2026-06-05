# 2026-06-05 Taint Toleration Basics

## Prework 內容

### 今日焦點

- 主題：Kubernetes Taint vs Toleration
- 範圍：taint / toleration 的方向、三種 effect、tolerations YAML 位置、和 nodeSelector 的差別
- 目標：先建立 CKA 與面試可用的最小理解骨架，之後再回 repo 內對照 WeaMind 為什麼只用了 nodeSelector
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的背景是：我已經知道 WeaMind 目前用 `nodeSelector` 把 app Pod 排到 worker，但我不熟 `taint / toleration`。請先教通用概念，不要先跳進 WeaMind 的實作細節。

### 今天一定要學會的最小骨架

1. Taint 是加在 Node 上的排斥條件，語意是「這台 node 不歡迎一般 Pod」。
2. Toleration 是加在 Pod spec 上的容忍宣告，語意是「這個 Pod 可以容忍某個 taint」。
3. Toleration 只代表「允許被排到有 taint 的 node」，不代表「一定會被排到那台 node」。
4. `NoSchedule`、`PreferNoSchedule`、`NoExecute` 的差別，尤其是 `NoExecute` 會影響已經在 node 上執行的 Pod。
5. `nodeSelector` 是 Pod 主動選符合 label 的 node；taint / toleration 是 node 先排斥，Pod 再宣告自己能不能進去。

### 建議教學順序

1. 先用生活化比喻講清楚 taint / toleration 的方向：Node 擋人，Pod 表示自己有通行資格。
2. 再用 scheduler 的角度說明：taint / toleration 如何影響 Pod 是否能成為某個 node 的候選。
3. 接著比較 `NoSchedule`、`PreferNoSchedule`、`NoExecute`，請特別說清楚它們對新 Pod 與既有 Pod 的差別。
4. 示範最小 YAML：Node 上的 taint 長什麼樣、Pod 裡 `spec.tolerations` 放在哪裡，並說明 `key`、`operator`、`value`、`effect`。
5. 比較 taint / toleration、nodeSelector、node affinity 的使用情境，收斂成 CKA/面試時好記的判斷方式。
6. 用 3 到 5 個小情境確認理解，例如 control-plane 不跑一般 workload、GPU node 專用、Pod Pending 因為 untolerated taint。

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

- 今天不只是學了 Taint / Toleration 的 YAML，而是建立了 Kubernetes Scheduler 的一個核心思維：Scheduler 會先不斷篩選候選 Node，再從候選 Node 裡選出最適合的節點。
- Taint / Toleration 正是候選 Node 篩選機制之一。它的方向和 `nodeSelector` 不同：`nodeSelector` 是 Pod 主動找符合 label 的 Node；Taint / Toleration 則是 Node 先標記「不歡迎一般 Pod」，Pod 再宣告自己能不能容忍這個限制。
- Taint 加在 Node 上，語意是排斥規則；Toleration 加在 Pod 上，語意是容忍宣告。Toleration 不是指定 Pod 一定要去某台 Node，而是讓 Scheduler 可以把那台帶 taint 的 Node 放回候選名單。
- 三種 effect 的差別：
  - `NoSchedule`：不讓新的 Pod 排進來，但不影響已經在 Node 上跑的 Pod。
  - `PreferNoSchedule`：盡量不要排進來，但不是硬性禁止。
  - `NoExecute`：不讓新的 Pod 排進來，也會驅逐沒有對應 toleration 的既有 Pod。
- YAML 上，Taint 可以理解成像 `gpu=true:NoSchedule` 這種 `key=value:effect` 結構；Toleration 放在 Pod 的 `spec.tolerations`，和 `containers` 同層。
- `operator: Equal` 代表 key 和 value 都要匹配；`operator: Exists` 代表只看 key，不看 value，因此條件比較寬。若 toleration 沒寫 `effect`，代表不限制 effect，能匹配同 key/value 下的多種 effect。

### 已能白話講清楚什麼

- Taint 是 Node 上的排斥規則，像是在 Node 門口貼「閒人勿入」。
- Toleration 是 Pod 的通行資格，意思是「我可以容忍這個 taint」，但不是「我一定要去這台 Node」。
- Toleration 是入場券，不是指定座位；它只讓 Node 重新進入候選名單，最後仍要由 Scheduler 依 CPU、Memory、Affinity、Scoring 等條件決定落點。
- `NoSchedule` 是關門但不趕人，`PreferNoSchedule` 是不建議進來，`NoExecute` 是關門加清場。
- `nodeSelector` 是 Pod 選 Node；Taint / Toleration 是 Node 篩 Pod。
- 回頭看 WeaMind，目前需求是 line-bot app Pod 要固定去 worker，而不是 worker 要排斥某類 Pod，所以用 `nodeSelector` 很合理。

### 目前還卡住什麼

- `tolerationSeconds` 還需要後續補，尤其是它通常和 `NoExecute` 搭配使用。
- Node Affinity 還需要另外整理；目前先知道它像是 `nodeSelector` 的進階版，未來常會和 Taint / Toleration 一起出現在排程題裡。
- Kubernetes control-plane 預設 taint 的細節可以再補強，之後看 CKA 題目時會遇到。

### 今日最重要的觀念

- Taint 是 Node 的排斥規則。
- Toleration 是 Pod 的容忍宣告。
- Toleration 不代表一定會被排到那台 Node，只代表那台 Node 可以成為候選。
- `NoExecute` 是最嚴格的 effect：不只阻止新的 Pod，也會驅逐既有 Pod。
- `nodeSelector` 是 Pod 主動選 Node；Taint / Toleration 是 Node 先排斥，Pod 再宣告自己能不能進去。

### 帶回 repo 內對照的問題

1. 目前 WeaMind line-bot Deployment 使用 `nodeSelector`。這是在描述「Pod 要去哪裡」，還是在描述「Node 要排斥誰」？如果是前者，為什麼 `nodeSelector` 比 Taint / Toleration 更自然？
2. 假設未來新增一台 GPU Worker，並加上 `gpu=true:NoSchedule` 專門跑 AI 推論，這時 `nodeSelector` 和 Taint / Toleration 哪一個更適合保護昂貴 GPU 資源？為什麼？
