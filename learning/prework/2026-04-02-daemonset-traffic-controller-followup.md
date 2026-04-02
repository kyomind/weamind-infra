# 2026-04-02 DaemonSet Traffic Controller Follow-up

## Prework 內容

### 今日焦點

- 主題：DaemonSet 補強 homework
- 範圍：DaemonSet 在 Kubernetes 裡到底負責什麼、它和 Deployment 差在哪裡、以及這件事如何解釋 WeaMind 裡的 `svclb-traefik`
- 目標：把「為什麼每個 node 都像有 Traefik 入口，但真正 backend endpoint 又可能只有一個」這件事講清楚
- 時間：控制在 25 到 40 分鐘

### 這份 prework 要怎麼用

這份文件雖然放在 `learning/prework/`，但定位不是正式課前預習，而是 2026-04-01 這份 lesson 後的輕量補強 homework。

把這份 outline 直接貼給外部 ChatGPT 類服務即可，不需要另外補很多 repo 背景。

它今天的任務是：

1. 用白話說明 `DaemonSet` 的核心目的：它想解決什麼問題、什麼情況下會比 `Deployment` 更適合。
2. 幫我切開 `DaemonSet`、`Deployment`、`Service` 三者的責任，不要只給教科書定義，要強調它們在流量路徑中的角色差異。
3. 直接帶入 WeaMind 的具體場景：`svclb-traefik` 為什麼是 `DaemonSet`，而真正的 `traefik` backend endpoint 卻不一定是每個 node 一個。
4. 解釋為什麼「每個 node 都可能成為入口」不等於「每個 node 都有一個真正處理 HTTP/TLS 的 Traefik backend Pod」。
5. 幫我建立一個最小口頭答題稿，讓我能用 WeaMind 的流量路徑講出：`Hetzner LB -> 某 worker -> svclb-traefik -> traefik Service -> Traefik backend -> Ingress routing -> app Service -> Pod`。
6. 最後產出一份可帶回 VS Code 的短版學習報告。

今天不要展開成完整 Kubernetes controller 大全，也不要講一堆與 WeaMind 無關的 CNI / kube-proxy 細節；重點是把 `DaemonSet` 在這個專案裡的存在意義補穩。

### 今天一定要學會的最小骨架

1. `DaemonSet` 的關鍵不是「很多 Pod」，而是「每個符合條件的 node 各跑一個」。
2. `Deployment` 比較像管理一組可伸縮的 app replicas；`DaemonSet` 比較像把某種節點層功能鋪到整個叢集。
3. 在 WeaMind 裡，`svclb-traefik` 是把入口能力鋪到每個 node；它不是最後負責 Ingress routing 的那個唯一 backend 證據。
4. 「每個 node 都可能是入口」和「真正 backend 在哪個 node 上處理」是兩層不同問題。
5. 面對流量入口題時，不能把 `DaemonSet`、`Service`、`Endpoints`、`Ingress controller backend` 全混成同一件事。

### 建議教學順序

1. 先用白話例子講 `DaemonSet` 與 `Deployment` 各自更像哪種工作。
2. 再用一條最小 Kubernetes 流量路徑，把 `DaemonSet`、`Service`、backend Pod 各自放回位置。
3. 接著直接帶 WeaMind：為什麼 `svclb-traefik` 適合是 `DaemonSet`。
4. 然後回答這個最容易混的問題：為什麼三個 node 都像入口，但 `Endpoints` 可能只有一個 Traefik backend。
5. 最後幫我整理成短版報告與 3 到 5 個真正值得帶回 VS Code 的觀念。

如果我卡住，請先用「log agent / node exporter / ingress entry proxy」這類白話例子，不要一開始就堆太多術語。

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

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 VS Code 的問題

1. `svclb-traefik` 這種 `DaemonSet` 型入口元件，和真正的 Traefik backend endpoint 應該如何一起描述，才不會把兩層責任混掉？
2. 若未來想把 ingress 資料面更明確地固定到 worker，應優先查看哪些 Kubernetes 資源與欄位？
