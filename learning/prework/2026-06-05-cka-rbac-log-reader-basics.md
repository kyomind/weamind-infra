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

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 repo 內對照的問題

1.
2.

