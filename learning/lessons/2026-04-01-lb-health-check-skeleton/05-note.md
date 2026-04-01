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

## Flashcards
