# 2026-04-01 LB Health Check Skeleton Note

## 學習注意事項

### 今日 lesson 邊界

- 今天主題是 WeaMind 的 LB 後端設計、Health Check Host header incident，以及 passthrough / termination 分工。
- 今天不展開 Hetzner LB 所有產品功能，也不展開 cert-manager / DNS-01 的完整細節。
- 今天也不把焦點放在 Service type `LoadBalancer` 的通用比較，而是只收斂 WeaMind 這條實際流量鏈。

### 今天要特別觀察的 repo 事實

- `README.md` 與 `docs/WeaMind Infra核心架構.md` 都已明確寫出：Hetzner LB 只做 TCP passthrough，TLS 終止在 Traefik。
- `manifests/ingress.yaml` 是 host-based routing，host 固定為 `k8s.kyomind.tw`。
- `manifests/deployment.yaml` 用 `nodeSelector.nodepool=worker` 把 line-bot Pods 固定到 worker。
- `PROGRESS.md` 已正式記錄：LB health check 在未帶 Host header 時會看到 `404`，補上 domain 後才恢復 healthy。

### 今天不展開的項目

- Hetzner Managed Certificate 與 Cloudflare DNS 的完整限制，今天只收斂到「為何沒有在 LB 終止 TLS」。
- Traefik 與 Nginx Ingress 的完整比較，保留到後續快問快答或補強。

## Notes

### 三個 node 都可能成為 Traefik 入口，但 LB 只選 worker

- 比較精準的說法不是「Traefik controller 部署在三個端點上」，而是：repo 證據顯示 `traefik` Pod 為 Running，且 `svclb-traefik` 會在各節點建立，所以 **Traefik 的 entrypoint 在每個 node 都有開放**。
- 這代表從叢集入口角度看，三個 node 都可能成為流量打進 K3s 的入口；不是只有兩個 worker 才具備入口能力。
- 但 WeaMind 在 Hetzner LB 的 target 配置上，刻意只填兩台 worker，而沒有把 control-plane 納入後端，所以 **真正對外承接 Hetzner LB 流量的 node 只有兩台 worker**。
- 因此要把兩件事分開講：**叢集層面可成為入口的 node 範圍**，和 **Hetzner LB 實際選了哪些 target**，不是同一個設定。
- 回答時也不要直接講死成「每個 node 都有一個 Traefik controller Pod」；目前 repo 內更穩的證據是 `svclb-traefik` 在各節點建立、entrypoint 在每個 node 開放。

### 用 Traefik Service 結構看三個入口與單一後端 Pod

- 你這次查到的 `kube-system/traefik` Service 更能把上一則 note 講清楚：它的 `Type` 是 `LoadBalancer`，`LoadBalancer Ingress` 同時列出 `10.0.0.3`、`10.0.0.4`、`10.0.0.5`，而 `80` / `443` 也各自對應到 `NodePort` `30417` / `31051`。
- 這代表 **三個 node IP 都被放進 Traefik 這個 Service 的對外入口集合裡**，所以從 Service 入口層來看，control-plane 與兩台 worker 都能接到打往 Traefik 的流量。
- 但 `describe svc` 同時也顯示 `Endpoints` 只有 `10.42.0.9:8000` 與 `10.42.0.9:8443`，表示目前後端實際對應到的是 **同一個 Traefik Pod endpoint**，不是三個 node 各有一個對應的 Traefik Pod endpoint。
- 再加上 `External Traffic Policy: Cluster`，更穩的理解是：**流量可以先進到任一個被列入入口的 node，再由 Service / kube-proxy 路徑轉送到實際的 Traefik endpoint**，而不是「打到哪個 node，就一定由該 node 本地的 Traefik Pod 處理」。
- 所以面試或複習時可以這樣講：WeaMind 的 K3s / Traefik 入口能力其實覆蓋三個 node，但 Hetzner LB 並沒有把這三個入口全都拿來當 target，而是只選兩台 worker，這是 **外層 LB target 選擇**，不是 **叢集內 Traefik Service 能力範圍** 的全部。

### 為什麼只有一個 Traefik Pod，三個 node 仍然都可能是入口

- 這裡最容易混掉的，是把 **入口層元件** 和 **實際處理 HTTP / TLS 的後端 Pod** 當成同一件事。
- 目前你查到的證據比較像這樣：`traefik` Service 把三個 node IP 都列進 `LoadBalancer Ingress`，而 `svclb-traefik-...` 是 DaemonSet，表示 **每個 node 都有一個 K3s ServiceLB 的入口代理 Pod**。
- 但 `Endpoints` 只有一個 `10.42.0.9`，表示真正被 Service 指到的 Traefik backend endpoint 當下只有一個，所以 **真正處理請求的 Traefik Pod 可以只有一個**。
- 因此比較準確的理解是：**三個 node 都能接流量進來，是因為 `svclb-traefik` DaemonSet 把入口鋪在每個 node 上；不是因為三個 node 都各自跑一個 Traefik backend Pod**。
- 流量路徑可以先暫時記成：`外部請求 -> 某個 node 上的 svclb-traefik 入口 -> traefik Service -> 單一 Traefik endpoint -> Ingress routing -> app Service -> app Pod`。

### Traefik backend 現在落在 control-plane，這樣合理嗎

- 目前這次 runtime 觀察顯示：真正被 `endpoints traefik` 指到的 backend Pod 是 `traefik-6f5f87584-g5knx`，而且它落在 `weamind-001`。若 `weamind-001` 是 control-plane，代表 **當下真正處理 Traefik 請求的 backend Pod 的確在 control-plane 上**。
- 這裡要先拆開兩件事：**外部入口從哪個 node 進來**，以及 **Traefik backend 最後在哪個 node 上處理請求**。WeaMind 的 Hetzner LB target 仍然只選兩台 worker，所以 **對外入口** 還是只從 worker 進來；但進來後，流量依然可能被 Service 轉送到 control-plane 上的 Traefik backend Pod。
- 對小型 K3s 叢集來說，這種情況 **技術上合理、也常見**，因為預設內建元件通常先求簡單可用，不一定會主動把 Ingress controller 嚴格限制在 worker。你目前查到的 `svclb-traefik` 也有 `control-plane` toleration，表示這套入口機制本來就允許 control-plane 參與。
- 但如果從 **角色隔離** 與 **維運風險控制** 來看，這不是最理想的最終狀態。因為 control-plane 的主要職責應該是叢集管理；若 Traefik backend 長期落在 control-plane，就表示 **控制面其實仍參與了部分資料面流量處理**。
- 若其中一台 worker 壞掉，只要另一台 worker 仍在 Hetzner LB target 裡，外部流量通常還是可以從剩下那台 worker 進來；而後續是否還能被轉到 Traefik backend，則要看 **control-plane 與剩餘 worker 之間的叢集內流量路徑** 是否正常。換句話說，worker 壞一台不代表入口必然全斷。
- 更貼近真實世界的常見做法通常有兩種：**把 Ingress controller 明確固定在 worker nodes**，或 **使用專門的 ingress nodes**；較少把它長期放在 control-plane 當主要資料面處理點，除非叢集很小、追求簡化，或只是暫時過渡配置。
- 另外也要校正一個容易混掉的點：**不是 DaemonSet 通常只有一個 Pod，而是 DaemonSet 通常在每個符合條件的 node 各跑一個 Pod**。這次你看到只有一個真正的 Traefik backend Pod，並不是因為 DaemonSet 天生只會有一個，而是因為 **真正的 backend 看起來不是 `svclb-traefik` 這個 DaemonSet，而是後面的 `traefik` workload 本身目前只有單一 backend endpoint**。
- 所以這一題目前最穩的短結論是：**WeaMind 現在的外部入口仍只從 worker 進來，但 Traefik backend runtime 觀察上仍落在 control-plane；對小型 K3s 這可以運作，但若追求更清楚的 control-plane / data-plane 分離，之後值得研究如何把 Traefik backend 也固定到 worker 或專用 ingress nodes。**

### Hetzner LB 的 `Domain` 為什麼最後會對應到 `Host` header

- 這裡其實是 **產品介面命名** 與 **HTTP 協定實作** 的差別。Hetzner LB 設定頁把欄位叫做 `Domain`，因為它是在問你：「這個 health check 要模擬哪個網域的請求？」
- 但當 LB 真的送出 HTTP health check request 時，它不能把「domain」這個概念直接塞進封包裡；在 HTTP 裡，這個資訊實際上是透過 **`Host` header** 來表達。
- 所以在設定畫面看到的是 `Domain: k8s.kyomind.tw`，而真正送到 Traefik 那一端時，效果等同於 request 內帶著 **`Host: k8s.kyomind.tw`**。
- 因此不要把它理解成兩套不同機制，而要理解成：**Hetzner UI 的 `Domain` 欄位，是用來決定 health check request 要帶什麼 `Host` header。**

### Traefik 做完 TLS termination 後所說的 HTTP routing，到底是什麼 routing

- 這裡的 **HTTP routing 不是 L4 routing，而是 L7 routing**。因為當 Traefik 完成 TLS termination 之後，它看到的已經不是單純的 TCP 連線，而是可以被解析的 HTTP request。
- 一旦 HTTPS 被解開，Traefik 就能根據 **HTTP 層資訊** 來決定往哪裡送，例如 `Host`、`Path`、Method，或 Ingress 規則裡宣告的 `host` / `path` 條件。這種依 HTTP 內容做判斷的轉送，就是 **L7 routing**。
- 以 WeaMind 這個專案來說，最直接的例子就是 [manifests/ingress.yaml](manifests/ingress.yaml#L9) 到 [manifests/ingress.yaml](manifests/ingress.yaml#L17) 裡的 `host: k8s.kyomind.tw` 和 `path: /`。Traefik 會先看 request 的 `Host` 是否命中，再看 path 是否命中，最後才轉到 `weamind-line-bot` Service。
- 相對地，**L4 routing** 只看連線層資訊，例如 IP、port、protocol。Hetzner LB 在這個專案的 `443 -> 443` passthrough 就比較接近這一層：它不需要理解 HTTP 內容，只是把 TCP 連線原樣轉進叢集。
- 所以這條鏈路可以記成：**Hetzner LB 做的是偏 L4 的 TCP 轉送；Traefik 在 termination 之後做的是 L7 的 HTTP routing。**

### L4 / L7 不是流程先後順序，Kubernetes 內部也有偏 L4 的轉送

- 這裡一個很值得記住的點是：**L4 和 L7 是「依據哪一層資訊做判斷」的分類，不是流程時間順序。** 所以完全可能出現「前面先經過一個偏 L4 的轉送層，後面再進入一個偏 L7 的路由層」；WeaMind 現在就是這種結構。
- 也就是說，不是一定要先 L7 再 L4，或先 L4 再 L7；真正要問的是：**這一跳轉送決策到底看的是 TCP / port，還是看的是 HTTP `Host` / `Path`。**
- Kubernetes 叢集內部當然也有偏 **L4** 的層。最典型的就是 **Service**：`ClusterIP`、`NodePort`、`LoadBalancer` 這些機制，本質上主要是在把流量依 `IP + Port` 轉送到後端 endpoints，較接近 L4 / transport 層的負載分流。
- 以你這次查到的 Traefik 路徑來說，`svclb-traefik` 把主機 `80/443` 導到 `traefik` Service 的 `ClusterIP`，而 `traefik` Service 再把流量轉到 backend endpoint，這一段就比較偏 **L4-style forwarding**。
- 真正進入 **L7** 的時刻，是 Traefik 拿到已解密的 HTTP request 之後，開始根據 Ingress 規則判斷 `Host` / `Path` 要轉去哪個 Service。這也是為什麼在 Kubernetes 世界裡，通常會說：**Service 比較像 L4，Ingress controller 比較像 L7。**

### 為什麼 WeaMind 現在外網直接打 HTTP 也能拿到回應

- 這裡要先把兩件事拆開：**「可以用 HTTP 打到」** 和 **「有沒有自動強制跳轉到 HTTPS」** 不是同一件事。現在 WeaMind 的現象看起來是：**HTTP 可以打到，而且目前沒有做 HTTP→HTTPS redirect**。
- repo 證據也支持這件事：`PROGRESS.md` 明確記錄 Hetzner LB 先建了 **HTTP `80 -> 80`** 的 service，見 [PROGRESS.md](PROGRESS.md#L108)；而 [manifests/ingress.yaml](manifests/ingress.yaml#L1) 到 [manifests/ingress.yaml](manifests/ingress.yaml#L17) 只有宣告 `tls` 與一般 `rules`，**沒有看到任何 redirect middleware、redirect annotation，或強制只走 `websecure` 的設定**。
- 這代表目前的 Traefik / Ingress 行為比較像是：**同一組 host/path 規則同時可被 HTTP 與 HTTPS 命中**；TLS 區塊只是讓 HTTPS 有可用憑證，**不等於自動把 HTTP 轉成 HTTPS**。
- 所以從外網直接打 `http://k8s.kyomind.tw/health`，目前仍可能得到正常回應；瀏覽器顯示「不安全」，主要是在提醒你 **這條連線沒有加密**，不是在說這個 route 不存在。
- 你前面一度猜「也許只有內網 HTTP 才能打」這個推論，現在看起來不成立。真正更準確的說法是：**內外網都可能打得到 HTTP，只是外網走 HTTP 時沒有 TLS 保護。**

### WeaMind 目前沒有做 HTTP→HTTPS redirect，這是不是風險

- 是，這可以視為目前配置上的一個 **安全性與一致性缺口**，至少和你單機版用 Nginx 強制導向 HTTPS 的習慣相比，K8s 這邊目前還沒補上同等行為。
- 只要外部 `80` 還開著，而且 Ingress 沒有加 redirect 規則，使用者或探測器就可能直接用 HTTP 拿到內容。對 `/health` 這種低敏感路徑，風險相對小；但若把同樣模式擴大到其他路徑，就不會是理想的最終狀態。
- 更精準地說，**TLS 已經存在，不代表 HTTPS-only 已經成立**。這兩件事需要分開確認：前者是「443 可用且有憑證」，後者是「80 來的請求會不會被強制導向 443」。WeaMind 目前 repo 證據看起來只完成了前者。
- 因此這裡很值得留一個後續問題：**若要把 K8s 版 WeaMind 做到更接近正式公開服務，是否應在 Traefik / Ingress 層補上 HTTP→HTTPS redirect。** 這題目前適合放進後續 lesson 或 command drill，不在今天直接展開。

### 外部實測：目前 HTTP 與 HTTPS 都能直接拿到 `/health` 回應

- 這次直接從外部實測後，可以把前面的推論正式坐實：`http://k8s.kyomind.tw/health` 與 `https://k8s.kyomind.tw/health` 目前都能直接回 `200` 與 `{"status":"ok"}`。
- 用 `curl -I` 打 `http` 與 `https` 都看到 `405 Method Not Allowed`，不是 redirect。這個現象不是 route 壞掉，而是因為 app 的 `/health` 目前 **不接受 `HEAD` 方法，只接受 `GET`**，所以 `curl -I` 會先撞到 method 問題。
- 改用一般 `GET` 後，HTTP 與 HTTPS 都能正常拿到 `200`，而且 `curl -L http://k8s.kyomind.tw/health` 的最終 URL 仍然是 `http://k8s.kyomind.tw/health`，這表示 **目前確實沒有做 HTTP→HTTPS redirect**。
- 這也代表目前外部 `80` 的流量不是只留給內網 health check 或某種特殊用途，而是真的可以從外網直接命中同一條 Ingress route。

### 對 WeaMind 當前用途來說，這個缺口的風險大概在哪裡

- 若只看 `/health` 這條路徑，本身回的是極少量狀態資訊，所以 **單一路徑風險不高**。
- 若看主要用途是 LINE webhook，LINE 平台本身會使用 HTTPS webhook URL，所以 **正常產品流量理論上仍會走 HTTPS，不會主動降級成 HTTP**。
- 但這不代表缺口不存在。因為只要 `80` 還開著且未 redirect，外部其他客戶端、人工測試、掃描器或誤用者，仍然可能直接用 HTTP 打到同一個 host/path。若未來更多 endpoint 暴露在同一組規則下，風險就不會只停在 `/health` 這種低敏感路徑。
- 換句話說：**就 WeaMind 目前以 LINE webhook 為主的情境來看，這比較像「不是最高優先的安全風險」，但仍是值得補的公開入口配置缺口。**
- 另外因為這個專案使用的是 **DNS-01** 申請憑證，不需要保留外部 `80` 來做 ACME HTTP-01 驗證，所以從需求面看，後續其實更有理由考慮補上 redirect，甚至評估是否縮小外部 `80` 的用途。

### 對 app repo 實際 paths 交叉檢查後，HTTP 缺口目前落在哪裡

- 在 `WeaMind` app repo 中，目前主要對外路徑包含：`GET /`、`GET /health`、`POST /line/webhook`、`POST /users/locations`。
- 外部 HTTP 實測顯示：`GET /` 會直接回 `200` 與 welcome JSON，表示 **這個公開根路徑目前也能被 HTTP 直接存取**。
- `POST /line/webhook` 走 HTTP 時，缺少 `X-Line-Signature` 會直接回 `422`；這表示 **即使入口缺少 redirect，webhook 路徑本身仍有應用層的簽章要求**，不會因為單純打到 HTTP 就直接成功執行 webhook 邏輯。
- `POST /users/locations` 走 HTTP 時，缺少 access token 會回 `403 Not authenticated`；這代表 **這條業務 API 也有應用層認證保護**。
- 但這些保護和「是否允許未加密 HTTP 傳輸」是兩件不同的事。更準確地說：**目前 app 層有基本存取保護，但入口層仍允許外部 HTTP 直接命中這些 paths。**
- 所以目前最值得擔心的，不是「有人一敲 HTTP 就能直接偽造成功 webhook」，而是 **原本應只透過 HTTPS 暴露的公開 API，現在仍可透過未加密 HTTP 被探測、呼叫或誤用**。

### 為什麼這條 `curl http://127.0.0.1/...` 要在 node 上跑，而不是在 Pod 或本機跑

- 這題的驗證目標不是 app Pod 本地有沒有回應，而是 **node 入口層能不能先命中 Traefik / Ingress**。所以 `127.0.0.1` 應該指向的是 **K3s node 自己**，不是本機 Mac，也不是 app Pod。
- 在本機 Mac 上跑時，`127.0.0.1` 只會指回 Mac 自己，所以看不到 K3s 節點上的 `80/443` 入口；因此得到 `curl: (7) Couldn't connect to server` 是合理結果。
- 在 app Pod 內跑也不適合，因為 Pod 內的 `127.0.0.1` 只會打到 Pod 自己，測到的是 container 本地網路，不是在測 node 入口與 Ingress 規則。
- 所以這類 `curl -H 'Host: ...' http://127.0.0.1/...` 的題目，本質上是在測 **某台 K3s node 本機的 Traefik 入口行為**。

### 為什麼 control-plane 上打 `127.0.0.1:80` 也能成功

- 使用者刻意在 `weamind-001`（control-plane）上執行 `curl -H 'Host: k8s.kyomind.tw' http://127.0.0.1/health`，成功得到 `{"status":"ok"}`。這再次證明：**control-plane 本機目前也確實有可用的 Traefik 入口。**
- 這不代表 Hetzner LB 會把外部流量送到 control-plane，而是代表 **在 node 本機這一層，`svclb-traefik` 已把 `80/443` 監聽起來，並能把流量導進 Traefik / Ingress**。
- 所以要把兩件事分清楚：**control-plane 不是 Hetzner LB target**，但 **control-plane 仍可能在叢集內 runtime 狀態下具備本地入口能力**。
- 這也是為什麼前面在談「LB 只選 worker」時，要避免把它講成「只有 worker 才有入口」。更穩的說法是：**worker 是外層 LB 的正式 target；而 node 本地入口能力在目前 K3s / `svclb-traefik` 配置下，control-plane 也可能同樣具備。**

### 如果未來有兩種服務，都想對外用 `80/443`，會怎麼分

- 目前 WeaMind 看起來像是「只有一個服務在用 `80/443`」，所以容易讓人誤以為是 app 自己獨占了這兩個 port；但更精準地說，**真正占住 node `80/443` 的不是 app Pod，而是入口層的 `svclb-traefik` / Traefik**。
- 如果未來有第二種服務，正常做法**不是**讓第二個 app 也直接去綁 node 的 `80/443`，因為同一台 node 上同一個 port 不能被兩個不同入口元件同時獨立占用。
- 更常見的做法是：**仍然只保留一個入口層（例如 Traefik）占住 `80/443`，再用不同的 `Host` 或 `Path` 規則把流量分到不同 backend Service。**
- 例如可以是：`app1.example.com` 轉到 Service A，`app2.example.com` 轉到 Service B；或 `/api-a` 走 Service A、`/api-b` 走 Service B。這時共用 `80/443` 的是入口層，不是後面的 app Pod。
- 若真的想讓兩個服務各自獨立擁有 `80/443`，通常就需要**不同的外部 IP / 不同的 Load Balancer / 不同的節點池 / 不同的 ingress nodes**，否則在同一組 node 上會出現 port conflict。
- 所以這題可以先記一個最穩的口訣：**多服務共享 `80/443` 的關鍵不是讓多個 app 去搶 port，而是讓單一 ingress 入口先接流量，再做 L7 分流。**

### `kubectl get ingress ... -o yaml` 這條指令到底在看什麼

- 這條指令的價值不只是「把 Ingress 印出來」，而是讓你直接看到 **Traefik 到底是依什麼規則在分流**。
- `spec.ingressClassName: traefik` 表示這份規則是交給 Traefik 接管；如果這裡不是 `traefik`，就代表這份 Ingress 不一定會被目前的 controller 實際處理。
- `spec.rules[].host: k8s.kyomind.tw` 是最關鍵的欄位，因為它直接說明：**這是一條 host-based routing 規則**。也就是說，request 只有在 `Host` 命中 `k8s.kyomind.tw` 時，才會被這條規則接住。
- `spec.rules[].http.paths[].backend.service.name: weamind-line-bot` 與 `port.number: 80` 則告訴你：**命中這條 host/path 規則後，流量接下來會被送到哪個 Service。**
- `path: /` 加 `pathType: Prefix` 代表這個 host 底下，以 `/` 為前綴的路徑都會被這條規則處理，所以像 `/health` 這類路徑也包含在內。
- `spec.tls.hosts` 與 `secretName: k8s-kyomind-tw-tls` 表示同一個 host 也綁了 TLS 憑證，所以 **這份 Ingress 不只定義 HTTP routing，也同時定義 HTTPS 要使用哪張憑證。**
- `status.loadBalancer.ingress` 出現 `10.0.0.3`、`10.0.0.4`、`10.0.0.5`，則是在告訴你 **目前這份 Ingress 對外宣告的入口資訊包含哪些 IP**。這不等於 Hetzner LB 一定會把流量送到三台，但它能幫你把 Ingress 規則和實際入口能力對起來。
- 所以最實用的記法是：**`kubectl get ingress -o yaml` 讓你一次看到 controller 是誰、host/path 怎麼匹配、後端 Service 是誰、TLS 憑證綁哪裡，以及它目前對外宣告了哪些入口 IP。**

### Hetzner LB 的 HTTP health check 到底在檢查什麼，和 Pod health 有什麼關係

- 這次很容易混淆的一點是：**Hetzner LB 的 health check 不是直接去看 Kubernetes Pod 的 liveness/readiness probe。** 它檢查的是「LB 這個 target node，能不能對這條外部入口路徑回出符合條件的結果」。
- 以 WeaMind 目前的 `http:80 -> 80` 來說，LB 送出的其實是一個 **真正的 HTTP request**：打 `80`、走 `/health`、帶 `Host: k8s.kyomind.tw`，然後期待收到 `200`。
- 所以它驗證到的不是單一 Pod 自身健康，而是 **一小段端到端入口鏈路** 是否成立：`LB -> worker node:80 -> Traefik entrypoint -> Ingress host/path match -> weamind Service -> app Pod -> /health 回 200`。
- 這也是為什麼當初沒帶正確 `Host` 時，即使 app 的 `/health` endpoint 沒壞，LB 仍然會看到 `404` 並把 target 判成 unhealthy。因為 **失敗點發生在 Ingress routing**，不是 Pod probe。
- 因此更精準的說法是：**Hetzner LB 現在做的是入口層的合成健康檢查（synthetic end-to-end check），不是 Kubernetes 原生的 Pod health probe。**
- 若要談 Pod 本身健康，應回頭看 Deployment / Pod 裡的 `readinessProbe`、`livenessProbe`；若要談外部使用者能不能真的經過入口打到服務，才看這個 LB health check。

### Hetzner UI 顯示 source port 固定、destination port 可改，這代表什麼

- 這次 UI 行為很關鍵：**Hetzner LB 的 service 是以 source port 為一個獨立 listener 來管理的。** 所以既有的 `80` listener 不能直接變成另一個 `443` listener；若要不同 source port，必須新建另一條 service。
- 因為 WeaMind 已經有一條 `tcp:443 -> 443`，所以你也不能再另外建第二條 source port `443` 的 service。這表示 **同一個 LB 上，同一個對外 port 只能有一條 service 佔用。**
- 更重要的是，當你把 `http:80 -> 80` 的 protocol 切成 `https` 時，UI 不是只在改 health check，而是在改 **整條 LB service 的協定語義**。這也是為什麼畫面立刻開始要求 `Add certificates`，並出現 `HTTP-Redirect (301)` 選項。
- 也就是說，這個 `https` 不是「保留原本 passthrough 架構，只讓 health check 偷偷改走 HTTPS」；它比較像是在說：**讓 Hetzner LB 自己成為 HTTPS listener / TLS termination 點。**
- `destination port` 可改，代表的是：**外部打進 LB 的某個 source port，可以被轉送到 target node 的另一個 port。** 例如理論上可做 `80 -> 443`，但那仍然是「外部入口是 80 這條 service」，不是在新增一條獨立的 `443` health check。
- 因此這次最重要的修正是：**先前以為可以在不動整體架構下，把 LB health check 單獨切到 HTTPS，這個推論過度樂觀。** 依 Hetzner 目前 UI 行為看，health check 與 service protocol 綁得比我們原先想像更緊。
- 對 WeaMind 而言，這代表後續若要補 `HTTP -> HTTPS redirect`，不能直接把現有 `80` service 改成 `https`，因為那會把 TLS termination 從 Traefik 拉回 Hetzner LB，和目前專案的 passthrough 設計衝突。

### 為什麼現在不能直接動 Hetzner LB，這其實是在動整個入口邊界

- 這次最需要拉高一層來看的，不是「某個欄位能不能改」，而是：**WeaMind 現在的 LB 設定其實已經承載了一整串過去收斂過的架構決策。**
- 從歷史脈絡看，這條線不是隨機長成現在這樣。當初先遇到的是 **HTTP health check 不帶 Host 會失敗**，所以 `80` 這條 service 被固定成「用 HTTP 做入口存活檢查」；後來又遇到 **Hetzner Managed Certificate 不適合 Cloudflare DNS**，於是 TLS 方案改走 **cert-manager + DNS-01**；再往後還踩到 **同一個 source port 不能重複宣告**，所以最終才收斂成現在這種：`80` 留給 HTTP 與 health check，`443` 留給 TCP passthrough，TLS termination 放在 Traefik。
- 也就是說，**目前的 LB 不是單純兩條 service 而已，而是一個已經和 K8s 內部責任邊界對齊的結果。** 它背後同時綁住了憑證生命週期、TLS 終止位置、LB 是否理解 HTTP、以及 Ingress 是否繼續作為唯一的 L7 路由入口。
- 因此現在若直接去動 Hetzner LB，風險不只是「health check 可能紅掉」，而是 **你可能在沒有明說的情況下，把 TLS 邊界從 Traefik 拉回 LB，或把原本分離好的責任重新混在一起。**
- 更麻煩的是，Hetzner 的限制讓這件事 **不太能用平行試跑的方式驗證**。因為 `443` source port 已經被既有 service 佔住，你不能再旁邊開另一條 `443` 來做對照；這代表任何改動都更像 **切換架構**，而不是 **局部微調**。
- 所以「現在不能動」更準確的意思不是永遠不能碰，而是：**在還沒重新定義 TLS 終止點、redirect 策略、health check 存活條件之前，不應把 Hetzner LB 當成可以直接試改的局部設定。**
- 若之後真的要動，前提也應該先變成一個新的設計題：究竟要維持 **LB 只做 L4、Traefik 做 TLS/L7**，還是要改成 **LB 也參與 HTTPS / redirect / certificate 管理**。這兩條路都能做，但不是同一個小修的延伸。

### 為什麼不能把 TLS termination 再拉回 Hetzner LB

- 這題可以再更直白一點：**不是我們不喜歡 Hetzner LB 做 termination，而是我們當初已經明確拒絕了它背後那整套前提。**
- 對 WeaMind 來說，若要讓 Hetzner LB 正規地做 HTTPS termination，最順的搭配通常就是 **Hetzner Managed Certificate**；但這條路的硬限制是 **憑證管理會綁到 Hetzner DNS 生態**。
- 而 WeaMind 的 DNS 明確留在 Cloudflare，這不是偶然，而是有意識的選擇。所以當初一旦拒絕「把網域託管搬去 Hetzner」，其實也就等於一起拒絕了「讓 Hetzner 成為我們主要 TLS 終止點」這條最自然的產品路徑。
- 也因此，現在的架構不是退而求其次的臨時 workaround，而是 **在保留 Cloudflare DNS 這個前提下，刻意收斂出來的穩定方案**：`443` 只做 TCP passthrough，真正的 TLS termination 留在 Traefik，憑證生命週期交給 `cert-manager + DNS-01`。
- 所以現在若又想把 termination 拉回 Hetzner LB，本質上不是優化同一條路，而是 **回頭推翻當初「DNS 不搬、憑證留在 K8s 內管理」這個核心決策。**

### Redirect 在 WeaMind 現況裡是 nice-to-have，不是非做不可

- 到目前為止，lesson 與外部實測都支持同一個判斷：**WeaMind 現在缺的是入口一致性，不是已知高危突破口。**
- 原因是目前能被 HTTP 直接命中的，主要是首頁與 `/health` 這類低敏感路徑；而比較關鍵的入口像 webhook 或 user API，仍然有應用層簽章或 token 驗證，不會因為單純走 HTTP 就直接成功。
- 所以這次研究 redirect 的價值，重點不只是「今天一定要把它做完」，而是 **把架構邊界、可行落點與 suspend 條件講清楚**。這對未來回頭補硬化時，會比硬做一個不乾淨的方案更有價值。
- 更精準地說，這題目前的成功標準可以拆成兩層：
- 第一層是 **技術上確認 Traefik / Middleware 能否優雅處理 redirect**。
- 第二層才是 **若方案不扭曲既有 TLS 邊界，就落地；若需要回頭碰 Hetzner termination 或讓 health check 變脆弱，就暫時 suspend。**

## Flashcards

- 為什麼 WeaMind 的 Hetzner LB 後端只放 worker？ #DevOps #card
	- `nodeSelector.nodepool=worker` 把 app workload 固定在 worker
	- LB target 也只選 worker，讓入口流量與 workload placement 對齊
	- 目的是避免把 control-plane 拉進正常資料面路徑

- 為什麼 LB health check 沒帶正確 `Host` 會看到 `404`？ #DevOps #card
	- `Ingress.rules.host` 在 HTTP 層實際靠 `Host` header 匹配
	- 沒命中時是 Traefik 在入口層先回 `404`
	- 這不等於 app `/health` endpoint 壞掉

- Hetzner LB 的 `Domain` 欄位和 `Host` header 是什麼關係？ #DevOps #card
	- `Domain` 是 Hetzner UI 的產品命名
	- 真正送出 HTTP request 時，效果等同帶上 `Host: <domain>`
	- Traefik 不看 UI 名稱，只看 request 內的 `Host`

- `cert-manager` 和 Traefik 在 TLS 流量裡怎麼分工？ #DevOps #card
	- `cert-manager` 負責申請、續期、保存憑證到 Secret
	- 真正做 TLS termination 與後續 HTTP routing 的是 Traefik
	- Hetzner LB 在這個專案只做 TCP passthrough

- 為什麼三個 node 都能成為入口，但 Traefik backend endpoint 只有一個？ #DevOps #card
	- `svclb-traefik` DaemonSet 在每個 node 鋪 `80/443` 入口
	- `traefik` Service 再把流量轉到 backend endpoint
	- 入口 node 數量不必等於 Traefik backend Pod 數量

- `curl -H 'Host: ...' http://127.0.0.1/health` 應該在哪裡執行？ #DevOps #card
	- 要在 K3s node 上跑，因為這是在測 node 本機的 Traefik 入口
	- 不是在測本機 Mac，也不是在測 app Pod 內部
	- 若要最貼近 LB target 設計，優先在 worker node 上測

- 為什麼 control-plane 上打 `127.0.0.1:80` 也可能成功？ #DevOps #card
	- control-plane 雖非 Hetzner LB target，但目前 runtime 仍具本地入口能力
	- `svclb-traefik` 已在 node 本機監聽 `80/443`
	- 這證明「不是 LB target」不等於「完全沒有入口」

- 如何用最小證據證明 WeaMind Pods 被固定在 worker？ #DevOps #card
	- `pods -o wide` 看的是當下落點
	- `deployment -o yaml` 的 `nodeSelector.nodepool=worker` 才是長期約束
	- 現況與約束都對上，才算真正證明 workload placement

- `curl -I` 和 `curl -L` 在 redirect 題目裡各自代表什麼？ #DevOps #card
	- `-I` 送的是 `HEAD` request，只看 headers
	- `-L` 只會在遇到 `301/302/307/308` 時追跳轉
	- 若先拿到 `405`，不能直接拿來判定 redirect 是否存在

- WeaMind 目前沒有 HTTP→HTTPS redirect，風險該怎麼看？ #DevOps #card
	- 現在是入口層配置缺口，不是立即高危漏洞
	- `/health` 與公開根路徑可被 HTTP 直接命中
	- webhook 與 user API 仍有應用層簽章或認證保護
	- 對 LINE webhook 為主的現況風險可控，但正式化後仍值得補 HTTPS-only
