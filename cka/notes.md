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

## -o wide 不是 --wide

```bash
k get pod -o wide    # ✓
k get pod --wide     # ✗ unknown flag
```

`-o` 是 output format 的 flag，`wide` 是它的值。

## NetworkPolicy 完整範例

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          project: myproject
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 5978
```

## NetworkPolicy 基本結構

```yaml
spec:
  podSelector:     # 這條規則保護誰
    matchLabels:
      role: db
  policyTypes:     # 管哪個方向
  - Ingress
  - Egress
  ingress:         # 誰可以進來
  - from: [...]
    ports: [...]
  egress:          # 可以出去哪
  - to: [...]
    ports: [...]
```

## NetworkPolicy OR vs AND 陷阱

`from`/`to` 陣列裡，每個 `-` 是 OR 關係。但同一個 `-` 底下放多個 selector 就變 AND：

```yaml
# OR — 兩個獨立的 -
- namespaceSelector: {matchLabels: {project: myproject}}
- podSelector: {matchLabels: {role: frontend}}

# AND — 同一個 - 底下
- namespaceSelector: {matchLabels: {project: myproject}}
  podSelector: {matchLabels: {role: frontend}}
```

第一種：myproject 的任何 Pod OR default 的 frontend Pod。
第二種：myproject 裡且 label 是 frontend 的 Pod。

## NetworkPolicy 預設行為

- 沒有任何 NetworkPolicy → 全部放行
- 一旦有 policy 的 `podSelector` 選到你 → 變 deny-all，只開明確允許的

## policyTypes 管哪個方向

| policyTypes | Ingress | Egress |
|-------------|---------|--------|
| 只寫 `Ingress` | 受管制 | 全開 |
| 只寫 `Egress` | 全開 | 受管制 |
| 兩個都寫 | 都管制 | 都管制 |

沒寫在 policyTypes 裡的方向不受這條 policy 影響。

## NetworkPolicy 是 stateful 的

跟 AWS Security Group 一樣，允許連線建立後 return traffic 自動放行。

例如：Ingress 規則允許 frontend → db:6379，db 回應給 frontend 的封包自動放行，不需要另外寫 Egress 規則。

對比 AWS NACL（stateless）：inbound 和 outbound 要分開設，少設一邊就會斷。

NetworkPolicy 只需要想「誰能發起連線」，不用管 response。

## ipBlock 的 except 是縮小允許範圍

```yaml
- ipBlock:
    cidr: 172.17.0.0/16
    except:
    - 172.17.1.0/24
```

這是「大範圍放行，小範圍踢掉」，不是「阻擋 + 例外放行」。

- `172.17.0.1` ✓ 可以進
- `172.17.1.50` ✗ 被 except 踢掉
- `172.17.2.100` ✓ 可以進

NetworkPolicy 是 allow list，沒寫的本來就擋。except 是從已允許的範圍裡再排除。

## ipBlock except 必須是 cidr 的子集

```yaml
# ✓ 合法：172.17.1.0/24 在 172.17.0.0/16 裡面
cidr: 172.17.0.0/16
except:
- 172.17.1.0/24

# ✗ 不合法：不相交或 except 比 cidr 大
cidr: 172.17.0.0/16
except:
- 10.0.0.0/8
```

except 是從 cidr 裡挖洞，不能挖比母集還大，也不能挖不相交的範圍。

## policyTypes 寫了就要給規則

policyTypes 是在說「我要管這些方向」。寫了某個方向卻沒給規則 = 那個方向 deny-all。

```yaml
policyTypes:
- Ingress
- Egress
ingress:
- from: [...]
# 沒寫 egress 規則 → Egress 變成 deny-all！
```

反過來，policyTypes 沒寫的方向不受影響（維持全開）。

## NetworkPolicy 沒有 kubectl create 骨架

不像 Pod、Deployment 可以 `--dry-run=client -o yaml` 生骨架，NetworkPolicy 必須手寫或從官方文件複製。

考試時搜尋 `network policy` → 找到官方範例 → 複製下來改。

## only from pods 怎麼寫

| 題目說 | 怎麼寫 |
|--------|--------|
| only from pods（沒其他限制）| `podSelector: {}` — 同 namespace 所有 pod |
| only from pods + 特定 label | `podSelector: { matchLabels: ... }` — 只寫這個，不加 `podSelector: {}` |

重點是「只用 podSelector，不加 ipBlock / namespaceSelector」。NetworkPolicy 是白名單，不寫 ipBlock，外部 IP 自然進不來。

## from 三種來源類型

| 來源類型 | 用途 |
|---------|------|
| `podSelector` | 同 namespace 的 pod |
| `namespaceSelector` | 其他 namespace 的 pod |
| `ipBlock` | 外部 IP 範圍（cluster 外的流量）|

題目說「only from pods」= 只拿 podSelector 這把武器。

## ingress 層級 vs from 層級

```yaml
# 兩條獨立規則
ingress:
- from:            # ← 第一條 rule
  - podSelector: {}
- from:            # ← 第二條 rule
  - podSelector:
      matchLabels:
        app: trusted

# 一條規則內的 OR
ingress:
- from:            # ← 一條 rule
  - podSelector: {}
  - podSelector:
      matchLabels:
        app: trusted
```

結構不同，但效果等價（都是 OR 關係）。練習平台可能比對結構，真實 CKA 只驗行為。

`ingress` 陣列的 `-` = 獨立規則；`from` 陣列的 `-` = 同一規則內的 OR 條件。

## 實務上哪種寫法常見

同 port 用同一條 rule（多個 from 條件）：

```yaml
ingress:
- from:
  - podSelector: {...}
  - namespaceSelector: {...}
  ports:
  - port: 80
```

不同 port 才拆成獨立 rules：

```yaml
ingress:
- from:
  - podSelector: {matchLabels: {app: web}}
  ports:
  - port: 80
- from:
  - podSelector: {matchLabels: {app: monitoring}}
  ports:
  - port: 9090
```

## CKA 煙霧彈資源

題目提到的資源不一定都要動。認準「Create / Configure / Edit」後面接的對象才是目標。

例如題目說「X and Y deployed」但只要求對 X 建 NetworkPolicy，Y 就是煙霧彈。

## 題目冗餘規則照做

題目有時會給邏輯上冗餘的規則（例如 `podSelector: {}` 已包含 `app=trusted`）。

不要幫它優化合併，題目說兩條就寫兩條。CKA 考的是照規格交付，不是最佳實踐。

## CKA 真實考試驗行為不驗結構

真正 CKA 考試驗證的是流量能不能通，不是比對 YAML 結構。

KillerCoda 等練習平台會比對結構甚至順序，這是平台限制，不用太糾結。

## 有檔案用 apply -f，沒檔案才用 edit

| 方式 | 適用情境 |
|------|---------|
| 改檔案 + `apply -f` | 自己建的資源，有 YAML 留底 |
| `kubectl edit` | 別人建的資源，手邊沒檔案 |

有檔案可以反覆修改、回溯，比 edit 穩。

## vi 刪除快捷鍵

`d` + 移動指令 = 從游標刪到那個位置。

| 按 | 移動指令的意思 | 結果 |
|---|--------------|------|
| `dG` | `G` = 跳到檔尾 | 從游標刪到檔尾 |
| `dgg` | `gg` = 跳到檔頭 | 從游標刪到檔頭 |
| `d$` 或 `D` | `$` = 跳到行尾 | 從游標刪到行尾 |
| `d0` | `0` = 跳到行首 | 從游標刪到行首 |

按 `d` 後 vi 會等你輸入 motion，不用搶快。`y`（複製）、`c`（刪除並編輯）也一樣會等。

## deployments.apps 是合法全名

`deployments.apps` 是 fully qualified resource name（`apps` API group 底下的 `deployments`）。

Tab 補全會補成這個，不用刪，直接用。跟 `deployment`、`deploy` 完全等價。

Tab 補全出來的值語法上一定正確（從 API server 拿的），善用它補資源類型、資源名稱、flag。

## expose 對 Pod/Deployment/ReplicaSet 行為一致

不管對象是 Pod、Deployment 還是 ReplicaSet，`kubectl expose` 都是去讀 spec 裡的 `containerPort`。找不到就報錯，必須手動帶 `--port`。

不會因為對象類型不同而改變解析邏輯。

## containerPort 是宣告不是開 port

`containerPort` 是純文件性質的欄位，不影響 container 實際監聽什麼 port。

實際 port 是 image 自己決定的（例如 WordPress 預設跑 80），寫不寫 `containerPort` 都不影響流量能不能通。

但寫了之後 `kubectl expose` 可以自動抓，算是好習慣。

## NodePort 免 YAML 流程

當所有參數都能用 flag 搞定時，可以完全不寫 YAML：

```bash
kubectl create deployment my-app --image=wordpress --replicas=2
kubectl expose deployment my-app --type=NodePort --port=80 --name=my-svc
kubectl edit svc my-svc  # 補上 nodePort: 30770
```

唯一要 edit 的是 `nodePort`，因為 `kubectl expose` 沒有 flag 可以指定它。

## RS/DaemonSet/StatefulSet 沒有 kubectl create 捷徑

這類資源沒有 `kubectl create <resource>` 的指令，考試最快路徑：

1. 官方文件搜尋資源名稱
2. 複製範例 YAML
3. 改欄位 → `kubectl apply -f`

不要浪費時間從頭手寫。

## selector.matchLabels ⟷ template.metadata.labels 必須一致

RS / Deployment / DaemonSet 共通的配對機制：

- `selector.matchLabels` — controller 用來「找 Pod」的查詢條件
- `template.metadata.labels` — Pod 出生時被貼上的標籤

兩邊必須吻合，少一邊或不一致就報錯。label 叫什麼名字不重要，重要的是對得上。

## kubernetes.default 測 DNS

`kubernetes.default` 是每個叢集自動建立的 Service，指向 API Server。

拿來測 DNS 解析最方便，因為它一定存在：

```bash
kubectl exec pod-name -n ns -- nslookup kubernetes.default
```

能查到 = CoreDNS 活著、Pod 網路通。

## kubectl exec 重導向在本機 shell

`>` 是在執行 kubectl 的那台機器做重導向，不是在 Pod 裡面：

```bash
kubectl exec pod-name -n ns -- nslookup kubernetes.default > output.txt
```

這會把輸出存到你跑 kubectl 的節點上，不是 Pod 內部。

## local Volume PV 必須搭配 nodeAffinity

local volume 綁定節點上的實際路徑，必須告訴 scheduler 這個 PV 只能在哪個節點用：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-pv
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /mnt/disks/ssd1  # 節點上的實際路徑
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - example-node  # 指定節點名稱
```

當 `local` volume type 存在時，`nodeAffinity` 是必填。原因：local volume 指向特定節點的路徑，scheduler 必須知道這個 PV 只能在哪個節點用，才能把 Pod 排到正確的節點。

結構是 `nodeAffinity.required.nodeSelectorTerms[].matchExpressions[]`，常用 `kubernetes.io/hostname` 指定節點。

## PV nodeAffinity 範例在 Volumes 頁

官方文件搜 `local persistent volume`，範例在 Volumes 頁的 `local` 段，不在 Persistent Volumes 頁。

考試時找 PV + nodeAffinity 骨架，去這裡抄：https://kubernetes.io/docs/concepts/storage/volumes/#local

## hostPath 的 nodeAffinity 不強制但更危險

| volume type | nodeAffinity |
|-------------|--------------|
| `local` | API 強制必填，少了直接報錯 |
| `hostPath` | 不強制，沒寫也能建 |

hostPath 更危險：題目要求綁 node 你漏寫，K8s 不會報錯提醒，PV 正常建立但考試扣分。

## 資料綁 node → local 概念 → nodeAffinity

心智模型：hostPath / local 的資料只存在特定 node 的磁碟上，天生跟那台 node 綁死。nodeAffinity 是把這個物理事實告訴 K8s，讓 scheduler 不會把 Pod 排到拿不到資料的 node。

題目出現「hostPath + 指定 node」→ 自動連結到 nodeAffinity。

## nodeAffinity 是 PV spec 層級

跟 volume type 無關，`hostPath`、`local` 的 nodeAffinity 結構完全相同。從文件複製 `local` 範例，把 `local:` 改成 `hostPath:` 就能用。

## labels 是 map 不是 array

```yaml
# ✗ 錯誤（寫成 matchExpressions 格式）
labels:
- key: tier
  value: white

# ✓ 正確
labels:
  tier: white
```

常見陷阱，labels 是 key-value map。

## PVC selector.matchLabels 對應 PV 的 metadata.labels

```yaml
# PV
metadata:
  labels:
    tier: white

# PVC
spec:
  selector:
    matchLabels:
      tier: white  # 對應 PV 的 labels，不是 name
```

題目說「from PV `xxx` using matchLabels」容易誤解成用名字 match，但 matchLabels 永遠是比對 label。

## matchLabels 是篩選不是指定

`selector.matchLabels` 縮小候選範圍，過濾完可能剩一個，也可能剩多個。

| 做法 | 機制 |
|------|------|
| `selector.matchLabels` | PVC 端用 label 篩選（可能多個）|
| `claimRef` | PV 端直接寫死 PVC 名字（一對一）|

`claimRef` 才是真正的指名綁定。

多個候選時，K8s 選**容量最小但足夠**的（smallest fitting），避免小 PVC 綁到大 PV 浪費空間。

## WaitForFirstConsumer 導致 PVC Pending

PVC 卡在 Pending + Events 顯示 `WaitForFirstConsumer` ≠ 錯誤。

這是 StorageClass 的 `volumeBindingMode` 設定，要等 Pod 使用這個 PVC 時才觸發綁定。題目只要求建 PV/PVC，這樣就算完成。

確認方式：`k get sc <name> -o yaml` 看 `volumeBindingMode`。

## kubectl apply -f 不看副檔名

只看內容格式，叫 `pv.yaml`、`pv.yml`、`pv.txt`、甚至沒副檔名都行，內容是合法 YAML 或 JSON 就能吃。

考試省事：`vi pv` → `k apply -f pv`。

## vim A 跳到行末並進 insert mode

`$` 跳到行末（停在 normal mode），`A` 跳到行末並直接進 insert mode。考試時 `A` 更實用，到了就能直接打字。

## apply 順序：先 PV 後 PVC

PVC 要找 PV 來綁，PV 得先存在。

```bash
k apply -f pv
k apply -f pvc
```

## 確認 PV/PVC 綁定狀態

```bash
k get pv,pvc
```

兩邊 STATUS 都是 `Bound`、互相指向對方就是成功。

## Dynamic vs Static Provisioning

| 方式 | 流程 | 實務常見度 |
|------|------|-----------|
| Static | 管理員手動建 PV → 開發者建 PVC 綁定 | 少 |
| Dynamic | 定義 StorageClass → 開發者建 PVC → 自動建 PV | 主流 |

Dynamic 主流原因：
- 開發者自助服務，不用等管理員
- 按需分配，不用事先猜容量
- 雲原生（AWS EBS、GCP PD）原生支援
- GitOps 友善，PVC manifest 進 repo 就完成

Static 場景：特定硬體（local SSD）、需要精確控制綁定、沒有 dynamic provisioner。

CKA 愛考 static 是因為考點多（手寫 PV、nodeAffinity、selector）。

## StorageClass 完整範例

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: low-latency
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: csi-driver.example-vendor.example
reclaimPolicy: Retain  # 預設是 Delete
allowVolumeExpansion: true
mountOptions:
  - discard
volumeBindingMode: WaitForFirstConsumer
parameters:
  guaranteedReadWriteLatency: "true"  # provider-specific
```

關鍵欄位：
- `provisioner`：指定用哪個 CSI driver 建 volume
- `reclaimPolicy`：`Delete`（預設）或 `Retain`，PVC 刪除後 PV 怎麼處理
- `allowVolumeExpansion`：是否允許事後擴容
- `volumeBindingMode`：`Immediate`（預設）或 `WaitForFirstConsumer`
- `parameters`：傳給 provisioner 的參數，各家不同
- `storageclass.kubernetes.io/is-default-class: "true"`：標記為 default StorageClass，沒指定 StorageClass 的 PVC 會用這個

## Storage 三件套都沒有 kubectl create

SC、PV、PVC 全部沒有 `kubectl create` 捷徑，都要從官方文件複製或手寫。

## Apply 順序：SC → PV → PVC

按依賴關係走。PV 要指定 `storageClassName`，PVC 要綁 PV，所以順序不能亂。

## PVC 綁定特定 PV 用 volumeName

題目出現「should be bound to 某 PV」→ 用 `volumeName` 直接指定：

```yaml
spec:
  storageClassName: blue-stc-cka
  volumeName: blue-pv-cka
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi
```

`volumeName` 是一對一指定，`selector.matchLabels` 是篩選（可能多個）。

## volumeName 跳過 WaitForFirstConsumer

`volumeName` 是強制指定，Kubernetes 直接綁定，不管 StorageClass 的 `volumeBindingMode` 設成什麼。

## storageClassName 是配對條件

即使用了 `volumeName` 指定 PV，PVC 和 PV 的 `storageClassName` 也必須一致才能綁定。

可以想成：`storageClassName` 驗票，`volumeName` 選座位。票不對，指定座位也沒用。

## CKA 題目沒要求的欄位不寫

題目要什麼給什麼，多寫沒加分還可能出錯。沒要求的欄位讓它用預設值。

## StorageClass 的 provisioner 是必填

`provisioner` 是 SC 唯一的必填欄位，告訴 K8s 用什麼 driver 建 volume。

常見值：
- `kubernetes.io/no-provisioner`：static provisioning，不自動建 PV
- CSI driver：各雲廠商或 local-path-provisioner
