# Traffic Path: Traefik / Hetzner LB

- 歷史對話可查證：Traefik service 曾顯示為 `LoadBalancer`，對外入口為 `80:30417/TCP,443:31051/TCP`。
- 依歷史紀錄，曾看到 `traefik` Pod + 3 個 `svclb-traefik` Pods，表示 K3s ServiceLB 參與對外入口建立。
- 依歷史紀錄，Hetzner LB 的 targets 是兩台 worker 的內網 IP，不含 control-plane。
- 回答 Day 2 流量路徑時，可穩定說：外部流量由 Hetzner LB 承接，進入 Traefik 入口後，再由 Ingress 規則轉到 app Service。
- 回答時避免直接講死成「每個 worker 各一個 Traefik Pod」；較穩的說法是 Traefik 有 Pod，本體前面由 K3s ServiceLB / NodePort 類入口承接，LB 則打到 worker 節點入口。
- 若要追原始脈絡，可回查 `.privatedocs/weamind/4-2.md`、`.privatedocs/weamind/4-5.md`、`.privatedocs/weamind/5-3.md`。
