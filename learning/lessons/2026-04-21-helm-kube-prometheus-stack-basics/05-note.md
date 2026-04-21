# 2026-04-21 Helm Kube Prometheus Stack Basics Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天先完成 `kube-prometheus-stack` 的最小安裝與元件辨識，不追求 production-grade observability 設計。
- 今天可以先使用 chart 預設值或最小必要設定，不把範圍擴成完整 values 架構規劃。
- 今天先把 Helm install、resource 驗證與元件角色說清楚；dashboard、PromQL、alerting、app metrics 掛點留到後續 lesson。

### Repo 對照文件與觀察點

- `.privatedocs/Phase2三週計畫.md`：確認今天是 W7 Day 2、`implement-heavy`，以及最低驗收標準。
- `references/phase2/w7-observability-minimum-spec.md`：提醒今天 install 的最終去向是 W7 的 Node 3、App 4、1 個 dashboard，但不是今天一次做完。
- `learning/prework/2026-04-20-prometheus-grafana-alertmanager-basics.md`：回收 Prometheus / Grafana / Alertmanager 的角色骨架。
- `docs/Kubernetes-Dashboard-臨時安裝紀錄.md`：對照 Helm CLI 在本機、資源建立在遠端叢集這個操作邊界。

### 暫時不在今天展開的點

- PromQL 與 alert rule 細節
- Grafana dashboard 視覺設計
- WeaMind app metrics 實作與 `/metrics` 掛點

## Notes

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的出現延伸問答或暫時結論後再填。 -->

## Flashcards

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的整理出卡片素材後再填。 -->
