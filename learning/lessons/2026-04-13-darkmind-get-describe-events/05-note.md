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

### `kubectl get` vs `kubectl describe`

- `kubectl get` 比較像列表式、高層的狀態摘要，適合第一輪快速掃描：先找出哪個 resource 不健康、異常大概落在哪一類。
- `kubectl describe` 比較像針對單一 resource 的展開式 Kubernetes 視角，適合第二輪往下看：`State`、`Conditions`、`Reason`、`Events`、probe 狀態、image pull 訊號等。
- 一句話口訣：`get` 先幫我找到哪裡怪，`describe` 再幫我看 Kubernetes 具體怎麼描述這個怪狀態。

### `describe` vs `events`

- `describe` 是以單一 resource 為中心的展開式觀察，回答的是「這個 Pod / resource 現在怎麼了」。
- `kubectl get events --sort-by=.lastTimestamp` 是以 event 列表為中心的觀察，回答的是「最近這個 namespace 裡先後發生了哪些事」。
- `describe` 裡的 `Events` section 可以看成以單一 resource 為中心擷取出的事件片段；`kubectl get events` 則是把 event 當成獨立列表來看。

### Kubernetes `Event` 是什麼

- `Event` 本身就是 Kubernetes API 裡的一種 resource kind，只是它屬於輔助型、短生命週期的事件紀錄資源。
- `Event` 不只記錯誤，也可能記正常流程，例如 `Scheduled`、`Pulled`、`Created`、`Started`；只是 debug 時通常會特別注意 warning 或 failure 類事件。
- 一句話口訣：`Event` 不是錯誤清單，而是 Kubernetes 的事件流；只是故障排查時，warning event 最有訊號價值。

### 同一份 YAML 放多個 resource

- 像 `darkmind/healthy.yaml` 這樣把 `Deployment` 和 `Service` 放在同一份檔案裡是完全合法的，只要用 `---` 把多個 YAML document 分開即可。
- Kubernetes 會把同一份檔案中的每個 document 視為獨立 resource 來套用，因此 `kubectl apply -f darkmind/healthy.yaml` 會一次建立兩個物件。
- 這種寫法很常用在彼此高度相關、通常一起建立與刪除的資源上；例如同一個練習情境中的 `Deployment` 加 `Service`。

### Darkmind 裡的 labels 在做什麼

- `app: darkmind-healthy` 是這份情境自己最直接使用的 label，通常用在 `selector`、`matchLabels` 或快速用 `-l app=...` 篩資源。
- `app.kubernetes.io/name: darkmind` 和 `app.kubernetes.io/component: healthy` 則比較接近 **Kubernetes 常見的推薦式 app labels**。它們不是 Kubernetes 強制要求，但很常見，目的是讓資源在工具、文件與跨團隊閱讀時有比較一致的語意。
- 可以先把它們理解成：`name` 表示這整組東西屬於哪個應用或 lab，`component` 表示它在這個應用裡扮演哪個角色或情境。
- WeaMind 正式 manifests 目前沒有全面採這套寫法也完全正常，因為這不是必填欄位；Darkmind 這裡多放，是為了讓練習素材的分類語意更清楚，也比較接近常見的 Kubernetes 標記慣例。

## Flashcards

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的整理出卡片素材後再填。 -->
