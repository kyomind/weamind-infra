# 2026-04-20 Metrics Server, kubectl top, HPA Basics

## Prework 內容

### 今日焦點

- 主題：Metrics Server、kubectl top、HPA 的最小分工
- 範圍：先建立 Kubernetes 內建資源使用量、即時查看與自動擴縮之間的基本關係，不進入 Prometheus / Grafana 的完整觀測鏈
- 目標：避免把 Metrics Server、kubectl top、HPA 混成三個彼此獨立的工具，而是先理解它們共用的資料路徑與限制
- 時間：控制在 25 到 35 分鐘

### 這份在今天兩份 prework 裡的位置

- 今天的外部預習被拆成兩份，這一份是第一份。
- 這一份的角色是先把 Kubernetes 內建 metrics 與 autoscaling 這條線切乾淨，也就是 Metrics Server、kubectl top、HPA 各自做什麼、彼此怎麼接起來、又有哪些限制。
- 今天的第二份 prework 會再處理 Prometheus、Grafana、Alertmanager 這條 observability 鏈；那一份不是這一份的延伸功能，而是在解另一類問題。
- 教學時請把這一份當成整天的第一個概念地基，幫我先建立「即時資源 metrics / autoscaling」與「完整 observability / dashboard / alerting」不是同一條鏈的認知。

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天只專注在 Kubernetes 內建 metrics 與 autoscaling 這條線，不要先跳去講 Prometheus、Grafana 的完整監控生態。
- 請幫我建立最小概念邊界：誰提供資料、誰查看資料、誰根據資料做擴縮，以及這條鏈不能解什麼問題。

### 今天一定要學會的最小骨架

1. Metrics Server 的核心任務是提供 Kubernetes 內建資源使用量，不是長期監控資料庫。
2. kubectl top 是查看當前資源使用量的入口之一，本身不是 metrics 收集系統。
3. HPA 會依賴 metrics 來決定是否擴縮，但 HPA 本身不是 metrics provider。
4. 這條鏈偏向即時資源觀察與 autoscaling，不等於完整的 observability。
5. 如果需求是歷史趨勢、長期查詢、視覺化 dashboard，通常就超出這條線的責任範圍。

### 建議教學順序

1. 先講 Metrics Server 為什麼存在，它在 Kubernetes 裡解的是什麼問題。
2. 再講 kubectl top 與 Metrics Server 的關係，特別是「看得到什麼」與「看不到什麼」。
3. 接著講 HPA 如何使用 metrics，以及它為什麼不等於 Prometheus 式監控。
4. 然後用 2 到 3 個小情境題，區分「我要看即時 CPU 使用量」和「我要看歷史趨勢」這兩類需求。
5. 最後讓我用自己的話，講一遍 Metrics Server、kubectl top、HPA 的資料流。

如果我卡住，請先用白話和類比講清楚，再讓我重述一次。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 VS Code 後，應該拿去和 GitHub Copilot 對照 repo 的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

- Metrics Server 是 Kubernetes 的 metrics provider，負責收集並提供即時的 CPU / memory 使用量。
- kubectl top 只是讀取 Metrics Server 的 CLI 工具，本身不收集資料，也不參與自動化決策。
- HPA 會根據 metrics 來調整 Deployment 的 replicas，但不會直接建立 Pod。
- 當 replicas 被修改後，Deployment 會透過 ReplicaSet 建立或刪除 Pod，再由 Scheduler 幫新 Pod 選 node。
- 這整條鏈是在解即時資源觀察與 autoscaling，不等於完整 observability。

### 已能白話講清楚什麼

- Metrics Server 比較像 Kubernetes 的即時抄表員，不是長期監控系統。
- kubectl top 是給人查看當前狀態的工具，不在自動流程裡。
- HPA 的角色是自動改 replicas，不是直接創 Pod。
- Scheduler 依據 requests 幫 Pod 選 node，不是依據即時 metrics 做決策。
- kubectl top 與 Prometheus 的使用時機不同：前者偏現在的即時資源狀況，後者偏長期觀測與分析。

### 目前還卡住什麼

- HPA 在實務上什麼情況真的值得導入。
- HPA 的調整策略，例如 scaling 速度、觀察窗口與 cooldown 類概念。
- 未來若接 Prometheus 或 custom metrics，HPA 可以如何擴充到不只 CPU / memory。

### 今日最重要的觀念

- Metrics Server 只提供即時 metrics，不存歷史資料。
- kubectl top 只是顯示工具，不是 metrics 系統。
- HPA 根據 metrics 決定 replicas，但不直接創 Pod。
- Scheduler 只看 requests 做資源配置，不看即時使用量。
- 這條鏈是即時資源觀察加 autoscaling，不是完整 observability。

### 帶回 VS Code 的問題

1. 我現在的 Deployment 有沒有設定 resources.requests？如果沒有，Scheduler 是怎麼分配的？
2. 如果我在 WeaMind 加上 HPA（例如 CPU 80%），實際上會怎麼影響 Pod 數量？在什麼流量情境下會真的觸發？
