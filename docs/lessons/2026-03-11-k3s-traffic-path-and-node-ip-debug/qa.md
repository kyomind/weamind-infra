# 2026-03-11 K3s Traffic Path And Node IP Debug QA

> 原則：每題都先回到 repo 檔案或既有架構文件，不直接背名詞。
> 這份 QA 的重點是流量路徑、責任邊界與 debug sequence，不是一般 Kubernetes 教科書。

## Q1

### 題目

在 WeaMind 這個專案裡，一個來自 LINE 的 webhook 請求，從外部進來到進入 line-bot Pod 為止，完整會經過哪些層？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`
- `manifests/ingress.yaml`
- `manifests/service.yaml`

### 使用者回答摘要

- 使用者先從 LINE Platform 會把 webhook 請求送到 `k8s.kyomind.tw` 開始描述。
- 使用者指出請求會先經過 DNS，再到 Hetzner Load Balancer，之後再進入 Traefik。
- 使用者也有抓到 Ingress 規則會依照 host 與 backend service，把流量送到 `weamind-line-bot` Service 的 `80` port。
- 使用者接著對照 `manifests/service.yaml`，指出 Service 是 `ClusterIP`，會透過 selector 找到 `app: weamind` 的 Pods，並把 `80` 轉到 Pod 的 `8000`。
- 使用者對 Traefik 在 K3s 內部的實際暴露方式還不夠確定，一度推測它可能以 NodePort Service 形式存在，且兩個 worker 節點上各有一個 Traefik Pod。

### AI 修正與補充

- 整體主幹是對的，已經抓到大方向：`LINE Platform → DNS → Hetzner LB → Traefik → Ingress 規則對到 Service → Service 對到 Pods`。
- 第一個要修正的是 DNS 這段。依照 [README.md](README.md#L67) 目前 repo 內明確寫的是 Cloudflare A record 指向 Hetzner LB 的公網 IP，不是這個 repo 已確認的 CNAME 架構，所以這裡不要先講成 CNAME。
- 第二個要修正的是 Traefik 這段。以目前 repo 內已確認的資料，我們可以穩定講的是：Hetzner LB 做 TCP 443 passthrough，流量進到 K3s 內的 Traefik，由 Traefik 做 TLS termination，再依 Ingress 規則把流量送到 `weamind-line-bot` Service。這點可由 [README.md](README.md#L84) 與 [docs/WeaMind Infra核心架構.md](docs/WeaMind%20Infra核心架構.md#L12) 支撐。
- 但「Traefik 一定是 NodePort Service 形式存在」、「一定在兩個 worker 各有一個 Pod」這兩件事，這個 repo 目前沒有直接證據可讓我們講得這麼死，所以這裡要先保守，不要把推測說成已驗證事實。
- Ingress 這段要再修精準一點：[manifests/ingress.yaml](manifests/ingress.yaml#L1) 裡的 host 是 `k8s.kyomind.tw`，backend service 是 `weamind-line-bot`，port 是 `80`。
- Service 這段方向正確，但更準確的說法是：Service 不會去看「來源是不是 80 才能處理」，而是它自己對外提供一個 cluster 內的 `80` port，然後把送到這個 service port 的流量轉到 targetPort `8000`，也就是 Pod container 的 `8000`。這點可由 [manifests/service.yaml](manifests/service.yaml#L1) 與 [manifests/deployment.yaml](manifests/deployment.yaml#L1) 對起來。
- 這題目前可以先收斂成一句比較穩的說法：LINE Platform 依 webhook URL 把請求送到 `k8s.kyomind.tw`，DNS 把網域解析到 Hetzner LB 公網 IP，LB 將 443/TCP 流量 passthrough 到 K3s 內的 Traefik，Traefik 在叢集內終止 TLS 並依 Ingress 規則把流量送到 `weamind-line-bot:80`，Service 再依 selector 把流量轉到 `app: weamind` 的 Pod `8000` port。

### 狀態

- 已完成

---

## Q2

### 題目

在這條流量路徑裡，Hetzner Load Balancer、Traefik、`weamind-line-bot` Service 三者的責任邊界分別是什麼？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`
- `manifests/ingress.yaml`
- `manifests/service.yaml`

### 使用者回答摘要

- 使用者指出 Hetzner Load Balancer 是接外部流量的那一層，並且有能力把流量分給後面的 Traefik。
- 使用者也指出 Ingress YAML 中的 host 與 backend service 很明確，因此 Traefik 之後如何把流量送到 `weamind-line-bot` Service 這段相對清楚。
- 使用者認為 `weamind-line-bot` Service 這一層負責把流量分配給後面的 Pods，若有兩個 Pods 就會做負載分配。
- 使用者另外補充了一個記憶中的實作細節：Traefik 在 worker 節點上有對應入口，Hetzner LB 的設定細節是在 Hetzner 後台完成，這部分在歷史對話中有記錄。

### AI 修正與補充

- 整體邊界其實已經抓到了，只是還需要把三層的責任切得更乾淨。
- 第一層是 Hetzner Load Balancer。它是外部流量的入口，接收來自 Internet 的請求，並把流量送進 K3s 叢集前面的 Traefik。就目前 repo 的最終文件來說，穩定版本是 [README.md](README.md#L84) 與 [docs/WeaMind Infra核心架構.md](docs/WeaMind%20Infra核心架構.md#L12) 所寫的架構：LB 做 TCP 443 passthrough，TLS termination 在 Traefik。
- 第二層是 Traefik，也就是 Ingress Controller。它的責任不是負責「對外買流量」，而是當流量已經進到叢集入口後，根據 host/path 這類 HTTP 規則決定應該把請求送到哪個 Service。這點可以直接由 [manifests/ingress.yaml](manifests/ingress.yaml#L1) 支撐。
- 第三層是 `weamind-line-bot` Service。它不做 host-based routing，也不直接面向 Internet；它的責任是提供 cluster 內穩定入口，並把送到這個 Service 的流量轉給 selector 選中的 Pods。這點由 [manifests/service.yaml](manifests/service.yaml#L1) 與 [manifests/deployment.yaml](manifests/deployment.yaml#L1) 可以對起來。
- 你補的歷史細節是有價值的，而且這次確實查得到：在 [.privatedocs/weamind/5-3.md](.privatedocs/weamind/5-3.md#L514) 的歷史紀錄裡，Traefik Service 曾顯示為 `LoadBalancer`，對外入口是 `80:30417` 與 `443:31051`，而且在 [.privatedocs/weamind/4-2.md](.privatedocs/weamind/4-2.md#L650) 可看到一個 `traefik` Pod 加上三個 `svclb-traefik` Pods。這代表你記得的「Traefik 不是只有一個抽象名詞，而是真的有節點入口」這個方向是對的。
- 但這裡要修精準的是：不是 `weamind-line-bot` Service 在接外部流量，而是 Hetzner LB 接外部流量，Traefik 做 HTTP/HTTPS 層路由，`weamind-line-bot` Service 做 cluster 內穩定入口與後端 Pod 分流。
- 另一個要修的是「Traefik Controller 部署在每個 worker 各一個」這句不能直接這樣講。從歷史紀錄看，較穩的說法是：Traefik 本體是 Pod，另外 K3s 的 ServiceLB 會在節點上建立對外入口；Hetzner LB 的 targets 則是兩台 worker 的內網 IP，這點可由 [.privatedocs/weamind/4-5.md](.privatedocs/weamind/4-5.md#L392) 與 [.privatedocs/weamind/4-5.md](.privatedocs/weamind/4-5.md#L426) 支撐。
- 這題最穩的收斂版本是：Hetzner LB 負責承接外部流量並送進叢集入口；Traefik 負責根據 Ingress 規則做 L7 路由；`weamind-line-bot` Service 負責在 cluster 內提供穩定入口並把流量分配到符合 selector 的 Pods。

### 狀態

- 已完成

---

## Q3

### 題目

為什麼這個專案會特別強調 K3s 節點要綁定私有網路介面？如果節點抓錯成公網 IP，最可能先影響哪一段路徑？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`

### 使用者回答摘要

- 待填

### AI 修正與補充

- 待填

### 狀態

- 未開始

---

## Q4

### 題目

`--node-ip` 和 `--flannel-iface` 在這個專案裡各自是要修什麼問題？為什麼常常需要一起講？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`

### 使用者回答摘要

- 待填

### AI 修正與補充

- 待填

### 狀態

- 未開始

---

## Q5

### 題目

如果今天外部 webhook 打到 `k8s.kyomind.tw` 沒有進到 line-bot，第一輪排查順序在這個專案裡應該怎麼排？

### 對照檔案

- `README.md`
- `manifests/ingress.yaml`
- `manifests/service.yaml`
- `manifests/deployment.yaml`

### 使用者回答摘要

- 待填

### AI 修正與補充

- 待填

### 狀態

- 未開始