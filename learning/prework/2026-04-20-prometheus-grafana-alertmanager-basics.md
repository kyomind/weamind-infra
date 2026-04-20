# 2026-04-20 Prometheus, Grafana, Alertmanager Basics

## Prework 內容

### 今日焦點

- 主題：Prometheus、Grafana、Alertmanager 的最小分工
- 範圍：先建立 observability 鏈裡 metrics 收集、儲存、查詢、視覺化與告警通知的角色邊界，不進入實際 Helm 安裝與 WeaMind repo 對照
- 目標：避免把 Prometheus、Grafana、Alertmanager 混成同一層工具，先理解誰負責收資料、誰負責展示、誰負責處理告警
- 時間：控制在 25 到 35 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天只專注在 Prometheus observability 鏈，不要先展開 kube-prometheus-stack 元件細節、實際 chart 設定或特定 repo manifests。
- 請幫我建立最小概念邊界：誰抓 metrics、誰存 metrics、誰查 metrics、誰畫 dashboard、誰負責告警通知。

### 今天一定要學會的最小骨架

1. Prometheus 的核心任務是抓取、儲存與查詢 time series metrics。
2. Grafana 主要負責 dashboard 與視覺化，不是 metrics collector。
3. Alertmanager 處理的是告警分群、抑制、路由與通知，不是 metrics database。
4. Prometheus 常見是 pull model，要理解 scrape、target、time series 這幾個最小語意。
5. 如果需求是「看歷史趨勢、畫圖、做告警」，這條鏈才是主要解法，而不是 Metrics Server + kubectl top。

### 建議教學順序

1. 先講 Prometheus 在整條 observability 鏈裡解的是什麼問題。
2. 再講 pull model、scrape target、time series 的最小語意，不要一開始就陷入深水區。
3. 接著講 Grafana 為什麼通常和 Prometheus 一起出現，但兩者角色不同。
4. 然後講 Alertmanager 站在什麼位置，處理的是哪一段告警流程。
5. 最後用 2 到 3 個小情境題，區分「我要看歷史趨勢」「我要做 dashboard」「我要把異常送通知」分別會先想到哪個元件。

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
