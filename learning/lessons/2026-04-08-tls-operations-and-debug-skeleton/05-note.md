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

### 為什麼 `Certificate` 會在 `weamind` namespace，而不是在 cert-manager 自己的 namespace？

- 這個點很重要，因為它剛好能把「controller 跑在哪裡」和「它管理的資源放在哪裡」拆開來看。
- cert-manager controller 本身通常跑在 `cert-manager` namespace，但它管理的 `Certificate` 不必也放在那裡。
- `Certificate` 是 namespaced 資源。它通常會放在「需要使用這張憑證的工作負載所在 namespace」，因為它最終要產出的 TLS Secret 也會放在同一個 namespace。
- 在 WeaMind 這題裡，Ingress 在 `weamind` namespace，並且引用 `k8s-kyomind-tw-tls` 這個 Secret；而 Kubernetes 的 Secret 本來就是 namespaced 資源，所以 **Ingress 只能引用同 namespace 的 Secret**。因此最自然的做法就是把 `Certificate` 也建在 `weamind`，讓它把結果寫進 `weamind/k8s-kyomind-tw-tls`。
- 這也解釋了為什麼 `ClusterIssuer` 和 `Certificate` 的 scope 不一樣：`ClusterIssuer` 是 cluster-scoped，代表整個叢集都能引用的簽發者；`Certificate` 則是某個 namespace 內的具體憑證需求。

### 我怎麼知道叢集裡有 `Certificate` 這種資源，而不是剛好猜對？

- 最直接的系統性做法不是先查某個物件，而是先查「目前 API server 認得哪些 resource kinds」。
- 這次最有用的指令是：`kubectl api-resources`。我剛剛實際查到，目前叢集裡已註冊這些 cert-manager 相關資源：`certificates`、`certificaterequests`、`orders`、`challenges`、`issuers`、`clusterissuers`。
- 也就是說，`kubectl get certificate` 之所以成立，不是因為 kubectl 碰巧心領神會，而是因為 API server 現在真的有 `cert-manager.io/v1` 這組資源型別。
- 若你想再往下確認它們是怎麼被加進來的，可以查 `kubectl get crd | rg 'cert-manager|acme.cert-manager'`。那會讓你看到對應的 CRD 名稱，證明這些 kinds 是透過 CRD 註冊進叢集的。
- 若你想看單一資源的 schema 與欄位說明，還可以用 `kubectl explain certificate` 或 `kubectl explain certificate.spec`。前提同樣是：這個 kind 已被叢集註冊。

### 在 Headlamp 裡，`Certificate` 大概算哪一類資源？

- 概念上，它屬於 cert-manager 提供的自訂資源，不屬於像 `Secrets`、`ConfigMaps` 這種 Kubernetes 核心內建配置資源。
- 你現在在 Headlamp 畫面裡能看到 `k8s-kyomind-tw-tls`，是因為它本質上真的是一個 core `Secret`，所以會出現在 `Configuration -> Secrets`。
- 但 `Certificate` 本身是 CRD，**不一定會在 Headlamp 預設側邊欄直接有一個明顯入口**。根據目前查到的資料，Headlamp 有 cert-manager plugin，裝上後會在側邊欄新增一個 cert-manager 區塊，專門瀏覽這些資源。
- 若目前這個 Headlamp 沒裝對應 plugin，你在預設 UI 裡不一定容易直接找到 `Certificate`；這不代表它不存在，而比較像是 GUI 沒幫這類 CRD 做出一個現成導航點。
- 所以在你現在這個環境裡，最穩的策略仍是：**先用 `kubectl api-resources` / `kubectl get certificate` 確認 kind 與物件存在，再把 Headlamp 視為查看 core 資源與部分插件資源的輔助介面。**

### `Certificate`、`CertificateRequest`、`Order`、`Challenge` 到底是在存什麼？它們只是流程記錄嗎？

- 你的直覺有抓到一半：`Secret` 的確最接近「真正的憑證 material」，因為 `tls.crt`、`tls.key` 這些實際會被 Traefik 使用的內容最後是放在 `Secret` 裡。
- 但 `Certificate` 不能只講成 metadata。更準確地說，它是 **期望狀態 + 結果狀態** 的資源：你在這裡宣告想要哪個 `dnsName`、找哪個 `Issuer`、最後輸出到哪個 `Secret`；同時 controller 也會在它的 status 上回報目前是否 ready、何時到期、何時要 renew。
- `CertificateRequest`、`Order`、`Challenge` 則更接近 **workflow artifact / 中間狀態資源**。它們不是最後被 app 直接使用的資料本體，而是 cert-manager / ACME 控制流程為了把憑證簽出來，沿途建立出來的狀態物件。
- 所以可以把它們粗分成三類：
- `Secret`：真正的輸出物，保存實際憑證與私鑰。
- `Certificate`：使用者宣告想要什麼憑證，以及 controller 回報目前結果如何的主資源。
- `CertificateRequest` / `Order` / `Challenge`：為了達成這個目標而展開的流程中間資源，用來承載申請、驗證、簽發各階段的狀態。
- 這也是 Kubernetes controller 模型很常見的樣子：**真正的 payload 往往在某個輸出資源裡，而控制流程本身則透過一串帶 `spec` / `status` 的資源物件來表達。**
- 如果把這題壓成最短版，可以這樣講：`Secret` 比較像最終產物；`Certificate` 比較像憑證需求與結果狀態；`CertificateRequest`、`Order`、`Challenge` 則是簽發流程中的中間狀態資源，不只是被動記錄，而是 controller 真的拿來驅動與回報流程的物件。

## Flashcards

- Ingress `spec.tls.secretName` 在 WeaMind 裡真正代表什麼？ #DevOps #card
	- 它只是在宣告 Traefik 處理這個 host 的 HTTPS 時應讀哪個 TLS Secret
	- 它不是建立 Secret 的地方
	- Secret 名稱是先在 `Certificate.spec.secretName` 宣告，再由 cert-manager 建立並維護

- WeaMind 的 TLS 分工最短版該怎麼講？ #DevOps #card
	- Hetzner LB 只做 `443` TCP passthrough
	- Traefik 在叢集內做 TLS termination 與 HTTP routing
	- cert-manager 負責憑證生命週期，不在即時請求路徑上
	- Ingress `tls` 區塊負責把 host 和 TLS Secret 綁起來

- `Certificate` 和 TLS Secret 的差別是什麼？ #DevOps #card
	- `Certificate` 是 cert-manager 的主資源，表達想要什麼憑證與輸出到哪個 Secret
	- TLS Secret 是最終輸出物，真的保存 `tls.crt` 和 `tls.key`
	- 前者偏期望狀態與結果狀態，後者偏實際 payload

- `Certificate`、`CertificateRequest`、`Order`、`Challenge` 各自站在哪一層？ #DevOps #card
	- `Certificate` 是憑證需求與輸出位置的宣告
	- `CertificateRequest` 是某一次實際簽發申請
	- `Order` 是 ACME 的簽發訂單
	- `Challenge` 是網域控制權驗證任務

- TLS 出問題時，為什麼不該先看 Pod log？ #DevOps #card
	- 瀏覽器憑證警告通常發生在請求真正進入 app 之前
	- 第一輪應先查 TLS 入口鏈，不是應用層
	- 只有在 HTTPS 已正常建立、但回應內容異常時，才往 `Service`、`Endpoints`、Pod log 查

- WeaMind 的 TLS 最小排查順序是什麼？ #DevOps #card
	- 先判斷症狀是不是典型 TLS 錯誤
	- 再查 Ingress `tls.secretName` 與 host
	- 接著查 `Certificate` 是否 `READY=True`
	- 若不正常，再往下追 `CertificateRequest`、`Order`、`Challenge`

- WeaMind 的 HTTP `80` 與 HTTPS `443` 入口差別在哪裡？ #DevOps #card
	- `443` 會經過 LB passthrough、Traefik 讀 TLS Secret 做 handshake，再進 Ingress / Service / Pod
	- `80` 也會先進 Traefik / Ingress
	- 但 `80` 這邊會被 redirect middleware 導去 HTTPS，不是由 `Ingress.spec.tls` 自動升級

- 正式 `443` 流量和 health check `443` 的差別是什麼？ #DevOps #card
	- 兩者共享 Traefik、Ingress、Service、Pod 這段後半鏈路
	- 正式 `443` 來自外部 client，處理真實 HTTPS 請求
	- health check `443` 來自 Hetzner LB，目的是驗證這條 HTTPS 入口鏈是否 healthy

- 為什麼 `Certificate` 會建在 `weamind` namespace？ #DevOps #card
	- `Certificate` 是 namespaced 資源
	- 它通常放在真正要使用這張憑證的 workload namespace
	- 因為 Ingress 只能引用同 namespace 的 Secret，所以 `Certificate` 與 TLS Secret 也自然放在 `weamind`
