# TODO: Cloudflare Tunnel 入口方案評估

整理日期：2026-05-04

## 1) MEMOS

### 給全新 AI session 的背景摘要

WeaMind 目前是小型 K3s / DevOps portfolio 專案，不是大型企業 production 平台。正式 app 入口目前走 Hetzner LB + Traefik：

`LINE -> k8s.kyomind.tw -> Hetzner LB TCP 443 passthrough -> K3s Traefik TLS termination -> Ingress -> weamind-line-bot Service -> Pods -> bastion PostgreSQL/Redis`

使用者正在評估未來若增加第 2、3 個服務，例如 Grafana、其他 Bot、side project，是否要用 Cloudflare Tunnel 取代或補充 Hetzner LB。這不是單純省 7.5 EUR 的問題；使用者重視的是做法是否正當、是否符合個人專案與 homelab 的主流實務，而不是為了省錢硬做奇怪架構。

### 當前進度

已釐清 Cloudflare Tunnel 的標準模型不是 Cloudflare 直接打 node 公網 IP，而是 cluster 內的 `cloudflared` 主動對外連到 Cloudflare，外部流量再沿著已建立的 tunnel 回到 cluster。

較準確的 tunnel 路徑是：

`User / LINE -> Cloudflare edge -> Cloudflare Tunnel -> cloudflared Pod -> Traefik Service -> Ingress -> app Service -> Pods`

也已形成初步判斷：Cloudflare Tunnel + Traefik 不是邪門歪道。對 homelab、小型 K3s、個人 self-hosted、Grafana / side project 這類場景，它可以算是成熟且常見的小主流。但在傳統 production Kubernetes 對外入口裡，`Cloud LB -> Ingress Controller / Gateway` 仍然是最標準、最容易被團隊理解的模型。

### 關鍵決策與理由

目前建議不要立刻替換 WeaMind production LINE webhook 的 Hetzner LB。

理由：

- 現有 Hetzner LB + Traefik 架構沒有錯，也不笨；它已經符合標準 `LB -> Ingress Controller -> Service -> Pod` 模型。
- 多服務 routing 的主角本來就是 Traefik，不是 LB 或 Tunnel。新增 HTTP/HTTPS 服務時，通常新增 Ingress host rule 即可，不需要每個服務一個 LB。
- Cloudflare Tunnel 的主要價值是 outbound connector / Zero Trust edge / origin 不暴露 inbound port，而不是單純省錢。
- Cloudflare Tunnel 對個人 K3s / homelab 是正當方案，但直接替換 production webhook 會同時改變入口、TLS、debug path、failure mode，風險不值得一次吃下。

目前推薦的落地策略：

`LINE production -> Hetzner LB -> Traefik -> WeaMind`

`lab / Grafana hostname -> Cloudflare Tunnel -> cloudflared -> Traefik -> Grafana`

也就是先雙軌驗證，用 Grafana 或 lab hostname 當 Cloudflare Tunnel 的第一個實驗服務；跑穩後再判斷是否值得替換 production 入口。

## 2) 討論紀錄

### 已知條件

- WeaMind 目前只有 app tier 在 K3s；PostgreSQL、Redis、weamind-data 仍在 bastion VM。
- Cloudflare 目前已作為 DNS provider，並搭配 cert-manager DNS-01 管理 `k8s.kyomind.tw` 憑證。
- Hetzner LB 目前做 `443` TCP passthrough，不做 TLS termination；TLS termination 在 K3s 內的 Traefik。
- `weamind-line-bot` Service 是 `ClusterIP`，正式對外入口由 Hetzner LB + Traefik 承接。
- 使用者不是真的差 7.5 EUR；成本是考量，但不是主因。
- 使用者偏好正統、可解釋、可維護的實務做法，不想採用過度冷門或邪門的 workaround。

### 本次討論要點

- Cloudflare Tunnel 可行，但不應被講成全面取代 Hetzner LB 的唯一正解。
- 標準 Cloudflare Tunnel 不要求 Cloudflare 直接打 node 公網 IP；它依賴 cluster 內 `cloudflared` 主動連外。
- 這會把風險模型從 inbound exposure 轉成 outbound connector dependency。
- `cloudflared` 可用多 replica 提高 connector 可用性，但不應理解成完整傳統 LB 替代品。
- 若 Tunnel terminates TLS at Cloudflare，內部 `cloudflared -> Traefik` 可以走 HTTP，這會改變目前 cert-manager / Traefik TLS 的責任邊界。
- 若仍要保留 Traefik TLS + cert-manager，就需要額外釐清 Cloudflare 到 origin 的 TLS 模式、hostname、憑證信任與 redirect 行為。
- Reddit / homelab / self-hosted 社群中，Cloudflare Tunnel + Traefik / K3s 是常見做法，特別適合個人 self-hosted、Grafana、管理介面、side project。
- X.com 上訊號較零碎，較不適合作為社群共識來源；Reddit、官方文件、Traefik forum、個人 homelab blog 更有參考價值。
- Grok 的整理方向大致可參考，但部分措辭太滿：
  - 「官方強烈推薦」應改成「官方正式支援並提供 Kubernetes 部署方式」。
  - 「自動 HA」應改成「可多 replica 提高 connector 可用性」。
  - 「多服務最強」應修正為「多服務 routing 仍由 Traefik 承擔；Tunnel 改變外部入口模型」。

### Senior practitioner 版結論

Cloudflare Tunnel 可以列為小型 K3s / homelab / 個人作品集的正當入口方案，但不要急著把現有 Hetzner LB 換掉。先用第二個服務做實驗，跑穩再決定是否替換 production webhook。

它不是邪門歪道。對個人 DevOps、小型自架、K3s、Grafana、side project 這個等級，`Cloudflare Tunnel + Traefik` 已經算是小主流。它的核心價值不是省 7.5 EUR，而是：

- 不開 inbound port
- 不讓 node / origin 直接暴露
- Cloudflare 負責 public edge
- Traefik 繼續負責 cluster 內 L7 routing
- 新增服務時主要是加 hostname / Ingress 規則

### 三種入口方案比較

| 方案 | 評分 | 適合程度 | 主要優點 | 主要問題 | 對 WeaMind 的判斷 |
| --- | --- | --- | --- | --- | --- |
| Hetzner LB + Traefik | 10/10 | 目前 production 主線 | 最接近標準 Kubernetes production 模型；`External LB -> Ingress Controller -> Service -> Pod` 很好解釋；LB 負責外部入口與 health check，Traefik 負責 TLS termination / L7 routing，Service 負責 cluster 內穩定入口 | 每月多一筆 LB 成本；origin 仍有正式 inbound edge；需要維護 LB health check 與 worker target 狀態 | 保留作為 WeaMind production LINE webhook 入口。這條路徑最穩、最清楚，也最適合作為目前的面試主線 |
| Cloudflare Tunnel + Traefik | 8/10 | homelab / 小型 K3s / lab service / admin UI | 對個人 self-hosted 是成熟且常見的小主流；不需要開 inbound port；origin / node 不直接暴露；Cloudflare 負責 public edge；Traefik 仍可保留內部 routing；適合搭 Cloudflare Access 做管理入口 | 不是傳統 production Kubernetes 第一主流；failure mode 較 Cloudflare-specific；多了 `cloudflared`、tunnel token、Cloudflare route、TLS / redirect 邊界等新依賴 | 值得做，但先拿 Grafana 或 lab hostname 驗證。不要第一步就替換 production LINE webhook |
| Bastion + HAProxy | 3-4/10 | 省錢 workaround，不建議作主線 | 便宜；元件直覺；熟悉單機 reverse proxy 的人容易理解；小流量下可以跑 | bastion 已承載 PostgreSQL / Redis / 管理入口，再加 public HAProxy 會混淆資料層、管理層、入口層；TLS、health check、HAProxy config / reload 都要自己維護；新增服務會回到手刻 reverse proxy；作品集上像是為省錢繞路 | 不建議。除非只是短期救急或非常明確的實驗，不應成為 WeaMind 的入口主線 |

簡短判斷：

`LB 是正統主線 10 分；Cloudflare Tunnel 是小型自架裡成熟的替代入口 8 分；Bastion HAProxy 是能跑但不漂亮的省錢 workaround，大概 3 到 4 分。`

## 3) 待辦與建議

### 建議下一步

1. 保留目前 production LINE webhook 入口不變：

   `LINE -> Hetzner LB -> Traefik -> WeaMind`

2. 選一個低風險服務作為 Cloudflare Tunnel 實驗入口，優先候選：

   - Grafana lab hostname
   - 非 production side project
   - 只供個人使用的 internal dashboard

3. 設計第一版 Cloudflare Tunnel 實驗路徑：

   `grafana-lab.kyomind.tw -> Cloudflare Tunnel -> cloudflared -> Traefik -> Grafana`

4. 在實作前先寫一份 mini RFC，回答以下問題：

   - 這個 tunnel hostname 是 public 還是需要 Cloudflare Access 保護？
   - Cloudflare 到 origin 要走 HTTP 還是 HTTPS？
   - 若走 HTTPS，Traefik / cert-manager / origin cert 如何分工？
   - `cloudflared` Deployment 要放在哪個 namespace？
   - tunnel token / credentials 要放哪個 Secret？
   - `cloudflared` replica 數量要設多少？
   - 發生 502、redirect loop、TLS mismatch 時如何排查？
   - rollback 是刪 Public Hostname、停 Deployment，還是切 DNS？

5. 若要進入實作，先做 lab，不動 production：

   - 新增 `cloudflared` namespace 或放入既有 infra namespace。
   - 建立 Cloudflare Tunnel 與 credentials Secret。
   - 建立 `cloudflared` Deployment。
   - 讓 tunnel 指向 Traefik 的 cluster 內 Service。
   - 新增一個 lab hostname。
   - 對應新增或調整 Grafana Ingress。
   - 驗證外部連線、Cloudflare Access、Traefik routing、Grafana login、Pod logs。

6. 實驗完成後再決定是否擴大：

   - 若只用於 Grafana / admin UI：可長期保留作為 Zero Trust 管理入口。
   - 若要替換 WeaMind production webhook：需另開正式決策，不要直接沿用 lab 結論。
   - 若保留雙軌：在 README 或 docs 中明確說明 production edge 與 lab / admin edge 的差異。

### 後續 AI 建立行動方案時的注意事項

- 不要把 Cloudflare Tunnel 當成「免費 LB」來推；要把它當成另一種入口模型。
- 不要把 Cloudflare Tunnel 寫成比 Hetzner LB 全面更正統；它在 homelab / small self-hosted 很正當，但傳統 production K8s 仍常見 Cloud LB + Ingress / Gateway。
- 不要先動 LINE webhook。先拿 Grafana 或 lab hostname 驗證。
- 不要混淆 DNS、TLS termination、Traefik routing、cert-manager 的責任。
- 如果要更新 repo docs，應清楚保留目前正式架構，並把 Cloudflare Tunnel 標成 future / lab / alternative edge pattern。
- 若進一步查社群資料，優先查 Cloudflare 官方文件、Traefik forum、Reddit `r/selfhosted` / `r/homelab` / `r/kubernetes`，X.com 僅作為輔助訊號。

### 可驗收成果

- 有一份 mini RFC 說清楚 Cloudflare Tunnel 在 WeaMind 裡的定位。
- 有一個非 production hostname 透過 Cloudflare Tunnel 成功進到 Traefik。
- Grafana 或其他 lab service 可透過 Cloudflare Access 保護後存取。
- 文件能清楚對比：
  - Hetzner LB model：`external LB -> Traefik -> Service -> Pod`
  - Cloudflare Tunnel model：`Cloudflare edge -> cloudflared outbound tunnel -> Traefik -> Service -> Pod`
- 能形成一段面試 / portfolio 可講版本：為什麼 production webhook 先保留 LB，而管理介面或 lab service 可以採 Tunnel。
