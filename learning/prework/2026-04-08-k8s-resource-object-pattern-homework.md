# 2026-04-08 Kubernetes Resource Object Pattern Homework

## Prework 內容

### 今日焦點

- 主題：Kubernetes 資源物件的共通模型，以及 core resource 與 CRD resource 的最小差異
- 範圍：resource object、`spec` / `status`、controller、desired state、CRD、namespaced / cluster-scoped、cert-manager 只是這個 pattern 的一個例子
- 目標：建立最小骨架，理解為什麼 `Deployment`、`Secret`、`Certificate`、`Order` 這些看似不同的東西，其實都在同一套 API / controller 模型裡運作
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識補強。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多 repo 細節。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 這不是正式課前預習，而是 lesson 後的輕量補強 homework。
- 請聚焦在 Kubernetes 的通用資源模型，不要展開太多 cert-manager 安裝細節，也不要把內容擴成 Kubernetes 全科總複習。

### 今天一定要學會的最小骨架

1. Kubernetes 資源物件最小共通格式是什麼，`apiVersion`、`kind`、`metadata`、`spec`、`status` 各自代表什麼。
2. 為什麼 YAML / JSON 只是「提交給 API server 的表示形式」，而真正的資源物件是存在於 Kubernetes API / etcd / controller 流程裡。
3. `Deployment`、`Service`、`Secret` 這些 core resources，和 `Certificate`、`CertificateRequest`、`Order`、`Challenge` 這些 CRD resources，遵循的共通法則是什麼。
4. controller 在這個模型裡到底做什麼，為什麼有些物件是人建立的，有些物件是 controller 自己再建立出來的。
5. namespaced resource 和 cluster-scoped resource 的差別是什麼，以及為什麼 `Certificate` 和 `Secret` 會在 workload 自己的 namespace，但 `ClusterIssuer` 不會。

### 建議教學順序

1. 先用最白話方式解釋：Kubernetes 的 resource object 到底是什麼，不要一開始就堆術語。
2. 再拆 `apiVersion`、`kind`、`metadata`、`spec`、`status` 這幾個欄位，並用 `Deployment` 當第一個例子。
3. 接著說明 controller / reconcile loop / desired state 之間的關係，讓我知道為什麼這些物件不是被動記錄，而是會產生控制效果。
4. 然後比較 core resource 與 CRD resource：它們共用哪套規則，又在哪些地方不同。
5. 最後才用 cert-manager 當例子，說明 `Certificate`、`CertificateRequest`、`Order`、`Challenge`、`Secret` 各自在這套模型裡扮演什麼角色。

### 額外要求

- 請特別回答下面這幾個我目前最在意的問題：
  1. YAML 到底是不是資源物件本身，還是只是描述資源物件的文件？
  2. 為什麼有些物件是我手動建立的，有些物件是 controller 之後再自動建立的？
  3. `Certificate` 這種 CRD 物件，和 `Deployment` 這種核心物件，最本質的共同點是什麼？
  4. `Secret` 比較像最終資料本體，而 `Certificate` / `Order` 比較像狀態物件，這樣理解為什麼只對一半？
- 請避免過度數學化或過度底層化，不需要講到 etcd 實作細節、controller-runtime 原始碼或完整 API machinery。
- 請多用 2 到 3 個簡短對照表，幫我把 core resource、CRD、controller-created resource 之間的關係一次看清楚。

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

- Kubernetes 的核心是 resource object，而不是 YAML 檔本身。
- resource object 會以 state 的形式存在於 Kubernetes API / etcd / controller 流程裡；YAML / JSON 只是提交給 API server 的表示形式。
- 所有資源都有一套共同骨架：`apiVersion`、`kind`、`metadata`、`spec`、`status`。
- `spec` 比較像 desired state，`status` 比較像 current state；controller 透過 reconcile loop 持續讓現實狀態往 `spec` 靠攏。
- core resource 與 CRD resource 在運作模型上本質相同，差別主要在於：前者是 Kubernetes 內建、後者是透過 CRD 註冊並搭配外掛 controller。

### 已能白話講清楚什麼

- Kubernetes 比較像宣告狀態的系統，不是逐步執行命令的系統。
- `Deployment` 不直接管 Pod，而是透過 `ReplicaSet` 來解耦版本更新與數量維持。
- YAML 比較像建立或更新 resource object 的文件，不等於 resource object 本身。
- controller 是讓 `spec` 變成真實效果的關鍵角色，所以資源物件不是被動記錄。
- cert-manager 這條 `Certificate -> Secret` 的路徑，本質上也是一串 resource object 狀態轉換。

### 目前還卡住什麼

- controller 內部更細的實作方式，像它到底怎麼 watch、怎麼決定要建立哪些後續物件，還沒有真的掌握。
- 不同 controller 之間如何協作，以及它們和 API server / etcd 的互動細節，現在還不需要，但之後值得補。

### 今日最重要的觀念

1. Kubernetes = state + controller，不只是 YAML。
2. `spec` vs `status` 可以先理解成 desired state vs current state。
3. controller 的核心工作是 reconcile，而不是一次性執行完就結束。
4. CRD 不是特例，而是 Kubernetes API 可擴充模型的自然延伸。
5. `Deployment`、`Secret`、`Certificate`、`Order` 這些資源在本質上都屬於 resource object，只是語意與 controller 不同。

### 帶回 VS Code 的問題

1. 在 WeaMind 裡，`Deployment -> ReplicaSet -> Pod` 這條鏈如何直接對回實際 `kubectl` 輸出，而不是只停留在概念圖？
2. 在 WeaMind 的 cert-manager 流程裡，當建立 `Certificate` 之後，哪些 resource 是我手動宣告的，哪些是 controller 後續自動建立的？
