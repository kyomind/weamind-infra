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

## Flashcards
