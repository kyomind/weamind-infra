# 2026-04-01 LB Health Check Skeleton Note

## 學習注意事項

### 今日 lesson 邊界

- 今天主題是 WeaMind 的 LB 後端設計、Health Check Host header incident，以及 passthrough / termination 分工。
- 今天不展開 Hetzner LB 所有產品功能，也不展開 cert-manager / DNS-01 的完整細節。
- 今天也不把焦點放在 Service type `LoadBalancer` 的通用比較，而是只收斂 WeaMind 這條實際流量鏈。

### 今天要特別觀察的 repo 事實

- `README.md` 與 `docs/WeaMind Infra核心架構.md` 都已明確寫出：Hetzner LB 只做 TCP passthrough，TLS 終止在 Traefik。
- `manifests/ingress.yaml` 是 host-based routing，host 固定為 `k8s.kyomind.tw`。
- `manifests/deployment.yaml` 用 `nodeSelector.nodepool=worker` 把 line-bot Pods 固定到 worker。
- `PROGRESS.md` 已正式記錄：LB health check 在未帶 Host header 時會看到 `404`，補上 domain 後才恢復 healthy。

### 今天不展開的項目

- Hetzner Managed Certificate 與 Cloudflare DNS 的完整限制，今天只收斂到「為何沒有在 LB 終止 TLS」。
- Traefik 與 Nginx Ingress 的完整比較，保留到後續快問快答或補強。

## Notes

### 三個 node 都可能成為 Traefik 入口，但 LB 只選 worker

- 比較精準的說法不是「Traefik controller 部署在三個端點上」，而是：repo 證據顯示 `traefik` Pod 為 Running，且 `svclb-traefik` 會在各節點建立，所以 **Traefik 的 entrypoint 在每個 node 都有開放**。
- 這代表從叢集入口角度看，三個 node 都可能成為流量打進 K3s 的入口；不是只有兩個 worker 才具備入口能力。
- 但 WeaMind 在 Hetzner LB 的 target 配置上，刻意只填兩台 worker，而沒有把 control-plane 納入後端，所以 **真正對外承接 Hetzner LB 流量的 node 只有兩台 worker**。
- 因此要把兩件事分開講：**叢集層面可成為入口的 node 範圍**，和 **Hetzner LB 實際選了哪些 target**，不是同一個設定。
- 回答時也不要直接講死成「每個 node 都有一個 Traefik controller Pod」；目前 repo 內更穩的證據是 `svclb-traefik` 在各節點建立、entrypoint 在每個 node 開放。

### 用 Traefik Service 結構看三個入口與單一後端 Pod

- 你這次查到的 `kube-system/traefik` Service 更能把上一則 note 講清楚：它的 `Type` 是 `LoadBalancer`，`LoadBalancer Ingress` 同時列出 `10.0.0.3`、`10.0.0.4`、`10.0.0.5`，而 `80` / `443` 也各自對應到 `NodePort` `30417` / `31051`。
- 這代表 **三個 node IP 都被放進 Traefik 這個 Service 的對外入口集合裡**，所以從 Service 入口層來看，control-plane 與兩台 worker 都能接到打往 Traefik 的流量。
- 但 `describe svc` 同時也顯示 `Endpoints` 只有 `10.42.0.9:8000` 與 `10.42.0.9:8443`，表示目前後端實際對應到的是 **同一個 Traefik Pod endpoint**，不是三個 node 各有一個對應的 Traefik Pod endpoint。
- 再加上 `External Traffic Policy: Cluster`，更穩的理解是：**流量可以先進到任一個被列入入口的 node，再由 Service / kube-proxy 路徑轉送到實際的 Traefik endpoint**，而不是「打到哪個 node，就一定由該 node 本地的 Traefik Pod 處理」。
- 所以面試或複習時可以這樣講：WeaMind 的 K3s / Traefik 入口能力其實覆蓋三個 node，但 Hetzner LB 並沒有把這三個入口全都拿來當 target，而是只選兩台 worker，這是 **外層 LB target 選擇**，不是 **叢集內 Traefik Service 能力範圍** 的全部。

### 為什麼只有一個 Traefik Pod，三個 node 仍然都可能是入口

- 這裡最容易混掉的，是把 **入口層元件** 和 **實際處理 HTTP / TLS 的後端 Pod** 當成同一件事。
- 目前你查到的證據比較像這樣：`traefik` Service 把三個 node IP 都列進 `LoadBalancer Ingress`，而 `svclb-traefik-...` 是 DaemonSet，表示 **每個 node 都有一個 K3s ServiceLB 的入口代理 Pod**。
- 但 `Endpoints` 只有一個 `10.42.0.9`，表示真正被 Service 指到的 Traefik backend endpoint 當下只有一個，所以 **真正處理請求的 Traefik Pod 可以只有一個**。
- 因此比較準確的理解是：**三個 node 都能接流量進來，是因為 `svclb-traefik` DaemonSet 把入口鋪在每個 node 上；不是因為三個 node 都各自跑一個 Traefik backend Pod**。
- 流量路徑可以先暫時記成：`外部請求 -> 某個 node 上的 svclb-traefik 入口 -> traefik Service -> 單一 Traefik endpoint -> Ingress routing -> app Service -> app Pod`。

### Traefik backend 現在落在 control-plane，這樣合理嗎

- 目前這次 runtime 觀察顯示：真正被 `endpoints traefik` 指到的 backend Pod 是 `traefik-6f5f87584-g5knx`，而且它落在 `weamind-001`。若 `weamind-001` 是 control-plane，代表 **當下真正處理 Traefik 請求的 backend Pod 的確在 control-plane 上**。
- 這裡要先拆開兩件事：**外部入口從哪個 node 進來**，以及 **Traefik backend 最後在哪個 node 上處理請求**。WeaMind 的 Hetzner LB target 仍然只選兩台 worker，所以 **對外入口** 還是只從 worker 進來；但進來後，流量依然可能被 Service 轉送到 control-plane 上的 Traefik backend Pod。
- 對小型 K3s 叢集來說，這種情況 **技術上合理、也常見**，因為預設內建元件通常先求簡單可用，不一定會主動把 Ingress controller 嚴格限制在 worker。你目前查到的 `svclb-traefik` 也有 `control-plane` toleration，表示這套入口機制本來就允許 control-plane 參與。
- 但如果從 **角色隔離** 與 **維運風險控制** 來看，這不是最理想的最終狀態。因為 control-plane 的主要職責應該是叢集管理；若 Traefik backend 長期落在 control-plane，就表示 **控制面其實仍參與了部分資料面流量處理**。
- 若其中一台 worker 壞掉，只要另一台 worker 仍在 Hetzner LB target 裡，外部流量通常還是可以從剩下那台 worker 進來；而後續是否還能被轉到 Traefik backend，則要看 **control-plane 與剩餘 worker 之間的叢集內流量路徑** 是否正常。換句話說，worker 壞一台不代表入口必然全斷。
- 更貼近真實世界的常見做法通常有兩種：**把 Ingress controller 明確固定在 worker nodes**，或 **使用專門的 ingress nodes**；較少把它長期放在 control-plane 當主要資料面處理點，除非叢集很小、追求簡化，或只是暫時過渡配置。
- 另外也要校正一個容易混掉的點：**不是 DaemonSet 通常只有一個 Pod，而是 DaemonSet 通常在每個符合條件的 node 各跑一個 Pod**。這次你看到只有一個真正的 Traefik backend Pod，並不是因為 DaemonSet 天生只會有一個，而是因為 **真正的 backend 看起來不是 `svclb-traefik` 這個 DaemonSet，而是後面的 `traefik` workload 本身目前只有單一 backend endpoint**。
- 所以這一題目前最穩的短結論是：**WeaMind 現在的外部入口仍只從 worker 進來，但 Traefik backend runtime 觀察上仍落在 control-plane；對小型 K3s 這可以運作，但若追求更清楚的 control-plane / data-plane 分離，之後值得研究如何把 Traefik backend 也固定到 worker 或專用 ingress nodes。**

### Hetzner LB 的 `Domain` 為什麼最後會對應到 `Host` header

- 這裡其實是 **產品介面命名** 與 **HTTP 協定實作** 的差別。Hetzner LB 設定頁把欄位叫做 `Domain`，因為它是在問你：「這個 health check 要模擬哪個網域的請求？」
- 但當 LB 真的送出 HTTP health check request 時，它不能把「domain」這個概念直接塞進封包裡；在 HTTP 裡，這個資訊實際上是透過 **`Host` header** 來表達。
- 所以在設定畫面看到的是 `Domain: k8s.kyomind.tw`，而真正送到 Traefik 那一端時，效果等同於 request 內帶著 **`Host: k8s.kyomind.tw`**。
- 因此不要把它理解成兩套不同機制，而要理解成：**Hetzner UI 的 `Domain` 欄位，是用來決定 health check request 要帶什麼 `Host` header。**

### Traefik 做完 TLS termination 後所說的 HTTP routing，到底是什麼 routing

- 這裡的 **HTTP routing 不是 L4 routing，而是 L7 routing**。因為當 Traefik 完成 TLS termination 之後，它看到的已經不是單純的 TCP 連線，而是可以被解析的 HTTP request。
- 一旦 HTTPS 被解開，Traefik 就能根據 **HTTP 層資訊** 來決定往哪裡送，例如 `Host`、`Path`、Method，或 Ingress 規則裡宣告的 `host` / `path` 條件。這種依 HTTP 內容做判斷的轉送，就是 **L7 routing**。
- 以 WeaMind 這個專案來說，最直接的例子就是 [manifests/ingress.yaml](manifests/ingress.yaml#L9) 到 [manifests/ingress.yaml](manifests/ingress.yaml#L17) 裡的 `host: k8s.kyomind.tw` 和 `path: /`。Traefik 會先看 request 的 `Host` 是否命中，再看 path 是否命中，最後才轉到 `weamind-line-bot` Service。
- 相對地，**L4 routing** 只看連線層資訊，例如 IP、port、protocol。Hetzner LB 在這個專案的 `443 -> 443` passthrough 就比較接近這一層：它不需要理解 HTTP 內容，只是把 TCP 連線原樣轉進叢集。
- 所以這條鏈路可以記成：**Hetzner LB 做的是偏 L4 的 TCP 轉送；Traefik 在 termination 之後做的是 L7 的 HTTP routing。**

## Flashcards
