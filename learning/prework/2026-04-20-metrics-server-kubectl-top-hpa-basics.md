# 2026-04-20 Metrics Server, kubectl top, HPA Basics

## Prework 內容

### 今日焦點

- 主題：Metrics Server、kubectl top、HPA 的最小分工
- 範圍：先建立 Kubernetes 內建資源使用量、即時查看與自動擴縮之間的基本關係，不進入 Prometheus / Grafana 的完整觀測鏈
- 目標：避免把 Metrics Server、kubectl top、HPA 混成三個彼此獨立的工具，而是先理解它們共用的資料路徑與限制
- 時間：控制在 25 到 35 分鐘

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

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 VS Code 的問題

1. 待填
2. 待填
