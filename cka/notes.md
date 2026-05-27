# CKA Practice Notes

## command 在 YAML 的位置

`command` 和 `name`、`image` 同層，在 `containers[]` 底下：

```yaml
spec:
  containers:
  - name: dns-container
    image: registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3
    command: ["sleep", "3600"]
```

單行 `["sleep", "3600"]` 最快，指令和參數各是 list 裡的一個元素。

## YAML flow syntax 引號空格規則

`[]` 寫法（flow syntax）很寬容：

- 單雙引號都行：`["sleep"]`、`['sleep']`
- 不加引號也行：`[sleep, 3600]`
- 逗號後空格可有可無：`["a","b"]` = `["a", "b"]`

考試建議統一雙引號 + 空格，最不容易出意外。

## kubectl create deployment 能設/不能設

能透過參數設定：
- `--image`
- `--replicas`
- `-n`（namespace）
- deployment 名稱（位置參數）

不能設，必須進 YAML 改：
- container name
- command

## kubectl exec 忘 namespace

剛 `apply -n some-ns` 完，切回來執行 `kubectl exec` 很容易忘記加 `-n`。

```bash
kubectl exec pod-name -- nslookup kubernetes.default  # ✗ 去 default 找
kubectl exec pod-name -n some-ns -- nslookup kubernetes.default  # ✓
```

考試超容易漏，尤其是前一步剛 apply 完切回來執行時。

## kubectl exec 的 -- 分隔符

`--` 左邊是 kubectl 參數，右邊是容器內指令。新版 kubectl 強制要求。

```bash
kubectl exec pod-name -n ns -- nslookup kubernetes.default  # ✓
kubectl exec pod-name -n ns nslookup kubernetes.default     # ✗ 報錯
```

## -it 只在互動時需要

`-i` 接 stdin，`-t` 分配 TTY。單純跑指令拿輸出不需要。

```bash
kubectl exec pod-name -n ns -- nslookup kubernetes.default > out.txt  # ✓ 不需要 -it
kubectl exec -it pod-name -n ns -- /bin/sh  # 要進去操作才需要 -it
```

## kubectl expose 能設/不能設

能透過參數設定：
- `--port`
- `--target-port`
- `--type`
- `--name`

不能設，必須事後 `edit` 或改 YAML：
- `nodePort`（指定 30000-32767 範圍內的特定 port）

## kubectl -h 查 flag

考試中忘記 flag 怎麼拼，先打 `-h`，比翻文件快。

```bash
kubectl expose -h    # 忘記 expose 有哪些 flag
kubectl create -h    # 忘記 create 後面能接什麼子資源
kubectl run -h       # 忘記 run 怎麼帶 command
```

`-h` 給簡短說明 + 範例，`--help` 給完整參數列表，考試用 `-h` 就夠。

## 什麼時候用什麼查資料

| 情境 | 用什麼 |
|------|--------|
| 忘記某個 flag 怎麼拼 | `-h` |
| 需要完整 YAML 範本（PV、NetworkPolicy 等） | 官方文件搜尋，直接複製改 |
| 能用指令生骨架的資源（Pod、Deployment、Service） | `--dry-run=client -o yaml` |

簡單資源靠 `-h` + `--dry-run`，複雜資源靠官方文件複製貼上。

## expose 預設 Service 名稱

不加 `--name` 會用來源資源同名：

```bash
kubectl expose deployment nginx-app    # Service 名稱 = nginx-app
kubectl expose deployment nginx-app --name my-svc  # Service 名稱 = my-svc
```

## metadata.name 不可變

Kubernetes 資源的 `metadata.name` 建出來就不能改。改名 = 刪掉重建。

```bash
kubectl delete svc old-name -n ns
kubectl expose deployment app --name new-name -n ns
```

## Service protocol 預設 TCP

不用特別指定，`protocol` 預設就是 TCP。

## Service type 有分大小寫

必須用正確的 camelCase：

- `ClusterIP`
- `NodePort`
- `LoadBalancer`
- `ExternalName`

寫成 `nodeport` 或 `NODEPORT` 會報錯。

## expose 自動讀 containerPort

`kubectl expose` 不帶 `--port` 時會去抄 Pod spec 的 `containerPort`。

```bash
kubectl expose pod nginx-pod --name nginx-service  # 自動用 Pod 的 containerPort
```

抄不到（Pod 沒定義 containerPort）就報錯，這時必須手動帶 `--port`。

## expose port 來源優先順序

1. 你指定的 `--port`（最高優先）
2. Pod spec 裡的 `containerPort`
3. 都沒有 → 報錯

## port-forward port mapping 是位置參數

`80:80` 直接接在資源後面，不需要 flag：

```bash
kubectl port-forward svc/nginx-service 80:80  # ✓ 位置參數
```

跟 `docker run -p 80:80` 不同，docker 的 `-p` 是 flag。

## Ingress YAML 最小結構

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
spec:
  ingressClassName: nginx-example
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

必填：`apiVersion: networking.k8s.io/v1`、`kind`、`metadata.name`、`spec.rules`。

注意：
- `ingressClassName` 指定用哪個 Ingress Controller
- `pathType` 必填，常用 `Prefix`（前綴匹配）或 `Exact`（完全匹配）
- `backend.service.port` 可用 `number`（port 號）或 `name`（port 名稱）

## Ingress rules 結構解讀

```yaml
rules:
- http:          # 規則層：可加 host 限定域名
    paths:       # 一個規則可有多條 path
    - path: /testpath
      pathType: Prefix
      backend:   # 這條 path 要轉到哪個 Service
        service:
          name: test       # Service 名稱
          port:
            number: 80     # Service 的 port
```

層級關係：`rules[]` → `http.paths[]` → `backend.service`

常見變化：
- 加 `host: example.com` 限定域名：`rules[].host`
- 多條 path 轉不同 Service：在 `paths[]` 加多個項目
- 用 port 名稱代替號碼：`port.name: http` 取代 `port.number: 80`

## Ingress 只處理 HTTP/HTTPS

`rules[].http` 是唯一選項，沒有 `tcp`、`udp` 之類的。

Ingress 專為 HTTP/HTTPS 設計。其他協議要用別的方式：
- Service `type: LoadBalancer`（直接暴露 TCP/UDP）
- Gateway API（較新標準，支援多協議）
- Ingress Controller 特定 CRD（如 nginx 的 TCPIngress）

## Ingress HTTPS 設定在 spec.tls

沒有 `rules[].https`，HTTPS 的 TLS 終止在 `spec.tls` 配置：

```yaml
spec:
  tls:
  - hosts:
    - example.com
    secretName: tls-secret  # 憑證放在 Secret
  rules:
  - host: example.com
    http:           # HTTP 和 HTTPS 都用這套路由規則
      paths: [...]
```

`rules[].http` 的 `http` 是「HTTP 協議層的路由規則」，不是「只處理 HTTP」。HTTPS 流量進來後，Ingress Controller 先解密（TLS 終止），再用同樣的 `http` 規則路由。

## kubectl create ingress 支援 --rule 和 --annotation

```bash
kubectl create ingress nginx-ingress-resource \
  --rule="/shop*=nginx-service:80" \
  --annotation=nginx.ingress.kubernetes.io/ssl-redirect="false"
```

能帶的就別事後補。

## --rule 語法詳解

格式：`host/path=service:port`

| 片段 | 對應設定 |
|------|----------|
| `example.com`（最前面） | `rules[].host: example.com` |
| `/shop` | `path: /shop` |
| `*`（尾巴加） | `pathType: Prefix` |
| 沒加 `*` | `pathType: Exact` |
| `nginx-service` | backend service name |
| `80` | backend service port |

那個 `*` 不是 wildcard，純粹是 kubectl 用來標記 Prefix 的語法糖。

## --rule 的 host 可省略

不指定 host = 匹配所有進來的流量，不管域名是什麼：

```bash
--rule="/shop*=nginx-service:80"           # 沒 host，任何域名都匹配
--rule="example.com/shop*=nginx-service:80"  # 有 host，只匹配 example.com
```

對應到 YAML：

```yaml
# 沒 host — 任何域名都匹配
rules:
- http:
    paths:
    - path: /shop
      ...

# 有 host — 只匹配 example.com
rules:
- host: example.com
  http:
    paths:
    - path: /shop
      ...
```

## --help 不夠就查 kubernetes.io

| 情境 | 做法 |
|------|------|
| `--help` 夠用 | 直接用，不浪費時間 |
| `--help` 不夠 | 去 kubernetes.io 搜範例 |
| 連官方文件都找不到 | 先 `--dry-run=client -o yaml` 生骨架，再手動改 |

考試允許開 kubernetes.io/docs。

## annotation 位置在 metadata 底下

跟 `name` 同層：

```yaml
metadata:
  name: nginx-ingress-resource
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
```

## Nginx Ingress annotation prefix

固定是 `nginx.ingress.kubernetes.io/`，後面接題目給的關鍵字。

```yaml
nginx.ingress.kubernetes.io/ssl-redirect: "false"
nginx.ingress.kubernetes.io/rewrite-target: /
```

這個 prefix 刷題過程中反覆出現，刷幾題就自然記住。

## labels vs annotations 區別

| 比較 | labels | annotations |
|------|--------|-------------|
| 給誰看 | Kubernetes 本身 | Controller / 外部工具 |
| 用途 | 篩選、匹配 | 控制行為、附加設定 |
| 可被 selector 使用 | ✅ | ❌ |

labels 用來「找到它」，annotations 用來「告訴 controller 怎麼處理它」。

## CKA 常考的 Ingress annotations

| Annotation | 值範例 | 作用 |
|------------|--------|------|
| `ssl-redirect` | `"false"` | 關閉 HTTP→HTTPS 自動跳轉 |
| `rewrite-target` | `/` 或 `/$2` | 重寫後端收到的 path |

`rewrite-target` 使用場景：使用者訪問 `/shop/items`，但後端 service 只認 `/items`，需要把 `/shop` 前綴吃掉：

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /shop
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
```

這樣 `/shop/items` 到後端就變成 `/items`。

