# 2026-04-01 LB Health Check Skeleton Implementation

## 這份文件的角色

- 這不是一般 `03-command.md` 的 command drill。
- 這份檔案只用在今天這種比較少見的情況：**lesson 進行中需要真的改動 cluster 設定**。
- 記錄重點不是完整逐字稿，而是每一輪都留下最小閉環：**這一輪想改什麼、實際做了什麼、看到什麼結果、目前怎麼判讀。**
- 最終 lesson 收斂仍以 `04-report.md` 為主；lesson 一般補充與卡片素材放 `05-note.md`，實作專屬補充放 `07-implementation-note.md`。

## 今日實作主題

- 目標：把 WeaMind 目前「HTTP 與 HTTPS 都可直接命中」的狀態，朝 **HTTPS health check + HTTP→HTTPS redirect** 的方向安全調整。
- 原則：先保住 Hetzner LB health check 的穩定，再做 redirect，避免入口先變 unhealthy。

## 今日實作順序

1. 先確認 Hetzner LB 目前 health check 設定與預計要改的欄位。
2. 先把 health check 改成走 HTTPS 的 `/health`。
3. 驗證 LB target 是否維持 healthy。
4. 再決定 Traefik / Ingress 要用哪種方式加上 HTTP→HTTPS redirect。
5. 驗證外部 `http://` 是否真的跳到 `https://`，且 `https://` 正常可用。
6. 若中途出現 unhealthy 或行為異常，先記錄現象與回退點，不硬往下做。

## 記錄格式

### Round 1

#### 這一輪要驗證什麼

- 先確認目前 Hetzner LB health check 還是不是走 HTTP，以及它的 `Domain` / path / port 設定是否與 lesson 裡的理解一致。

#### 預計操作

```bash
# Hetzner Cloud Console
# 1. 打開 WeaMind 的 Load Balancer
# 2. 檢查 80 與 443 兩個 service 的 protocol / port / health check
# 3. 確認 worker targets 的目前狀態
```

#### 實際輸出 / 操作結果

```bash
Health check summary
- http:80 -> 80
	- Protocol: http
	- Port: 80
	- Path: /health
	- Domain: k8s.kyomind.tw
	- Status codes: 200

- tcp:443 -> 443
	- Protocol: tcp
	- Port: 443
	- Health check detail: only interval / timeout / retries shown

Targets
- weamind-002: Healthy
- weamind-003: Healthy
```

#### AI 判讀與收斂

- 目前 lesson 裡的核心判讀已被畫面再次證實：**真正依賴 `Host` / `Domain` 的，是 `http:80 -> 80` 這條 health check。**
- `http:80 -> 80` 目前明確使用 `Domain: k8s.kyomind.tw` 與 `Path: /health`，而且兩個 worker target 都是 `Healthy`，表示 **現況確實建立在 HTTP health check + 正確 Host header 之上**。
- `tcp:443 -> 443` 這條 service 目前仍是 **TCP passthrough**，畫面上也沒有出現 HTTP 型 health check 的 `Path` / `Domain` 欄位，這和我們前面對 Hetzner LB / Traefik 分工的理解一致。
- 因此下一輪最合理的動作是：**先把外層 LB 的 health check 從 HTTP `/health` 改成 HTTPS `/health`，先驗證 target 仍維持 healthy，再去做 redirect。**

#### 目前狀態

- 已完成

### Round 2

#### 這一輪要驗證什麼

- 把 Hetzner LB 的 health check 切到 HTTPS `/health` 後，worker targets 是否仍維持 `Healthy`。

#### 預計操作

```bash
# Hetzner Cloud Console
# 1. 編輯 http:80 -> 80 這條 service 的 health check
# 2. 將 protocol 改成 https
# 3. 保留 Port = 80 或改成 443 前，先停下來確認 UI 欄位實際限制
# 4. 若 UI 允許獨立指定 health check port，優先對準 Traefik 的 HTTPS 入口
# 5. 儲存後觀察 targets 狀態
```

#### 實際輸出 / 操作結果

```bash
Hetzner UI observation
- When protocol is switched from http to https on the existing :80 service:
	- Source port remains fixed at 80
	- Source port cannot be changed in-place
	- Destination port remains editable
	- UI shows certificate attachment is required
	- UI shows HTTP-Redirect (301) option
	- Existing :443 source port cannot be duplicated because tcp:443 -> 443 already exists
```

#### AI 判讀與收斂

- 這輪最重要的發現是：**Hetzner 這裡的 protocol 切換不是只改 health check，而是在改整條 LB service 的性質。**
- 當 `:80` service 切成 `https` 時，UI 立刻要求 certificate，代表 **Hetzner LB 準備在這條 service 上做 TLS termination**，而不是單純把 backend health check 偷換成 HTTPS。
- `source port` 固定、`destination port` 可改，表示 **listener 的身份是由 source port 決定**；你可以改它往 target 送到哪個 port，但不能把既有 `80` listener 直接變成另一條 `443` listener。
- 因為專案現在已經有 `tcp:443 -> 443 passthrough`，所以無法再加第二條 `443` service 來做另一種 HTTPS health check；而把 `:80` service 直接改成 `https` 又會和目前 **TLS termination 在 Traefik** 的架構衝突。
- 因此這一輪的結論不是「可以直接繼續切 HTTPS health check」，而是：**原先的實作假設不成立，下一步必須先改成重新設計 redirect 方案，而不是直接套用 `health check 先改 HTTPS` 這條路。**

#### 目前狀態

- 已完成

### Round 3

#### 這一輪要驗證什麼

- 在維持 `443` 仍由 Traefik 做 TCP passthrough / TLS termination 的前提下，如何補 `HTTP -> HTTPS redirect`，同時不讓現有 `http:80 -> 80` health check 失效。

#### 預計操作

```bash
# 先不改 Hetzner LB
# 1. 回頭檢查 Traefik / Ingress 是否能做 redirect exception 或全域 redirect
# 2. 釐清 /health 是否需要保留 HTTP 200，或能否接受 redirect / 其他狀態碼
# 3. 再決定要改 manifest 還是調整 LB service 結構
```

#### 實際輸出 / 操作結果

```bash
Repo / history check
- manifests/ingress.yaml currently has only tls + host/path rules
- No redirect annotations or Traefik middleware references exist in manifests/
- Historical docs confirm current architecture is intentional:
	- Hetzner Managed Certificate was rejected because DNS stays on Cloudflare
	- Final 443 design was changed to TCP passthrough
	- Private notes mention Traefik Middleware redirectScheme as the likely place for HTTP -> HTTPS redirect

Cluster capability check
- kubectl get crd | rg 'middleware|traefik'
	- middlewares.traefik.io exists
	- ingressroutes.traefik.io exists
- kubectl api-resources | rg -i 'middleware|traefik'
	- Middleware is available as traefik.io/v1alpha1
	- IngressRoute is available as traefik.io/v1alpha1

Cluster usage check
- kubectl get middleware -A
	- No resources found
- kubectl get ingressroute -A
	- No resources found

Hetzner health check UI check
- Status codes field is editable
- Help text says returned HTTP status codes can be entered as comma-separated values
- Help text also mentions wildcard support: `?` for one character and `*` for multiple characters
- Advanced settings show health check has its own:
	- Protocol
	- Destination
	- Domain
	- Path
	- TLS enable/disable toggle
- User validated in UI, without saving yet:
	- Destination can be changed from 80 to 443
	- TLS can be enabled without immediate warning
	- Domain / Path / Status codes remain visible after enabling TLS
	- TLS help text says: "Use HTTPS for health check if TLS option is enabled."
- User saved the health check change and observed for more than 5 minutes:
	- http:80 -> 80 service remained healthy
	- both worker targets remained healthy
	- effective health check behavior appears to allow independent Destination=443 + TLS=Enabled
```

#### AI 判讀與收斂

- 目前 repo 沒有現成的 redirect 設定可直接打開，表示 **這不是單純補一個遺漏 annotation 就能證明已存在的功能**。
- 但歷史文件也顯示，若要維持現在這種 **`443` 由 Traefik 做 TLS termination** 的架構，redirect 的合理落點仍然是在 **Traefik / Ingress / Middleware**，而不是回頭改 Hetzner LB。
- 這一步已經確認：**目前叢集具備 Traefik Middleware / IngressRoute CRD，代表從能力面看，確實可以在 Traefik 這一層研究 redirect 做法。**
- 但目前 **完全沒有既有 Middleware / IngressRoute 使用先例**，代表如果要做 redirect，會是這個叢集第一次正式引入這類 Traefik 物件，而不是沿用既有模式。
- 但是否要真的實作，仍要回到風險與收益判斷：目前沒有 redirect **不是高優先安全事故**，而是公開入口一致性的缺口；若能優雅落地就做，若需要扭曲現有架構，暫時 suspend 也是合理結論。
- 這張畫面把 Round 3 的路線又往前推了一步：**health check 似乎比整條 LB service 更可獨立調整。**
- 也就是說，先前「只要碰到 HTTPS 就等於碰到整條 LB service 協定」這個判斷，對 **service 本身** 仍成立；但對 **health check advanced settings** 可能還不夠精準，因為這裡額外出現了獨立 `TLS` 開關與可編輯 `Destination`。
- 目前最值得做的最小實驗，已經收斂成：**不改 LB service listener，只改 health check advanced settings，直接測試 `Destination=443` + `TLS=Enabled` 是否能讓 target 維持 healthy。**
- 這個實驗若成功，代表我們可能可以把健康檢查獨立切到 HTTPS，而不必動 Hetzner 的 TLS termination 邊界；若失敗，也能立即回退到原本 `80` / HTTP 設定。
- 這個實驗已成功，代表 **Hetzner 的 health check advanced settings 與 listener/service 行為之間，至少在這個案例中具有足夠的獨立性**，可讓我們把健康檢查切到 HTTPS，同時維持 `443` 仍由 Traefik 做 TLS termination。
- 因此目前最合理的下一步，已從「是否 suspend」進入「可以嘗試最小 redirect 實作」：在 repo 中新增 Traefik `Middleware`，並把既有 `Ingress` 掛上 `redirectScheme`。

### Round 4

#### 這一輪要驗證什麼

- 在不改 Hetzner LB listener 與 TLS termination 邊界的前提下，使用 Traefik `Middleware` 實作 `HTTP -> HTTPS redirect` 是否可行。

#### 預計操作

```bash
# repo manifest changes
# 1. 新增 Traefik Middleware: redirectScheme -> https
# 2. 在既有 Ingress 上掛上 router.middlewares annotation
# 3. kubectl apply 後驗證 http / https / health check 行為
```

#### 實際輸出 / 操作結果

```bash
kubectl apply -f manifests/middleware-https-redirect.yaml
kubectl apply -f manifests/ingress.yaml
- middleware.traefik.io/https-redirect created
- ingress.networking.k8s.io/weamind configured

curl -i http://k8s.kyomind.tw/health
- HTTP/1.1 301 Moved Permanently
- location: https://k8s.kyomind.tw/health

curl -iL http://k8s.kyomind.tw/health
- HTTP/1.1 301 Moved Permanently
- location: https://k8s.kyomind.tw/health
- HTTP/2 200
- {"status":"ok"}

curl -i https://k8s.kyomind.tw/health
- HTTP/2 200
- {"status":"ok"}

Post-check observation
- Hetzner targets still remained healthy after redirect was enabled
```

#### AI 判讀與收斂

- 這輪已正式驗證成功：**HTTP 請求會先被 Traefik 回 `301` 到 HTTPS，而 HTTPS 路徑本身仍正常回 `200`。**
- 這表示目前的最小實作已經成立：**redirect 發生在 Traefik，健康檢查仍已被獨立切到 HTTPS，Hetzner LB 不需要重新接手 TLS termination。**
- 這也是目前最乾淨的結果，因為它同時保住了三件事：
- 第一，**TLS termination 仍留在 Traefik**。
- 第二，**Hetzner LB 的 health check 已可獨立走 HTTPS**。
- 第三，**公開 HTTP 入口現在已具備自動導向 HTTPS 的一致性行為**。

#### 目前狀態

- 已完成
