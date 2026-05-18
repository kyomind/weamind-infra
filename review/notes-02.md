# Lesson

整理日期：2026-05-18

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

| 架構                       | 優點             | 缺點               |
| -------------------------- | ---------------- | ------------------ |
| L7 LB 一層做完             | 簡單、少一層元件 | 彈性較低、綁定協定 |
| L4 LB + Ingress Controller | 彈性高、職責清楚 | 複雜度較高         |

WeaMind 用的是 L4 + Ingress（Hetzner LB + Traefik）。這是一種選擇，不是唯一正解。

一句話記法：L7 LB 存在且常見，選哪種看你要簡單還是要彈性。

## kubectl describe pod 最常看什麼？

最常見的場景是 Pod 出問題時的第一輪診斷。

最常看的區塊：

| 區塊                       | 看什麼                                                        |
| -------------------------- | ------------------------------------------------------------- |
| Events（最底部）           | 最近發生什麼事：Scheduled、Pulled、Started、Failed、Unhealthy |
| Status / Conditions        | Pod 整體狀態：Ready、PodScheduled、ContainersReady            |
| Containers → State         | 目前狀態：Running / Waiting / Terminated                      |
| Containers → Restart Count | 重啟幾次，判斷是否反覆 crash                                  |
| Containers → Last State    | 上一次為什麼掛掉（如果有重啟過）                              |
| Node                       | 排到哪台 node                                                 |

常見應用場景：

- Pending：看 Events 有沒有排程失敗原因
- ImagePullBackOff：看 Events 有沒有 pull 失敗訊息
- CrashLoopBackOff：看 Last State 和 Restart Count

一句話記法：`describe pod` 是看 Kubernetes 怎麼看這個 Pod，重點在 Events 和 Container State。

## kubectl get pods 最常看什麼？

欄位解讀：

| 欄位     | 看什麼                             |
| -------- | ---------------------------------- |
| READY    | `1/1` 正常，`0/1` 代表還沒 ready   |
| STATUS   | Pod 目前狀態，異常狀態是第一個警報 |
| RESTARTS | 數字高代表反覆重啟                 |
| AGE      | 剛建立還是跑很久了                 |

常見異常 STATUS：

| 狀態                 | 代表什麼                | 下一步                          |
| -------------------- | ----------------------- | ------------------------------- |
| Pending              | Pod 還沒排到 node       | 查資源、nodeSelector、taint     |
| CrashLoopBackOff     | container 反覆 crash    | 查 logs、Last State             |
| ImagePullBackOff     | image 拉不下來          | 查 image 名稱、registry 權限    |
| CreateContainerError | container 建立失敗      | 查 ConfigMap/Secret 引用        |
| Init:0/1             | init container 還沒完成 | 查 init container logs          |
| Terminating          | Pod 卡在終止            | 查 finalizer、graceful shutdown |

一句話記法：`get pods` 先掃 STATUS 和 READY，有異常再用 `describe` 或 `logs` 深挖。

## Webhook path 填錯的 404 是誰給的？

通常是 App 給的。

如果 Ingress 規則是寬鬆的 prefix match（例如 `/`），webhook path 填錯時流量還是會進 Pod，404 是 FastAPI 找不到 route 給的。

兩種 404 的差異：

| 來源           | 發生原因                                                 | 判斷方式                             |
| -------------- | -------------------------------------------------------- | ------------------------------------ |
| App 層 404     | Ingress 命中，流量進 Pod，但 app routing 找不到 endpoint | `kubectl logs` 有該請求的 access log |
| Ingress 層 404 | Host 或 path 沒命中任何 Ingress 規則                     | `kubectl logs` 沒有該請求紀錄        |

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

| 情境                 | 做什麼                                                                        |
| -------------------- | ----------------------------------------------------------------------------- |
| 網路連通性           | 從 Pod 內 curl 其他 service 或外部 API，確認 DNS、防火牆、TLS                 |
| 環境變數/config 驗證 | `env \| grep XXX` 或 `cat /app/config.yaml`，確認 ConfigMap/Secret 注入對不對 |
| 緊急狀況             | 清 cache、殺卡住的 process、看暫存檔                                          |

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

| 欄位          | 健康 Pod                                     | CrashLoopBackOff                     |
| ------------- | -------------------------------------------- | ------------------------------------ |
| State         | Running                                      | Waiting (Reason: CrashLoopBackOff)   |
| Ready         | True                                         | False                                |
| Restart Count | 0 或低且穩定                                 | 持續增加                             |
| Last State    | 通常沒有或正常 Terminated                    | Terminated + Error 或 OOMKilled      |
| Conditions    | 幾乎全 True                                  | ContainersReady=False                |
| Events        | `<none>` 或只有正常 Scheduled/Pulled/Started | Back-off restarting failed container |

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

## 懷疑 Pod 到 VM 依賴問題時的兩部曲

1. 先 `kubectl logs` — 看 App 有沒有噴資料庫或快取連線錯誤
2. 看不出來才 `kubectl exec` — 進 container 查 env、跑連線測試

logs 是非侵入式、有歷史紀錄；exec 是進去戳，能查更細但成本較高。先輕後重。

## Webhook debug 三步曲

1. path — LINE 後台 webhook URL 和 app route 有沒有對上
2. logs — 請求有沒有進 app、處理時有沒有錯
3. exec — 前兩步都沒線索，才進去查 env 或跑連線測試

順序是：先 path，再 logs，最後才 exec。

## Pod logs 完全沒收到請求時怎麼查 routing

流量根本沒進到 Pod，要由外而內查。WeaMind 流量路徑：

```bash
LINE → Hetzner LB → Traefik (Ingress Controller) → Service → Pod
```

排查順序：

1. 外部 URL — LINE 後台填的 webhook URL 對不對（Host、path）
2. LB — Hetzner LB health check 有沒有 pass、target 對不對
3. Ingress — `kubectl describe ingress` 看 Host/path/backend 規則是否命中
4. Service → Pod — `kubectl get endpoints` 看 Service 背後有沒有活的 Pod

快速判斷：如果 `/health` 能通但 webhook 沒進 logs，問題通常在第 1 步（URL 填錯）或 App routing（path 不存在）。連 `/health` 都不通，才往 2-4 查。

## kubectl describe ingress 的用途

確認 cluster 端宣告的 routing 規則。

常用情境：

1. 懷疑 Host/path 規則寫錯 — 看 `Rules` 區塊，確認 Host 和 path 是否對應到預期的 backend Service
2. 確認 Ingress 有沒有被處理 — 看 `Ingress Class`，確認是交給哪個 controller（例如 traefik）
3. 看 backend 有沒有活的 Pod — 輸出會順帶顯示 Service 背後的 Pod endpoints

邊界：只能回答「Kubernetes 預期怎麼路由」，不能證明外部請求真的帶著正確的 Host/path 打進來。

## Debug 時的正交思考

每一層驗證只能回答它那一層的問題，不能跨層推論：

1. 設定注入 ⊥ 連線成功 — `printenv` 顯示 `POSTGRES_HOST=10.0.0.2` 正確，不代表 `10.0.0.2:5433` 真的可連
2. 外層宣告 ⊥ 內部視角 — `kubectl describe service` 看 K8s 資源定義，`kubectl exec` 看 container 進程實際收到什麼，兩者不能互相替代
3. Kubernetes 狀態 ⊥ App 狀態 — Pod `Running/Ready` 只代表 container 活著，不代表 App 能正確連 DB

設定對了還是可能連不上，Pod 活著還是可能業務邏輯錯。

## 單機版與 K8s 版排錯的對比

共通點：一旦確認請求進到 App，排錯邏輯和單機版幾乎一樣 — 先查 path/routing，再看 logs，最後查設定與依賴。

K8s 多出來的：在確認「請求有沒有進到 App」之前，要先過 DNS → LB → Ingress → Service → Pod 這幾層。

實務判斷：如果 `/health=200` 且 Pod `Running/Ready`，代表外層已通，後面就用單機版思路查 App 層。

一句話：K8s 不是改寫 App 排錯邏輯，而是多了「先確認外層哪裡斷」這一段。

## ⭐️為什麼 K8s 會多這麼多層

單機版：App 跑在一台機器，IP 固定、port 固定，沒什麼好路由的。

K8s 要處理的現實不一樣：Pod 會死會生（IP 不固定）、有多副本（要負載均衡）、多服務共用入口（要分流）、外部流量要進 cluster、服務之間要互相找。

⭐️每一層解決一個特定問題：

| 層      | 解決什麼                               |
| ------- | -------------------------------------- |
| DNS     | 用名字找 Service，不用記 IP            |
| LB      | 外部流量進 cluster                     |
| Ingress | 多服務共用 443，靠 Host/path 分流      |
| Service | Pod IP 不固定，提供穩定入口 + 負載均衡 |
| Pod     | 實際跑 App                             |

一句話：不是為了複雜而複雜，是因為 Pod 會動、有多個、要共用入口，所以需要這些層來抽象化。

## Load Balancer 是 K8s 的標配嗎？

要看環境。

雲端環境（AWS、GCP、Azure）：幾乎是標配。用 LoadBalancer Service 或 Ingress Controller，雲端會自動 provision LB。

自建環境（bare metal、Hetzner）：不一定。可以用自建 LB、MetalLB、NodePort、或 hostPort。

更精確的說法：「外部流量進 cluster 的入口機制」是標配，LB 是最常見的實現方式，但不是唯一。

WeaMind 的組合是 Hetzner LB + Traefik hostPort，這是自建環境的典型做法。

## Production 環境 LB 是標配嗎？

是，幾乎是標配。

Production 需要：
- 穩定入口 — 外部 DNS 指向一個不會變的 IP/endpoint
- 高可用 — 某個 node 掛了，流量自動導去其他 node
- 健康檢查 — 自動剔除不健康的後端

沒有 LB 的替代方案（NodePort、hostPort）都做不好這三件事。即使自建環境跑 production，也會架某種 LB（Hetzner LB、HAProxy、MetalLB、Nginx 等），不會用裸 NodePort 對外。

一句話：production 要高可用和穩定入口，LB 是最直接的解法。

## 環境變數放 ConfigMap 還是 Secret？

簡單判斷法：這個值被別人看到，會不會有安全問題？

- 會 → Secret（密碼、token、私鑰、API key）
- 不會 → ConfigMap（host、port、功能開關、環境標識）

WeaMind 的例子：

| ConfigMap             | Secret                    |
| --------------------- | ------------------------- |
| POSTGRES_HOST         | POSTGRES_PASSWORD         |
| POSTGRES_PORT         | LINE_CHANNEL_SECRET       |
| POSTGRES_DB           | LINE_CHANNEL_ACCESS_TOKEN |
| REDIS_URL（不含密碼） |                           |

灰色地帶：不確定就先放 Secret。從 Secret 改成 ConfigMap 容易，反過來比較麻煩。

## Deployment 裡環境變數怎麼寫？

實務上很少直接在 Deployment 裡硬寫 `env.value`，而是用 `envFrom` 或 `valueFrom` 從 ConfigMap/Secret 拉。

```yaml
# 硬寫值（不推薦）
env:
  - name: FOO
    value: "bar"

# 從 ConfigMap/Secret 取單一值
env:
  - name: POSTGRES_HOST
    valueFrom:
      configMapKeyRef:
        name: weamind-config
        key: POSTGRES_HOST

# 整包引入（最常用）
envFrom:
  - configMapRef:
      name: weamind-config
  - secretRef:
      name: weamind-secret
```

為什麼不硬寫：設定散落在 Deployment、不好管理、多 Deployment 要複製貼上、Secret 值會暴露在 manifest。

WeaMind 用 `envFrom` 整包引入。

## 新增環境變數時的判斷流程

第一步：判斷敏感性
- 洩漏會有安全問題嗎？會 → Secret，不會 → ConfigMap

第二步：判斷是否適合加進現有的 envFrom
- 這是這個 app 的「常態設定」嗎？是 → 加進現有的 ConfigMap/Secret

不該直接加進 envFrom 的情況：
- 值來自 downward API（Pod name、namespace）→ 用 `valueFrom.fieldRef`
- 只有這個 Deployment 用，不想污染共用 ConfigMap → 另開或用單獨 `env`
- 臨時測試，還沒確定要正式化 → 先不動 ConfigMap

一句話：先問敏感性決定 ConfigMap 或 Secret，再問「這是不是常態設定」決定要不要加進共用的 envFrom。

## Secret 的 stringData 和 data 差在哪？

- 最終都是 data — `stringData` 只是輸入時的便利寫法，送進 API server 後會被轉成 `data`。`kubectl get secret -o yaml` 只會看到 `data`。
- base64 不是加密 — 它只是編碼格式，讓二進位內容能放進 YAML/JSON。任何人都能 decode。
- 分工：人寫 stringData，機器存 data — 手寫 manifest 用 `stringData` 比較方便，但最終儲存和輸出都是 `data`。

一句話：`stringData` 是輸入便利，`data` 是實際儲存格式，base64 是為了格式相容不是為了安全。

## ConfigMap 和 Secret 在 container 裡是什麼形態？

看注入方式。

- 用 envFrom 或 valueFrom 注入 → 在 container 裡是 ENV，`printenv` 看得到
- 用 volume mount 注入 → 在 container 裡是檔案，不是 ENV

WeaMind 用 `envFrom`，所以 ConfigMap 和 Secret 的值都變成環境變數。在 container 裡你分不出哪些來自 ConfigMap、哪些來自 Secret。

一句話：注入方式決定最終形態。envFrom/valueFrom → ENV，volume mount → 檔案。

## Volume mount 注入用在什麼情境？

蠻常見的，特別是這些情境：

| 情境     | 為什麼用 volume mount                         |
| -------- | --------------------------------------------- |
| 設定檔   | nginx.conf、redis.conf — 應用本來就是讀檔案   |
| TLS 憑證 | cert + key 要當檔案讓 app 讀                  |
| SSH 金鑰 | 掛成 ~/.ssh/id_rsa                            |
| 大段內容 | 環境變數有長度限制，複雜 JSON/YAML 用檔案更穩 |

判斷原則：應用讀環境變數 → envFrom，應用讀設定檔 → volume mount，兩者可混用。

## 更新 Secret/ConfigMap 後 Pod 為什麼不會自動拿到新值？

更新設定資源和讓 Pod 吃到新值，是兩件不同的事。

1. 環境變數是 Pod 建立時注入的 — 用 `envFrom` 注入時，值在 container 啟動當下就固定了，不是和 Secret/ConfigMap 保持即時同步
2. K8s 不會自動重建 Pod — 設定資源改了，K8s 不會主動把用到它的 Pod 換掉，這是設計不是 bug
3. 要吃到新值，需要新 Pod — 常見做法是 `kubectl rollout restart deployment`

面試可講版：WeaMind 用 `envFrom` 把 Secret/ConfigMap 在 Pod 建立時注入成環境變數。更新 Secret 只代表設定資源本身變了，既有 Pod 的環境變數不會即時更新。要讓 app 吃到新值，需要讓 Deployment 產生新 Pod。

## ⭐️更新環境變數的完整指令流程

```bash
# 1. 修改 Secret 或 ConfigMap YAML 後 apply
kubectl apply -f manifests/secret.yaml -n weamind
kubectl apply -f manifests/configmap.yaml -n weamind

# 2. 確認資源已更新
kubectl get secret weamind-secret -n weamind -o yaml
kubectl get configmap weamind-config -n weamind -o yaml

# 3. 觸發 Pod 重建，讓新值生效
kubectl rollout restart deployment weamind -n weamind

# 4. 確認 rollout 完成
kubectl rollout status deployment weamind -n weamind

# 5. (可選) 驗證新值已注入
kubectl exec -it <pod-name> -n weamind -- printenv | grep <KEY>
```

重點：步驟 1-2 只是更新設定資源，步驟 3 才是讓 Pod 吃到新值的關鍵。

## WeaMind 踩坑：CreateContainerError (invalid UTF-8)

症狀：Pod 起不來，`kubectl describe pod` 看到 CreateContainerError，錯誤訊息是 invalid UTF-8。

根因：Secret 用了 `data` 欄位，但放進去的內容不是正確的 base64 格式（包含非 base64 字元和不該有的引號）。

因果鏈：
```
錯誤格式塞進 data → 解碼後得到非法 bytes → runtime 無法當字串處理 → container 建立失敗
```

修法：改用 `stringData` 直接寫明文，讓 K8s 幫忙轉換。

收斂規則：
- 人工維護 Secret 一律用 `stringData`
- 只有機器穩定產生的 base64 才用 `data`

教訓：這種錯誤不會出現在 app log，因為 container 根本還沒建起來。要往 Pod events 和 Secret 寫法查。

## kubectl get -o yaml 和 describe 差在哪？

|        | `get -o yaml`                  | `describe`                |
| ------ | ------------------------------ | ------------------------- |
| 格式   | 完整資源定義，機器可讀         | 人類可讀摘要              |
| 值     | 顯示實際值（Secret 是 base64） | Secret 只列 key，不顯示值 |
| Events | 不包含                         | 包含                      |
| 用途   | 確認值、備份、比對             | 快速瀏覽狀態、看 Events   |

確認「值有沒有改」→ `get -o yaml`。確認「資源狀態、有沒有問題」→ `describe`。

## 怎麼看 Deployment 的 rollout 歷史？

```bash
kubectl rollout history deployment/weamind -n weamind
```

這會列出 revision 號碼和變更原因，是看 rollout 歷史的標準指令。

`kubectl get rs` 看到的是目前 ReplicaSet 的狀態快照（哪個 active、哪些縮成 0），比較像「版本切換的痕跡」，不是歷史紀錄。

一句話記法：要看歷史用 `rollout history`，要看目前 RS 狀態用 `get rs`。

## 確認 Secret 更新成功，用 describe 還是 get -o yaml？

看你要確認什麼。

- 確認 key 結構對不對（有沒有多、少、改名）→ `describe` 就夠
- 確認**值**內容對不對 → 只能用 `get -o yaml`，因為 `describe` 不顯示值

實務判斷：如果你是改「某個 key 的值」，describe 看到的 byte 數可能根本沒變或變化不明顯，無法確認內容是否正確。這時 `get -o yaml` 配合 base64 decode 才能驗證。

一句話記法：describe 驗結構，get -o yaml 驗內容。

## 控制 Pod 排到哪些 node 的主流手段

| 手段                       | 彈性 | 適用情境                                                             |
| -------------------------- | ---- | -------------------------------------------------------------------- |
| nodeSelector               | 低   | 簡單 label 匹配，只能 AND，夠用就用這個                              |
| Node Affinity              | 中高 | 支援 In/NotIn/Exists 等運算符，可做軟性偏好（preferred）             |
| Taints + Tolerations       | 中高 | 反向思維：node 標記「不歡迎」，Pod 要有 toleration 才能排上去        |
| Pod Affinity/Anti-Affinity | 高   | 基於其他 Pod 位置決定，例如「和某 Pod 同 node」或「分散到不同 node」 |

WeaMind 用 nodeSelector 是因為需求單純：worker node 有 `node-role: worker` label，Deployment 寫 `nodeSelector` 指定就搞定。

什麼時候換成其他手段：
- 想要「盡量」但不強制 → Node Affinity 的 preferred
- 想讓某些 node 專門跑特定工作（例如 GPU node）→ Taints + Tolerations
- 想讓多副本分散到不同 node → Pod Anti-Affinity

## Workload Placement 實務情境對照

| 情境                                  | 手段                      | 做法                                                              |
| ------------------------------------- | ------------------------- | ----------------------------------------------------------------- |
| GPU node 專用，不讓普通 workload 佔用 | Taints + Tolerations      | GPU node 加 `gpu=true:NoSchedule`，ML workload 加對應 toleration  |
| 多副本分散到不同 node，避免單點故障   | Pod Anti-Affinity         | 指定「不要和同 `app` label 的 Pod 在同一 node」                   |
| 優先排 SSD node，滿了才排 HDD         | Node Affinity (preferred) | `preferredDuringSchedulingIgnoredDuringExecution` 偏好 `disk=ssd` |
| App 和 Redis 同 node，減少網路延遲    | Pod Affinity              | 指定要和 `app=redis` 的 Pod 在同一 node                           |
| Control plane 不跑一般 workload       | Taints + Tolerations      | master node 預設有 taint，只有 system Pod 有 toleration           |

選擇邏輯：
- 基於 node 特性選 node → nodeSelector 或 Node Affinity
- 排斥特定 workload → Taints + Tolerations
- 基於其他 Pod 位置 → Pod Affinity/Anti-Affinity
- 硬性要求 → required，軟性偏好 → preferred

## Ingress 用 Host header 分流是標準做法嗎？

是，這不是 Kubernetes 特有的。

**Host-based routing（又叫 virtual hosting）是 HTTP/1.1 以來的標準機制**：一個 IP + port 可以服務多個 domain，靠 Host header 區分。

Nginx、Apache、HAProxy、Traefik、雲端 ALB 全都這樣做。Kubernetes Ingress 只是把這個概念標準化成一個資源定義。

## TCP passthrough 是什麼意思？

LB 不解密、不看內容，只把 TCP 封包原封不動轉給後端。

| 做法                  | LB 做什麼                               | 誰解密 TLS      |
| --------------------- | --------------------------------------- | --------------- |
| TLS termination at LB | LB 解密 TLS，看到明文 HTTP，再轉發      | LB              |
| TCP passthrough       | LB 只看 IP + port，加密封包直接轉給後端 | 後端（Traefik） |

WeaMind 的架構：

```bash
Client --[HTTPS 加密]--> Hetzner LB --[仍是加密]--> Traefik --[解密後的 HTTP]--> Service
```

Hetzner LB 做 TCP passthrough：它只知道「**有流量要去 443 port**」，不知道裡面是什麼 Host、什麼 path。Traefik 才是真正解開 TLS、看到 Host header、做 routing 的那一層。

⭐️更精準地拆層可以這樣說：**Hetzner LB 落在 L4 / TCP 層，負責把 `443` 連線原樣轉送進 K3s；Traefik 落在叢集內入口層，負責 TLS termination 與後續的 HTTP routing。**

為什麼這樣設計：
- 簡化 LB 設定（不用管憑證）
- 憑證集中在 Traefik 管理（cert-manager + Let's Encrypt）
- LB 保持 L4 的簡單與通用

## LB target unhealthy 的排查順序

核心觀念：target unhealthy ≠ app 壞掉，只代表 LB 的 health check 這一跳沒拿到預期結果。

排查順序（由外而內）：

| 順序 | 檢查什麼               | 為什麼                                                         |
| ---- | ---------------------- | -------------------------------------------------------------- |
| 1    | Health check 條件本身  | LB 打的 path、期望的 status code 對不對                        |
| 2    | Ingress host/path 命中 | Health check request 有沒有帶正確 Host header、path 有沒有匹配 |
| 3    | Worker / backend 落點  | 入口 worker 能不能接流量、Pod 有沒有跑在正確位置               |
| 4    | TLS / termination      | WeaMind 的 health check 是 HTTP，TLS 問題通常不是第一嫌疑      |

面試短答：看到 LB target unhealthy，不會先說 app 壞了，而是先懷疑 health check request 有沒有命中 Ingress 規則；再確認 worker 與 Pod 落點；最後才看 TLS。

## 為什麼 LB health check 改走 443 + TLS 也能通？

Traefik 的 TLS termination 不會區分「這是外部用戶流量」還是「這是 LB health check 流量」。只要是打到 443 port 的 HTTPS 請求，Traefik 就統一解密、統一做 HTTP routing。

```bash
LB health check --[HTTPS 443]--> Traefik --[解密]--> 命中 Ingress 規則 --> Pod /health --> 200
```

所以不用額外設定，只要 health check 帶正確的 Host header + path，對 Traefik 來說就是一個普通的 HTTPS 請求。

## WeaMind 踩坑：LB target 先綠後紅

症狀：LB health check 設定好後，target 一開始 healthy，過一陣子變 unhealthy。

原因：Hetzner LB 預設 health check 不帶 Host header，但 Traefik 用 host-based routing，沒有 Host header 就找不到規則 → 回 404 → unhealthy。

驗證方式（在 worker node 上測試）：
```bash
curl http://127.0.0.1/health                              # 404（沒帶 Host）
curl -H 'Host: k8s.kyomind.tw' http://127.0.0.1/health    # 200
```

修正：在 Hetzner LB health check 設定裡補上 `Domain: k8s.kyomind.tw`，讓 health check 帶 Host header。

## 為什麼 LB target 會「先綠後紅」而不是直接紅？

兩個因素：

1. 剛加入 target 時，LB 先假設它是 healthy（還沒做第一輪 check）
2. Health check 有 retry 機制，例如 `Interval 15s, Retries 3` 要連續 3 次失敗才會標記 unhealthy

所以大約 45 秒後才會從綠變紅。這也是為什麼這種問題容易漏掉：設定完當下看起來沒事，過一會兒才爆。

## 驗證 LB health check 是 Host header 問題的流程

在 ⭐️**worker node** 上執行（不是本機、**不是 Pod 內**）：

```bash
# 1. 對照組：帶 Host header（確認 app 本身是通的）
curl -H 'Host: k8s.kyomind.tw' http://127.0.0.1/health
# 預期：200 {"status":"ok"}

# 2. 實驗組：不帶 Host header
curl http://127.0.0.1/health
# 如果回 404 page not found → 問題在 Ingress host-based routing

# 3. 確認 Ingress 規則
kubectl get ingress weamind -n weamind -o yaml
# 看 spec.rules[].host 是否為 k8s.kyomind.tw
```

結論：同一台 node、同一個 path，只差 Host header，結果從 200 變 404，問題就是 Ingress 沒命中，不是 app 壞掉。

## 為什麼測 Ingress 入口要在 node 上，不能在 Pod 內？

在 Pod 內打 `127.0.0.1` 只會打到那個 Pod 自己，測不到 Ingress 層。

- Pod 有自己的 network namespace，`127.0.0.1:80` 指向的是 Pod 自己
- WeaMind app Pod 監聽的是 `8000`，不是 `80`，所以根本連不到任何東西

在 node 上：
- `127.0.0.1:80` 會打到 Traefik（因為 `svclb-traefik` 用 hostPort 綁了 80）
- 這才是測「外部流量進來後 Ingress 會怎麼 routing」的正確位置

一句話記法：Pod 內的 localhost 是 Pod 自己，node 上的 localhost 才能測到 Traefik 入口。

## Traefik Ingress Controller 怎麼把 node 的 80/443 接到 Ingress 規則？

比較準的說法是：node 的 `80/443` 先進 Traefik 入口，Traefik 再依 Ingress 規則決定怎麼轉到後端 Service。

- 入口層：K3s 的 `svclb-traefik` 是 DaemonSet，會在各 node 建立 Pod，並綁 `HostPort 80/443`。所以打進 node `80/443` 的流量，先碰到的是 Traefik，不是 app Pod
- 規則層：`manifests/ingress.yaml` 裡的 `ingressClassName: traefik` 表示規則由 Traefik 接管；`rules.host: k8s.kyomind.tw` 加上 `path: /`、`pathType: Prefix` 表示 Traefik 會先看 Host 和 path 有沒有命中
- 後端層：命中後，Traefik 會把流量送到 `weamind-line-bot` Service:80；這個 `80` 是 Service port，不是 app 真正監聽的 port，真正後端是 `targetPort: 8000`
- HTTP/HTTPS 分工：`tls` 區塊只決定 HTTPS 用哪張 Secret；HTTP -> HTTPS redirect 則是另外靠 Traefik Middleware `https-redirect` 加上 Ingress annotation，不是因為有 `tls` 就自動成立

一句話記法：node `80/443` 先進 Traefik，Traefik 讀 Ingress 規則後，再轉到 Service:80，最後到 Pod:8000。

## 為什麼現在 control-plane 沒有被排除出 Pod 排程？

比較準的說法是：不是所有 Pod 都沒有排除 control-plane，而是不同 workload 的排程規則不一樣。

- app 這一層有排除：`manifests/deployment.yaml` 裡的 `nodeSelector: nodepool=worker`，已經把 WeaMind line-bot Pods 固定在 worker，所以 app Pod 不會被排到 control-plane
- Traefik 相關 workload 沒有同樣被排除：lesson 裡的 runtime 觀察顯示，`svclb-traefik` 是 DaemonSet，而且帶有 control-plane toleration，所以 control-plane 也可以參與入口層元件的排程
- Kubernetes 會不會排到某個 node，不是看「這台是不是 control-plane」這個名字本身，而是看有沒有 `taint / toleration`、`nodeSelector`、`affinity` 這些約束。沒有明確限制時，control-plane 就不一定會自動被排除
- 對小型 K3s 來說，這種現象很常見。預設內建元件通常先求簡單可用，不一定會主動幫你做嚴格的 control-plane / worker 隔離

所以你現在看到的現象應該拆成兩句講：WeaMind app Pods 已經明確固定在 worker；但 Traefik 或 `svclb-traefik` 這類入口層元件，目前沒有被同等程度地限制，因此 control-plane 仍可能承接這些 Pod。

一句話記法：control-plane 沒有被排除，通常不是因為 K3s 完全不能排除，而是因為那個 workload 本身沒有加上足夠的排程限制。

## 如果是 kubeadm 版 Kubernetes，control-plane 會自動排除嗎？

簡答：通常會。kubeadm 建好的 control-plane node，預設就會帶 `NoSchedule` taint，所以一般 workload 不會自動被排上去。

- kubeadm 常見的預設 taint 是 `node-role.kubernetes.io/control-plane:NoSchedule`；舊版也可能看到 `node-role.kubernetes.io/master:NoSchedule`
- 這代表一般沒有對應 toleration 的 Pod，預設就會被擋在 control-plane 外面
- 但這不是說 control-plane 永遠完全不能跑 Pod。像 kube-system 裡的一些系統元件，如果本身帶了 toleration，還是可以排上去
- 如果你是單節點叢集，很多人會手動 `untaint` control-plane，讓一般 workload 也能排進去；一旦這樣做，就不再是「自動排除」

所以更準的說法是：kubeadm 預設比 K3s 更接近「先把 control-plane 隔離起來」；但最後哪些 Pod 能不能上去，仍然要看 taint / toleration 和你有沒有手動改動預設行為。

一句話記法：kubeadm 通常預設會用 `NoSchedule` taint 把一般 Pod 擋在 control-plane 外，但你仍可以靠 toleration 或 untaint 改變這件事。

## 為什麼只有一個 Traefik endpoint，但三個 node 都還能當入口？

白話講：接流量的地方和真正處理流量的地方，不一定是同一層。

- 三個 node 都能當入口，是因為 `svclb-traefik` 這個 DaemonSet 會在每個 node 都放一個入口 Pod，所以每台 node 都能先把 `80/443` 的流量接住
- 但這些入口 Pod 不是真的在做 Ingress routing；它們比較像入口轉接站，先把流量送進 `traefik` Service
- `traefik` Service 後面目前只有一個 endpoint，表示**真正負責處理 Traefik 規則的 backend Pod 只有一個**
- 所以會變成：三台都能先接到流量，但最後可能都轉給同一個 Traefik Pod 處理

比較準的講法是：node 數量對應的是入口鋪設範圍，endpoint 數量對應的是後端實際處理流量的 Pod 數量。這兩個數字本來就不一定一樣。

一句話記法：三個 node 是三個入口，不代表三個 Traefik backend；入口可以很多，真正處理的 Pod 也可以只有一個。

## curl 的 `-I` 和 `-L` 常用嗎？DevOps 需要知道嗎？

簡答：算常用，而且值得知道。它們不是很進階的技巧，但在查入口行為、redirect、健康檢查、HTTP 狀態碼時很常出現。

- `curl -I` 會送 `HEAD` request，只看 response headers，不拿 body。常用來快速看 status code、server、location、cache headers，或檢查入口層回應長什麼樣
- `curl -L` 代表遇到 redirect 就自動跟下去。常用來確認網址最後會被導到哪裡，或檢查 HTTP -> HTTPS redirect 有沒有真的成立
- 對 DevOps 來說，這兩個參數很實用，因為你常需要分辨問題是在入口層、redirect、TLS，還是在 app 本身
- 但也要記邊界：`-I` 用的是 `HEAD`，不是 `GET`。如果後端不接受 `HEAD`，你看到的結果可能是在測 method 支援，不是在測 redirect 本身

所以更準的說法是：DevOps 不一定要背一大堆 curl 參數，但 `-I` 和 `-L` 這種會直接幫你看入口行為的，屬於很值得熟的基本工具。

一句話記法：`-I` 用來快速看 headers，`-L` 用來追 redirect；兩個都算 DevOps 常用的基本參數。

## 為什麼三個 node 都能當入口，但真正的 Traefik backend 只有一個？

白話講：`svclb-traefik` 比較像接待員，真正的 Traefik backend 比較像櫃檯人員。

- `svclb-traefik` 會分散在每個 node 上，所以每台 node 都能先把 `80/443` 的流量接住
- 但它不是實際讀 Ingress 規則、決定後端去向的那一層；它比較像先接住，再把流量轉交出去
- 真正讀 Ingress 規則、決定流量怎麼轉的，是後面的 Traefik backend Pod
- 所以完全可能出現「三個 node 都有門口，但最後都把流量送去同一個 Traefik backend」這種狀況

所以不要把「入口數量」和「真正處理流量的 backend Pod 數量」當成同一件事。前者是在說有幾個地方能先接住流量，後者是在說最後有幾個 Pod 真正在處理。

一句話記法：每個 node 都可以有門口，但門後面不一定各自都有一位櫃檯人員；也可能三個門最後都把人帶去同一個櫃檯。

## 同一個 Pod IP 為什麼可以同時對應兩個 port？

因為 Pod 本來就可以同時開多個 port，所以「同一個 IP + 不同 port」仍然完全可能是同一個 Pod。

- IP 是在回答「是同一台網路端點嗎」
- port 是在回答「這台端點上的哪個服務入口」
- 所以 `10.42.0.9:8000` 和 `10.42.0.9:8443` 的意思不是兩個不同 Pod，而是同一個 Pod 上有兩個不同的 listening port
- 以 Traefik 來說，**這通常就是同一個 Traefik Pod 同時提供 HTTP 與 HTTPS 相關入口，所以 endpoints 會看到同一個 IP 配兩個 port**

你可以把它想成同一棟大樓有同一個地址，但裡面有兩個不同櫃檯窗口。地址沒變，所以還是同一棟；只是窗口編號不同，所以服務入口有兩個。

一句話記法：同一個 Pod 只有一個 IP，但可以同時開很多個 port；IP 相同、port 不同，不代表是不同 Pod。

## 專門處理 Ingress 的 Pod，正常是一個還是多個？

簡答：正式環境通常會希望是多個，不是長期只靠一個。

- 一個也能運作，特別是在小型叢集、測試環境，或剛起步時很常見
- 但如果只有一個 Ingress controller backend Pod，它就是明顯的單點。那個 Pod 掛掉、所在 node 出事，或滾動更新期間，就可能直接影響入口層可用性
- 所以比較常見的正式做法，是讓 Ingress controller 至少有兩個以上 replicas，並盡量分散在不同 node 上
- 你現在看到 WeaMind runtime 只有一個 Traefik backend，代表目前入口層後段仍偏單點；前面雖然有 `svclb-traefik` 幫你在三個 node 鋪入口，但真正處理規則的 backend 還是只有一個

所以這題要拆開講：入口可以很多，但真正處理流量的 backend 如果只有一個，風險還是存在。也就是說，三個 node 都能接流量，不等於入口層已經高可用。

一句話記法：Ingress controller 一個能跑，但正式環境通常不該長期只剩一個；不然 backend 還是單點。

## 這裡只有一個 Traefik backend，是不是因為 K3s 的簡化設計？

簡答：現在可以講得比剛剛更強一點。這不只是在 WeaMind runtime 剛好看到一個而已；查 K3s 官方文件與 Traefik chart 後，的確有充分理由說「K3s 內建 Traefik 的預設配置就是單副本」。

- repo 內能先確定兩件事：K3s 啟用了內建 Traefik；而 lesson 的 command 輸出也明確顯示 `traefik` Service 當時只有一個 backend endpoint
- 同一份輸出也顯示 `svclb-traefik` DaemonSet 在三個 node 都有 Pod，所以要分清楚：三個 node 都能接入口流量，不等於三個 node 各有一個 Traefik backend
- K3s 官方文件說，Traefik 是 packaged component，會透過 `/var/lib/rancher/k3s/server/manifests/traefik.yaml` 這個 HelmChart 來部署；若要客製，應該另外加 `HelmChartConfig`
- K3s 這份 `traefik.yaml` 只覆寫 image、tolerations、publishedService 等值，沒有看到 replicas 覆寫；而 Traefik Helm chart 的預設 values 則明確寫 `deployment.replicas: 1`
- 所以把這幾層證據接起來，比較合理的結論就是：K3s 內建 Traefik 這條安裝路徑，預設確實是單副本；WeaMind 當下看到只有一個 backend，不只是巧合，也和這個預設對得起來
- 但這仍然不是不能改的鐵律。K3s 官方同時也明講可以用 `HelmChartConfig` 客製 Traefik，因此比較精準的說法是「預設是單副本」，不是「K3s 本質上永遠只能一個」

所以這題最穩的回答是：WeaMind 目前只有一個 Traefik backend，既符合當時 runtime 觀察，也符合 K3s 內建 Traefik 的預設 chart 行為；但如果要更正式的高可用入口，仍然可以透過 Traefik chart 設定去調整。

一句話記法：K3s 內建 Traefik 預設就是單副本，但那是預設值，不是永遠不能改的限制。

## Traefik 做完 TLS termination 後，為什麼叫 L7 routing？

白話講：Traefik 把 HTTPS 解開之後，就看得懂裡面的 HTTP 內容了。

- 這時它不只是看到「有一條連線進來」，而是能看到 `Host`、`Path` 這些 HTTP 資訊
- 能根據 `Host`、`Path` 決定要把請求送去哪個 Service，這就是 L7 routing
- 相對地，Hetzner LB 比較像只看「這個流量是打到哪個 port」，例如 `443 -> 443`，這比較接近 L4
- 所以 WeaMind 這條路徑可以記成：**Hetzner LB 先做看 port 的轉送；Traefik 解開 HTTPS 後，再做看 Host/path 的轉送**

如果要更白話地背：**LB 像警衛，只看你走哪個門；Traefik 像櫃檯，會看你要辦什麼事，再帶你去對的地方。**

一句話記法：L4 主要看 IP/port，L7 主要看 HTTP 內容；WeaMind 是 Hetzner LB 先做 L4 轉送，Traefik 再做 L7 路由。

## 為什麼 redirect 和 TLS termination 有關？用正交角度怎麼理解？

簡答：這兩件事在概念上不是同一件事，但在 Hetzner LB 這個產品裡，它們又被綁在一起，所以對 WeaMind 才會變成強關聯。

- 先把兩個問題拆開：**redirect** 在問的是「哪一層能看懂 HTTP，並主動回 301/302」；**TLS termination** 在問的是「哪一層負責解開 HTTPS、持有憑證」
- 所以在概念層上，這兩件事其實是兩條不同軸，不該混成一句「會 redirect 就一定等於管憑證」
- 但 Hetzner LB 目前走的是 **TCP passthrough**，代表它刻意停在外層，只負責轉送 `443` 連線，不去看 HTTP 內容
- 一旦你想讓 Hetzner LB 做 redirect，就表示它不能再只做 L4 轉送，而要升級成能理解 HTTP 的那一層
- 問題在於：在 **Hetzner LB 這個產品設計** 裡，redirect 功能是和 HTTP/HTTPS service mode 綁在一起的，所以你一旦想用它做 redirect，通常就要一起接受 **TLS termination 也搬到 LB**
- 但 WeaMind 的 TLS 生命週期是放在 K8s 內，由 **cert-manager + DNS-01 + Traefik** 這條鏈處理；這樣做的背景又和 **Hetzner Managed Certificate 不適合配 Cloudflare DNS** 有關
- 所以對 WeaMind 來說，最一致的責任切法就是：**Hetzner LB 繼續單純 passthrough；Traefik 同時負責 TLS termination 和 redirect**

所以這題最精準的說法是：**redirect 和 TLS termination 在概念上是不同問題；但在 Hetzner LB 這個產品裡，它們沒有完全正交，而是被包成同一組能力。這就是為什麼 WeaMind 不能只把 redirect 單獨搬上 LB。**

一句話記法：概念上，redirect 和 TLS termination 是兩條軸；產品上，Hetzner LB 把它們綁在一起；架構上，WeaMind 才把兩者都留在 Traefik。

## Hetzner LB 的 health check 在檢查什麼？和 Pod health 有什麼差別？

簡答：**LB health check 不是在看 Pod 本身健不健康，而是在看「外面這條入口路徑有沒有真的打通」。**

- 它送出的不是 Kubernetes 內部 probe，而是一個**真的 HTTP request**
- 以 WeaMind 這次來說，就是 LB 去打 worker node 的 `80`，走 `/health`，帶 `Host: k8s.kyomind.tw`，期待拿到 `200`
- 所以它測到的是整條入口鏈路：**LB -> node:80 -> Traefik -> Ingress 規則 -> Service -> Pod -> /health**
- 只要這條路中間任何一段沒通，就算 app 還活著，LB 也可能把 target 判成 unhealthy
- 這也是為什麼之前沒帶對 `Host` 時，app 的 `/health` 明明沒壞，LB 還是會看到 `404`：因為壞的是 Ingress 命中，不是 Pod 本身

所以要分清楚：**Pod probe** 在回答「這個 Pod 自己活不活、能不能收流量」；**LB health check** 在回答「外部使用者走入口打進來，這條路到底通不通」。

一句話記法：Pod health 看的是單一 Pod；LB health check 看的是整條入口路徑。

## 這次 YAML 到底改了什麼？

簡答：**這次其實只做了兩件事。第一，新增一個「把 HTTP 轉去 HTTPS」的 Traefik Middleware。第二，在既有 Ingress 上掛一句設定，叫 Traefik 先套用這個 Middleware。**

- `middleware-https-redirect.yaml` 做的事很單純：定義一個 redirect 規則，意思就是「如果是 HTTP 進來，就把它轉去 HTTPS」
- `redirectScheme.scheme: https` 可以直接理解成「目標要跳去 HTTPS」
- `permanent: true` 可以直接理解成「這不是暫時跳一下，而是正式永久導向」
- `ingress.yaml` 本身沒有重寫 host、path、backend，也沒有改 TLS secret；只是多加了一句設定，告訴 Traefik：**這條入口規則命中時，先套用剛剛那個 redirect middleware**
- 所以整體效果不是「把原本路由砍掉重做」，而是**在原本已經能跑的入口前面，多加一層 HTTP -> HTTPS redirect**

所以這題可以背成：**這次 YAML 沒有大改路由，只是新增一個 redirect 零件，再把它掛到既有 Ingress 上。**

一句話記法：Middleware 是新加的 redirect 零件；Ingress 只是多掛了一個開關去用它。

## Annotation 為什麼不是只是註解？

簡答：**Kubernetes 的 annotation 不是寫給人看的備註，而是可能被 controller 讀取的 metadata。**

- YAML 裡的 `# 註解` 才是真的只給人看，送進 Kubernetes 後就沒了
- `metadata.annotations` 會真的存進 Kubernetes 物件裡，所以 controller 看得到
- 但 annotation 也不是「天生一定有魔法」；它會不會改變行為，要看有沒有 controller 願意讀它
- 在 WeaMind 這題裡，真正讓它生效的關鍵是：**Traefik 會主動讀 `traefik.ingress.kubernetes.io/router.middlewares` 這個 key，並把它當成設定來執行**
- 所以這行 annotation 的本質不是「備註」，而是**寫給 Traefik controller 看的指令入口**

所以這題可以背成：**comment 是給人看的；annotation 是存進物件裡、可能給 controller 讀的。**

一句話記法：註解只給人看；annotation 可以是 controller 的設定入口。
