# CKA Practice Notes

## jsonpath 取 Secret 單一 key

`-o jsonpath='{.data.<KEY>}'` 直接取 raw 值，可 pipe 給 `base64 -d`：

```bash
k get secret my-secret -n ns -o jsonpath='{.data.DB_PASSWORD}' | base64 -d > decoded.txt
```

比 `-o yaml` 乾淨，不帶多餘內容。

## 單一值直接複製最快

`k get secret -o yaml` 複製值，再：

```bash
echo c2VjcmV0 | base64 -d > decoded.txt
```

考試計時下，這比打 jsonpath 語法快。jsonpath 留給多值或腳本化場景。

## CKA 預設 Linux 基礎

`base64`、`openssl`、`systemctl`、`journalctl`、`curl` 等不在 K8s 文件裡，考試預設你會。不確定時用 `--help`。

## create secret 要接類型

```bash
k create secret generic my-secret --from-file=data.txt
```

`secret` 後面必須接類型，不能直接接名稱。三種：`generic`、`docker-registry`、`tls`，CKA 幾乎都用 `generic`。

## --from-file vs --from-env-file

`--from-file=data.txt`：整個檔案塞進一個 key，key 名是檔名

```yaml
data:
  data.txt: <整個檔案內容的 base64>
```

`--from-env-file=data.txt`：檔案裡每行 `KEY=value` 變成獨立的 key

```yaml
data:
  DB_User: <value1 的 base64>
  DB_Password: <value2 的 base64>
```

要指定 key：`--from-file=mykey=data.txt`

## kubectl run 的 -- 和 --command 差異

```bash
k run x --image=nginx -- sleep 5         # 進 args（Docker CMD）
k run x --image=nginx --command -- sleep 5  # 進 command（Docker ENTRYPOINT）
```

題目說「用 command」就要加 `--command`。沒有 `--args` flag，因為 `--` 後面預設就是 args。

## jsonpath 必須指定資源名稱

```bash
k get svc -o jsonpath='{.spec.ports[0].targetPort}'       # 錯：沒指定名稱，查全部 svc
k get svc redis-service -o jsonpath='{.spec.ports[0].targetPort}'  # 對
```

不指定名稱時結果是 list，路徑變成 `.items[*].spec...`，原本的 `.spec...` 對不上。

## jsonpath 一律用單引號

```bash
# 安全
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# 有風險：* 可能被 shell glob 展開
kubectl get pods -o jsonpath="{.items[*].metadata.name}"
```

單引號不解析任何內容，雙引號會嘗試展開 `*`、`$`、`!` 等。考試不用記哪些安全，統一單引號。

## jsonpath 基本語法

把 YAML 層級用 `.` 串起來，陣列加 `[]`：

| 語法 | 用途 | 範例 |
|------|------|------|
| `.spec.field` | 取單一欄位 | `.spec.clusterIP` |
| `.items[*]` | 遍歷陣列 | `.items[*].metadata.name` |
| `.items[0]` | 取特定索引 | `.spec.ports[0].targetPort` |
| `?(@.key==val)` | 條件過濾 | `.items[?(@.metadata.name=="redis")]` |
| `{"\n"}` | 換行輸出 | 多筆結果時好讀 |

實戰：先 `-o yaml` 看結構，再把層級翻譯成 jsonpath。

## --sort-by 也是 jsonpath，一律加單引號

`--sort-by` 用的是 jsonpath 語法。官方文件有時省略引號，但有 `[]` 等字元時 shell 會嘗試展開。統一加單引號最安全：

```bash
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'
```

## boolean flag 不能空格接值

Boolean flag 出現即是 true，不需要帶值。空格後的字會被當成下一個參數。

```bash
k logs pod --all-containers true   # 錯：true 被當成 container name
k logs pod --all-containers        # 對：出現即 true
k logs pod --all-containers=true   # 對：明確寫法
k logs pod --all-containers=false  # 要關掉才需要 =false
```

所有 boolean flag 同理：`--watch`、`--dry-run`、`--force` 等。

## 已知 pod name，找它在哪個 namespace

```bash
k get pod -A | grep <pod-name>
k get pod --all-namespaces | grep <pod-name>
```

`-A` 是 `--all-namespaces` 的簡寫。

## kubectl logs 記得加 --all-containers

```bash
k logs <pod> --all-containers > logs.txt
```

考試題目可能是多容器 pod，養成習慣加這個 flag，避免漏掉其他 container 的 log。

## kubectl top node --sort-by

找資源用量最高/最低的 node：

```bash
k top node --sort-by memory
k top node --sort-by cpu
```

此時 `--sort-by` 只接受 `cpu` 或 `memory` 兩個值。

## tab completion 不補 flag 的值

Tab 補齊範圍：子命令、flag 名稱、資源類型、資源名稱。

Flag 的可選值（如 `--sort-by` 的 `cpu`/`memory`）不在補齊範圍，要自己打完整字串。

## CKA 改卷看結果不看過程

能用眼睛看出答案就直接手寫，不需要硬湊 pipeline。省下的時間拿去做下一題。

```bash
echo "$(k config current-context),controlplane" > high_memory_node.txt
```

## k config current-context

取得當前 context 名稱，題目常要求輸出格式包含 context。

```bash
k config current-context
```

## CKA 常用兩層子命令

不用背，`-h` 看一眼就知道有哪些子命令。

| 命令群組 | 常用子命令 | CKA 用途 |
|----------|------------|----------|
| `config` | `current-context`, `get-contexts`, `use-context`, `set-context` | context 切換、查詢 |
| `rollout` | `status`, `history`, `undo`, `restart` | Deployment 滾動更新 |
| `certificate` | `approve`, `deny` | CSR 簽發 |
| `auth` | `can-i` | RBAC 權限檢查 |
| `top` | `node`, `pod` | 資源用量查詢 |
| `cluster-info` | `dump` | 叢集資訊 |

## kubectl logs 沒有內容過濾參數

`kubectl logs` 的參數都是時間/行數/容器層級，不做內容過濾：

| 參數 | 過濾什麼 |
|------|----------|
| `--since=1h` | 最近 1 小時 |
| `--tail=100` | 最後 100 行 |
| `--previous` | 前一個容器的 log |
| `-c <name>` | 指定容器 |

內容過濾交給 shell：`grep`、`awk` 等。

## CKA 常用 grep

| 用法 | 效果 |
|------|------|
| `grep "ERROR"` | 只看含 ERROR 的行 |
| `grep -i "error"` | 不分大小寫 |
| `grep -c "ERROR"` | 算有幾行符合 |
| `grep -v "INFO"` | 反向——排除含 INFO 的行 |

速記：`grep "關鍵字"` = 只留匹配行，`-v` = 反向排除

## CKA log 題套路

kubectl 負責取、grep 負責篩、`>` 負責存：

```bash
k logs <pod> | grep "ERROR" > errors.txt
```

## /bin/sh -c 後面是一整個字串

```yaml
# 錯：拆成多個元素，-f 和路徑變成 $0、$1
args:
  - tail
  - -f
  - /config/log.txt

# 對：一整個字串當命令執行
args:
  - "tail -f /config/log.txt"
```

`-c` 只看第一個 arg，後面的變成 shell 的位置參數。

分開寫時，shell 只執行 `tail`（**沒參數**），`-f` 和路徑變成 shell 的 `$0`、`$1`，**根本沒傳給** `tail`。

## -c 是必要的但題目可能不寫

看到 `/bin/sh` + 命令字串的組合，要自己知道補 `-c`：

```yaml
command: ["/bin/sh", "-c"]
args: ["tail -f /config/log.txt"]
```

沒有 `-c` 時，shell 會把後面的字串當檔案路徑去找，兩種寫法都報錯但原因不同：

- `args: ["tail", "-f", "/config/log.txt"]` → 找一個叫 `tail` 的腳本檔案，`-f` 和路徑變成腳本的 `$0`、`$1`
- `args: ["tail -f /config/log.txt"]` → 找一個檔名含空格的檔案

實際錯誤訊息：`/bin/sh: can't open 'tail -f /config/log.txt': No such file or directory`

## command 和 args 是拼接關係

K8s 執行時把 command + args 串起來：

| K8s 欄位 | Docker 對應 | 用途 |
|----------|-------------|------|
| `command` | ENTRYPOINT | 執行器 |
| `args` | CMD | 參數 |

題目指定哪個欄位放什麼就照做，全塞 command 功能上可行但會被扣分。

## kubectl run 的 container name = pod name

`kubectl run` 生成的 container name 預設等於 pod name，沒有 flag 可改。要不同名只能編輯 YAML：

```yaml
containers:
  - name: alpine-container  # 手動改這裡
```

## mountPath 從命令路徑反推

題目不直接給 mountPath，要從命令推：

```
tail -f /config/log.txt
        ^^^^^^^ 這就是 mountPath
```

## ConfigMap volume 範例位置

官方文件：`kubernetes.io/docs/concepts/storage/volumes/#configmap`

考試直接抄，改三個值：volume `name`、`configMap.name`、`mountPath`。

## YAML 的 - 代表新物件

同一個 container 內只有開頭有 `-`，其他欄位縮排對齊不加 `-`：

```yaml
containers:
- command:      # <- 第一個 container 開始
    - /bin/sh
    - -c
  args:         # <- 同個 container，不加 -
    - "tail -f /config/log.txt"
  image: alpine:latest
  name: alpine-container
```

在 `args` 前面加 `-` 會變成宣告第二個 container。

## Debug SOP: describe + logs

```
Status Error / CrashLoopBackOff
        ↓
k describe pod  → 看 State、Exit Code、Events
        ↓
k logs <pod>    → 看實際錯誤訊息
```

describe 告訴你「死了」，logs 告訴你「怎麼死的」。Exit Code 2 通常是 shell 層級錯誤（找不到檔案、語法錯）。

## Role YAML 範例

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default  # Role 是 namespace-scoped
  name: pod-reader
rules:
- apiGroups: [""]  # "" = core API group（pods, services, configmaps 等）
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

`apiGroups` 其他常見值：`apps`（Deployment）、`batch`（Job, CronJob）、`rbac.authorization.k8s.io`（Role, RoleBinding）。

## ClusterRole YAML 範例

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # ClusterRole 沒有 namespace，是 cluster-scoped
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```

結構跟 Role 一樣，差別只在沒有 `namespace` 欄位。ClusterRole 可搭配 RoleBinding（限定 namespace）或 ClusterRoleBinding（全叢集）。

## RoleBinding YAML 範例

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User  # User / Group / ServiceAccount
  name: jane  # name 是 case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role  # Role 或 ClusterRole
  name: pod-reader  # 要綁定的 Role 名稱
  apiGroup: rbac.authorization.k8s.io
```

subjects 可以有多個。roleRef 指向同 namespace 的 Role，或任意 ClusterRole（此時權限限縮在這個 namespace）。

## ClusterRoleBinding YAML 範例

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global  # 沒有 namespace，cluster-scoped
subjects:
- kind: Group  # 這例子用 Group
  name: manager  # name 是 case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

ClusterRoleBinding + ClusterRole = 全叢集權限。subjects 可以是 User、Group、ServiceAccount。

## RBAC subjects 三種類型

| | User | Group | ServiceAccount |
|--|------|-------|----------------|
| K8s 管理 | ✗ | ✗ | ✓ |
| 用途 | 人 | 人的集合 | Pod 內程式 |
| 有 API 物件 | ✗ | ✗ | ✓ |

User/Group 由外部系統定義（憑證 CN、OIDC），叢集內查不到。ServiceAccount 是 K8s 原生物件，`kubectl get sa` 可查。題目給 SA 就綁 SA，給人名就綁 User。

## RBAC 資源沒有 shortname

Role、ClusterRole、RoleBinding、ClusterRoleBinding 都沒有官方縮寫，要打全名或靠 tab 補齊。只有 ServiceAccount 有 `sa`。

## RBAC 權限更新題型拆解

題目給 SA + ClusterRole + ClusterRoleBinding，要你改權限：

1. SA 和 Binding 已經綁好，不用動
2. 只改 ClusterRole 的 rules
3. `k edit clusterrole <name>` 最快

關鍵字「only」代表改完後 rules 裡只能剩指定的 resources 和 verbs。

## YAML list 格式陷阱

```yaml
# 錯：這是一個字串 "get,list,create"
verbs:
- get,list,create

# 對：三個獨立元素
verbs: ["get", "list", "create"]

# 或
verbs:
- get
- list
- create
```

YAML list 每個元素要獨立 `-`，用逗號串在一起只是一個字串。

## apiGroups 常見組合速查表

| apiGroups | resources |
|-----------|-----------|
| `""` (core) | pods, services, configmaps, secrets, persistentvolumeclaims, nodes, namespaces, serviceaccounts |
| `apps` | deployments, statefulsets, daemonsets, replicasets |
| `batch` | jobs, cronjobs |
| `networking.k8s.io` | ingresses, networkpolicies |
| `rbac.authorization.k8s.io` | roles, clusterroles, rolebindings, clusterrolebindings |
| `storage.k8s.io` | storageclasses |

不確定時現查：`k api-resources | grep <resource>`，看 APIVERSION 欄位。

## 不同 apiGroups 要分開寫 rules

一條 rule 內的 resources 必須屬於同一個 apiGroups。要授權 pods (core) + deployments (apps) 要寫兩條：

```yaml
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
```

注意：`apiGroups: []` 是空陣列（錯），`apiGroups: [""]` 才是 core group。

## apiGroups 和 resources 必須對應正確

`apiGroups: [""]` + `resources: ["deployments"]` 是錯的——deployments 屬於 apps，不在 core group。

API server 不會報錯，但權限不會生效（silent failure）。這是 RBAC 題常見陷阱。

## APIVERSION 格式就是 group/version

`k api-resources` 的 APIVERSION 欄位格式是 `<group>/<version>`：

- `v1` → core group，apiGroups 寫 `""`（特例，省略 group 名）
- `apps/v1` → apiGroups 寫 `"apps"`
- `batch/v1` → apiGroups 寫 `"batch"`
- `networking.k8s.io/v1` → apiGroups 寫 `"networking.k8s.io"`

斜線前面那段就是 `apiGroups` 的值。

## RBAC 三件套都有 kubectl create 捷徑

```bash
kubectl create serviceaccount app-account
kubectl create role app-role --verb=get --resource=pods
kubectl create rolebinding app-binding --role=app-role --serviceaccount=default:app-account
```

不用手寫 YAML，直接 `kubectl create` 最快。

## RBAC kubectl create 語法在官方 RBAC 文件頁

考試搜 "rbac" 直接到位，往下滑就有 `kubectl create role`、`kubectl create rolebinding` 的完整範例。

文件位置：`kubernetes.io/docs/reference/access-authn-authz/rbac/`

## --api-group 預設空字串 = core group

```bash
# pods 在 core group，不用指定
k create role my-role --verb=get --resource=pods

# deployments 在 apps group，要指定
k create role my-role --verb=get --resource=deployments --api-group=apps
```

`--api-group` 預設是 `""`（core），只有非 core 資源才要明確指定。

## --serviceaccount 格式是 namespace:name

```bash
k create rolebinding app-binding --role=app-role --serviceaccount=default:app-account
```

`--serviceaccount` 要帶 `namespace:name`，不能只寫名字。

## kubectl create role 多個 verb 寫法

```bash
# 逗號串起來
k create role my-role --verb=get,list,watch --resource=pods

# 或重複 flag
k create role my-role --verb=get --verb=list --verb=watch --resource=pods
```

CLI 用逗號串是可以的，跟 YAML 不同（YAML 要每個元素獨立 `-`）。

原因：kubectl 的 flag parser 專門設計成逗號分隔 = 多個值，但 YAML parser 不做這種處理，逗號就是字串的一部分。

