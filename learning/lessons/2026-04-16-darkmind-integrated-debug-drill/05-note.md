# 2026-04-16 Darkmind Integrated Debug Drill Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天要驗收的是整體排查順序，不是單一工具會不會用；因此第一步重點是找最能縮圈的證據入口。
- `port-forward` 仍然只是其中一個 debug 工具；今天它若出現，也只會是整合 sequence 裡的一步，不是整天的主軸。

### Repo 對照文件與觀察點

- 對照 `darkmind/README.md` 與既有壞情境 YAML，確認每種場景本來就刻意對應不同的第一輪證據入口。
- 對照 `.privatedocs/六週版學習計畫.md` 裡 W6 Day 4 的設計：今天不追求高輪數，而是較長的整合題與口頭收斂。

### 暫時不在今天展開的點

- 不延伸到真實 WeaMind Service 的 `port-forward` 實作。
- 不回頭補新的通用概念或外部預習。

## Notes

### 錯誤通常是怎麼先被發現的

- 在真實工作裡，錯誤最常見的起點通常不是先開 `kubectl`，而是 **先從外部症狀發現異常**。
- 例如最常見的是：你在 UI 上操作功能失敗、測試環境某個頁面打不開、某個 API 回 `5xx` 或 timeout、QA 回報流程壞掉、監控或告警先跳出來。
- 也就是說，真實排查的第一個訊號常常不是「我知道 Pod 壞了」，而是 **「我知道這個服務的某個外部行為不符合預期」**。
- 進到 cluster 之後，真正要做的不是立刻找單一指令，而是把這個外部症狀先翻譯成一個較像 infra / app 的問題：到底比較像 **入口沒進來、Pod 沒起來、container 啟動後自己炸掉，還是部署切版出了問題**。

### 最常見、最實務的排查順序

- 若你是從 UI、API 或測試流程先發現異常，最實務的第一步通常不是先 `exec`，而是先做 **低成本縮圈**。
⭐️一條很常見的實務順序可以先記成：

1. **先確認外部症狀長什麼樣**：是 `404`、`5xx`、timeout、連線被拒、還是功能結果錯誤。這一步在回答「現在比較像哪一層先出問題」。
2. **進 cluster 看資源快照**：先用 `kubectl get` 看 Pod、Deployment、Service 是否存在，狀態字樣是不是 `ImagePullBackOff`、`CrashLoopBackOff`、`Running` 但 `0/1 Ready`，還是 rollout 本身卡住。這一步在回答「問題大概落在哪個階段」。
3. **再用 `describe` / `events` 補 Kubernetes 視角**：看排程、拉 image、probe、重啟、selector、conditions、近期事件。這一步在回答「Kubernetes 自己認為目前卡在哪裡」。
4. **只有在已懷疑 container 啟動過、且問題更像 app 內部時，才接 `logs` / `logs --previous`**。這一步在回答「app 或程序啟動期實際吐了什麼」。
5. **只有在已確認 target 存在、而且確實需要 container 內部視角時，才接 `exec`**。這一步在回答「container 裡面現在到底長什麼樣」。
6. **若已懷疑是部署交接問題，再接 `rollout status`、`rollout history`、必要時 `rollout undo`**。這一步在回答「這是不是版本切換或 revision 交接失敗」。
7. **若只是想快速驗證某個 Pod / Service port 本身有沒有回應，才考慮 `port-forward`**。這一步在回答「debug 用的臨時通道能不能打到目標」，不是在直接證明正式外部流量一定健康。

- 這條順序的核心不是每次都要從 1 走到 7，而是：**先從最便宜、最外層、最能縮圈的證據開始，再逐步往內層走。**
- 所以更短版可以記成：**先看外部症狀，再看 `get` / `describe` / `events`，之後才決定要不要接 `logs`、`exec`、`rollout` 或 `port-forward`。**

## Flashcards

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的整理出卡片素材後再填。 -->
