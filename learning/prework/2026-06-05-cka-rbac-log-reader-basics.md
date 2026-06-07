# 2026-06-05 CKA RBAC Log Reader Basics

## Prework 內容

### 今日焦點

- 主題：CKA 題目中的 ServiceAccount、Role / ClusterRole、RoleBinding / ClusterRoleBinding 與 Log Reader 權限
- 範圍：RBAC 最小心智模型、namespaced 與 cluster-scoped 權限、`pods/log` subresource、常見 `kubectl create` 指令骨架
- 目標：建立能看懂並解出 CKA RBAC 題的最小概念骨架，不先展開完整企業權限治理
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的背景是：我正在刷 KillerCoda CKA 題庫，Architecture / Installation / Maintenance 類別中反覆出現 ServiceAccount、ClusterRole、ClusterRoleBinding、Log Reader。請先教可攜的 CKA 概念與解題骨架，不要先跳進任何特定 repo 實作。

### 今天一定要學會的最小骨架

1. ServiceAccount 是 Pod 或工作負載在 Kubernetes API 裡使用的身分，不是權限本身。
2. Role / ClusterRole 定義「可以對哪些 resource 做哪些 verbs」；Binding 才是把權限綁到 user、group 或 ServiceAccount。
3. Role 與 RoleBinding 是 namespaced；ClusterRole 是 cluster-scoped 權限定義；ClusterRoleBinding 會把權限套到整個 cluster。
4. ClusterRole 也可以被 RoleBinding 綁在單一 namespace 內使用。
5. 讀 Pod logs 通常需要對 `pods/log` subresource 有 `get` 權限，不只是對 `pods` 有 `get` 權限。
6. CKA 題目要先判斷 scope：題目要求單一 namespace，還是整個 cluster。

### 建議教學順序

1. 先用白話拆 RBAC 四件事：身分、權限定義、權限綁定、作用範圍。
2. 再比較 Role vs ClusterRole、RoleBinding vs ClusterRoleBinding，重點放在 scope，而不是背名詞。
3. 用 Log Reader 題型說明為什麼 `pods/log` 是 subresource，以及 verbs 應該怎麼選。
4. 示範最小 YAML 或命令式指令骨架：建立 ServiceAccount、ClusterRole、RoleBinding / ClusterRoleBinding。
5. 練 3 到 5 個判斷題：什麼時候用 RoleBinding 綁 ClusterRole？什麼時候不能用 ClusterRoleBinding？ServiceAccount 名稱和 namespace 怎麼指定？
6. 最後整理一條 CKA 解題流程：先看 namespace、再看身分、再看 resource / verb、最後選 binding 類型。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 repo 內後，應該拿去做專案對照的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

- 今天表面上學的是 ServiceAccount、Role、ClusterRole、RoleBinding、ClusterRoleBinding、`pods/log`，但本質上是在建立一套能套用到所有 CKA RBAC 題的解題框架。
- Kubernetes RBAC 可以先用一句話理解：誰可以對什麼做什麼。對應到題目，就是先判斷身分、resource、verb 與 scope。
- RBAC 的最小心智模型可以拆成四件事：身分、權限規則、權限綁定、作用範圍。對應到 Kubernetes 物件就是 ServiceAccount、Role / ClusterRole、RoleBinding / ClusterRoleBinding、Namespace / Cluster。
- ServiceAccount 是身分，不是權限。它代表 Pod 或 workload 以哪個身分存取 Kubernetes API，但本身不會自動帶有特殊授權。
- Role / ClusterRole 是權限定義，負責描述哪些 resources 可以執行哪些 verbs，但還沒有指定授權給誰。
- RoleBinding / ClusterRoleBinding 才是讓權限真正生效的授權動作：把某份 Role 或 ClusterRole 的權限授予 user、group 或 ServiceAccount。
- Scope 是 RBAC 題目的第一判斷點。Role 和 RoleBinding 是 namespaced；ClusterRole 和 ClusterRoleBinding 是 cluster-scoped，但 ClusterRole 可以被 RoleBinding 用在單一 namespace 內。
- ClusterRole 不一定要搭配 ClusterRoleBinding。ClusterRole 可以像共用權限模板，由不同 namespace 的 RoleBinding 引用，避免每個 namespace 都重複建立相同 Role。
- `pods` 和 `pods/log` 是不同的 RBAC 檢查項目。能 `get pods` 不代表能 `kubectl logs`，因為 Pod 本身和 Pod logs 是不同 resource / subresource。
- Log Reader 題型常見需求是先 `get/list pods` 找 Pod 名稱，再 `get pods/log` 讀 logs，所以規則常會同時包含 `pods` 與 `pods/log`。
- ServiceAccount 的完整識別通常要看 namespace 與名稱，例如 `monitoring:log-reader`，因為不同 namespace 可以有同名 ServiceAccount。
- 以後遇到 RBAC 題，先照流程判斷：scope -> subject / identity -> resource -> verb -> binding 類型，不要一開始就急著寫 YAML。

### 已能白話講清楚什麼

- ServiceAccount 是 Pod 存取 Kubernetes API 時使用的身分，不是權限本身。
- Role / ClusterRole 是權限定義，描述哪些 resource 可以被哪些 verbs 操作。
- RoleBinding / ClusterRoleBinding 是授權，把某份權限定義授予某個身分。
- RoleBinding 不是把 ServiceAccount 綁到 Role，而是把 Role 或 ClusterRole 的權限授予 ServiceAccount。
- RBAC 題目第一步不是選 YAML，而是先判斷權限要作用在單一 namespace 還是整個 cluster。
- `pods/log` 是 Pod 的 subresource，和 `pods` 是不同的權限檢查項目；能看 Pod 不代表能看 log。
- ClusterRole 可以透過 RoleBinding 限制在單一 namespace 內使用，因此 ClusterRole 不等於一定全 cluster 生效。

### 目前還卡住什麼

- `get`、`list`、`watch` 等 verbs 的差異還需要更多題目建立直覺，尤其是什麼情境只需要 `get`，什麼情境需要 `list`。
- 常見 subresources 還需要後續補強，例如 `pods/log`、`pods/exec`、`pods/attach`、`pods/portforward` 各自需要什麼權限。
- YAML 閱讀速度還需要練習。下一階段希望看到一份 RBAC YAML 時，能在 30 秒內回答：誰、可以做什麼、在哪裡做。

### 今日最重要的觀念

- ServiceAccount 是身分，不是權限。
- Role / ClusterRole 是權限定義。
- RoleBinding / ClusterRoleBinding 是授權。
- Scope 優先於名詞：先看 namespace 還是 cluster，再決定 RBAC 元件。
- `pods` 不等於 `pods/log`；能看 Pod 不代表能看 logs。

### 帶回 repo 內對照的問題

1. 目前叢集中有哪些 ServiceAccount？試著追一條完整權限鏈：`ServiceAccount -> RoleBinding -> Role / ClusterRole -> Resource / Verb`。
2. 如果未來建立 `weamind-log-reader` ServiceAccount，只允許查看 `weamind` namespace 中的 Pod logs，我會選 Role 還是 ClusterRole？RoleBinding 還是 ClusterRoleBinding？理由是什麼？
