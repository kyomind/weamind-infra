# Lesson 複習筆記

## Endpoints 是怎麼產生與動態更新的？

Endpoints 可以理解成「某個 Service 在執行期實際可以導流到哪些後端 Pod IP / port」。在 WeaMind 這個 repo 裡，`weamind-line-bot` Service 不是手動指定 Pod IP，而是靠 `manifests/service.yaml` 裡的 selector：

```yaml
selector:
  app: weamind
```

這個 selector 會去對 `manifests/deployment.yaml` 建出來的 Pod label：

```yaml
labels:
  app: weamind
```

當 Service selector 選到符合 label 的 Pod，而且 Pod 已經進入**可接流量**的狀態時，**Kubernetes 會把這些 Pod 的 IP 和目標 port 整理成 Service 對應的 Endpoints**。對 WeaMind 來說，就是把 `weamind-line-bot:80` 對到後端 Pod 的 `8000`。

⭐️它是**動態更新**的，不是固定寫死。當 Deployment 建新 Pod、舊 Pod 被刪除、Pod IP 改變、**Pod readiness 狀態改變**，或 Service **selector 被修改**時，Kubernetes **控制器**會重新計算這個 Service 後面有哪些可用後端。現在 Kubernetes 內部更主要使用 EndpointSlice，但 `kubectl get endpoints weamind-line-bot -n weamind` 仍然是很直覺的觀察點。

Endpoints 會是空的，通常代表 `Service -> Pod` 這一段還沒有成立。第一輪先查：

- Service selector 是否真的對得到 Pod label：`app: weamind` 對 `app: weamind`
- Pod 是否存在，而且是否 Running / Ready
- Deployment 是否成功建立 Pod，例如 image pull、排程、啟動或 readiness probe 是否失敗
- namespace 是否查對，這裡應該是 `weamind`

所以面試時可以收斂成：Service 是穩定入口，Endpoints 是 Kubernetes 根據 Service selector、Pod label 和 Pod readiness 動態整理出的後端清單；如果 Endpoints 是空的，我會先對照 Service selector 和 Deployment 的 Pod labels，再看 Pod 是否 Ready，而不是先跳去查 PostgreSQL 或 Redis。

## Service 是否有自己的內部 DNS 和 Port？

這個理解大方向是合理的，但可以修得更精準：Service 是 Kubernetes 裡一個獨立資源，它會提供一個穩定的 cluster 內入口；這個入口通常包含穩定的 Service name / DNS 名稱、ClusterIP，以及 Service port。

在 WeaMind 裡，`weamind-line-bot` Service 宣告在 `weamind` namespace，因此叢集內可以用類似 `weamind-line-bot` 或完整一點的 `weamind-line-bot.weamind.svc.cluster.local` 來解析它。這個 DNS 名稱不是在 YAML 裡另外手寫一個 `dns` 欄位，而是 Kubernetes/CoreDNS 根據 Service 的 `metadata.name` 和 `metadata.namespace` 自動提供。

真正需要在 Service spec 裡明確宣告的是 selector 與 ports。例如這個 repo 裡的 Service 宣告：

```yaml
selector:
  app: weamind
ports:
  - name: http
    port: 80
    targetPort: 8000
```

這代表：打到 `weamind-line-bot:80` 的 cluster 內流量，會被 Service 導向符合 `app: weamind` 的 Pod，並轉到 Pod 的 `8000` port。

所以比較準確的說法是：Service 一旦被建立，就會**因為自己的 name / namespace 取得 cluster 內 DNS 名稱**；而 Service port、targetPort、selector 則是我們在 manifest 裡明確宣告的路由規則。不是「DNS 和 port 兩者都要手動聲明才算 Service」，而是「建立 Service 並宣告 port/selector 後，Kubernetes 會自動提供對應的 cluster 內 DNS 入口」。

## Service metadata.name 如何影響內部 DNS？

`metadata.name` 不是一個專門的 DNS 欄位，但它會成為 Kubernetes Service 內部 DNS 名稱的核心部分。

以 WeaMind 來說，Service manifest 裡宣告：

```yaml
metadata:
  name: weamind-line-bot
  namespace: weamind
```

因此在同一個 namespace 裡，Pod 通常**可以直接用短名 `weamind-line-bot` 連到**這個 Service；若要寫完整一點，可以是：

```bash
weamind-line-bot.weamind.svc.cluster.local
```

這個完整名稱可以拆成：⭐️

```bash
<service-name>.<namespace>.svc.cluster.local
```

⭐️⭐️⭐️
所以 `metadata.name: weamind-line-bot` **會影響 DNS 的第一段**，也就是 Service name；`metadata.namespace: weamind` 會影響第二段。這就是為什麼 Ingress backend 可以寫 `name: weamind-line-bot`，⭐️而**叢集內(任一 node)測試時**也可以打 `http://weamind-line-bot/health`：它們都在指向同一個 Service 入口。

比較精準的講法是：我們沒有在 Service 裡另外宣告 DNS 記錄，但我們宣告了 Service 的 name 和 namespace；Kubernetes/CoreDNS 會**根據這兩個值產生可解析的 cluster 內 DNS 名稱**。

## Service、Endpoints 和 CoreDNS 的關係是什麼？

CoreDNS 和前面兩則 note 的關係可以切成兩段看。

第一段是 Service name 的解析。當叢集內某個 Pod 打 `http://weamind-line-bot/health`，或查完整名稱 `weamind-line-bot.weamind.svc.cluster.local` 時，CoreDNS 負責回答：「這個 Service name 對應到哪個 cluster 內位址？」以 WeaMind 這種一般 `ClusterIP` Service 來說，CoreDNS 通常解析出來的是 **Service 的 ClusterIP**，而不是直接回 Pod IP。

第二段是流量如何到 Pod。當 client 已經拿到 Service 的 ClusterIP，或請求已經被導到這個 Service 入口後，真正把流量分到後端 Pod 的不是 CoreDNS，而是 Kubernetes Service networking 這一層，常見會牽涉到 kube-proxy / iptables / IPVS，以及 Endpoints 或 EndpointSlice 裡記錄的後端 Pod IP / port。

所以 CoreDNS **不負責「產生 Endpoints」**。Endpoints 是 Kubernetes 根據 Service selector、Pod labels、Pod readiness 等狀態整理出的後端清單。CoreDNS 主要負責「**讓 Service 的名字可被解析**」。兩者都和 Service 有關，但責任不同：

```bash
Service name -> CoreDNS -> ClusterIP
ClusterIP -> Service networking / kube-proxy -> EndpointSlice / Pod IP:port
```

另外要注意，Ingress 裡的 `backend.service.name: weamind-line-bot` 比較像 Kubernetes 物件參照，不一定代表 Traefik 是靠一般 DNS lookup 去找 `weamind-line-bot`。

⭐️Traefik 作為 Ingress controller 通常會 **watch Kubernetes API**，讀到 Ingress、Service、Endpoints / EndpointSlice 後，**建立自己的路由設定**。

對外講解時可以簡化成「Traefik 依 Ingress 規則把流量送到 `weamind-line-bot:80`」，但深入一層要知道：**CoreDNS 主要服務的是叢集內 DNS 解析**，不是 Ingress controller 唯一或必然的查找機制。

面試收斂版可以講成：CoreDNS 讓 `weamind-line-bot.weamind.svc.cluster.local` 這種 Service name 在 cluster 內可解析；Endpoints / EndpointSlice 則描述這個 Service 後面目前有哪些 Ready Pod。CoreDNS 管名字解析，Endpoints 管後端清單，真正導流到 Pod 則是 Service networking 這層在做。

## 為什麼用 EndpointSlice 取代 Endpoints 是合理的？

從這次輸出可以看到，舊的 `Endpoints` 和新的 `EndpointSlice` 描述的是同一個 Service 後面的同一批 Pod：

```bash
Endpoints:
weamind-line-bot   10.42.1.20:8000,10.42.2.19:8000

EndpointSlice:
weamind-line-bot-vqt42   IPv4   8000   10.42.1.20,10.42.2.19
```

所以在 WeaMind 目前只有兩個後端 Pod 的情境下，看起來兩者資訊差不多。但 Kubernetes 會把 `v1 Endpoints` 標成 deprecated，主因不是小型服務不能用，而是 `Endpoints` 這種**單一大物件的模型在大型服務上不夠好**。

傳統 `Endpoints` 會把同一個 Service **後面的所有後端塞在同一個物件裡**。當後端 Pod 很多、狀態常改變時，**這個物件會變得很大**，而且每次更新都容易造成較大的 API server / watch / network 負擔。`EndpointSlice` 則把後端切成多個 slice，每個 slice 只承載一部分 endpoints；後端變動時，不一定要更新整個巨大清單。

`EndpointSlice` 也比較適合承載更多結構化資訊，例如 `addressType` 顯示這批 endpoint 是 `IPv4`，port 欄位獨立呈現 `8000`，也能支援更多拓撲、條件與未來擴充資訊。這讓 controller、Ingress controller、Service networking 元件更容易用一致且可擴展的方式追蹤後端。

因此這題可以收斂成：`Endpoints` 和 `EndpointSlice` 都是在描述 Service 後端，但 `EndpointSlice` 把「一個 Service 後面可能有大量、動態變化的 Pod」這件事切成更可擴展的資料模型。對 WeaMind 這種兩個 Pod 的服務，肉眼看差異不大；對 Kubernetes 平台設計來說，EndpointSlice 更適合大規模、頻繁更新與未來擴充，所以取代 Endpoints 是合理的。

## EndpointSlice 的切分原則是什麼？50 個 replicas 會怎麼切？

EndpointSlice 的切分不是依照「每個 Deployment replica 一個 slice」，而是由 Kubernetes **endpoint slice controller** 依照 Service 的後端 endpoints 去管理。

官方文件提到，控制平面預設會讓每個 EndpointSlice **不超過 100 個** endpoints；這個值可以透過 kube-controller-manager 的 `--max-endpoints-per-slice` 調整，最高可到 1000。

所以如果 WeaMind 的 `weamind-line-bot` 從 2 replicas 擴到 50 replicas，在預設設定下，而且仍然只有同一種 address type、同一組 port/protocol，大致會是：

```bash
1 個 EndpointSlice
裡面放 50 個 endpoints
```

如果 replicas 變成 250，在預設每 slice 100 個 endpoints 的設定下，才會比較像：

```bash
EndpointSlice A: 約 100 個 endpoints
EndpointSlice B: 約 100 個 endpoints
EndpointSlice C: 約 50 個 endpoints
```

但這不是一個永遠平均分配的承諾。EndpointSlice controller 會盡量管理與填充既有 slices，但不會為了完美平均而一直重排所有 endpoints，因為那反而會製造更多更新成本。它的主要目標是讓後端清單可以被分片、可擴展地更新，而不是做漂亮的平均切片。

另外，EndpointSlice 也會受到 address type 與 port/protocol 組合影響。每個 EndpointSlice 有自己的 `addressType`，例如 `IPv4`；也有一組適用於該 slice 內 endpoints 的 ports。如果同一個 Service 因為 IPv4 / IPv6、不同 port 組合或其他條件需要分開表示，也可能出現更多 EndpointSlices。

這題可以收斂成：在 WeaMind 目前這種單一 Service port、IPv4、50 replicas 的假設下，預設通常是一個 EndpointSlice 就裝得下；EndpointSlice 真正發揮差異是在超過 100 endpoints、或有更多 address type / port 組合、或大量 endpoints 頻繁變動時。
