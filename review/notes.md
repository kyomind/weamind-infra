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
