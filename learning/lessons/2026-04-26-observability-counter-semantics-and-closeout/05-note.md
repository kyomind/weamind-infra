# 2026-04-26 Observability Counter Semantics and Closeout Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天的第一優先不是多做幾張 Grafana 圖，而是先判斷 App 4 的 counter 序列是否可信。
- 若今天證明問題主要落在多 worker 下的 metrics runtime，W7 可以先用 demo-grade 保守做法收尾，不需要在同一天硬補 production-grade multiprocess 支援。
- 今天要刻意分開三層：真實 webhook 流量、PromQL 對 counter 的解讀、以及 app runtime 如何暴露 metrics。

## Notes

<!-- 待回填 -->

## Flashcards

<!-- 待回填 -->
