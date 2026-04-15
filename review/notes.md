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

## 如果 Endpoints 查出來是空的，能不能直接判斷 Service 接不到 Pod？

可以先下的結論是：**就這個 Service 目前的導流狀態來說，它後面沒有可用的 Pod endpoints，所以它現在無法把流量轉送到 Pod。** 這個判斷在 WeaMind 的情境裡是成立的，因為 [manifests/service.yaml](manifests/service.yaml) 的 `weamind-line-bot` Service 是靠 `selector: app: weamind` 去選 Pod，而 [manifests/deployment.yaml](manifests/deployment.yaml) 的 Pod 也確實是靠 `app: weamind` 這個 label 被選到。

但更精準地說，**空 Endpoints 不等於「叢集裡完全沒有 Pod」**，而是等於「這個 Service 目前沒有可導流的後端」。常見原因有幾種：
1. Pod 根本沒起來
2. Pod 有起來但 label 不符合 Service selector
3. Pod 還沒 Ready
4. 查錯 namespace

以 WeaMind 這份 Deployment 來看，因為有 readiness probe，所以就算 Pod 處於 Running，也可能尚未被納入 Service 後端。

所以面試或複習時，最穩的說法是：如果 `kubectl get endpoints -n weamind` 看到 `weamind-line-bot` 的 endpoints 是空的，我可以先確認這個 Service 現在接不到可用 Pod；下一步要去分辨是「沒有 Pod」、還是「有 Pod 但沒有被這個 Service 選進來」。這時通常就接著查：

```bash
kubectl get pods -n weamind
kubectl get pods -n weamind -o wide --show-labels
kubectl describe svc weamind-line-bot -n weamind
```

一句話收斂：**空 Endpoints 可以判斷 Service 目前沒有可導流的 Pod，但不能只靠這一點就斷言整個 namespace 裡完全沒有 Pod。**

## -o wide 是什麼？用不用它，差別到底在哪？

`-o wide` 可以先理解成：**還是同一個 `kubectl get`，只是把預設表格輸出再展開一點，補更多實用欄位**。它不是查另一種資料來源，也不是改變資源本身，只是改變你看到的顯示內容。

所以「有沒有用 `-o wide`」的差別，核心不是 Kubernetes 看到的世界不同，而是**你拿到的觀察資訊密度不同**。

以這次 WeaMind 的例子來說：

- `kubectl get pods -n weamind`：你先看到 Pod 名稱、Ready、Status、Restarts、Age，適合先判斷有沒有活著
- `kubectl get pods -n weamind -o wide`：會再補出像 Pod IP、Node 這類欄位，才有辦法把 Endpoints 裡的 IP 對回實際 Pod

所以這題真正要記住的是：**`-o wide` 不是「更多細節的萬用完整版」，而是「表格模式下的加欄版」**。當你只是想快速看健康狀態，預設輸出通常夠；當你要對 IP、對 node、看 image、看更具體的執行位置時，`-o wide` 才會有差。

另外也要補一個邊界：`-o wide` 常見於 `kubectl get`，而且是否有明顯差異，取決於資源種類。像 Pods 用 `-o wide` 很常有用，因為會多出 Pod IP / Node；但有些資源就可能只多一兩欄，甚至差異不大。所以它不是「所有 kubectl 指令的通用深度模式」，而是某些 `get` 輸出格式的一種變體。

如果要和其他 `-o` 一起比較，可以這樣背：

- 預設輸出：快速掃狀態
- `-o wide`：仍然是表格，但多幾個關鍵欄位
- `-o yaml` / `-o json`：看完整物件內容

所以在 debug 流程裡，`-o wide` 很適合卡在中間那一層：**預設輸出不夠，但又還沒必要直接翻整份 YAML/JSON。**

一句話收斂：**`-o wide` 不會改變 Kubernetes 裡的實際狀態，只是把 `kubectl get` 的表格輸出展開，讓你多看到像 Pod IP、Node 這種預設沒顯示的欄位。**

## pod-template-hash 是誰加的？目的與作用是什麼？

可以先回答成：**是 Deployment / ReplicaSet 這條控制鏈自動加上的，不是你在 manifest 手動寫的。**

更精準一點說，通常是 Deployment controller 依照 Pod template 的內容算出一個 hash，然後把這個值放進它建立出的 ReplicaSet selector、Pod template labels，最後你才會在 Pod 身上看到像 `pod-template-hash=5985b7f7f6` 這種 label。

它的主要目的不是給 Service 用，而是給 Kubernetes 自己做「版本分流與歸屬辨識」。作用可以抓三個重點：

- 區分不同版本的 ReplicaSet：同一個 Deployment 每次 Pod template 有變更，例如 image、env、command、probe 變了，就會產生新的 hash，從而建立新的 ReplicaSet
- 讓 ReplicaSet 只接管屬於自己的 Pods：ReplicaSet 需要有辦法辨認哪些 Pods 是它那一版模板生出來的，避免不同版本互相搶 Pod
- 支援 rollout / rollback：Deployment 做 rolling update 時，本質上就是新舊 ReplicaSet 並存一段時間；這個 hash 讓系統能清楚分辨舊版本 Pods 和新版本 Pods

所以在你這次看到的情境裡，兩個 Pods 都有同樣的 `pod-template-hash=5985b7f7f6`，表示它們來自同一個 ReplicaSet，也就是同一版 Pod template。若之後 Deployment 更新，常見情況就是會看到另一批 Pods 帶著不同的 `pod-template-hash`。

也因為它的用途是給 Deployment / ReplicaSet 管理版本，所以 **Service 通常不應該依賴這個 hash 當 selector**。Service 應該選穩定、業務語意明確的 label，例如這個 repo 裡的 `app=weamind`；如果用 `pod-template-hash` 當 selector，rollout 時很容易只選到某一版 Pods，甚至導致切流不穩。

一句話收斂：**`pod-template-hash` 是 Kubernetes 控制器為了區分不同 Pod template 版本而自動加上的標記，主要服務對象是 Deployment 與 ReplicaSet 的 rollout 管理，不是給 Service 當主要 selector 用的。**

## Pod crash 時，什麼情況是 Kubelet 重啟容器？什麼情況是 ReplicaSet 建新 Pod？

這題最重要的第一句是：**Kubernetes 平常不是在「重啟同一個 Pod 物件」，而是兩條不同機制在工作。**

- `Kubelet` 管的是「這個已存在的 Pod 裡面的容器要不要重啟」
- `ReplicaSet` 管的是「目前符合條件的 Pod 數量夠不夠，不夠就補一個新的 Pod」

所以判斷關鍵不是只看「app 掛了」，而是要看：**壞掉的是容器執行狀態，還是整個 Pod 物件已經不存在 / 即將消失 / 被判定失效。**

先講 Kubelet 這條。

在 WeaMind 這種由 Deployment 建出的 Pod，`restartPolicy` 預設就是 `Always`。這表示如果 Pod 還在、也還綁在某個 node 上，而只是容器程序退出了，例如：

- 主程序 crash
- liveness probe 失敗後容器被 kill
- container process 被 OOM kill

⭐️這時通常是 **同一個 Pod 物件裡的容器被 Kubelet 重啟**。你常看到的現象會是：

- Pod 名稱不變
- Pod UID 不變
- 通常 Pod IP 也不變
- `RESTARTS` 數字增加
- 可能進入 `CrashLoopBackOff`

也就是說，這比較像「同一間房子裡的人一直重開機」，不是重新蓋一間新房子。

再講 ReplicaSet 這條。

ReplicaSet 不直接處理容器 crash；它處理的是 **Pod 數量與歸屬**。當它發現自己應該維持的 Pod 不夠了，才會建立新的 Pod。常見情況包括：

- 某個 Pod 物件被刪掉
- 某個 Pod 已經進入 `Failed` 並不再算有效副本
- node 故障後，原 Pod 最後被控制平面判定失效並移除
- rollout 時舊 Pod 被逐步淘汰，需要新 Pod 遞補

這時你看到的通常會是：

- 出現新的 Pod 名稱
- 新的 Pod UID
- 常常也會有新的 Pod IP
- 舊 Pod 可能處於 `Terminating`、`Failed`，或已消失

所以比較精準地說：**ReplicaSet 不是因為「容器一 crash」就立刻補 Pod，而是因為「它管理的有效 Pod 數量少了」才補新 Pod。**

這也是最容易混淆的地方。比如一個 Pod 裡的 app 一直 crash，若 Pod 物件本身還在，那常常只是 Kubelet 一直重啟容器，ReplicaSet 不一定會立刻多生一個新 Pod。你可能會看到的是一個**還活著但不健康的 Pod**，狀態變成 `CrashLoopBackOff`，而不是自動冒出另一個替身。

把這件事跟 WeaMind 現在的 Deployment 連起來看，因為 [manifests/deployment.yaml](manifests/deployment.yaml) 有 `livenessProbe` 和 `readinessProbe`：

- 如果 app 卡死、health check 過不了，Kubelet 可能先依 liveness probe 把容器殺掉再重啟
- 如果 Pod 雖然還活著但 readiness 沒過，它可能先從 Service 後端清單拿掉，但 **不代表 ReplicaSet 一定會立刻補一個新的 Pod**
- 只有當原 Pod 真的被刪除、失效，或 rollout 正在替換時，ReplicaSet 才會建立新的 Pod 來維持副本數

因此最好背的版本是：

- **容器層故障**：先看 Kubelet 是否在同一個 Pod 內重啟容器
- **Pod 層消失或被淘汰**：才輪到 ReplicaSet 補新的 Pod

如果要用觀察訊號快速分辨，可以這樣看：

- `RESTARTS` 一直增加、Pod 名稱沒變：比較像 Kubelet 在重啟容器
- 冒出一個新 Pod 名稱、舊 Pod 消失或進入終止：比較像 ReplicaSet 在補新的 Pod

一句話收斂：**Kubelet 負責把「還存在的 Pod」裡壞掉的容器重啟；ReplicaSet 則在「有效 Pod 數量不足」時，另外建立新的 Pod 來補足副本數。**

補一個複習時很好用的快速判斷表：

| 看到的狀態               | 比較像誰在處理                                      | 代表什麼                      | ReplicaSet 會不會立刻補新 Pod         |
| ------------------------ | --------------------------------------------------- | ----------------------------- | ------------------------------------- |
| `CrashLoopBackOff`       | Kubelet                                             | Pod 還在，但容器反覆啟動失敗  | 通常不會立刻補，因為 Pod 物件還在     |
| `NotReady`               | 先是 Kubelet / Pod 狀態機制影響，再反映到 Endpoints | Pod 還存在，但暫時不該接流量  | 通常不會只因為 `NotReady` 就立刻補    |
| `Failed`                 | Pod 已經失效，接著控制器會介入                      | 這個 Pod 物件已不算有效副本   | 比較可能，因為有效副本數少了          |
| `Terminating`            | 控制器或刪除流程中                                  | 舊 Pod 正在退場               | 常常會，視副本策略與 rollout 狀態而定 |
| Pod 直接消失，冒出新名字 | ReplicaSet                                          | 舊 Pod 已不在，控制器補新副本 | 會，這就是補新 Pod 的典型訊號         |

可以把它背成一句很短的規則：**只要 Pod 物件還在，通常先想 Kubelet；只要 Pod 物件少了、失效了、被淘汰了，才開始想 ReplicaSet。**

## 怎麼理解 workload：定義、控制器和 WeaMind 例子

可以先用一個夠準的版本來記：**workload 是 Kubernetes 裡要被執行、維持、管理的應用工作負載。** 它不是某一個固定 Pod，也不是某一種單一資源型別；重點是「**這個應用要怎麼被穩定地跑著**」。

因此，Deployment、StatefulSet、DaemonSet 比較好的理解不是 workload 本體，而是「**它們是拿來管理不同類型 workload 的控制器**」。真正被跑起來的執行單位仍然是 Pod，但 Kubernetes 更在意的是**這個 workload 能不能持續維持期望狀態**。

放回 WeaMind，line-bot 就是最典型的 workload。[manifests/deployment.yaml](manifests/deployment.yaml) 不是在保護某一顆固定 Pod，而是在宣告這個服務要持續存在、維持副本數、能更新、能被 Service 接流量。這就是 workload 思維，也就是「**顧好這個服務整體有沒有持續可用**」。

例子可以這樣記：line-bot 是由 Deployment 管理的 workload；Traefik 也是 workload，只是它負責入口流量；PostgreSQL、Redis 也可以算 workload，但更偏 stateful，因此 WeaMind 目前仍留在 VM 端。

最後只要再記一個邊界：**workload 不是等於 Pod。** Pod 比較像 workload 在某個時刻的執行個體；你真正想維持的是 line-bot 這個服務，而不是某個 Pod 名字本身。

一句話收斂：**workload 就是 Kubernetes 想持續跑著並管理的應用；Pod 是它的執行個體，Deployment / StatefulSet / DaemonSet 則是管理不同 workload 形態的控制器。**

## 實務上會直接寫 Pod 或 ReplicaSet YAML 嗎？

簡答：**有，但很少。**

- Pod YAML 在實務上多半只用於臨時測試、除錯、一次性驗證，或非常簡單的示範。
- ReplicaSet YAML 幾乎不會直接手寫，因為長期服務通常會直接寫 Deployment，讓 Deployment 去建立和管理 ReplicaSet。
- 真正常見的做法是直接寫更高層控制器，例如 Deployment、StatefulSet、DaemonSet、Job、CronJob。

一句話記法：**Pod 偶爾手寫來做臨時事；ReplicaSet 幾乎不手寫；正式服務通常寫更高層控制器。**

## `-o json` 什麼情況下比 `-o wide` 更常用？

簡答：**當你不是只想「看」，而是想「取欄位、做自動化、交給程式處理」時，`json` 更常用。**

- `-o wide` 比較像給人眼看的加欄版表格，適合快速觀察。
- `-o yaml` 常用來看完整物件內容、對照 manifest、讀設定結構。
- `-o json` 則更常出現在腳本、自動化、CI、或要搭配 `jq` 精準抽欄位的情境。

例如你想只抓某個 Deployment 的 image、replicas、labels，或想把多個物件的欄位整理成固定格式，`json` 會比 `wide` 好處理，也比直接剖 YAML 更穩。

一句話記法：**`wide` 偏人工快速觀察，`yaml` 偏人工閱讀完整結構，`json` 偏程式處理與精準取值。**
