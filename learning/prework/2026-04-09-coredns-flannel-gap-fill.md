# 2026-04-09 CoreDNS / Flannel Gap Fill Prework

## Prework 內容

### 今日焦點

- 主題：CoreDNS 與 Flannel 的最小骨架，以及它們在 WeaMind 這種 K3s 架構裡各自站在哪一層
- 範圍：CoreDNS 的 service discovery / cluster DNS、Flannel 的 Pod 網路 / overlay 網路、它們和 Ingress / Service / app 設定的邊界
- 目標：補上先前 lesson 沒特別展開的基礎元件，讓我回到 VS Code 後能把這兩個元件對回 WeaMind 的 repo 與 debug 故事
- 時間：30 到 45 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識補強。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多 repo 細節。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 這是一份收尾日的小型 prework，不是完整新主題；請保持聚焦，只補今天 QA 會用到的最小骨架。
- 請特別幫我分清楚：CoreDNS 不等於外部 DNS 代管、Flannel 不等於 Ingress 或 kube-proxy、而且它們和 Traefik / Service / Pod 各自不在同一層。

### 今天一定要學會的最小骨架

1. CoreDNS 在 Kubernetes 裡解的是什麼問題，為什麼 Pod 可以解析像 `kubernetes.default.svc.cluster.local` 這種名稱。
2. CoreDNS、外部 DNS（例如 Cloudflare）、Ingress、Service 四者各自回答的是哪一類問題。
3. Flannel 在 K3s 裡主要解的是什麼問題，為什麼它和 Pod-to-Pod / node-to-node 網路、overlay 網路有關。
4. `--node-ip` 與 `--flannel-iface` 為什麼常常一起出現，以及它們各自修的是哪一層。
5. 在像 WeaMind 這種「app 進 K8s、PostgreSQL / Redis 留在 VM」的架構裡，為什麼 CoreDNS 看起來比較不顯眼，但 Flannel / 節點私網設定仍然很重要。

### 建議教學順序

1. 先用最白話方式解釋 CoreDNS 與 Flannel 各自在解什麼問題，不要一開始就丟很多術語。
2. 再把 CoreDNS 和外部 DNS、Ingress、Service 分開比較，讓我知道哪些是名字解析、哪些是流量轉送。
3. 接著解釋 Flannel、CNI、overlay network 的最小關係，但不用展開到各種 CNI 產品總比較。
4. 然後說明 `--node-ip` 與 `--flannel-iface` 的差別，最好用 Hetzner 私網 / 公網介面的例子來講。
5. 最後用 1 到 2 個小情境收斂：像是「Pod 解析得到 service name 但流量還是不通」以及「為什麼 app 直接連 VM 私網 IP 時，CoreDNS 不是主角」。

### 額外要求

- 請特別回答下面這幾個我目前最在意的問題：
  1. 為什麼 `k8s.kyomind.tw` 這種外部 domain 不歸 CoreDNS 管，但 `kubernetes.default.svc.cluster.local` 歸它管？
  2. Flannel 和 kube-proxy / Service / Ingress 的差別最短怎麼講？
  3. 如果 Pod 之間的 overlay 網路出問題，最典型會先影響哪一類現象？
  4. 在 WeaMind 這種架構裡，什麼情況下我才會主動想到 CoreDNS，什麼情況下更像 Flannel / 私網介面問題？
- 請避免把內容擴成整套 K8s networking 課程，也不要展開 Calico、Cilium、kube-dns 歷史細節。
- 若可以，請用 2 到 3 個小對照表，把 CoreDNS / 外部 DNS / Service / Ingress 與 Flannel / kube-proxy / Traefik 的邊界整理清楚。

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

1.
2.