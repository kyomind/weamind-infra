# 2026-04-13 Darkmind Get Describe Events Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天只練 `get`、`describe`、`events` 這條 Day 1 觀察鏈，不提前混入 `logs`、`exec`、`port-forward` 或 `rollout` 主題。
- 今天的壞情境以 `image-pull-error` 為主，目標是把第一層縮圈做穩，不追求一次碰多種故障家族。

### Repo 對照文件與觀察點

- `darkmind/README.md`：確認 Day 1 的操作目標與經典場景邊界。
- `darkmind/healthy.yaml`：建立健康基準，知道正常狀態長什麼樣。
- `darkmind/scenarios/image-pull-error.yaml`：對照 image tag 故意不存在時，Kubernetes 會給什麼訊號。

### 暫時不在今天展開的點

- `logs`、`logs --previous` 留到 Day 2。
- `exec`、`port-forward` 留到 Day 3。
- `readiness-fail` 與 `bad-rollout` 情境今天不正式展開。

## Notes

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的出現延伸問答或暫時結論後再填。 -->

## Flashcards

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的整理出卡片素材後再填。 -->
