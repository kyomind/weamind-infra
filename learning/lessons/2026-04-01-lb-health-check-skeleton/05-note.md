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

### worker-only 後端不是孤立設定

- 今天要避免把「LB 後端只放 worker」講成單一平台設定。更準確的說法是：這是 control-plane / worker 分工、Pod 排程位置、以及外部流量入口設計三者一起收斂出的結果。
- 如果 app Pod 透過 `nodeSelector` 被固定在 worker，而 LB 後端卻把 control-plane 也納進去，就會出現角色與流量不一致的設計。

### Host header 問題的真正層次

- 今天要把 `404` 放回正確層次：這不一定代表 app `/health` endpoint 壞掉，也可能是 request 根本還沒命中正確的 Ingress rule。
- 因為 `manifests/ingress.yaml` 是依 `host: k8s.kyomind.tw` 做 routing，所以沒有正確 Host header 時，Traefik 不會把流量送到 `weamind-line-bot` Service。

### passthrough 與 termination 的邊界

- 今天要收斂的是 WeaMind 的實際分工，不是泛論所有 LB 型態。
- 在這個專案裡，Hetzner LB 負責對外入口與 TCP 層轉發；Traefik 負責拿到 TLS 憑證與做 HTTP routing，兩者不要混成同一層。

## Flashcards

- 為什麼 WeaMind 的 Hetzner LB 後端只放 worker？ #DevOps #card
	- 因為 line-bot Pods 被 `nodeSelector.nodepool=worker` 固定在 worker，正常應用流量應直接送往承載 workload 的節點
	- control-plane 主要負責 API server / 叢集控制，不應作為正常對外流量後端

- 為什麼 LB Health Check 沒帶 Host header 會看到 `404`？ #DevOps #card
	- 因為 WeaMind 的 Ingress 是 host-based routing，必須命中 `k8s.kyomind.tw`
	- 沒帶正確 Host header 時，Traefik 不會把 request 轉給 line-bot Service，所以問題在 Ingress 規則命中，而不一定是 app endpoint 本身壞掉

- WeaMind 裡 TCP passthrough 與 TLS termination 怎麼分工？ #DevOps #card
	- Hetzner LB 只做 TCP 443 passthrough，把連線送進 K3s
	- Traefik 在叢集內終止 TLS，並依 Host / path 規則把 HTTP 流量轉到後端 Service

- 若 LB target 又變 unhealthy，第一輪該先拆哪幾層？ #DevOps #card
	- 先拆成 Host header / Ingress rule 是否命中、worker 與 Pod 落點是否一致、以及 TLS / 流量終止位置是否判讀錯誤
	- 不要一開始就把問題籠統叫做「LB 壞掉」
