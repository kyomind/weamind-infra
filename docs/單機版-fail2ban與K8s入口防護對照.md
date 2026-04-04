# 單機版 fail2ban 與 K8s 入口防護對照

整理日期：2026-04-04

## 為什麼要補這份

前面在單機版環境中，我們已經看到一條很清楚的防護鏈：

`Internet -> Nginx -> access log -> fail2ban -> ban IP`

這條鏈在單機版很好理解，因為「看 log 的地方」和「封鎖流量的地方」通常就在同一台機器上。

但 WeaMind 目前的 K8s 版不是這種結構。它的公開流量路徑是：

`Internet -> k8s.kyomind.tw -> Hetzner LB -> Traefik -> weamind Service -> line-bot Pods -> bastion VM(PostgreSQL/Redis)`

所以同樣面對惡意掃描時，問題不再是「app log 有沒有看到」，而是「哪一層才是合理的觀察點與封鎖點」。

## 先講結論

### 1. K8s 版不是因為走內網就比較安全

K8s 版比較安全的地方，是 **資料庫與 Redis 沒有直接暴露在公網**，而不是公開入口消失了。

- 公開入口依然存在：`k8s.kyomind.tw` 會進到 Traefik Ingress。
- 只有 app 後面的依賴改走內網：PostgreSQL 與 Redis 走 bastion private IP。
- 因此，掃描者還是可以打你的公開入口，只是比較難直接碰到後端依賴。

### 2. K8s 版目前的強項是縮小暴露面，不是主動封鎖惡意 IP

從 repo 目前 manifest 可確認：

- 有 Ingress、TLS、HTTPS redirect。
- app Service 是 `ClusterIP`，不是直接對外的 `NodePort` / `LoadBalancer`。
- app 有 2 個副本，並透過 probe 做基本可用性維持。
- PostgreSQL / Redis 走內網位址。

但 repo 目前沒有看見以下明確配置：

- Traefik rate limit middleware
- IP allow / deny list
- WAF
- NetworkPolicy
- 以 Traefik access log 為基礎的 fail2ban 方案

所以目前比較準確的說法是：

> WeaMind K8s 版已經把「後端暴露面」收得比單機版更小，但還沒有做到像單機版 fail2ban 那樣，對惡意來源做主動封鎖。

### 3. 如果要做 K8s 版的等價防護，落點應該在入口層，不是 Pod 內

單機版的 fail2ban 思路，在 K8s 裡不應該直接翻成「在 app Pod 裡裝 fail2ban」。

更合理的落點通常是：

- Traefik 入口層
- LB / CDN / WAF 入口前層
- 節點層防火牆（較不建議作為第一選項）

原因很直接：

- app Pod 是多副本、會重建、log 會分散。
- 真正看到完整外部來源流量的是入口層。
- 真正適合做統一限流、封鎖或 challenge 的也是入口層。

## 單機版 vs K8s 版：怎麼對齊理解

### 單機版

```text
Internet
  -> Nginx
  -> Nginx access log
  -> fail2ban 解析 log
  -> iptables / Nginx map / host-level ban
  -> app container
```

特徵：

- log 集中
- 封鎖點集中
- 真實 client IP 通常比較容易掌握
- fail2ban 很適合直接落地

### K8s 版（目前 WeaMind）

```text
Internet
  -> Hetzner LB
  -> Traefik
  -> Ingress rule
  -> weamind Service (ClusterIP)
  -> 2 個 line-bot Pods
  -> bastion VM (PostgreSQL / Redis)
```

特徵：

- 入口與 app 已分層
- app Pod 可替換、可擴縮，不適合塞 host-style 封鎖邏輯
- 後端依賴不對外，這點比單機版更好
- 若要做惡意 IP 封鎖，應優先考慮 Traefik / 外層流量治理

## 「內網比較安全」這句話，哪裡對，哪裡不對

### 對的部分

- PostgreSQL / Redis 不直接暴露在網路邊界。
- app Service 是 cluster 內部服務，不是直接對外。
- K8s 節點本身也不是以 app port 的方式直接暴露公網。

這些都會讓攻擊者更難直接命中資料層與內部服務。

### 不對的部分

- `k8s.kyomind.tw` 仍然是公開入口。
- Traefik 還是會收到外部掃描、探測與垃圾請求。
- 只要入口仍對外，就不能把「有內網」誤解成「入口已經安全」。

更準確的說法是：

> 內網提升的是橫向保護與後端隔離，不是自動替入口層做惡意流量防護。

## 目前 repo 能證明什麼

從現有 repo，可以明確講出的事實如下：

- `k8s.kyomind.tw` 透過 Ingress 對外提供服務。
- HTTPS 在 Traefik 這層終止。
- `weamind-line-bot` 是 `ClusterIP` Service。
- line-bot 目前是 2 replicas。
- app 啟動時有 `--proxy-headers`，代表 app 會信任代理 headers。
- PostgreSQL 與 Redis 走 bastion private IP。

這些都支持一個核心判斷：

> K8s 版真正的公開攻擊面，主要集中在 Hetzner LB + Traefik 這一段，而不是 Pod 後面的內部連線。

## 研究後的防護選項排序

下面不是「一定要做」，而是把現階段可能的選項，按實務上的合理性排序。

### 選項 A：先補 Traefik access log 與真實 client IP 驗證

這不是封鎖本身，但它是所有後續防護的前置條件。

如果這一步沒先確認，後面不管是 rate limit、IP allowlist、還是 fail2ban，都有可能套在錯的 IP 上。

要驗證的核心問題：

1. Traefik access log 是否已開啟。
2. log 裡看到的 `ClientHost` 是否是真實外部 IP，而不是 LB / node / 內網位址。
3. `X-Forwarded-For` 鏈是否可信、是否需要額外 trusted proxy 設定。

我會把這步排第一，不是因為它最有成就感，而是因為它能避免後面整條防護鏈建立在錯資料上。

### 選項 B：用 Traefik middleware 做最小入口保護

這是我認為 **最短可行、也最符合目前 repo 風格** 的方案。

可考慮的 middleware 類型：

- `rateLimit`
- `inFlightReq`
- `ipAllowList`，但只適合明確白名單場景，不適合一般公開 bot

這條路的優點：

- 延續你現在已經在用的 Traefik CRD / Middleware 思路。
- 變更邊界清楚，仍然是「入口層行為」而不是 app 業務邏輯。
- 對面試敘事也合理，因為這是典型 ingress hardening。

限制也很清楚：

- 它比較像「節流」，不是「根據 log 自動 ban 24 小時」。
- 對低頻但持續的掃描，不一定像 fail2ban 那樣直覺。
- 參數如果設太緊，可能誤傷正常 webhook 或 burst traffic。

### 選項 C：把 Cloudflare 放到更前面，交給外層做 WAF / rate limit

如果未來你真的想補惡意掃描的主動治理，這在實務上常常是 **最省維運腦力** 的方案。

原因：

- 封鎖發生在更外層，不會先把垃圾流量送進 LB / Traefik / app。
- Cloudflare 有現成的 rate limiting、managed challenge、WAF 規則能力。
- 對常見掃描、撞密碼、爬蟲式探測，比自己在叢集裡兜 fail2ban 更順手。

缺點：

- 這個主題會明顯往 CDN / 邊界安全偏，不再是純 K8s 操作題。
- 某些更細的能力可能牽涉方案等級。
- 會增加另一層平台依賴。

### 選項 D：在 Traefik log 上重建 fail2ban 風格封鎖

技術上不是做不到，但我不會把它排成你現階段的優先項。

原因：

- 需要先啟用並收集 Traefik access log。
- 需要決定 ban action 到底打在哪一層：node firewall、DOCKER-USER chain、或其他機制。
- 入口是 LB + Traefik + 多節點，封鎖行為不像單機 Nginx 那麼單純。
- 維運複雜度與 debug 成本會明顯高於單機版。

這條路更像是「把單機時代熟悉的工具硬搬進叢集」，不是最自然的 K8s 入口治理做法。

## 現階段我會怎麼建議

### 建議結論

如果目標是：

- 把 WeaMind 這套架構講清楚
- 聚焦在 Kubernetes / ingress / traffic path 的理解
- 不讓學習主線被安全治理議題分散

那我傾向同意你現在先 **不做主動封鎖實作**。

這不是因為它不重要，而是因為它現在對你的學習目標不是最高報酬的主線。

### 但不做，不代表不能講

你完全可以把這段整理成這樣的面試答案：

> 單機版時，我可以用 Nginx access log 搭配 fail2ban，因為觀察點和封鎖點都在同一台主機上。到了 WeaMind 這個 K3s 架構後，公開入口已經前移到 Hetzner LB 與 Traefik，資料庫和 Redis 則退到內網，所以安全改善主要是縮小後端暴露面，不是自動獲得入口防護。如果要做惡意掃描治理，合理落點會是 Traefik middleware 或更外層的 WAF / rate limiting，而不是在 app Pod 內重建單機式 fail2ban。

這樣的回答有三個好處：

- 你講的是架構邊界，而不是亂丟名詞。
- 你能清楚說出「內網保護的是哪一段」。
- 你也能交代為什麼現在沒有優先做這塊。

## 若未來真的要補，最短路徑是什麼

我會建議用下面順序，而不是直接上 fail2ban：

1. 確認 Traefik access log 與真實 client IP。
2. 若只是想擋明顯濫用，先試最小 `rateLimit` middleware。
3. 如果未來遇到更明顯的掃描、撞密碼或 bot 壓力，再評估 Cloudflare rate limiting / WAF。
4. 只有在你真的明確需要「依 log 自動 ban IP 很久」時，才回頭評估 fail2ban 風格方案。

## 一句話版本

單機版的安全故事是「Nginx log + fail2ban 主動封鎖」；WeaMind K8s 版目前的安全故事則是「把公開入口與內部依賴分層，先縮小暴露面，但尚未把主動封鎖做進入口層」。
