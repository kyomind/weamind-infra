# 2026-04-24 Prometheus Instrumentation Homework

## Prework 內容

### 今日焦點

- 主題：Prometheus instrumentation 在 FastAPI / webhook app 裡的常見實踐
- 範圍：metric 型別選擇、`/metrics` endpoint、request / success / error / latency 掛點、labels 最小設計
- 目標：補上今天 W7 Day 3 在 app instrumentation 這一側缺的純知識骨架，讓後續在 WeaMind app repo 內實作時不只是照做
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這不是正式課前預習，而是 W7 Day 3 lesson 後補建的輕量 homework。
- 這份文件是給外部 ChatGPT 類服務做純知識補強，不是給 VS Code 內直接講 repo 細節。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天請特別避免把內容展開成 Prometheus 全科。聚焦在「一個 FastAPI webhook 服務要怎麼暴露給 Prometheus 抓」這條最小實作鏈即可。

### 今天一定要學會的最小骨架

1. instrumentation、exporter、`/metrics` endpoint 三者各自是什麼
2. Counter、Histogram、Gauge 在 webhook request / success / error / latency 這種情境下通常怎麼選
3. app 端生 metrics 與 infra 端被 Prometheus scrape 是兩個不同責任
4. labels 為什麼不能亂加，以及 event_type / error_type 這類 labels 為什麼要克制
5. FastAPI 這類 app 最常見的 `/metrics` 暴露方式與掛點位置

### 建議教學順序

1. 先用白話解釋 instrumentation 是什麼，和 exporter / Prometheus server 的責任怎麼分
2. 再講常見 metric 型別：Counter、Gauge、Histogram，並用 webhook request / success / error / latency 做最小對照
3. 再講一個 FastAPI app 要怎麼暴露 `/metrics`，以及為什麼這不等於 Prometheus 已經會來抓
4. 再講 labels 設計的最小原則，特別是 event_type、error_type 這類欄位為什麼不能無限制膨脹
5. 最後用一個最小實作鏈總結：app instrumentation -> `/metrics` -> Service -> ServiceMonitor -> Prometheus -> Grafana

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

### 今日主題與學習範圍

- 主題：Prometheus instrumentation 在 FastAPI / webhook app 的最小實作骨架
- 範圍：
  - instrumentation / exporter / Prometheus 分工
  - Counter / Gauge / Histogram 選擇
  - `/metrics` endpoint 的角色
  - Prometheus scrape flow（Service / ServiceMonitor）
  - labels 設計原則與 cardinality 控制

### 今日學到什麼

- instrumentation 是在 app 裡記錄 metrics 的一整組行為，本質上是在程式內埋觀測點，不等於 exporter，也不等於 Prometheus。
- app 端 metrics 預設存在 memory，保留的是當前聚合結果，不是 raw data；真正把資料持久化成 time series 的是 Prometheus。
- webhook 這種情境下，`request / success / error` 適合先用 Counter，`request latency` 適合用 Histogram；若未來要看當前處理中的請求數，才會再補 Gauge。
- Counter 會因 Pod 重啟而歸零，但 Prometheus 主要搭配 `rate()` 或其他變化量查詢使用，所以重點不在絕對值，而在增長速度。
- `/metrics` 只是資料出口，不代表 Prometheus 已經會來抓；完整鏈路仍然是：app instrumentation -> `/metrics` -> Service -> ServiceMonitor -> Prometheus -> Grafana。
- Prometheus 採 pull model。也就是 app 端 event 發生時更新 memory 內的 metrics，Prometheus 再定期來 scrape，Grafana 則是定期 query Prometheus。
- labels 的真正重點是控制 cardinality。label 不是不能加，而是只能放有限、穩定、低變化的分類，不該放會無限制膨脹的動態值。

### 已能白話講清楚什麼

- instrumentation 是在程式內埋測量點，讓 app 能持續產生可觀察的 metrics。
- metrics 存的是 memory 裡的聚合結果，不是每一筆 raw event，也不是直接寫進 DB。
- Prometheus 會主動來抓 `/metrics`，不是 app 自己把資料推給 Prometheus。
- Counter reset 不會破壞主要觀測價值，因為 Prometheus 常看的是 rate 或 increase 這類變化量。
- Histogram 的價值在於能支撐 average、p95、p99 這種 latency 觀測，而不是只看單一平均值。
- `/metrics` 不等於整個監控系統已經打通；Service 與 ServiceMonitor 才是讓 Prometheus 在 Kubernetes 裡找到 target 的關鍵。
- labels 很強，但也很危險；如果用在高 cardinality 欄位上，time series 數量會快速膨脹。

### 目前還卡住什麼

- Histogram bucket 應該怎麼設，才比較符合真實流量與 latency 分布。
- ServiceMonitor YAML 的細節怎麼和實際 Service 的 label、port、path 正確對齊。
- PromQL 尤其是 `rate()`、`increase()`、`histogram_quantile()` 這些查詢要怎麼穩定套到 dashboard。
- 多 Pod / 多 instance 的 metrics 聚合該怎麼理解，尤其是跨 instance aggregation 的觀測語意。

### 今日最重要的觀念

- instrumentation、exporter、Prometheus 是三層不同責任：app 生 metrics、出口暴露 metrics、Prometheus 抓與存 metrics。
- metrics 是聚合結果，不是 raw data。
- Counter 的重點是變化率，不是當下數字本身。
- `/metrics` 只是入口，不是整條 observability 鏈的完成訊號。
- labels 很有表達力，但必須控制 cardinality，避免把 system 維度炸開。

### 帶回 VS Code 的問題

1. 我現在的 FastAPI webhook，有沒有加上以下 metrics：`request_total`、`success_total`、`error_total`、`request_latency`？如果沒有，這些掛點應該落在 middleware、router 還是 handler？
2. 如果 `/metrics` endpoint 已經存在，那目前的 Service 有沒有 expose 正確 port、ServiceMonitor 有沒有 match 到正確 label、path 是不是 `/metrics`？如果 Grafana 沒資料，應該怎麼逐層 debug？
