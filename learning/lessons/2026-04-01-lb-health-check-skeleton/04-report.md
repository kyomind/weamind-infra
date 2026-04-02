# 2026-04-01 LB Health Check Skeleton Report

## 今日主題

- 把 WeaMind 的 Hetzner LB 設計、Health Check Host header incident，以及 TCP passthrough / TLS termination 分工收斂成可重講的骨架。

## 狀態

已完成 QA、command 與 implementation 收斂，已能作為這份 lesson 的正式結論頁。

## QA 收斂了什麼

- 已把「LB 後端只放 worker」拆成兩層：`nodeSelector` 決定 workload placement，LB target 決定 traffic entry placement；兩者共同服務於 control-plane / worker 的角色隔離。
- 已釐清 Hetzner LB health check 為什麼需要正確 `Host` header：`Ingress.rules.host` 在 HTTP 層實際就是靠 `Host` 值做匹配，未命中時 Traefik 會先回 `404`。
- 已把 Hetzner LB、`cert-manager`、Traefik 的分工拆清楚：LB 只做 TCP passthrough，`cert-manager` 負責憑證生命週期，真正做 TLS termination 與後續 HTTP routing 的是 Traefik。
- 已建立 `target unhealthy` 的第一輪判斷順序：先看 health check 條件與 Ingress host/path 命中，再看 worker / backend 落點，最後才看 TLS / termination 是否被誤判。

## 使用者原本卡住什麼

- 原本容易把 control-plane 是否是 LB target、control-plane 是否仍具本地入口能力、以及 Traefik backend 落在哪個 node 上這三件事混在一起。
- 原本對 `Host` header、Hetzner LB `Domain` 欄位、以及 `Ingress.rules.host` 三者之間的對應關係還不夠穩。
- 原本對 `curl -I`、`curl -L` 在測什麼，以及為什麼 `405` 不能直接等同於 redirect 結論，還沒有完全掌握。

## 今日 command 練習收斂

- 已用 K3s node 上的「有 `Host`」與「沒 `Host`」對照，直接證明 `/health` 的 `200 / 404` 差異來自 Traefik 的 host-based routing，而不是 app endpoint 壞掉。
- 已用 `pods -o wide` 與 `deployment -o yaml` 的搭配，區分「當下觀察」與「長期排程約束」：Pod 確實跑在 worker，而 `nodeSelector.nodepool=worker` 才是讓這件事不是偶然的主證據。
- 已用 `DaemonSet / Service / Endpoints` 三層看懂 Traefik：三個 node 都能成為入口，是因為 `svclb-traefik` 在每個 node 鋪入口；真正 backend endpoint 當下則可以只有一個。
- 已釐清 WeaMind 目前沒有做 HTTP→HTTPS redirect，而且外部 HTTP 與 HTTPS 都能直接命中 `/health`；同時也釐清 `curl -I` 看到的 `405` 是因為 `/health` 不接受 `HEAD`，不是 redirect 證據。
- 已把 Hetzner LB 的 health check 獨立切到 `443 + TLS` 並驗證 targets 仍維持 healthy，證明 health check advanced settings 在這個案例裡可與 listener 邊界分開理解。
- 已用 Traefik `Middleware + Ingress annotation` 成功補上 `HTTP -> HTTPS redirect`，並外部驗證 `http://k8s.kyomind.tw/health` 會先回 `301`，跟隨後能成功到 `https://k8s.kyomind.tw/health` 並回 `200`。

## 今日真正留下來的核心收穫

- LB / Ingress / Traefik / Service / Pod 必須分層看，不能把任何一層的成功或失敗直接簡化成「app 壞了」或「LB 壞了」。
- WeaMind 這個專案最有價值的理解，不是背 Kubernetes 名詞，而是能用 repo 證據把設計取捨、incident 與 runtime 行為連成同一條解釋鏈。
- `Host` header、node 入口能力、TLS termination、worker-only placement 這些看似分散的問題，其實都能回到同一條流量路徑來理解。
- 這次還多收斂出一個很實用的工程判斷：**Hetzner 的 listener/service 邊界與 health check advanced settings，不應混成同一件事看。** 前者關乎 termination 邊界，後者在這個案例裡則可獨立調整。

## 學完後已能講清楚什麼

- 為什麼 Hetzner LB 後端只放 worker，而不是把 control-plane 一起放進去。
- 為什麼同一個 `/health`，帶正確 `Host` 會回 `200`，沒帶時會回 `404`。
- 為什麼 Hetzner LB 在 WeaMind 只做 TCP passthrough，而 TLS termination / HTTP routing 落在 Traefik。
- 為什麼 control-plane 不是 Hetzner LB target，但在目前 K3s runtime 狀態下仍可能具備本地入口能力。
- 為什麼 WeaMind 目前 HTTP 仍可從外部命中，以及這和「已經有 TLS」是不同層次的問題。
- 為什麼 WeaMind 最後能在 **不把 TLS termination 拉回 Hetzner LB** 的前提下，同時做到 **HTTPS health check** 與 **HTTP→HTTPS redirect**。

## 仍需補強的地方

- Traefik backend 為什麼目前落在 control-plane，以及若要把 ingress workload 更明確固定到 worker，應該怎麼驗證與調整。
- `DNS-01 vs HTTP-01` 與 WeaMind 目前入口策略、redirect 設計之間的完整關係，留待 Week 5 的 certificate 主題展開。
- Traefik annotation 與 controller-specific metadata 的一般化理解，之後可再補到 Kubernetes metadata / controller pattern 的更通用視角。

## 下一步

- 若要延續這份 lesson 的工程 follow-up，可補做一次 manifest 回看與 rollback 路徑整理，確保未來知道要回退哪兩個 YAML 與哪個 Hetzner health check 設定。
- 若回到學習計畫主線，接續 W4 後續主題或在 Week 5 進入 `DNS-01 vs HTTP-01 與 WeaMind 的情況`。
