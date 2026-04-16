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

### 1 分鐘口頭收斂版本

- 如果我在測試環境或 production 先從外部發現異常，例如 API timeout、回 `4xx` / `5xx`、頁面壞掉，或 webhook 沒正常進來，我不會一開始就直接 `exec` 進 Pod。
- 我的第一步通常是先進 cluster 做縮圈，先用 `kubectl get` 看 Deployment、Pod、Service 這些資源目前的狀態，再用 `describe`，必要時加 `events`，去確認問題大概落在哪一層。
- 如果我看到的是 image pull 類錯誤，我就知道 container 根本還沒成功啟動，這時重點是看 Pod 狀態和 events，不是看 app logs。
- 如果是 crash loop 類，我就會先看 `kubectl logs --previous`，因為我要知道上一輪 container 啟動後到底吐了什麼、為什麼死掉。
- 如果我懷疑不是單顆 Pod 壞掉，而是 deployment 切版失敗，我就會看 `rollout status`、`rollout history`，必要時補 `describe deployment`，確認是不是 rollout 卡住或 revision 有問題。
- 等我確認問題層級後，才決定要不要進一步 `exec` 看 container 內部，或在 production 先保留證據後 `rollout undo`。
- `port-forward` 對我來說比較像局部驗證工具，不是整條排查主線。

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

### `kubectl logs` 用 selector 與 `--previous` 時的實務邊界

- 若你要指定 **單一 Pod**，最穩的寫法通常是直接寫 Pod 名稱，例如：

```bash
kubectl logs -n darkmind darkmind-crash-loop-f6dfb6fdd-dwv22 --previous
```

- 也可以顯式寫成資源型別加名稱，例如：

```bash
kubectl logs -n darkmind pod/darkmind-crash-loop-f6dfb6fdd-dwv22 --previous
```

- 若你用的是 label selector，例如：

```bash
kubectl logs -n darkmind -l app=darkmind-crash-loop --previous
```

這代表 `kubectl` 會先找出所有符合 selector 的 Pods，再對它們嘗試取 logs；所以它比較像 **批次選取**，不是在保證只看單一目標。
- 若 selector 剛好只命中一個 Pod，體感上會像單一 Pod 指令；但這只是因為當下符合條件的目標剛好只有一個，不代表 selector 本身只會看一個。
- 若 selector 命中多個 Pod，輸出可能會變得比較難讀。實務上通常會搭配 `--prefix` 幫每行加上 Pod / container 來源，或乾脆先用 `kubectl get pods -l ...` 找出目標，再指定單一 Pod 名稱。
- 這次用現場驗證 `kubectl logs -n darkmind -l app=darkmind-rollout --tail=1 --prefix --max-log-requests=10`，當 selector 命中多個 Pod 而其中某顆 Pod 甚至還卡在 image pull、沒有可讀 logs 時，指令會直接回：

```bash
Error from server (BadRequest): container "app" in pod "darkmind-rollout-..." is waiting to start: trying and failing to pull image
```

- 也就是說，**selector 命中多個 Pod 時，不保證你會拿到一份乾淨、完整、好判讀的聚合輸出；有時候其中一顆 Pod 的錯誤就足以讓整個命令直接失敗。**
- `--previous` 更要小心。它的語意是：**我要看這顆 Pod 裡「上一個已終止 container instance」的 logs。** 所以如果某顆 Pod 根本沒有 previous instance，例如它從沒成功啟動過、或從未重啟過，就可能直接回：

```bash
Error from server (BadRequest): previous terminated container "app" in pod "..." not found
```

- 這表示若 selector 命中兩個 replicas，其中一個曾 crash 過、另一個從沒重啟過，那你用 selector 加 `--previous` 很可能會因為「沒有 previous 的那顆 Pod」直接報錯，讓整體輸出變得不穩。
- 所以最實務的規則是：**`logs --previous` 幾乎都應該在你已經先鎖定特定壞 Pod 之後，再直接指定 Pod 名稱來用；不要把 selector + --previous 當成預設主力。**

### `kubectl logs` 能不能打其他資源

- `kubectl logs` 最終看的當然還是 **Pod 裡某個 container 的 logs**，所以它不是像 `describe` 那樣幾乎任何資源都能看一份物件描述。
- 但在 CLI 用法上，`kubectl logs` 不只接受 Pod 名稱，也能接受某些 **會對應到 Pods 的 workload 資源**，例如 `deployment/...`、`job/...`。
- 例如：

```bash
kubectl logs deployment/nginx
kubectl logs deployment/nginx --all-pods=true
kubectl logs job/hello
```

- 這時它並不是去看 Deployment 或 Job 物件本身有自己的 logs，而是 **先從這些 workload 資源找出對應 Pods，再去抓那些 Pods 的 container logs**。
- 所以更精確地說：**`kubectl logs` 真正能看的永遠是 Pod / container logs；只是它有些方便寫法，可以從 Deployment、Job 這類會管理 Pods 的資源出發去幫你找 Pod。**
- 相對地，像 `Service`、`Ingress` 這種本身不承載 container 的資源，就沒有「自己的 logs」可以直接用 `kubectl logs service/...` 這樣去看。

### 為什麼 `rollout status` / `history` 看起來資訊不多

- `kubectl rollout status` 的責任很單純：它主要是回答 **這次 rollout 有沒有完成、是否卡住**，不是完整診斷報表。
- 所以它最重要的參數通常是：

```bash
kubectl rollout status deployment/darkmind-rollout -n darkmind
kubectl rollout status deployment/darkmind-rollout -n darkmind --watch=false
kubectl rollout status deployment/darkmind-rollout -n darkmind --revision=2
```

- 其中 `--watch=false` 只是不要持續等待，`--revision=N` 則是把觀察固定在特定 revision；它們都不是在多印很多診斷欄位。
- `kubectl rollout history` 的責任也偏窄：它主要是回答 **目前有哪些 revision**。若你有額外維護 `CHANGE-CAUSE` annotation，它才會更有說明性；否則常常只會看到 revision 編號而已。
- 所以當你真的想看「到底成功還是失敗、卡在哪裡、哪些副本可用、舊版和新版 ReplicaSet 各是誰」時，更高價值的通常是：

```bash
kubectl describe deployment darkmind-rollout -n darkmind
kubectl get rs -n darkmind
kubectl get pods -n darkmind
kubectl rollout history deployment/darkmind-rollout -n darkmind --revision=2
```

- 這次現場最有價值的訊號，其實就出現在 `describe deployment`：`Progressing=False`、`Reason=ProgressDeadlineExceeded`、`OldReplicaSets`、`NewReplicaSet`，以及 `1 available | 2 unavailable`。這些比單看 `rollout history` 更接近真正的失敗證據。

## Flashcards

- 壞 Pod 的第一步真正目標是什麼？ #DevOps #card
	- 不是直接找完整答案
	- 而是先選最能縮圈的證據入口
	- 預設常先看 `get`、`describe`、`events`

- image pull 類問題第一輪為什麼不先看 `logs`？ #DevOps #card
	- 因為 container 根本還沒成功啟動
	- 這時重點是 Pod 狀態、waiting reason、events
	- 要先證明問題卡在 image 下載 / back-off 階段

- `ErrImagePull` 和 `ImagePullBackOff` 差在哪裡？ #DevOps #card
	- `ErrImagePull` 比較像這次拉 image 失敗
	- `ImagePullBackOff` 比較像連續失敗後進入退避重試
	- 它們常是同一條失敗流程的不同時間點

- crash loop 類問題為什麼先看 `kubectl logs --previous`？ #DevOps #card
	- 因為要回答上一輪 container 啟動後吐了什麼
	- 它直接對到已終止的前一個 container instance
	- 比只看一般 events 更接近 app / process 的死因

- 什麼時候不該直接用 selector 加 `logs --previous`？ #DevOps #card
	- 當符合條件的 Pod 可能不只一顆時
	- 因為有些 Pod 沒有 previous instance 會直接報錯
	- 最穩做法是先鎖定單一壞 Pod 再指定名稱

- rollout 類問題第一輪最穩的判讀組合是什麼？ #DevOps #card
	- 先看 `rollout status` 確認 deployment 是否卡住
	- 再看 `rollout history` 確認 revision 脈絡
	- 若要看真正失敗證據，再補 `describe deployment`

- 為什麼有些問題雖然表現在 Pod，切點卻不在 Pod？ #DevOps #card
	- Pod 常常只是症狀承載點
	- 根因可能在 Deployment、Service、Ingress 這些上游物件
	- 排查時要問是 Pod 自己壞了，還是上游造成的結果

- `port-forward` 在整條排查 sequence 裡的定位是什麼？ #DevOps #card
	- 它是局部驗證工具，不是整條主線
	- 比較適合驗證某個 Pod / Service port 能不能被 debug tunnel 打到
	- 不等於正式外部流量已經健康

- 同一份 Deployment YAML 重複 apply，什麼情況才會長新 revision？ #DevOps #card
	- 關鍵不是 apply 幾次
	- 而是 `spec.template` 有沒有實質變化
	- 只有新的 Pod template 才會形成新 ReplicaSet / revision

- 1 分鐘口頭排查稿最少要保住哪四個轉折點？ #DevOps #card
	- 先講外部症狀怎麼被發現
	- 再講 `get` / `describe` / `events` 如何縮圈
	- 再講 image、crash、rollout 三種分流
	- 最後講修復邊界與 `port-forward` 的定位
