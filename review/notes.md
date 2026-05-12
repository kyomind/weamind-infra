# Lesson 複習筆記

## Debug 時該由外而內還是由內而外？

看「**最強的異常訊號**」先出現在哪一層。

- 由外而內：異常訊號是「外面打不進來」或「打進來但沒命中正確路由」。例如 LB health check 失敗、503、timeout、Ingress 沒命中。這時 Pod 內部還是問號，先查外層路徑
- 由內而外：異常訊號是「Pod 狀態本身就異常」。例如 `kubectl get pods` 直接看到 CrashLoopBackOff、CreateContainerError、Pending。這時外層路由可能還沒機會被測試，先查 Pod 層

一句話記法：kubectl 先告訴你 Pod 有問題，就先查 Pod；外部監控或用戶先告訴你連不到，就先查外層。

## LB health check 為什麼要帶 Host header？

只要 Ingress 用 host-based routing（根據 `spec.rules[].host` 分流），所有進來的 HTTP 請求都要帶正確的 Host header，規則才會命中。

LB health check 也不例外。如果只打 IP + path，沒帶 Host header，Ingress Controller 會找不到對應規則，通常回 404。

WeaMind 踩過這個坑：Hetzner LB 預設 health check 不帶 Host header，導致 `/health` 被 Traefik 擋掉。修法是在 LB health check 設定裡補上 `Host: k8s.kyomind.tw`。

一句話記法：用 host-based routing 時，LB health check 也要帶正確的 Host header，不然 Ingress 規則不會命中。

## Service 的 port 80 綁在哪裡？

Service 的 `port: 80` 是綁在這個 Service 自己的 ClusterIP 上（例如 `10.43.x.x:80`），不是綁在 node 的 80 port。

叢集內其他 Pod 要連這個 Service，可以用：

```bash
# 用 ClusterIP
10.43.x.x:80

# 用 Service DNS（更常見）
weamind-line-bot:80
weamind-line-bot.weamind.svc.cluster.local:80
```

這個 80 和 node 上的 80 port 完全獨立。除非用 NodePort 或 LoadBalancer 類型的 Service，否則 Service port 不會佔用 node 的任何 port。

一句話記法：ClusterIP Service 的 port 只存在於叢集內的虛擬網路層，和實體 node port 沒有關係。

## 三種 Service 類型的 port 差異

- ClusterIP（WeaMind 用的）：port 只存在於叢集內虛擬網路，不佔用任何 node 實際 port，外部無法直接連
- NodePort：除了 ClusterIP 之外，還會在每個 node 上開一個實際 port（預設 30000-32767），外部可以用 `<NodeIP>:<NodePort>` 連進來
- LoadBalancer：雲端環境用，會自動建外部 load balancer，底層通常也用 NodePort 機制

WeaMind 的外部流量路徑：

```bash
Hetzner LB -> Traefik (hostPort 80/443) -> Ingress 規則 -> Service ClusterIP:80 -> Pod:8000
```

真正佔用 node port 的是 Traefik 用的 `hostPort`，不是 Service 的 port。

## Service 的內部 DNS 是誰提供的？

CoreDNS。Kubernetes 叢集內的 DNS 伺服器預設是 CoreDNS。

當你建立一個 Service，CoreDNS 會自動為它產生 DNS 記錄：

```bash
<service-name>.<namespace>.svc.cluster.local
```

Pod 查詢這個名稱時，CoreDNS 會把它解析成 Service 的 ClusterIP。

流程：Pod 發 DNS 查詢 → CoreDNS 回應 ClusterIP → 流量走 Service networking 到後端 Pod。

## Ingress 規則和 Service 多 port 的核心理解

Ingress 規則看 Host + path，不是看 port。外部請求走 443 進來，但 Ingress 是靠 Host header（`k8s.kyomind.tw`）和 path（`/`）來決定導去哪個 Service，不是靠請求的 port 做分流。

Service 多 port 是給同一組 Pod 用的。一個 Service 可以定義多個 port，例如 `http:80` 和 `metrics:9090`，但這些 port 都是面向同一組被 selector 選到的 Pods。如果要讓不同 port 對應不同 Pod 群，通常會拆成不同 Service。

## 為什麼 LB 看 port，Ingress 看 Host？

因為它們工作在不同的網路層級。

- Load Balancer（L4，傳輸層）：只能看到 IP 和 port，還沒解析 HTTP 內容，所以只能靠 port 決定把流量導到哪裡
- Ingress Controller（L7，應用層）：已經解析了 HTTP 請求，可以看到 Host header、path、headers，所以可以用 Host + path 做更精細的路由

在 WeaMind 的架構：

```bash
Hetzner LB (L4) 看 port 443 → 轉到 worker nodes
Traefik (L7) 看 Host + path → 轉到對應 Service
```

一句話記法：L4 只看 IP/port，L7 才能看 HTTP 內容。這就是為什麼兩層分工不同。

## 為什麼 L4 LB 不需要管 HTTP 內容？

這是職責分離的設計哲學。

- 效能考量：L4 只看封包 header（IP + port），不需要解析 HTTP、不需要 TLS 解密，所以可以做得非常快、非常輕量
- 通用性：L4 LB 不綁定 HTTP，也能處理 TCP、UDP、gRPC、資料庫連線
- 穩定性：越靠近入口越需要穩定，L4 LB 狀態少、邏輯簡單，更不容易出錯
- 職責清楚：L4 LB 決定流量去哪台機器，L7 Ingress 決定流量去哪個服務

一句話記法：L4 LB 追求快、穩、通用；L7 處理應用邏輯。分工讓系統更可靠。

## 有 L7 Load Balancer 嗎？什麼時候用？

有，而且很常見，不是反模式。

L7 LB 的例子：AWS ALB、GCP HTTP(S) Load Balancer、Cloudflare、Nginx、HAProxy。

什麼時候用 L7 LB：

- 想在 LB 層就做 host-based 或 path-based routing
- 想在 LB 層終止 TLS（SSL offloading）
- 想在 LB 層做 WAF、rate limiting、認證
- 用雲端託管服務，不想自己管 Ingress Controller

兩種架構的取捨：

| 架構 | 優點 | 缺點 |
|------|------|------|
| L7 LB 一層做完 | 簡單、少一層元件 | 彈性較低、綁定協定 |
| L4 LB + Ingress Controller | 彈性高、職責清楚 | 複雜度較高 |

WeaMind 用的是 L4 + Ingress（Hetzner LB + Traefik）。這是一種選擇，不是唯一正解。

一句話記法：L7 LB 存在且常見，選哪種看你要簡單還是要彈性。

## kubectl describe pod 最常看什麼？

最常見的場景是 Pod 出問題時的第一輪診斷。

最常看的區塊：

| 區塊 | 看什麼 |
|------|--------|
| Events（最底部） | 最近發生什麼事：Scheduled、Pulled、Started、Failed、Unhealthy |
| Status / Conditions | Pod 整體狀態：Ready、PodScheduled、ContainersReady |
| Containers → State | 目前狀態：Running / Waiting / Terminated |
| Containers → Restart Count | 重啟幾次，判斷是否反覆 crash |
| Containers → Last State | 上一次為什麼掛掉（如果有重啟過） |
| Node | 排到哪台 node |

常見應用場景：

- Pending：看 Events 有沒有排程失敗原因
- ImagePullBackOff：看 Events 有沒有 pull 失敗訊息
- CrashLoopBackOff：看 Last State 和 Restart Count

一句話記法：`describe pod` 是看 Kubernetes 怎麼看這個 Pod，重點在 Events 和 Container State。

## kubectl get pods 最常看什麼？

欄位解讀：

| 欄位 | 看什麼 |
|------|--------|
| READY | `1/1` 正常，`0/1` 代表還沒 ready |
| STATUS | Pod 目前狀態，異常狀態是第一個警報 |
| RESTARTS | 數字高代表反覆重啟 |
| AGE | 剛建立還是跑很久了 |

常見異常 STATUS：

| 狀態 | 代表什麼 | 下一步 |
|------|----------|--------|
| Pending | Pod 還沒排到 node | 查資源、nodeSelector、taint |
| CrashLoopBackOff | container 反覆 crash | 查 logs、Last State |
| ImagePullBackOff | image 拉不下來 | 查 image 名稱、registry 權限 |
| CreateContainerError | container 建立失敗 | 查 ConfigMap/Secret 引用 |
| Init:0/1 | init container 還沒完成 | 查 init container logs |
| Terminating | Pod 卡在終止 | 查 finalizer、graceful shutdown |

一句話記法：`get pods` 先掃 STATUS 和 READY，有異常再用 `describe` 或 `logs` 深挖。

## Webhook path 填錯的 404 是誰給的？

通常是 App 給的。

如果 Ingress 規則是寬鬆的 prefix match（例如 `/`），webhook path 填錯時流量還是會進 Pod，404 是 FastAPI 找不到 route 給的。

兩種 404 的差異：

| 來源 | 發生原因 | 判斷方式 |
|------|----------|----------|
| App 層 404 | Ingress 命中，流量進 Pod，但 app routing 找不到 endpoint | `kubectl logs` 有該請求的 access log |
| Ingress 層 404 | Host 或 path 沒命中任何 Ingress 規則 | `kubectl logs` 沒有該請求紀錄 |

WeaMind 的 Ingress 用 prefix `/`，所以 webhook path 填錯通常是 App 層 404。

## 怎麼判斷 404 是 Ingress 給的還是 App 給的？

看 response body 格式。

Traefik（WeaMind 用的 Ingress Controller）給的 404 是純文字：

```bash
404 page not found
```

FastAPI 給的 404 是 JSON：

```json
{"detail":"Not Found"}
```

一眼就能分辨是哪一層擋掉的。

## kubectl exec 實務上常用嗎？什麼情境會用？

蠻常用，但頻率看環境。開發/staging 經常用，production 能不進就不進，但卡住時還是會用。

最常見的實際情境：

| 情境 | 做什麼 |
|------|--------|
| 網路連通性 | 從 Pod 內 curl 其他 service 或外部 API，確認 DNS、防火牆、TLS |
| 環境變數/config 驗證 | `env \| grep XXX` 或 `cat /app/config.yaml`，確認 ConfigMap/Secret 注入對不對 |
| 緊急狀況 | 清 cache、殺卡住的 process、看暫存檔 |

實務上很多公司 production 還是會 exec 進去，尤其問題難重現時。但理想上能用 logs/metrics 解決就不要 exec，因為 exec 不留痕跡、不好 audit。

## kubectl exec 是進 Pod 還是進 container？

進 container，不是進 Pod。

Pod 是邏輯包裝，裡面可以有一個或多個 container。exec 進去時，實際上是進某一個 container 的 shell。

大部分 Pod 只有一個 container，所以感覺像「進 Pod」。但如果 Pod 有多個 container（例如 sidecar），要用 `-c` 指定：

```bash
kubectl exec -it my-pod -c main-container -- /bin/sh
```

不指定的話，Kubernetes 會選第一個 container，可能不是你要的。

## 健康 Pod 和 CrashLoopBackOff Pod 在 describe 輸出的差異

| 欄位 | 健康 Pod | CrashLoopBackOff |
|------|----------|------------------|
| State | Running | Waiting (Reason: CrashLoopBackOff) |
| Ready | True | False |
| Restart Count | 0 或低且穩定 | 持續增加 |
| Last State | 通常沒有或正常 Terminated | Terminated + Error 或 OOMKilled |
| Conditions | 幾乎全 True | ContainersReady=False |
| Events | `<none>` 或只有正常 Scheduled/Pulled/Started | Back-off restarting failed container |

一句話記法：健康 Pod 安靜（沒 Events、沒 Last State 異常），CrashLoopBackOff 很吵（Restart 一直加、Events 一直噴）。

## kubectl exec 為什麼要用 -- 分隔？和 docker exec 差在哪？

`--` 是告訴 kubectl：後面的都是要傳給 container 的命令，不是 kubectl 自己的參數。

kubectl 參數很多（`-n`、`-c`、`-it`），如果命令本身也有 `-` 開頭的參數，kubectl 會搞混。`--` 是明確切開的分隔符。

```bash
# Docker：container name 後面的都自動當命令
docker exec -it my-container /bin/sh

# kubectl：需要 -- 明確分隔
kubectl exec -it my-pod -- /bin/sh
```

kubectl 的命令結構比較複雜（有 namespace、pod、container 多層），所以用 `--` 是最保險的寫法。

## 什麼時候 kubectl exec 不加 -- 也能跑？

當命令本身沒有 `-` 開頭的參數時，kubectl 分得清楚：

```bash
# 不加 -- 通常能跑
kubectl exec -it my-pod /bin/sh
kubectl exec -it my-pod ls

# 會出問題，-la 可能被 kubectl 誤解
kubectl exec -it my-pod ls -la

# 正確寫法
kubectl exec -it my-pod -- ls -la
```

簡單說：命令沒帶參數時通常沒事，命令帶 `-` 參數時就會出問題。養成習慣加 `--` 就不用記這些邊界條件。

## Pod Conditions 各欄位的意思

- `PodScheduled`：Pod 已被 scheduler 指派到某個 node
- `Initialized`：init containers 都已完成（沒有的話直接 True）
- `PodReadyToStartContainers`：Pod sandbox 就緒，可以開始啟動 containers（較新版 K8s 才有）
- `ContainersReady`：Pod 裡所有 containers 都 ready
- `Ready`：Pod 可接收流量，Service 會把它當作可用後端

實務上最常看 `Ready`，因為它直接決定 Service 會不會把流量導過來。其他幾個主要在 debug 啟動卡住時才會細看。

## Pod Conditions 能判斷和不能判斷的邊界

能判斷的（邊界內）：
- Pod 有沒有排到 node
- init containers 有沒有完成
- containers 有沒有啟動成功
- Pod 是否 ready 可接收流量

判斷不了的（邊界外）：
- Service selector 有沒有選對 Pod
- Ingress 規則有沒有命中
- App 內部 routing 錯誤（404）
- App 業務邏輯錯誤（500）
- DNS 解析、TLS 憑證
- 外部 LB 或防火牆

一句話記法：Conditions 全 True 只代表「Pod 本身活著且 ready」，不代表「流量能正確進來且 App 行為正確」。

## /health 200 但 webhook 404，老手怎麼判斷？

第一反應：「/health 通了，webhook 404，同一個 App 兩個 path，八成是 path 對不上。」

下一步：直接對照 LINE Developers 上填的 webhook URL 和 FastAPI 實際註冊的 route，看是不是打錯字或路徑不一致。

不會先查 Ingress、Service、Pod，因為 /health 能通已經證明外層路徑沒問題。

## 為什麼 /health 通了就能排除外層問題？

因為 WeaMind 的 Ingress 用 `path: /` Prefix，所有路徑都會轉給 Service。

/health 能通，就能確定：
- Ingress 規則有命中
- Service 有導到 Pod
- Pod 有在跑

webhook 的 404 只剩一個可能：App 內部 routing 找不到那個 path。不需要再往外查了。

## CrashLoopBackOff 排查的兩輪分工

第一輪：`describe pod`（Kubernetes 視角）
- 回答「它怎麼壞的」
- 看 State、Last State、Restart Count、Events
- 確認是不是真的在反覆失敗

第二輪：`logs --previous`（App 視角）
- 回答「它為什麼壞」
- CrashLoopBackOff 時直接考慮 `--previous`，因為當前 container 可能剛起來還沒吐完整錯誤，真正有價值的訊息在上一輪死前

一句話記法：第一輪問「怎麼壞」，第二輪問「為什麼壞」。
