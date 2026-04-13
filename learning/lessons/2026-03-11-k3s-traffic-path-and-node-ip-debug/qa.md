# 2026-03-11 K3s Traffic Path And Node IP Debug QA
複習：2026-04-13
> 原則：每題都先回到 repo 檔案或既有架構文件，不直接背名詞。
> 這份 QA 的重點是流量路徑、責任邊界與 debug sequence，不是一般 Kubernetes 教科書。

## Q1

### 題目

在 WeaMind 這個專案裡，一個來自 LINE 的 webhook 請求，從外部進來到進入 line-bot Pod 為止，完整會經過哪些層？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`
- `manifests/ingress.yaml`
- `manifests/service.yaml`

### 使用者回答摘要

- 使用者先從 LINE Platform 會把 webhook 請求送到 `k8s.kyomind.tw` 開始描述。
- 使用者指出請求會先經過 DNS(Cloudflare A record 指向 Hetzner LB **公網 IP**)，再到 Hetzner Load Balancer，之後再進入 Traefik。
- 使用者也有抓到 Ingress 規則會依照 host 與 backend service，把流量送到 `weamind-line-bot` Service 的 `80` port。
- 使用者接著對照 `manifests/service.yaml`，指出 Service 是 `ClusterIP`，會透過 selector 找到 `app: weamind` 的 Pods，並把 `80` 轉到 Pod 的 `8000`。
- 使用者對 Traefik 在 K3s 內部的實際暴露方式還不夠確定，一度推測它可能以 NodePort Service 形式存在，且兩個 worker 節點上各有一個 Traefik Pod。

### AI 修正與補充

- 整體主幹是對的，已經抓到大方向：`LINE Platform → DNS → Hetzner LB → Traefik → Ingress 規則對到 Service → Service 對到 Pods`。
- 第一個要修正的是 DNS 這段。依照 [README.md](README.md#L67) 目前 repo 內明確寫的是 Cloudflare A record 指向 Hetzner LB 的公網 IP，不是這個 repo 已確認的 CNAME 架構，所以這裡不要先講成 CNAME。
- 第二個要修正的是 Traefik 這段。以目前 repo 內已確認的資料，我們可以穩定講的是：Hetzner LB 做 TCP 443 passthrough，流量進到 K3s 內的 Traefik，由 Traefik 做 TLS termination，再依 Ingress 規則把流量送到 `weamind-line-bot` Service。這點可由 [README.md](README.md#L84) 與 [docs/WeaMind Infra核心架構.md](docs/WeaMind%20Infra核心架構.md#L12) 支撐。
- 但「Traefik 一定是 NodePort Service 形式存在」、「一定在兩個 worker 各有一個 Pod」這兩件事，這個 repo 目前沒有直接證據可讓我們講得這麼死，所以這裡要先保守，不要把推測說成已驗證事實。
- Ingress 這段要再修精準一點：[manifests/ingress.yaml](manifests/ingress.yaml#L1) 裡的 host 是 `k8s.kyomind.tw`，backend service 是 `weamind-line-bot`，port 是 `80`。
- Service 這段方向正確，但更準確的說法是：Service 不會去看「來源是不是 80 才能處理」，而是它**自己對外提供一個 cluster 內的 `80` port**，然後把送到這個 service port 的流量轉到 targetPort `8000`，也就是 Pod container 的 `8000`。這點可由 [manifests/service.yaml](manifests/service.yaml#L1) 與 [manifests/deployment.yaml](manifests/deployment.yaml#L1) 對起來。
- 這題目前可以先收斂成一句比較穩的說法：LINE Platform 依 webhook URL 把請求送到 `k8s.kyomind.tw`，DNS 把網域解析到 Hetzner LB 公網 IP，LB 將 443/TCP 流量 passthrough 到 K3s 內的 Traefik，Traefik 在叢集內終止 TLS 並**依 Ingress 規則把流量送到 `weamind-line-bot:80`**，Service 再依 selector 把流量轉到 `app: weamind` 的 Pod `8000` port。

### 狀態

- 已完成

---

## Q2

### 題目

在這條流量路徑裡，Hetzner Load Balancer、Traefik、`weamind-line-bot` Service 三者的責任邊界分別是什麼？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`
- `manifests/ingress.yaml`
- `manifests/service.yaml`

### 使用者回答摘要

- 使用者指出 Hetzner Load Balancer 是接外部流量的那一層，並且有能力把流量分給後面的 Traefik。
- 使用者也指出 Ingress YAML 中的 host 與 backend service 很明確，因此 Traefik 之後如何把流量送到 `weamind-line-bot` Service 這段相對清楚。
- 使用者認為 `weamind-line-bot` Service 這一層負責把流量分配給後面的 Pods，若有兩個 Pods 就會做負載分配。
- 使用者另外補充了一個記憶中的實作細節：Traefik 在 worker 節點上有對應入口，Hetzner LB 的設定細節是在 Hetzner 後台完成，這部分在歷史對話中有記錄。

### AI 修正與補充

- 整體邊界其實已經抓到了，只是還需要把三層的責任切得更乾淨。
- 第一層是 Hetzner Load Balancer。它是外部流量的入口，接收來自 Internet 的請求，並把流量送進 K3s 叢集前面的 Traefik。就目前 repo 的最終文件來說，穩定版本是 [README.md](README.md#L84) 與 [docs/WeaMind Infra核心架構.md](docs/WeaMind%20Infra核心架構.md#L12) 所寫的架構：LB 做 TCP 443 passthrough，TLS termination 在 Traefik。
- 第二層是 Traefik，也就是 Ingress Controller。它的責任不是負責「對外買流量」，而是當流量已經進到叢集入口後，根據 host/path 這類 HTTP 規則決定應該把請求送到哪個 Service。這點可以直接由 [manifests/ingress.yaml](manifests/ingress.yaml#L1) 支撐。
- 第三層是 `weamind-line-bot` Service。它不做 host-based routing，也不直接面向 Internet；它的責任是提供 cluster 內穩定入口，並把送到這個 Service 的流量轉給 selector 選中的 Pods。這點由 [manifests/service.yaml](manifests/service.yaml#L1) 與 [manifests/deployment.yaml](manifests/deployment.yaml#L1) 可以對起來。
- 你補的歷史細節是有價值的，而且這次確實查得到：在 [.privatedocs/weamind/5-3.md](.privatedocs/weamind/5-3.md#L514) 的歷史紀錄裡，Traefik Service 曾顯示為 `LoadBalancer`，對外入口是 `80:30417` 與 `443:31051`，而且在 [.privatedocs/weamind/4-2.md](.privatedocs/weamind/4-2.md#L650) 可看到一個 `traefik` Pod 加上三個 `svclb-traefik` Pods。這代表你記得的「Traefik 不是只有一個抽象名詞，而是真的有節點入口」這個方向是對的。
- 但這裡要修精準的是：不是 `weamind-line-bot` Service 在接外部流量，而是 Hetzner LB 接外部流量，Traefik 做 HTTP/HTTPS 層路由，`weamind-line-bot` Service 做 cluster 內穩定入口與後端 Pod 分流。
- 另一個要修的是「Traefik Controller 部署在每個 worker 各一個」這句不能直接這樣講。從歷史紀錄看，較穩的說法是：Traefik 本體是 Pod，另外 K3s 的 ServiceLB 會在節點上建立對外入口；Hetzner LB 的 targets 則是兩台 worker 的內網 IP，這點可由 [.privatedocs/weamind/4-5.md](.privatedocs/weamind/4-5.md#L392) 與 [.privatedocs/weamind/4-5.md](.privatedocs/weamind/4-5.md#L426) 支撐。
- 這題最穩的收斂版本是：Hetzner LB 負責承接外部流量並送進叢集入口；Traefik 負責根據 Ingress 規則做 L7 路由；`weamind-line-bot` Service 負責在 cluster 內提供穩定入口並把流量分配到符合 selector 的 Pods。

### 狀態

- 已完成

---

## Q3

### 題目

為什麼這個專案會特別強調 K3s 節點要綁定私有網路介面？如果節點抓錯成公網 IP，最可能先影響哪一段路徑？

### 拆題

- 這兩個參數是在處理哪一層的問題？
- 如果 node 彼此都用錯 IP，最先壞掉的會是哪一類現象？
- 在外部流量路徑上，最容易最先觀察到的症狀會是哪一段？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`

### 使用者回答摘要

- 使用者先抓到這題的核心不是 Ingress 規則或 app 本身，而是 node 與 node 之間應該如何彼此定位與通訊。
- 使用者指出先前踩過的坑是：節點抓到了公網 IP，導致節點彼此不是走 Hetzner 私網，而是試圖透過公網位址互相找到對方。
- 使用者也補充，因為公網流量後來被封鎖，這種「抓錯成公網 IP」的行為就直接導致節點彼此找不到對方。
- 使用者進一步指出，如果 node 用錯 IP，最先壞掉的一定是跨節點通訊本身；節點彼此找不到對方，就更不用說去找到其他節點上的服務或 Pod。
- 使用者最後把症狀拉回外部流量路徑，認為最容易先觀察到的外層問題，會是 Hetzner LB 很難把流量正確送到應該接流量的 worker 節點入口，因為底層 node address 已經錯了。

### AI 修正與補充

- 這個方向是對的，而且已經碰到這題最核心的點：`--node-ip` 與 `--flannel-iface` 修的不是應用層 YAML，而是節點地址與叢集網路層。
- 更精準的說法是：當 K3s 節點把自己宣告成公網 IP，而不是 Hetzner 私網 IP 時，⭐️最先被破壞的是**節點彼此、overlay 網路、以及需要依賴正確 node address 的元件通訊**；外部 webhook 打不進來通常是**後續連鎖反應**，不是第一層根因。
- 你提到「公網被 ban 掉，所以找不到對方」這個記憶非常關鍵，因為它剛好說明了為什麼這題不是抽象的最佳實踐，而是這個專案的真實 root cause。
- 這一步可以再收斂成一句：如果 node address 錯了，最早出事的是叢集自己的網路與節點間通訊，Traefik、Service、甚至外部 LB 相關症狀，很多都是後面才浮出來的表面現象。
- 你選 Hetzner LB 這個觀察點也是合理的。因為在這個專案裡，外部最早能看到的表面症狀，常常就是「LB 打不進正確的私網節點入口」或「Traefik 那段看起來不通」。但更底層的 root cause 仍然是 node address 與私網介面綁定錯誤，而不是 LB 規則本身先壞掉。
- 這題完整答案可以收斂成：這個專案特別強調 K3s 節點要綁定私有網路介面，是因為整個叢集內部通訊、overlay 網路、Traefik 入口與 Hetzner LB 的私網轉發都依賴正確的 node 私網 IP。若節點誤抓成公網 IP，最先壞掉的是節點彼此與叢集網路層；而在外部流量路徑上，最容易先看到的症狀通常會是 LB 無法穩定把流量送到正確的 worker / Traefik 入口。

### 狀態

- 已完成

---

## Q4

### 題目

`--node-ip` 和 `--flannel-iface` 在這個專案裡各自是要修什麼問題？為什麼常常需要一起講？

### 拆題

- `--node-ip` 比較像是在指定什麼？
- `--flannel-iface` 比較像是在指定什麼？
- 為什麼只修其中一個還不夠？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`

### 使用者回答摘要

- 使用者坦白表示這兩個參數原本是由 AI 協助下的，自己對它們的作用沒有穩定理解。
- 使用者目前只隱約抓到兩個方向：`--flannel-iface` 應該和 CNI / Flannel 有關；`--node-ip` 應該是在指定節點應該使用哪個正確的 node IP。
- 使用者進一步連回 AWS 網路觀念，指出除了 IP 要選對之外，網卡本身也要選對，因為正確的私有網卡上才會掛著該私有網段內可用的 IP。
- 使用者已能白話說出：如果 IP 選對了但網卡選錯，或網卡對了但 node 宣告錯 IP，整體路徑仍然可能失敗。

### AI 修正與補充

- 這一題目前先不用要求完整回答，先把兩個參數各自的作用拆開理解。
- `--node-ip` 的核心是：告訴 K3s 這台節點應該用哪個 IP 當作自己的節點位址，對外與對叢集宣告自己時不要抓錯成公網 IP，而是明確使用 Hetzner 私網 IP。
- `--flannel-iface` 的核心是：告訴 Flannel 這個 CNI / overlay 網路應該綁哪一張網卡傳遞節點間與 Pod 網路相關流量，避免它跑去用錯誤的公網介面。
- 先有這兩個小答案，後面才容易組成完整說法：一個是在修「node identity / node address」，另一個是在修「overlay network 要走哪張介面」。
- 你用 AWS 的語感去想是對的。這裡你想找的名詞，通常是「子網」或「CIDR 網段」。更具體地說，私有網卡會掛在某個私有 subnet 上，而那個 subnet 會有自己的 CIDR 範圍，例如 `10.0.0.0/24` 這種。
- 所以這兩個參數常常一起講，是因為它們分別修兩件互補的事：`--node-ip` 確保節點宣告自己時用的是正確私網 IP；`--flannel-iface` 確保節點間與 Pod 網路實際走的是那張掛在私有 subnet 上的網卡。只修其中一個，另一個仍可能把流量帶去錯的介面或錯的位址。

### 狀態

- 已完成

---

## Q5

### 題目

如果今天外部 webhook 打到 `k8s.kyomind.tw` 沒有進到 line-bot，第一輪排查順序在這個專案裡應該怎麼排？

### 拆題

- 第一輪應該先查外部入口，還是先查 cluster 內 Service / Endpoints / Pods？
- 如果先查 cluster 內部，第一個最該看的會是什麼？
- 當 Service / Endpoints / Pods 都健康後，下一步應先看 Ingress / Traefik，還是先看 DNS？

### 對照檔案

- `README.md`
- `manifests/ingress.yaml`
- `manifests/service.yaml`
- `manifests/deployment.yaml`

### 使用者回答摘要

- 使用者的直覺是「請求由外而內」，因此若 webhook 沒有進到 line-bot，第一反應會想先從最接近外部請求的地方開始查，也就是 DNS、Hetzner LB、Traefik 這條外部入口路徑。
- 在調整思路後，使用者認為若要先查 cluster 內部，第一個最該看的會是 `weamind-line-bot` 的 **Endpoints**，因為這能最快確認 Service 後面是否真的有健康的 Pod 可接流量。
- 使用者也已能說出判斷邏輯：如果 Service → Endpoints → Pods 這段本身就不正常，其他更外層的檢查就沒有意義。
- 使用者接著判斷，如果 Service 底下的 Endpoints 與 Pods 都正常，下一步應先看 Ingress / Traefik 是否有正確把流量導到 `weamind-line-bot`，而不是直接跳去查 DNS。
- 使用者目前的理由是：排查順序應該沿著 Service 的外圍一層一層往外推，而不是在中間層尚未驗證時直接跳到最外層。

### AI 修正與補充

- 這個直覺很自然，但在這個專案裡，第一輪更穩的排查起點**通常不是最外面**，而是先切開內外，優先確認 cluster 內部的 `Service → Endpoints → Pods` 這段是不是活的。
- 原因不是因為外部不重要，而是因為 cluster 內這段**比較容易隔離、驗證成本更低**，而且一旦內部這段本來就壞了，去查 DNS / Hetzner LB / Traefik 只會浪費時間。
- 這點其實也和 [docs/LINE-Webhook-切換流程.md](docs/LINE-Webhook-%E5%88%87%E6%8F%9B%E6%B5%81%E7%A8%8B.md#L20) 的前置檢查順序一致：先看 nodes、pods、endpoints，再看 HTTPS 驗證與 LB 健康狀態。
- 你選 **Endpoints** 是對的。因為它是 Service 和 Pod 之間最直接的觀察點，能最快告訴你這個 Service 底下到底有沒有被正確選到、而且可接流量的 Pod。
- 你接著選 Ingress / Traefik 也是對的，而且理由可以再講得更精準：DNS 只能回答「網域有沒有被解析到某個入口」，但它完全不能告訴你請求進到叢集入口之後，有沒有被正確路由到 `weamind-line-bot`。如果 Service / Endpoints / Pods 已經健康，下一個最有診斷價值的就是 Ingress / Traefik 這一層。
- 所以這題在這個專案裡的第一輪排查順序，可以先收斂成：先看 nodes / pods / endpoints，確認 cluster 內基礎路徑活著；再看 Ingress / Traefik 是否把 `k8s.kyomind.tw` 導到 `weamind-line-bot:80`；最後才看 DNS、Hetzner LB、Webhook URL 這些更外層入口。
- 這樣排序的理由是：越靠內層越容易隔離問題、驗證成本越低，而且只要內層已經壞了，外層資訊幾乎沒有診斷價值。

### 狀態

- 已完成
