# CKA Practice Notes

整理日期：2026-06-10

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

## env 引用的兩種寫法

| 情境 | 寫法 | 誰展開 |
|------|------|--------|
| `sh -c` 裡面 | `echo "$VAR"` | shell |
| `args` 裡面（無 shell） | `["echo", "$(VAR)"]` | Kubernetes |

用 `sh -c` 就用 `$VAR`，用 `args` 就用 `$(VAR)`。

## 有空格的值要雙引號包 $VAR

```bash
# 錯：$ 在引號外面，這是 bash localization 語法
echo $"MY_VAR"

# 對：$ 在引號裡面
echo "$MY_VAR"
```

`Sony Tv Is Good` 有空格，不加引號會被 shell 拆成多個參數。

## Pod command/env 不可變，改了要刪掉重建

`k edit` 改 `command` 或 `env` 會被 API server 拒絕。流程：

```bash
k get pod product -o yaml > product.yaml
# 改 yaml
k delete pod product
k apply -f product.yaml
```

Pod 除了 `image`、`activeDeadlineSeconds`、`tolerations` 等少數欄位外，幾乎都不可變。

## k run --env 可以直接帶環境變數

```bash
k run mypod --image=busybox --env="MY_VAR=Sony Tv Is Good" -- sh -c 'echo "$MY_VAR"'
```

從零建 Pod 比手寫 YAML 快。多個變數就重複 `--env`。

## env 是 array，每個項目要 -

```yaml
# 錯：沒有 -，變成 key 而不是 list 項目
env:
  name: MY_VAR
  value: hello

# 對：有 -
env:
- name: MY_VAR
  value: hello
```

跟其他 list（`containers`、`ports`、`volumeMounts`）同理。

## env YAML 範例（官方文件）

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: print-greeting
spec:
  containers:
  - name: env-print-demo
    image: bash
    env:
    - name: GREETING
      value: "Warm greetings to"
    - name: HONORIFIC
      value: "The Most Honorable"
    - name: NAME
      value: "Kubernetes"
    - name: MESSAGE
      value: "$(GREETING) $(HONORIFIC) $(NAME)"  # env 可以引用其他 env
    command: ["echo"]
    args: ["$(MESSAGE)"]  # args 用 $(VAR) 語法，K8s 替換
```

重點：沒有 `sh -c` 時，用 `$(VAR)` 讓 Kubernetes 做替換。env 的 value 裡也可以用 `$(OTHER_VAR)` 組合其他變數。

## echo 內容不確定時加雙引號

```bash
echo "kube-apiserver-controlplane,kube-system" > high_cpu_pod.txt
```

內容沒有特殊字元時可以不加，但習慣加雙引號零成本防禦，不用每次判斷。

## --sort-by 是字串排序，有坑

`k top pod --sort-by cpu` 是 lexicographic（字串）排序：

- `9m` 會排在 `19m` 前面（因為 `'9' > '1'`）
- 數據少時碰巧對，數據多時可能出錯

## --sort-by 結果要肉眼驗證

考試數據量不大，跑完 `--sort-by` 後看一眼確認第一筆確實是最大值，不要直接相信工具排對了就抄第一行。

## k top 基本用法

```bash
# node 資源用量
k top node
k top node --sort-by cpu
k top node --sort-by memory

# pod 資源用量
k top pod                    # 當前 namespace
k top pod -A                 # 所有 namespace
k top pod -n kube-system     # 指定 namespace
k top pod --sort-by cpu
k top pod --sort-by memory
```

前提：叢集要有 metrics-server，CKA 考試環境已裝好。

## etcd backup SOP

kubeadm 叢集的 etcd 跑 static pod，連線參數全在 pod 的 `command` 裡。用 `describe` + `grep` 取出來，轉成 `etcdctl` 的參數名填進去。

```bash
# 1. 確認在 control plane 節點
hostname

# 2. 取連線參數（從 etcd pod 的 command）
k describe pod -n kube-system etcd-controlplane | grep -- '--'

# 3. 執行備份（參數名要轉換，見下一條筆記）
etcdctl snapshot save /opt/backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

題目要存 console output 就加 `&> output.txt`。

## etcd → etcdctl 參數名轉換

| etcd 啟動參數 | etcdctl 參數 |
|---------------|--------------|
| `--cert-file` | `--cert` |
| `--key-file` | `--key` |
| `--trusted-ca-file` | `--cacert` |
| `--advertise-client-urls` | `--endpoints` |

左右兩欄名字不一樣，從 pod 複製後要改。

## --endpoints 有 s

```bash
# 錯
etcdctl snapshot save ... --endpoint=https://...

# 對
etcdctl snapshot save ... --endpoints=https://...
```

`--endpoint` 會報 `unknown flag`。

## etcdctl 沒 tab completion

CKA 環境只有 `kubectl` 裝了 bash completion，`etcdctl` 沒有。參數要從 `describe` 結果複製貼上，不要硬背。

## 存 console output 用 &>

`etcdctl` 同時輸出 stdout（`Snapshot saved at...`）和 stderr（JSON log），用 `>` 只拿到一半。

```bash
# 完整捕捉
etcdctl snapshot save ... &> backup.txt
```

題目要求存 output 就用 `&>`，不要賭它走哪一邊。

## grep -- 開頭的字串

```bash
# 錯：grep 把 -- 當選項結束標記，後面沒 pattern
grep "--"

# 對：第一個 -- 告訴 grep 選項結束，第二個 -- 是 pattern
grep -- '--'
```

## 確認當前節點

```bash
hostname
# 或直接看 prompt: root@controlplane:~#
```

etcd 只跑在 control plane，題目說 `ssh controlplane` 就要照做。

## kubeadm etcd = static pod

kubeadm 建的叢集，etcd 跑的是 static pod，所有設定都在 `command` 參數裡，沒有另外的 config file。

CKA 固定 pattern：etcd 相關題目，參數一律從 pod 的 `command` 拿。

## etcdctl 不帶連線參數會卡住

`etcdctl` 預設連 `http://127.0.0.1:2379`，但 etcd 開了 `--client-cert-auth=true`，只接受帶憑證的 HTTPS。

不帶參數 → TLS 握手失敗 → 卡住等 timeout。`Ctrl+C` 中斷後補齊參數。

## 三種重導向寫法

| 寫法 | 捕捉什麼 |
|------|----------|
| `> file` | 只有 stdout |
| `2> file` | 只有 stderr |
| `&> file` | stdout + stderr |

不確定程式輸出走哪邊，用 `&>` 最保險。

## 重導向驗證法

執行完螢幕還有輸出 = 漏網之魚。

正確的 `&>` 執行後螢幕應該**什麼都沒有**，全部進了檔案。

## CKA 冷門題型策略

etcd backup、kubeadm upgrade、節點維護這類題目不深，但沒練過考場上現翻文件會耗大量時間。

策略：每種至少完整跑過一次，讓流程變肌肉記憶。考試這些題應該是送分題，省時間給核心資源的複雜題。

## etcd 3.6+ restore 改用 etcdutl

```bash
# 3.5 以前
etcdctl snapshot restore ...

# 3.6+（etcdctl snapshot restore 已移除）
etcdutl snapshot restore ...
```

網路上大部分教學還是舊寫法，直接照抄會報 `unknown flag: --data-dir`。

## save 用 etcdctl，restore 用 etcdutl

```bash
etcdctl snapshot save /opt/backup.db ...
etcdutl snapshot restore /opt/backup.db --data-dir /root/default.etcd
```

這樣寫不管 etcd 版本都能跑，不用記哪個版本支援什麼。

## etcdctl vs etcdutl

| | etcdctl | etcdutl |
|--|---------|---------|
| 全名 | control | utility |
| 本質 | client，透過 gRPC 連 server | 本地工具，直接操作檔案 |
| 需要連線 | ✓ 要 endpoint + TLS 憑證 | ✗ 不需要 server 運行 |
| 代表操作 | save、put、get、member list | restore、defrag（離線）|

要跟 server 講話的 → `etcdctl`；純粹操作檔案的 → `etcdutl`。

## restore 的 --data-dir 必須空或不存在

```bash
# 報錯：data-dir "/root/default.etcd" not empty or could not be read
etcdutl snapshot restore ... --data-dir /root/default.etcd

# 清掉重跑
rm -rf /root/default.etcd
etcdutl snapshot restore ... --data-dir /root/default.etcd
```

## etcdutl 實務用途

| 操作 | 場景 |
|------|------|
| `snapshot restore` | 災難復原，從備份重建 |
| `defrag` (離線) | 維護時整理磁碟、回收空間 |
| `snapshot status` | 檢查備份檔是否完整 |

平常不碰，災難復原才用。日常的 CRUD、健康檢查、member 管理全走 `etcdctl`。

## 重導向完整寫法對照

| 寫法 | 效果 |
|------|------|
| `> file` | 只捕 stdout，stderr 還是印螢幕 |
| `2>&1 > file` | ❌ 順序錯，stderr 還是跑到螢幕 |
| `> file 2>&1` | ✓ stdout + stderr 都進檔案 |
| `&> file` | ✓ 同上，bash 簡寫 |
| `2>&1 \| tee file` | ✓ 進檔案同時螢幕也看得到 |

不確定就用 `&>`；想邊跑邊看就用 `tee`。

## kubeadm upgrade 三階段

```bash
# 0. 確認目標版本存在（minor 升級要先改 repo）
# minor 升級：先改 /etc/apt/sources.list.d/kubernetes.list 裡的版號
sudo apt-get update
apt-cache madison kubeadm  # 找到你要的版本

# 1. 升 kubeadm
apt-mark unhold kubeadm
apt-get install -y kubeadm='1.35.2-*'
apt-mark hold kubeadm

# 2. 升 cluster
kubeadm upgrade plan
kubeadm upgrade apply v1.35.2

# 3. 升 kubelet/kubectl
kubectl drain controlplane --ignore-daemonsets
apt-mark unhold kubelet kubectl
apt-get install -y kubelet='1.35.2-*' kubectl='1.35.2-*'
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet
kubectl uncordon controlplane
```

順序不能亂：kubeadm 先 → cluster → kubelet/kubectl。

## patch vs minor 升級差異

| 類型 | 例子 | 換 repo？ |
|------|------|-----------|
| patch | 1.27.1 → 1.27.2 | ✗ 不用 |
| minor | 1.27.x → 1.28.x | ✓ 要 |

K8s apt repo 按 minor version 分開：

```
https://pkgs.k8s.io/core:/stable:/v1.27/deb/  # 1.27.0, 1.27.1, 1.27.2 ...
https://pkgs.k8s.io/core:/stable:/v1.28/deb/  # 1.28.0, 1.28.1, 1.28.2 ...
```

minor 升級要先改 repo 再 `apt-get update`：

```bash
sudo nano /etc/apt/sources.list.d/kubernetes.list
# 把 v1.27 改成 v1.28

sudo apt-get update
```

patch 升級不用動 repo，直接從 `apt-get update` 開始。

## apt-cache madison 查版號

```bash
apt-cache madison kubeadm
```

列出所有可裝的版號，確認目標版本存在再裝。

## 版號格式用 x.y.z-*

```bash
apt-get install -y kubeadm='1.35.2-*'
```

`-*` 自動 match build suffix（如 `-1.1`），不用查完整版號。

## apply vs upgrade node

| 指令 | 用在哪 |
|------|--------|
| `kubeadm upgrade apply v1.35.2` | 第一個 control plane |
| `kubeadm upgrade node` | 其他 cp 和 worker nodes |

CKA 通常只有一個 cp，所以 cp 升級用 `apply`。但如果題目要求升級 worker node，在 worker 上要用 `upgrade node`。

## k get nodes 的 VERSION 是 kubelet

```bash
$ k get nodes
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   23d   v1.35.2   # <- 這是 kubelet 版本
node01         Ready    <none>          23d   v1.35.1

$ k version
Client Version: v1.35.2      # <- kubectl 版本
Server Version: v1.35.2      # <- API server 版本
```

## upgrade 驗收三件套

| 檢查項目 | 指令 |
|----------|------|
| kubeadm | `kubeadm version` |
| cluster (API server) | `k version` → Server Version |
| kubelet | `k get nodes` → VERSION |
| kubectl | `k version` → Client Version |

## upgrade 題是文件導航題

搜 "upgrade" 進 "Upgrading kubeadm clusters" 頁面，照 checklist 做。不用背流程，但要練到知道大概有哪些步驟，看文件時才不會漏。

## drain/uncordon 別忘

```bash
# 升 kubelet 前
kubectl drain <node> --ignore-daemonsets

# 升完後
kubectl uncordon <node>
```

漏掉 drain 不會報錯但不符合 best practice；漏掉 uncordon 節點會一直是 SchedulingDisabled。

## Pending Pod debug SOP

```
Pod Pending
    ↓
k describe pod <name>  → 看 Events 關鍵字
    ↓
根據關鍵字定位問題資源 → 修復
```

debug SOP 永遠是 `describe` → 讀 Events → 追根源。

## Pending Pod 常見原因

| 原因 | Events 關鍵字 | 追查方向 |
|------|---------------|----------|
| 排程失敗 | `FailedScheduling` | node 資源不足、taint 沒對應 toleration、nodeSelector/affinity 沒匹配的 node |
| PVC 未綁定 | `unbound immediate PersistentVolumeClaims` | PVC 還在 Pending → 往下查 PV/StorageClass |
| 節點不可用 | `no nodes available` | node 是否 Ready、是否被 cordon |
| 資源配額超限 | `exceeded quota` | ResourceQuota 限制 |
| 排程器名稱錯誤 | `no nodes available to schedule` | `schedulerName` 指到不存在的 scheduler |

CKA 最高頻是前兩個，尤其 PVC 未綁定常跟 storage 題組合出現。

## PVC Pending 常見原因

| PVC Pending 原因 | 怎麼查 |
|------------------|--------|
| `storageClassName` 不匹配 | 比對 PV 和 PVC 的 `storageClassName` |
| `accessModes` 不匹配 | PVC 要求的 mode 必須是 PV 提供的子集 |
| 容量不足 | PVC `requests.storage` > PV `capacity` |
| `volumeName` 指向不存在的 PV | PVC 指定了名稱但 PV 不存在或已 Bound |
| `WaitForFirstConsumer` | SC 的 bindingMode 導致沒 Pod 就不綁（這種其實不算錯） |
| selector/label 不匹配 | PVC 用了 `matchLabels` 但 PV 沒對應 label |

## PVC 綁定三要素

`storageClassName`、`accessModes`、`capacity`，三個都要對得上。

快速排查 PVC Pending 就先比這三個。

## hostPath 只支援 RWO

`hostPath` 是單節點本地路徑，`ReadWriteMany` 在這裡沒意義。

accessModes 不匹配時，改 PVC 去適應 PV（基礎設施層不動）。

## PVC spec 建了就鎖死

| 欄位 | 能否改 | 備註 |
|------|--------|------|
| `accessModes` | ✗ immutable | |
| `volumeMode` | ✗ immutable | |
| `storageClassName` | ✗ immutable | |
| `volumeName` | ✗ immutable | |
| `selector` | ✗ immutable | |
| `resources.requests.storage` | ⚠️ 只能變大 | 需要 StorageClass 的 `allowVolumeExpansion: true` |

PVC 建立之後 spec 幾乎全部鎖死，要改就 delete → recreate。

## --dry-run 只給寫的指令用

| 支援 `--dry-run` | 不支援 `--dry-run` |
|------------------|---------------------|
| `create`、`apply`、`run`、`expose`、`delete`、`patch`、`scale` | `get`、`describe`、`logs`、`top`、`exec` |

`--dry-run=client` 只適用於寫入操作。`k get` 本身就是唯讀的，不需要也不支援 dry-run。

## Troubleshooting YAML 標準流程

```
k apply -f xxx.yaml
    ↓
看錯誤訊息 → 定位問題（語法錯、欄位名錯、結構層級錯、值的型別錯）
    ↓
修復 → 再 apply 確認
```

題目說「Don't remove any specification」代表只能改不能刪。

## apply 成功 ≠ 資源正常運作

`k apply` 成功只代表 **API server 接受了你的 spec**，不代表 Pod 跑得起來。

你只是過了「文件審查」，還沒上路。永遠往下查到 Pod 層級確認實際狀態。

## Debug 順序永遠往下查

```
Deployment → Pod → describe pod → logs
```

Deployment 只是「責成單位」，Pod 才是「實際執行」。Deployment apply 成功只代表 API server 接受了 spec，不代表 Pod 跑得起來。

## CreateContainerConfigError

通常是 Secret / ConfigMap 引用問題：

- Secret / ConfigMap 名稱打錯（typo）
- Secret / ConfigMap 存在但 key 不存在
- Secret / ConfigMap 根本不存在

下一步：`k describe pod <name>` 看 Events，會告訴你具體是哪個 Secret 或 key 找不到。

## 線索藏在兩個地方

| 位置 | 比喻 | 看什麼 |
|------|------|--------|
| Events | 案發現場 | 錯誤訊息、時間軸 |
| spec 細節 | 證人口供 | typo、引用名稱、key 名稱 |

兇手不只在案發現場（Events），也可能藏在「證人口供」（spec 細節）裡。兩邊都要看。

## Controller 資源 vs bare Pod 的 apply 行為

| 資源 | `k apply` 能直接更新？ | 原因 |
|------|------------------------|------|
| Deployment | ✓ | spec 幾乎全 mutable，改了自動 rollout |
| Service | ✓ | 大部分欄位可改（`clusterIP` 除外） |
| PVC | ⚠️ 部分 | `accessModes`、`storageClassName` 不可改 |
| bare Pod | ✗ 大部分不行 | 核心欄位 immutable，要刪除重建 |

Controller 資源（Deployment / Service）直接 `apply` 蓋上去；bare Pod 幾乎都要刪了重建。

## Troubleshooting 是剝洋蔥

```
apply 成功（不代表能跑）
    ↓
get 確認狀態 → 有差就往下查
    ↓
describe 上層資源 → 看 spec + events 找線索
    ↓
describe pod → 真正的錯誤訊息在這裡
    ↓
交叉比對引用的資源 → Secret / ConfigMap / PV 的實際內容 vs 引用名稱
    ↓
修一輪，再跑一輪 → 可能有多個問題，別修一個就收工
```

每次只進一層錯誤，修完再看下一層，永遠要驗證到 Pod 進 `Running` 才算收工。

## 交叉比對引用資源

Deployment 引用 Secret/ConfigMap 時，兩層都要對：

1. **資源名稱**：`secretKeyRef.name` 要對到實際 Secret 名稱
2. **key 名稱**：`secretKeyRef.key` 要對到 Secret 裡實際的 key

```bash
# 看 Secret 實際有哪些 key
k get secret <name> -o yaml
```

名稱對了 key 也要對，兩個都是 typo 高發區。

## Troubleshooting 三層流程

```
get → describe → logs
```

| 層級 | 指令 | 看什麼 |
|------|------|--------|
| 1 | `k get pod <name>` | STATUS：Pending / CrashLoopBackOff / ImagePullBackOff / Error |
| 2 | `k describe pod <name>` | Events 區塊，找失敗的具體原因 |
| 3 | `k logs <pod>` | 容器層級的錯誤訊息 |

不同 STATUS 修復方向不同，先確認狀態再往下挖。

## 容器沒啟動就沒 log

`CreateContainerError` 時 `k logs` 是空的——容器根本沒跑起來，當然沒 log。

這時線索在 `k describe pod` 的 Events 裡，不要浪費時間查 logs。

## 讀錯誤訊息的心法

從後往前讀，四步驟定位問題：

| 步驟 | 做什麼 | 範例 |
|------|--------|------|
| 1 | 找關鍵字 | `not found`、`error`、`failed` |
| 2 | 找對象 | 引號裡的東西就是出問題的目標 |
| 3 | 找階段 | 前綴詞告訴你發生在什麼時機（`exec` = 執行階段）|
| 4 | 回頭對照 spec | 把錯誤指向的對象拿去 YAML 裡找本體 |

引號內的東西就是「兇手」，從那裡出發去 YAML 找錯字。

## executable file not found 範例

```
exec: "shell": executable file not found in $PATH
```

翻譯：容器啟動時要跑 `shell` 這個程式，但容器裡根本沒有叫 `shell` 的東西。

對照 YAML 的 `command` 欄位，發現是 `/bin/sh` 的 typo。

## 看到 -c 就知道前面是 shell

```yaml
command:
- shell  # <- 這裡寫錯
- -c
- "while true; do echo 'Hello'; sleep 5; done"
```

`-c` + 一段 script = 只有 `sh`、`bash`、`zsh` 這類 shell 才吃的組合。

看到這個 pattern 就能反推：前面那個一定是 shell，`shell` 不是任何真實程式名稱，所以是 typo。

## shell 選擇優先順序

| 選項 | 可不可以 | 為什麼 |
|------|----------|--------|
| `/bin/sh` | ✓ 首選 | POSIX 標準，幾乎所有 image 都有 |
| `sh` | ✓ 也行 | 會透過 `$PATH` 找到 |
| `/bin/bash` | ⚠️ 不一定 | 不是所有 image 都有（Alpine 沒有）|
| `shell` | ✗ | 不存在這個程式 |

考試除非題目指定，否則一律用 `/bin/sh` 最保險。
