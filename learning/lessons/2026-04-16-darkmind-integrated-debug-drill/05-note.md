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

### 問題雖然表現在 Pod，但真正切點不一定在 Pod

- **Deployment 類最常見例子**：新版本 rollout 後，畫面開始壞掉，你用 `kubectl get pods` 看到新 Pod 不健康，表面上像是 Pod 壞了；但真正切點常常是 **Deployment 的新 revision 本身有問題**，例如 image tag 寫錯、command 改壞、環境變數改壞，或 rollout 交接卡住。這類問題真正要回答的是「這次版本交接是不是壞版本」，所以常要看 `rollout status`、`rollout history`，必要時 `rollout undo`，而不是只盯著單顆 Pod。
- **Service 類最常見例子**：UI timeout 或 API 打不通時，你可能看到 Pod 其實還在 `Running`，甚至 app 自己也活著；但真正切點可能在 **Service 沒有正確把流量送進去**，例如 selector 對不到、Pod 不 Ready 導致 `endpoints` 是空的，或 targetPort 對錯。這時表面上像 Pod 沒反應，實際上更像是 **Service backend membership** 問題。
- **Ingress 類最常見例子**：外部打進來拿到 `404`，第一眼很容易誤以為是 app route 壞了，因為最後請求沒成功；但真正切點可能在 **Ingress 的 host / path 規則**，例如 host 不對、path 填錯、Prefix 規則沒對上，或 request 根本還沒正確進到後面的 Service。WeaMind 真實脈絡裡，像 webhook path 寫錯，或 health check 沒帶對 host header，這種都更像入口 routing 層問題，不是 Pod 內部邏輯先壞掉。
- 所以這句話要記成：**Pod 常常只是症狀承載點，不一定是根因所在。** 真正排查時，要問的是「我現在看到的是 Pod 上的症狀，還是 Deployment / Service / Ingress 這些上游物件造成的結果」。

### 同一份 Deployment YAML 連續 apply，revision 會怎麼變

- 一般而言，**如果你連續 apply 同一份 Deployment YAML，而且 `spec.template` 沒有任何實質變化，Deployment controller 不會新增新的 rollout revision。**
- 原因不是它單純記得「這是同一個檔案」，而是 Deployment 真正拿來判斷要不要建立新 ReplicaSet / 新 revision 的核心，主要是 **Pod template 是否改變**，也就是 `spec.template.metadata` 與 `spec.template.spec` 這一塊。
- 所以最常見的行為是：

1. **若只有重新 apply、內容沒變**：API server 仍可能接受這次 apply，但 Deployment 不會因此產生新的 ReplicaSet，也通常不會多一個新的 rollout revision。
2. **若改到 Deployment 本身但沒改到 Pod template**：例如部分不影響 `spec.template` 的欄位，通常也不會觸發新 Pod rollout。
3. **若改到 `spec.template`**：例如 image tag、command、env、labels（長在 template 上）、probe、container port 等，這才會被視為新的 Pod template，Deployment 會建立新的 ReplicaSet，並形成新的 rollout revision。

- 更實務地記：**Deployment 的 revision 不是看你 apply 幾次，而是看你有沒有改出一個新的 Pod template。**
- 所以你這次前置建立裡，`bad-rollout-01-good.yaml` 先成功 rollout，之後再 apply `bad-rollout-02-bad.yaml`，會形成新狀態，就是因為第二次 apply 實際上改動了 deployment 對應的 Pod template，而不只是重送同一份內容。

## Flashcards

<!-- 初始化時保持空白；若需要佔位，可只保留這類特殊註記。等 lesson 過程中真的整理出卡片素材後再填。 -->
