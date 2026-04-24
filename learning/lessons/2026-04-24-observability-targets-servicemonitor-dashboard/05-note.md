# 2026-04-24 Observability Targets ServiceMonitor Dashboard Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天先做 W7 demo MVP 所需的 target discovery、`ServiceMonitor` / `PodMonitor` 與 dashboard 最小骨架，不追 production-grade observability。
- 今天可以接受先把 cluster metrics 與 app metrics 的邊界切清楚；如果 WeaMind app 尚未暴露 `/metrics`，重點是定位缺口，而不是硬補一整套應用程式重構。
- 今天優先保住一條可 demo、可面試重講的證據鏈，不追求把 PromQL、Alertmanager 與 dashboard 視覺設計一次做滿。

### Repo 對照文件與觀察點

- `.privatedocs/Phase2三週計畫.md`：確認今天是 W7 Day 3、`implement-heavy`，以及最低驗收標準。
- `references/phase2/w7-observability-minimum-spec.md`：固定今天的 Node 3、App 4、1 個 dashboard MVP 邊界。
- `learning/lessons/2026-04-21-helm-kube-prometheus-stack-basics/05-note.md`：回收前一天已確認的 operator / workload / install 邊界。
- `manifests/deployment.yaml`、`manifests/service.yaml`：對照 WeaMind app 若要被 scrape，最小可能修改點在哪。

### 暫時不在今天展開的點

- PromQL 深水區與 recording rules
- Alertmanager routing 與通知策略
- Production-grade dashboard folder / RBAC / provisioning 設計

## Notes

## Flashcards
