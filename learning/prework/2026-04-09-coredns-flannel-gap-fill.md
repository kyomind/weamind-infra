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

- 這次 prework 聚焦在補齊 Kubernetes networking 的兩個基礎元件：`CoreDNS` 與 `Flannel`，並把它們和 `Service`、`kube-proxy`、`Ingress`、外部 DNS 之間的邊界重新切清楚。
- 我更清楚 `CoreDNS` 在 Kubernetes 裡主要解的是 cluster 內部的 service discovery，也就是把 service name 解析成 `ClusterIP`；它不負責 `Pod IP`、不做 load balancing，也不負責像 `k8s.kyomind.tw` 這類外部 domain。
- 我把 `Service` 的角色重新講清楚了：它比較像一個穩定入口與抽象層，本質上是固定的 `ClusterIP` 加上一組對到後端 `Pods` 的 endpoints，而不是 Pod 本身。
- 我也補起了 `kube-proxy` 在這條鏈裡的角色：流量打到 `ClusterIP` 之後，真正負責把流量轉到某個後端 Pod 的，是 `kube-proxy` 而不是 `CoreDNS`。
- 我對 `Flannel` 的定位也更穩了：它是 K3s 目前用來解 Pod 網路連通性的 CNI 元件，重點不是「流量去哪一個 Pod」，而是「不同 node 上的 Pods 到底能不能互相通」。
- 今天另一個重要收穫是把 `overlay network` 與 `underlay network` 分開理解：Hetzner private network 是 underlay，`Flannel` 透過 `VXLAN` 在它上面建立 Pod 的 overlay 網路。
- 我也正式把 `Pod IP` 與 `ClusterIP` 的差異切清楚：`Pod IP` 是真實 endpoint，`ClusterIP` 是虛擬入口；因此更完整的最小流量鏈是 `Pod -> ClusterIP -> kube-proxy -> Pod`。
- 我知道 Pod 的確可以直接打另一個 Pod IP，但這樣會失去穩定抽象、load balancing 與 endpoint 可替換性，因此實務上通常不把它當成主要介面。
- 我也釐清了 `CoreDNS` 和外部 DNS 的分工：`CoreDNS` 管 cluster 內的 service name；像 `Cloudflare` 這類外部 DNS 才負責公網 domain。當 Pod 查外部 domain 時，`CoreDNS` 才是扮演 forwarder，而不是 authoritative source。
- 我另外補上 K3s 常見預設網段的概念：`Pod CIDR` 常見是 `10.42.0.0/16`，`Service CIDR` 常見是 `10.43.0.0/16`，但這些是發行版預設，不是 Kubernetes 規格強制。
- 在 WeaMind 脈絡下，我更清楚為什麼 `CoreDNS` 看起來比較不顯眼：因為這個專案裡 app 連 PostgreSQL / Redis 走的是 VM 私網 IP，不是 cluster 內的 service name；反過來，`Flannel` 與私網介面設定則直接影響 Pod 跨 node 通訊穩定性，因此更接近這個專案的關鍵基礎能力。
- 今天也額外建立了一條很實用的 debug 分類法：name 解析失敗先懷疑 `CoreDNS`，有 IP 但 timeout 先懷疑 `Flannel` / 網路層，打 `ClusterIP` 不對再看 `Service` / `endpoints` / `kube-proxy`，外部打不進來才優先查 `Ingress` / `LB`。

### 已能白話講清楚什麼

- `CoreDNS` 是 Kubernetes 內部 DNS，只負責把 service name 解析成 `ClusterIP`，不負責流量分配，也不是外部 DNS 代管服務。
- `Service` 提供的是穩定入口與抽象層，真正把流量轉到某個 Pod 的通常是 `kube-proxy`；所以 Kubernetes networking 不能只講 DNS 或只講 Service。
- `Flannel` 是負責 Pod 網路連通性的 CNI，透過 `VXLAN` 這類封裝方式在 node 的真實網路之上建立 overlay network，讓不同 node 上的 Pods 可以互通。
- `overlay network` 不是額外一張真實網卡，而是邏輯網路；底下真正承載封包的仍是 Hetzner private network 這類 underlay。
- 若用一句話壓縮今天的收穫，我已經能講成：Kubernetes networking 的最小骨架是 DNS 找入口、Service 做抽象、`kube-proxy` 做分流、CNI 負責連通。

### 目前還卡住什麼

- `kube-proxy` 更底層的實作方式，例如 `iptables` 與 `IPVS` 的差異，現在還沒有正式展開。
- `CoreDNS` 自己的設定檔、`ConfigMap` 與 upstream forwarding 細節，目前只建立了功能定位，還沒進入實作層。
- `Flannel` 在 Linux 上實際的 routing / interface 呈現，例如 `flannel.1` 與封包路徑，還值得之後補一輪。
- `VXLAN` 封包更底層地怎麼進出 Linux network stack，目前知道概念，但還不算真正掌握。
- `NetworkPolicy` 會怎麼影響 Pod-to-Pod 流量，今天還沒有一起展開。

### 今日最重要的觀念

- `CoreDNS` 不等於外部 DNS；它主要管理 cluster 內 `.svc.cluster.local` 這類 service discovery。
- `Service` 不是 Pod，本質是穩定入口與抽象層；`ClusterIP` 是虛擬入口，不是後端實體 endpoint。
- 真正做 `ClusterIP -> Pod` 分流的是 `kube-proxy`，不是 `CoreDNS`。
- `Flannel` 解的是 Pod 網路「能不能通」的問題，不是 Ingress routing，也不是決定哪個 Pod 接流量。
- `overlay network` 是透過封裝建立在 underlay 之上的邏輯網路，不是另一套獨立實體網路。

### 帶回 VS Code 的問題

1. 在 WeaMind 目前 repo 與既有 debug 故事裡，`Service`、`selector`、`endpoints`、`Pod IP` 這四者最穩的對照方式是什麼？哪些檔案或 `kubectl` 觀察點最能直接把它們串起來？
2. 在 WeaMind 這種 app 進 K8s、PostgreSQL / Redis 留在 VM 的架構裡，什麼情況更該先想到 `CoreDNS` 問題，什麼情況更像 `Flannel` / 私網介面或 node-to-node 網路問題？