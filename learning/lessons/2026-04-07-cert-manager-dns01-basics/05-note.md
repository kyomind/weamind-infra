# 2026-04-07 cert-manager DNS-01 Basics Note

## 學習注意事項

### 今日 lesson 邊界

- 今天主題是 cert-manager 的角色、DNS-01 vs HTTP-01、WeaMind 的選型理由，以及 ACME 驗證與正式流量策略的邊界。
- 今天不展開完整 PKI、CA 信任鏈、openssl 細節，也不提前展開明天的 Certificate / CertificateRequest / Order / Challenge 排查鏈。
- 今天也不把焦點放成 cert-manager 安裝步驟清單，而是聚焦在為什麼這個專案這樣選。

### 今天要特別觀察的 repo 事實

- README 已明確寫出 WeaMind 採用 cert-manager + Cloudflare DNS-01。
- PROGRESS 已記錄 Hetzner Managed Certificate 因 Cloudflare DNS 架構而不可行，改採 cert-manager + Cloudflare DNS-01。
- Ingress 目前直接引用 TLS secret，代表憑證最終是提供給 K8s 內的 Traefik 使用。
- ACME 驗證方法與正式 HTTP→HTTPS redirect 策略不是同一層決策。

## Notes

### HTTP-01 在 WeaMind 架構下是不是完全不可能

- 不是完全不可能，但 **明顯比較麻煩，也更容易和既有流量路徑糾纏在一起**。
- 你這個直覺是對的：在 WeaMind 目前的架構裡，若走 HTTP-01，挑戰請求就必須真的走到公開 HTTP 路徑，等於要依賴 **LB → Traefik / Ingress → solver 路徑** 這條資料平面是通的。
- 相比之下，DNS-01 只需要 cert-manager 能透過 Cloudflare API 寫入 `_acme-challenge` 的 TXT record，不必為了驗證再特地調整對外 HTTP 入口，所以更符合這個專案的現況。

### 如果用 HTTP-01，續約時是不是也還要再走 HTTP-01

- 是。若憑證最初就是透過 HTTP-01 solver 取得，**後續續約時原則上也會再次走同一類 challenge flow**，不是第一次簽完之後就永遠不需要驗證。
- 所以你這個問題很重要：若架構後面改成全面 HTTPS-only，卻沒有保留 HTTP-01 所需的 challenge 路徑或例外處理，**續約就可能失敗**。

### 那現在做了 HTTP→HTTPS redirect，HTTP-01 就一定不 work 嗎

- 不能直接講成「一定不 work」，但 **至少不能把它當成理所當然會 work**。
- 比較精準的說法是：一旦你對所有 HTTP 流量都直接套用 redirect middleware，HTTP-01 會變得更脆弱，因為 `/.well-known/acme-challenge/` 這種驗證路徑通常需要被正確放行，或至少要有專門的 solver ingress / 例外規則。
- 也就是說，問題不在於 HTTP-01 理論上做不到，而在於 **你為了讓它可靠續約，必須持續照顧那條公開 HTTP 驗證路徑**；這正是 WeaMind 偏向 DNS-01 的原因之一。

### 一句話收斂

- **HTTP-01 在 WeaMind 不是絕對不可能，但它會把憑證續約綁回公開 HTTP 路徑與路由例外；DNS-01 則把驗證移到 Cloudflare DNS API，較不會和正式流量策略互相牽制。**

### 為什麼單機版加了 redirect，HTTP-01 續約還可能成功

- 你這個追問很重要，因為它剛好能修正一個過度粗糙的說法：**有 HTTP→HTTPS redirect，不等於 HTTP-01 一定失敗。**
- 更精準的說法應該是：**若 redirect 規則沒有擋到 `/.well-known/acme-challenge/`，或 Web server 對這條路徑保留了例外處理，HTTP-01 仍然可以成功。**
- 這件事現在已經有答案了。從你提供的單機 nginx 設定可直接看出：HTTP 80 的 server block 先對 `/.well-known/acme-challenge/` 設了獨立 `location`，把 challenge 檔案從 certbot 的 webroot 提供出去；只有其他一般請求才在 `location /` 裡被 `301` 轉去 HTTPS。
- 這代表你的單機版不是「redirect 開了之後 HTTP-01 仍自動神奇成立」，而是 **challenge 路徑被刻意保留下來，所以 HTTP-01 續約依然能 work**。
- 也就是說，真正成立的不是「HTTP-01 不怕 redirect」，而是：**redirect 可以存在，但必須替 ACME challenge 路徑保留例外。**
- 這也同時回答了你前面的續約疑問：若憑證續約仍走 HTTP-01，那續約時一樣需要這條 HTTP challenge 路徑可用；你的單機版之所以沒壞掉，就是因為 nginx 設定確實保住了它。

### 和 WeaMind 這題的真正差別

- 單機版 nginx + certbot 的 HTTP-01 能長期穩定，是因為你只要照顧一條 nginx 路徑規則即可。
- WeaMind 的 Kubernetes 版本則多了 Hetzner LB、Traefik、Ingress 規則、middleware 與 solver 流量問題，所以若改走 HTTP-01，就不只是「加一條 location」那麼簡單，而是要持續照顧整條資料平面。
- 這也是為什麼 **HTTP-01 在單機可能很自然，但在 WeaMind 這種 K8s 架構下就沒有 DNS-01 那麼乾淨。**

### 這段外部配置能支持的最小結論

- 可以保守、公開地講成：**某個既有單機 nginx + certbot 配置中，HTTP 80 並不是完全無條件 redirect；它對 `/.well-known/acme-challenge/` 保留了例外，因此 HTTP-01 的申請與續約仍可成立。**
- 這個例子剛好說明：**HTTP→HTTPS redirect 和 HTTP-01 並非絕對衝突，真正關鍵是 challenge 路徑有沒有被正確放行。**
- ⭐️也因為如此，當系統從單機進入 K8s，多出 LB、Ingress Controller、middleware 與 solver ingress 後，**HTTP-01 的維護成本就比單機版高得多。**

### TLS Secret 和一般業務 Secret 在本質上是不是同一種東西

- 是，**它們本質上都還是 Kubernetes Secret 物件**，都屬於叢集裡的 Secret resource。
- 但它們常見的差異在於 **用途、type、欄位格式，以及被誰消費**。
- 在 WeaMind 目前 repo 可直接看到兩條證據：
	- [manifests/ingress.yaml](manifests/ingress.yaml#L9) 到 [manifests/ingress.yaml](manifests/ingress.yaml#L12) 宣告 Ingress 會引用 `k8s-kyomind-tw-tls` 這個 TLS Secret。
	- [manifests/deployment.yaml](manifests/deployment.yaml#L47) 到 [manifests/deployment.yaml](manifests/deployment.yaml#L50) 則顯示 app 的一般 Secret `weamind-secret` 是拿來 `envFrom + secretRef` 注入敏感環境變數。

### TLS Secret 和一般 Secret 的主要差異

- **TLS Secret** 常見 type 是 `kubernetes.io/tls`，通常包含固定語意的 key，例如 `tls.crt` 與 `tls.key`。
- **一般業務 Secret** 若沒有特別指定，常見是 `Opaque`，裡面放的是應用程式自己的 key-value，例如 `LINE_CHANNEL_SECRET`、`POSTGRES_PASSWORD` 這類值。
- 在 WeaMind 裡，`k8s-kyomind-tw-tls` 這類 TLS Secret 是給 **Traefik / Ingress** 在 TLS termination 時使用；`weamind-secret` 這類一般 Secret 則是給 **line-bot container** 當環境變數使用。

### 這兩種 Secret 的來源方式也不一樣

- WeaMind 的一般敏感設定，repo 證據顯示是人手維護在不提交 Git 的檔案裡，例如 [PROGRESS.md](PROGRESS.md#L75) 到 [PROGRESS.md](PROGRESS.md#L78) 提到的 `.privatedocs/secrets/secret.yaml`，並收斂成「人工撰寫一律用 `stringData`」的規則。
- TLS Secret 則不是 repo 內手寫 manifest 的主角；在目前這條 TLS 流程裡，它更像是 **由 cert-manager 根據 Certificate / Issuer 流程產生並維護的叢集內 Secret**，再由 Ingress 引用。

### 一句話比較

- **兩者本質上都是 Kubernetes Secret；差別不在是不是 Secret，而在它的 type、內容格式、建立方式，以及最後是被 Ingress/Traefik 還是被應用 Pod 消費。**

## Flashcards

- 在 WeaMind 裡，cert-manager 真正自動化的是什麼？ #DevOps #card
	- 不只是拿到一次憑證
	- 它處理申請、DNS-01 驗證、儲存與續期
	- 它是憑證生命週期 controller，不是一次性工具

- WeaMind 的 TLS 分工怎麼講最準？ #DevOps #card
	- Hetzner LB 只做 TCP 443 passthrough
	- Traefik 在 K3s 內做 TLS termination
	- cert-manager 負責憑證生命週期
	- Cloudflare 提供可被 API 寫入的 DNS

- DNS-01 和 HTTP-01 的核心差異是什麼？ #DevOps #card
	- DNS-01 驗證 DNS 控制權
	- HTTP-01 驗證公開 HTTP 路徑控制權
	- DNS-01 依賴 DNS API 控制面
	- HTTP-01 依賴資料平面是否打通

- 為什麼 WeaMind 偏向 DNS-01 而不是 HTTP-01？ #DevOps #card
	- DNS 在 Cloudflare，不在 Hetzner
	- 無法直接走 Hetzner Managed Certificate
	- DNS-01 不必持續照顧公開 HTTP challenge 路徑
	- 比 HTTP-01 更不會和 LB、Ingress、redirect 糾纏

- 為什麼 WeaMind 不需要為 ACME 驗證特地保留外部 80？ #DevOps #card
	- 因為憑證驗證走 DNS-01，不走公開 HTTP challenge
	- ACME 驗證方法和正式流量策略是兩層不同問題
	- 所以一般 HTTP 流量可更乾淨地 redirect 到 HTTPS

- HTTP→HTTPS redirect 會讓 HTTP-01 一定失敗嗎？ #DevOps #card
	- 不一定
	- 關鍵是 `/.well-known/acme-challenge/` 有沒有被正確放行
	- redirect 可以存在，但 challenge 路徑通常要保留例外

- 為什麼單機版 HTTP-01 常比 K8s 版自然？ #DevOps #card
	- 單機常只要照顧一條 nginx challenge 路徑
	- K8s 版多了 LB、Ingress Controller、middleware 與 solver 路徑
	- 所以 HTTP-01 在 K8s 的維護成本更高

- TLS Secret 和一般業務 Secret 的差別是什麼？ #DevOps #card
	- 兩者本質上都是 Kubernetes Secret
	- TLS Secret 常見 type 是 `kubernetes.io/tls`
	- 一般業務 Secret 常見 type 是 `Opaque`
	- 前者給 Ingress/Traefik 用，後者給 Pod 當環境變數

- DNS-01 的安全核心是什麼？ #DevOps #card
	- TXT record 可公開查詢，不是敏感點
	- 真正敏感的是能修改 DNS 的 API Token
	- 安全性在於寫入權，不在於記錄內容保密
