# 2026-04-14 Darkmind Logs Previous Rollout Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天只練 `logs`、`logs --previous`、`rollout status`、`rollout history`、`rollout undo` 這條 Day 2 操作鏈，不提前混入 `exec`、`port-forward` 或 `readiness-fail` 主題。
- 今天的壞情境只用 `crash-loop` 與 `bad-rollout`，目標是把 app-level 證據和 Deployment-level 證據分清楚，不追求一次碰更多故障家族。

### Repo 對照文件與觀察點

- `darkmind/README.md`：確認 Day 2 的操作目標與情境邊界。
- `darkmind/scenarios/crash-loop.yaml`：對照 container 一啟動就退出時，`logs` 與 `logs --previous` 會對應到哪種證據。
- `darkmind/scenarios/bad-rollout-01-good.yaml` 與 `darkmind/scenarios/bad-rollout-02-bad.yaml`：對照正常 rollout 和壞版本 rollout 卡住時，Deployment 層級指令要怎麼接。

### 暫時不在今天展開的點

- `exec`、`port-forward` 留到後續 lesson。
- `readiness-fail` 與 service endpoints 今天不正式展開。
- 更細的 `kubectl logs` 篩選參數與多 container log 變體今天不先展開。

## Notes

<!-- lesson 進行後再回填 -->

## Flashcards

<!-- lesson 進行後再回填 -->
