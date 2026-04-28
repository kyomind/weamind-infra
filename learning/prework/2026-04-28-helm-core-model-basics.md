# 2026-04-28 Helm Core Model Basics

## Prework 內容

### 今日焦點

- 主題：Helm 核心模型
- 範圍：先建立 Helm 是什麼、解什麼問題，以及 `chart`、`template`、`values`、`release`、`install`、`upgrade` 的最小骨架；不進入 WeaMind repo 對照、實際 chart 撰寫或 CD 設計
- 目標：把「我只會照著下 Helm 指令」補成「我至少能用白話講清楚 Helm 在做什麼」
- 時間：控制在 45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 我目前的真實狀態是：曾經用 Helm 安裝過 `kube-prometheus-stack`，但其實不懂 Helm 的核心模型；請把教學重點放在概念骨架，而不是預設我已經懂。
- 今天不要先展開 WeaMind repo 細節、Helm chart 開發實作、template 語法深水區、subchart、chart publishing 或 GitOps。

### 今天一定要學會的最小骨架

1. Helm 不是 Kubernetes 內建資源，而是用來封裝、參數化與管理 Kubernetes manifests 的套件管理與 release 工具。
2. `chart` 是可安裝的套件內容，`release` 是某個 chart 被安裝到某個 cluster / namespace 後形成的實際部署實例。
3. `values` 不是任意 yaml merge，而是 chart 作者預先暴露出來的參數入口。
4. `helm install` / `helm upgrade` 的核心，不是神奇地「直接裝好」，而是拿 chart templates 配上 values render 出 Kubernetes manifests，再交給 cluster。
5. Helm、raw manifests、Kustomize 都在解配置與部署問題，但抽象層和適合情境不同。

### 建議教學順序

1. 先用白話講 Helm 到底在解什麼問題，為什麼它不只是「比較方便的 `kubectl apply`」。
2. 再把 `chart`、`template`、`values`、`release` 各自分開講清楚，避免混成一團。
3. 接著講一次 `helm install` / `helm upgrade` 背後大致發生什麼事，不需要陷入底層實作細節。
4. 然後講 `values` 的邊界，特別是為什麼它不能被講成對任意 yaml 的自由 merge。
5. 最後用 Helm、raw manifests、Kustomize 的高階比較做收尾，只講最小差異，不要展開工具大全。

如果我卡住，請先用更白話的比喻或最小例子講一次，再讓我重述；不要直接丟術語定義給我背。

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

### 今日學到什麼

- Helm 不是 Kubernetes 內建，而是外部工具，用來封裝與管理 Kubernetes manifests。
- Helm 的核心不是「管理 YAML」，而是用 `template` 加上 `values` 生成 YAML，再送進 cluster。
- `chart` 本質上是一個有規範的資料夾，裡面包含 `templates/` 與 `values.yaml` 等內容。
- `helm install` 的最小流程是：讀 chart、合併 values、render templates、套用到 cluster，最後記錄成 release。
- `release` 不只是名稱，而是一次部署實例與歷史紀錄；Helm 的 rollback 也因此能回復整組資源，而不只是單一 Deployment。

### 已能白話講清楚什麼

- Helm 是一個工具，讓我可以把 Kubernetes YAML 做成模板，再用不同 values 產生不同環境設定，最後部署成一個 release。
- `helm install` 會拿 chart 裡的 templates，加上 values render 成 Kubernetes YAML，送進 cluster，並同時記錄成一個 release。
- `release` 是 Helm 管理一次部署的單位，裡面包含這次部署的設定與 revision 歷史，因此可以 rollback。
- `kubectl` 是直接套用 YAML；Helm 則是先生成 YAML 再套用，並多了 template、參數化與 release 管理能力。

### 目前還卡住什麼

- `values` 的邊界還需要再對回 chart 設計：哪些能改、哪些不能改，最後仍由 chart 作者決定。
- `release rollback` 和 `Deployment rollout undo` 的邊界已經有概念，但還需要回到 repo 與資源層級再驗證一次。
- chart 設計思維仍是後續主題，尤其是哪些欄位值得 expose 成 values。

### 今日最重要的觀念

- Helm 的核心可壓成：`template + values -> YAML -> Kubernetes`。
- `chart` 是模板包，不是單一 YAML。
- `values` 不是任意 YAML merge，而是 chart 預先暴露出來的參數入口。
- `release` 是部署實例，不是版本號；版本歷史體現在 revision。
- Helm rollback 回復的是整組由這個 release 管理的資源，而不只是單一 Deployment。

### 帶回 VS Code 的問題

1. 如果把現在的 manifests 變成 Helm chart，哪 3 個欄位最值得做成 values，哪些東西又不應該輕易讓人改？
2. 目前的 Deployment、Service、Ingress 若 deploy 壞掉，`kubectl rollout undo` 和 Helm rollback 各自能救回什麼、救不回什麼？
