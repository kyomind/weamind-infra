# Cluster 元件與設定管理

## Prework 內容

### 今日焦點

- 主題：Cluster 元件與設定管理
- 範圍：Node、kube-apiserver、kube-scheduler、kube-controller-manager、etcd、Kustomize、Helm
- 目標：先把 cluster control-plane 元件與配置管理的基本心智模型建立起來
- 時間：控制在 45 到 60 分鐘

### 這份 outline 要怎麼用

這份文件是給外部 ChatGPT 類服務做今天的純知識預習。

直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。

這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。

它今天的任務是：

1. 先幫我建立 cluster 元件的最小理解骨架。
2. 用白話方式講清楚 kube-apiserver、scheduler、controller-manager、etcd 各自負責什麼。
3. 說明 Kustomize 的 base / overlay / patch 心智模型。
4. 幫我理解 Helm 和 Kustomize 的差異，不要把兩者混成同一件事。
5. 用少量問題確認我是否真的有聽懂。
6. 最後產出一份可以帶回 VS Code 的學習報告。

今天先專注在通用知識，不進入 kubeadm 安裝、etcd 高可用、備份策略，或 Helm / Kustomize 的實作細節。

### 今天一定要學會的 4 件事

1. kube-apiserver 是所有資源操作的 API 入口。
2. scheduler 負責決定 Pod 去哪個 node，controller-manager 會持續把實際狀態拉回期望狀態，etcd 保存叢集狀態資料。
3. Kustomize 是在既有 YAML 上做組合與 patch。
4. Helm 偏向模板化與套件生命週期管理，Kustomize 偏向原生 YAML 疊加。

### 建議教學順序

1. 先講 cluster 元件大圖，再放入各元件角色。
2. 再講 kube-apiserver / scheduler / controller-manager / etcd 的分工。
3. 接著補 Kustomize 的 base / overlay / patch。
4. 最後講 Helm 與 Kustomize 的差異與取捨。
5. 用 2 到 3 個小問題確認理解。

如果我卡住，請先換一個更簡單的說法或例子，再讓我重述一次。

### 學完後請產出學習報告

請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。

下面這一段是回填模板，不是新的教學主題。

這份報告請至少包含以下內容：

1. 今日主題與學習範圍。
2. 我今天學到什麼。
3. 我已經能用白話講清楚什麼。
4. 我還卡住什麼。
5. 今天最重要的 3 到 5 個觀念整理。
6. 我回到 VS Code 後，應該拿去和 GitHub Copilot 對照 repo 的 2 個問題。

如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

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

### 帶回 VS Code 的問題

1.
2.
