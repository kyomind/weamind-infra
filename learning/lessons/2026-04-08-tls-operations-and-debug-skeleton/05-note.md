# 2026-04-08 TLS Operations and Debug Skeleton Note

## 學習注意事項

- 今天主題聚焦在 WeaMind 目前的 TLS 接法、cert-manager 資源鏈與最小排查順序。
- 今天不展開完整 PKI、CA 信任鏈、openssl 細節，也不把焦點擴成所有 Traefik 進階設定。
- 若中途出現和今天主線無關的延伸問題，先記在這裡，不讓 QA 或 command drill 膨脹。

## Notes

### Kubernetes 為什麼可以有 `Certificate` 這種物件？

- 可以。Kubernetes 本身就允許擴充 API，不是只能用內建的 `Pod`、`Service`、`Deployment` 這些資源。
- 內建資源是 Kubernetes 核心 API 已經定義好的物件；像 cert-manager 這類擴充元件，則可以透過 CRD（CustomResourceDefinition）把新的資源型別註冊進叢集，例如 `Certificate`、`CertificateRequest`、`Order`、`Challenge`。
- 一旦 CRD 被安裝完成，這些物件對 Kubernetes 來說就會變成「叢集認得的 API 資源」。所以你才能用 `kubectl get certificate`、`kubectl get certificaterequest` 這類指令去查它們。
- 這些物件和 Kubernetes 內建物件的差別，不在於「是不是合法資源」；差別在於 **誰定義它的 schema，誰負責實作控制邏輯**。內建物件由 Kubernetes 核心專案定義與實作；`Certificate` 這類 CRD 物件則由 cert-manager 定義 schema，再由 cert-manager controller 負責 watching 與 reconcile。
- 可以把它想成兩層：Kubernetes 提供可擴充的 API 平台與控制器模型；cert-manager 則是在這個平台上額外加了一組「憑證領域」專用資源與 controller。
- 所以更精準的說法是：Kubernetes 確實先定義了一批核心物件，但也允許你追加自訂物件；前提是你要先把對應的 CRD 與 controller 安裝進叢集。沒有 controller，物件通常只會「存在」，但不會真的產生有意義的行為。

### `80` 與 `443` 打到 LB 後，流量各自怎麼走？

- 這個問題值得獨立記住，因為它剛好把「同一份 Ingress 規則」和「不同協定入口」拆開來看。
- 就 WeaMind 目前的設計，`443` 這條線是：client -> Hetzner LB `443` -> TCP passthrough -> Traefik `443` entrypoint -> Traefik 依 Ingress `tls` 區塊讀取 TLS Secret 做 TLS handshake -> 再依 host/path 把流量送到 `weamind-line-bot:80` -> Pod `8000`。
- `80` 這條線則是：client -> Hetzner LB `80` -> Traefik `80` entrypoint -> 先用同一份 Ingress 的 host/path 規則做匹配 -> 再由 redirect middleware 把 HTTP request 導去 HTTPS。也就是說，HTTP 流量不是完全沒進 Ingress；它是先進 Ingress，再被 middleware 改寫成 redirect response。
- `Ingress.spec.tls` 的角色是處理 HTTPS 這一側要用哪個 Secret，不是負責把 HTTP 自動升級成 HTTPS。真正做 HTTP -> HTTPS redirect 的，是 Traefik middleware `https-redirect` 加上 Ingress annotation。
- 因此更準確的說法是：**host/path 規則同時服務 HTTP 與 HTTPS；`tls` 區塊只影響 HTTPS 的憑證綁定；redirect middleware 則只影響 HTTP 請求會不會被導轉。**
- 這也解釋了為什麼你直覺覺得 `80` 顯然也會進來，這個方向是對的。它確實會進來，只是後續不是直接把 request 送進 app，而是先被入口層的 redirect middleware 攔下並導向 HTTPS。

### 目前的 Hetzner LB health check 到底是不是走 HTTPS？和 `80/443` 正式流量鏈是什麼關係？

- 依目前 repo 記錄，答案是：**是，現在 health check 已改成走 `Destination=443` 並啟用 `TLS`；但這不等於正式外部 listener 也一起改掉。**
- 最直接的證據在 [PROGRESS.md](PROGRESS.md#L151-L156)：它明確記錄目前 `http:80 -> 80` 與 `tcp:443 -> 443` 的 listener 分工仍成立，同時 health check advanced settings 已被改成 `Destination=443` + `TLS`，而 targets 仍維持 healthy。
- 這代表在 WeaMind 目前案例裡，**Hetzner LB 的 health check 探測邏輯，和外部 listener / service 的協定邊界，具有相當高的獨立性。** 也就是說，外面對使用者仍然可以維持 `80` 與 `443` 兩條正式入口，但 health check 可以另外指定要用哪個 destination port 與是否開 TLS 來探測 target。
- 若把現在的 health check 路徑壓成最小版本，可以講成：**LB health check -> worker node:443 -> Traefik TLS entrypoint -> Traefik 終止 TLS -> Ingress host/path 命中 -> Service -> Pod `/health`**。這條鏈是在驗證入口層到 app 的一小段合成路徑，不是直接等同於外部使用者那條 `80` HTTP 流量，也不是 Kubernetes Pod probe。
- 與它對照，正式使用者流量目前有兩條：
- `80` 正式流量：client -> LB `80` -> Traefik `80` -> Ingress host/path -> redirect middleware -> 回 HTTPS redirect。
- `443` 正式流量：client -> LB `443` -> TCP passthrough -> Traefik `443` -> 讀 TLS Secret -> TLS handshake -> Ingress host/path -> Service -> Pod。
- 所以更精準的說法不是「health check 也在遵循 80 或 443 的正式流量設計二選一」，而是：**health check 現在獨立選擇去探測 `443 + TLS` 這條入口鏈；正式對外 listener 則仍保留 `80` 與 `443` 各自的角色分工。**
- 這件事之所以重要，是因為它回答了前幾天那個容易混淆的問題：**不能把「LB listener 現在是什麼」和「health check 現在怎麼探測」視為同一件事。** 在這個專案裡，它們現在不是完全綁死的。

### 正式流量的 `443` 和 health check 的 `443`，差別到底在哪裡？

- 兩者後半段會經過很多相同元件，但它們不是同一條流量，只是共用同一套入口系統。
- 正式 `443` 流量的來源是外部 client 或 LINE webhook；health check `443` 的來源則是 Hetzner LB 自己的探測機制。
- 正式 `443` 流量的目的是處理真實 HTTPS 請求，所以 path、method、header 與內容都可能是業務流量；health check `443` 則是固定條件的探測，目的是判斷 target 是否 healthy，通常只看像 `/health` 這種預先定義好的檢查路徑與狀態碼。
- 正式 `443` 流量可以壓成：client -> LB `443` listener -> TCP passthrough -> Traefik `443` -> TLS handshake -> Ingress -> Service -> Pod。
- health check `443` 則可以壓成：LB health checker -> target node `443` -> Traefik `443` -> TLS -> Ingress -> Service -> Pod `/health`。
- 所以更準確的說法是：**兩者共享 Traefik、Ingress、Service、Pod 這段後半鏈路，但前半段的發起者、用途、請求內容與成功條件不同。**
- 最短口述版可以講成：正式 `443` 是真實使用者 HTTPS 流量；health check `443` 是 LB 用固定條件去驗證「這條 HTTPS 入口鏈現在通不通」。

## Flashcards

<!-- 待補 -->
