# Grafana 安全公開入口與堡壘機資源評估 Handoff

整理日期：2026-08-30

## MEMOS

### 給全新 AI Session 的快速摘要

本次從「Hetzner 堡壘機資源過剩，是否應再部署常見 self-hosted 服務」開始，實際盤點後確認：堡壘機雖有大量剩餘 RAM，但目前沒有需要用新服務解決的問題，因此決定不為了消耗資源而部署東西。

討論接著收斂到真正影響使用意願的問題：Prometheus 與 Grafana 已部署在 K3s cluster 內，但從台灣查看 Grafana 時，需要經過本機 `kubectl port-forward`、autossh、德國 control plane 與 Kubernetes port-forward stream。這條跨洲 control-plane 路徑讓 Grafana 前端資產與 API 請求非常慢，甚至可能載入失敗，所以使用者實際上很少打開 dashboard。

本次形成的決策是：

1. 現在不新增 exporters、通知服務或其他 self-hosted 服務。
2. 保留既有 Prometheus/Grafana，不搬遷，也不為了填滿 RAM 擴建 monitoring。
3. 在沒有日常查看或告警需求前，不處理 Grafana 入口。
4. 未來真的需要穩定查看 Grafana 時，第一優先不是增加 metrics，而是建立安全、正式的 GUI 入口。
5. 當時建議的最小安全方案是：

   `Browser -> Cloudflare Access (Google identity + MFA) -> Cloudflare Tunnel -> Traefik -> Grafana ClusterIP Service`

6. 第一版保留 Grafana 原生帳號密碼作第二道門，不急著整合 Grafana OAuth、auth proxy、Authentik、Authelia 或 Keycloak。
7. Prometheus UI 不公開；WeaMind production LINE webhook 入口也不因這項實驗而改動。

本次只做盤點、分析與決策，沒有修改遠端 VM、K3s、Cloudflare、Grafana、Traefik 或 DNS。

### 下一次應從哪裡開始

除非使用者明確表示「現在真的需要從公網穩定查看 Grafana」，否則不需要執行任何工作。

若需求成立，先讀：

- `docs/DONE-monitoring-port-forward-高延遲與Grafana載入異常紀錄.md`
- `docs/TODO-cloudflare-tunnel-entry-evaluation.md`
- 本文件

然後先寫一份小型實作計畫，確認 Cloudflare Access identity policy、Tunnel 到 Traefik 的路徑、TLS 邊界、Grafana hostname、rollback 與驗收方式，再進入實作。不要先動 production LINE webhook。

## 討論起點

使用者注意到 Hetzner 德國 VM 價格便宜，而堡壘機的 8 GB RAM 長期只使用約 1.2 至 1.4 GB，因此想確認：

- 堡壘機目前實際部署了什麼？
- 是否有常見、值得部署的 self-hosted 服務？
- 能否讓剩餘硬體資源產生價值？

討論原則不是「怎麼把資源吃滿」，而是「是否存在值得用新服務解決的真實需求」。

## 遠端堡壘機盤點

本次透過本機 SSH alias `bastion` 對 Hetzner VM 做唯讀檢查。

### 主機資源快照

| 項目 | 狀況 |
| --- | --- |
| RAM | 7.5 GiB total，約 1.4 GiB used，約 6.2 GiB available |
| Swap | 2 GiB，盤點時未使用 |
| Disk | 75 GB，約使用 23 GB，剩餘約 50 GB |
| Load average | 約 `0.07 / 0.05 / 0.01` |
| Docker | 10 個 running containers、6 個 Compose projects |

### 現有 Docker workloads

WeaMind：

- `wea-app-prod`
- `wea-db-prod`
- `wea-redis-prod`
- `wea-data-prod`

個人服務：

- Umami + PostgreSQL
- Wakapi
- Portainer

入口與憑證：

- Nginx
- Certbot

Compose projects：

- `weamind`
- `wea-data`
- `umami`
- `wakapi`
- `nginx-certbot`
- `portainer`

主機層另有 SSH、fail2ban、cron、unattended-upgrades、Docker/containerd 等服務。

### 對外入口

Nginx 當時代理：

- `api.kyomind.tw`
- `umami.kyomind.tw`
- `wakapi.kyomind.tw`

從外部測試只有 22、80、443 可連線；5433、6379、8000、9000 不可達。

需要保留的一項安全觀察是：WeaMind PostgreSQL 5433 與 app 8000 雖被外層防火牆擋住，但 container port 當時綁在 `0.0.0.0`。未來若改 Hetzner Firewall 或主機防火牆，不應誤將它們暴露到 Internet。

## 原先考慮過的部署項目

討論曾依實用性排列以下候選：

1. `node_exporter`、`postgres_exporter`、`redis_exporter`
2. ntfy
3. Uptime Kuma
4. Miniflux 或 FreshRSS
5. linkding
6. Vaultwarden

也排除了目前缺乏需求或維護負擔偏高的項目：

- Nextcloud
- Immich
- Jellyfin
- n8n
- Gitea / Forgejo
- 為了使用剩餘 RAM 而把 Prometheus/Grafana 搬到堡壘機

使用者看完盤點後的結論是：以上項目都沒有立即需求，因此不需要部署。

## 為什麼現在不增加可觀測性元件

原先最合理的候選是把堡壘機 exporters 接進現有 Prometheus，但後續確認：使用者連目前已有的 Grafana 都因為存取太 lag 而很少查看。

在這種情況下，增加 exporters 只會變成：

- 收集更多沒人看的資料
- 增加 ServiceMonitor、dashboard 與告警設定
- 擴大維護面
- 沒有改善真正阻礙使用的入口體驗

因此現在不增加 exporters。若未來要補堡壘機 metrics，也應先解決 Grafana 的安全、低摩擦入口。

## Grafana 很慢的真正原因

這不是 Grafana Pod 或 Prometheus 本體故障，也不只是「HTML 檔案太大」。完整資料路徑是：

```text
Browser
  -> localhost Grafana port
  -> kubectl port-forward
  -> localhost:6443
  -> autossh tunnel
  -> weamind-001 in Germany
  -> K3s API Server
  -> Kubernetes port-forward stream
  -> Grafana Pod / Service
```

既有 incident 紀錄顯示：

- 台灣到德國的跨洲 latency 約 600 至 800 ms。
- 本機經 tunnel 打 API Server `/readyz` 約需 1.35 至 1.77 秒，遠端本機只需約 0.01 秒。
- Grafana full reload 會同時載入多個 JS、CSS 與 API resources。
- 個別 Grafana JS asset 曾需約 13.2 秒。
- 部分 forwarding streams 可能 timeout，導致 `broken pipe`、載入不完整或 Grafana fallback error page。
- Service-based port-forward 比 Pod-based port-forward 更脆弱，但改成 Pod-based 只能改善，不會消除跨洲 control-plane 路徑的根本成本。

所以 `kubectl port-forward` 適合臨時 debug 或 break-glass，不適合這個情境下的長期互動式 GUI 存取。

## 未來需要時的推薦入口

### 推薦拓撲

```text
Browser
  -> Cloudflare Access
  -> Cloudflare Tunnel
  -> cloudflared Pod
  -> Traefik
  -> Grafana ClusterIP Service
```

這個模型的目的有兩個：

1. 瀏覽器走正常 HTTPS/data-plane 路徑，不再透過 Kubernetes API Server 與 `kubectl port-forward`。
2. Grafana origin 不需要公開 inbound port，Cloudflare Access 在到達 Grafana 前先完成身份驗證。

### 第一層：Cloudflare Access

第一版建議：

- 建立 Grafana self-hosted application。
- Access policy 採 deny-by-default。
- 只允許使用者指定的 Google identity/email。
- MFA 在 Google IdP 或 Cloudflare 支援的 MFA policy 層完成。
- 適度設定 Access session duration。

未通過 Access 的使用者連 Grafana login page 都看不到。

### 第二層：Grafana 原生登入

第一版保留 Grafana 原生帳號密碼：

- 關閉 anonymous access。
- 不開放自行註冊。
- admin 使用獨立、隨機長密碼。
- Grafana 維持 HTTPS 使用情境下的安全 cookie 設定。
- 正常套用 Grafana security updates。

這會形成兩道門：Cloudflare identity/MFA 加上 Grafana local login。雖然第一次可能登入兩次，但兩邊都有 session 後，日常摩擦通常有限，而且比一開始導入 auth proxy 或額外 IdP 簡單。

### 為什麼搭配 Cloudflare Tunnel

若 Grafana 同時存在可直接打到的 Hetzner LB/public origin，攻擊者可能嘗試繞過 Cloudflare Access。因此第一版最好不要替 Grafana建立另一條可直接從 Internet 到達的 origin 路徑。

建議：

- Grafana Service 維持 `ClusterIP`。
- `cloudflared` 從 cluster 主動向 Cloudflare 建立 outbound tunnel。
- Grafana hostname 只透過 Tunnel 到達。
- 不為 Grafana 開放 K3s node inbound public port。
- 不把 Grafana掛到既有 production Hetzner LB public route。

### 暫時不公開 Prometheus

Prometheus UI 比 Grafana 更接近維運內部工具，且 Grafana已能透過 datasource 查詢 Prometheus。第一版只開 Grafana，不公開 Prometheus。

需要直接操作 Prometheus UI 或 API 時，仍可把 `port-forward` 保留為臨時 debug/break-glass 路徑。

## 未來可以延伸但第一版不要做的項目

### Grafana Google OAuth/OIDC

若兩次登入真的造成明顯摩擦，之後可讓 Grafana直接使用 Google OAuth/OIDC，並考慮：

- `disable_login_form`
- 關閉 basic authentication
- `auto_login`

必須先驗證 OAuth login 與緊急復原路徑，再關閉 local login form。

### Cloudflare Access identity header + Grafana auth proxy

可讓 Grafana信任 Cloudflare Access 已驗證的 identity header，達到較接近單一登入的體驗。但這要求：

- Grafana origin 完全無法繞過 Cloudflare Access。
- Traefik/cloudflared 不允許未受信任來源偽造身份 header。
- Grafana auth proxy 信任邊界設定正確。

這比保留 Grafana local login 更容易因設定錯誤造成身份繞過，因此不建議作第一版。

### 自架 Identity Provider

目前只有單一使用者，不需要為 Grafana引入：

- Keycloak
- Authentik
- Authelia

除非未來有多個內部服務、多人、角色管理或統一 SSO 需求，否則它們的維護成本高於收益。

## 不應混淆的架構邊界

WeaMind production LINE webhook 目前仍應維持：

```text
LINE -> Hetzner LB -> Traefik -> WeaMind
```

未來 Grafana管理入口可以是：

```text
Browser -> Cloudflare Access -> Cloudflare Tunnel -> Traefik -> Grafana
```

這是刻意的雙軌入口：

- production webhook 保留標準 external LB 模型。
- admin/lab GUI 使用 Zero Trust/Tunnel 模型。

不要因為實作 Grafana Tunnel，就順手替換 LINE webhook 的 production edge。

## 待處理事項

目前沒有需要立即處理的 issue，也沒有尚未完成但已承諾要落地的實作。

只有一個由需求觸發的 future item：

> 當使用者確實需要穩定、頻繁地從公網查看 Grafana 時，再實作 Cloudflare Tunnel + Cloudflare Access + Grafana local login 的第一版安全入口。

觸發前不需要建立 placeholder manifests、Cloudflare resources、DNS record 或額外 secrets。

## 未來實作時的最小驗收標準

若 future item 被正式啟動，至少驗證：

1. 未通過 Cloudflare Access 時看不到 Grafana login page。
2. 只有指定 identity 可通過 Access，且身份層有 MFA。
3. 通過 Access 後仍須完成 Grafana登入。
4. Grafana從台灣完整載入時，不再出現既有 port-forward stream timeout 問題。
5. Grafana Service 仍為 `ClusterIP`，K3s nodes 沒有新增 Grafana public inbound port。
6. 直接打 Hetzner LB IP 或其他 origin 路徑無法繞過 Access 到達 Grafana。
7. Prometheus UI 未公開。
8. WeaMind production LINE webhook 路徑不受影響。
9. 停用 Tunnel/public hostname 後，可以快速回到原本 `port-forward` 的 break-glass 存取方式。

## 相關文件

- `docs/DONE-monitoring-port-forward-高延遲與Grafana載入異常紀錄.md`
- `docs/TODO-cloudflare-tunnel-entry-evaluation.md`
- `learning/lessons/2026-04-24-observability-targets-servicemonitor-dashboard/05-note.md`
- `docs/WeaMind Infra核心架構.md`

## 一句話結論

堡壘機有剩餘資源但沒有立即需求，所以現在不新增服務；未來若真的需要常態查看 Grafana，先以 Cloudflare Access + Cloudflare Tunnel 建立受保護的正式入口，保留 Grafana原生登入作第二道門，而不是繼續優化跨洲 `kubectl port-forward`。
