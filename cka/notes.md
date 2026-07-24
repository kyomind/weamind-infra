# CKA Practice Notes

## DaemonSet 問題診斷方向

DaemonSet 考題幾乎都是排程問題，重點永遠在 node 端（taint/label），不在 DaemonSet 本身。

## grep YAML 多行結構要帶 -A

`grep -i tai` 只抓到 `taints:` 那行，value 在下一行會漏掉。標準做法：

```bash
grep -iA5 taint
```

## 查 taint 標準指令

```bash
k describe node <name> | grep -iA5 Taint
```

## Taint vs Label 定位

| 機制 | 用途 | 粒度 |
|------|------|------|
| Taint | 禁令、排除 | 粗，數量少 |
| Label | 標籤、選擇 | 細，數量多 |

排程精細控制靠 label + nodeAffinity，不靠 taint。

## toleration 沒有 imperative 指令

只能 `k edit` 或改 YAML apply。nodeAffinity、volumeMounts 也一樣沒有對應的 kubectl 指令。

## toleration 層級記法

`spec.template.spec.tolerations`，和 containers 同層。

Controller 類資源（Deployment / DaemonSet / StatefulSet）的 Pod 設定都在 `spec.template.spec` 下。

## Taint 沒 value 時用 Exists

Taint 格式 `key=value:effect`，value 可選。沒有 `=` 代表沒 value，toleration 用 `operator: Exists` 最乾淨：

```yaml
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
```

## Vim 多行縮排

`V` 選行 → `j`/`k` 或方向鍵擴選 → `>` 縮排 → `.` 重複。

按 `>` 後 Vim 會退出 Visual 模式回到 Normal 模式，此時再按單個 `>` 沒反應（在等 motion）。`.` 的好處是不用重選，直接對同一範圍再縮一層。

## node 加 / 移除 taint 語法

```bash
# 加 taint
kubectl taint nodes node1 key1=value1:NoSchedule

# 移除 taint（結尾加 -）
kubectl taint nodes node1 key1=value1:NoSchedule-
```

## etcdctl 輸出走 stderr

要用 `&>` 才能捕捉完整輸出，單用 `>` 只抓 stdout 會是空的。

```bash
etcdctl snapshot save /opt/backup.db &> backup.txt
```

## Node NotReady + NodeStatusUnknown = kubelet

`describe node`，Conditions 全顯示 `Kubelet stopped posting node status` 時，直接：

```bash
systemctl restart kubelet
```

Node 的 STATUS 是靠 kubelet heartbeat/lease（預設 10 秒）回報給 API Server，跟 Pod 是否正常運行是兩條不同資訊流。「Pod 都正常」不能推論「Node 正常」，看到題目卡在 kube-system 底下要做事之前，先 `k get no` 排除 Node 層級問題。

## Conditions vs Events 使用時機

| 面向 | Conditions | Events |
|------|------------|--------|
| 本質 | 持續性的狀態快照 | 一次性的事件紀錄 |
| 回答問題 | 「現在怎麼了？」 | 「剛才發生什麼？」 |
| 適用層級 | Node | Pod |
| 典型內容 | Ready、MemoryPressure | Scheduled、Pulling、FailedMount |

Node 問題看 Conditions（心跳消失會自動變 Unknown）；Pod 問題看 Events（動作失敗才有紀錄）。

## etcd 沒帶 TLS 會 hang 不報錯

超過 2 秒沒回應就是缺證書參數，直接 `Ctrl+C` 檢查 `--cacert`、`--cert`、`--key` 有沒有帶齊。

## &> 是覆寫模式

忘記導向不用刪檔，重跑加 `&>` 就會覆蓋。`&>>` 才是追加。

## etcd backup 流程口訣

1. 修 kubelet（如果 Node NotReady）
2. 確認 etcd pod 活著
3. `grep -- "--"` 從 etcd pod yaml 拿 TLS 路徑
4. `snapshot save` + `&>` 一次搞定備份和輸出存檔

## 每題做完要自己驗證

KillerCoda 有 checker 但真考試沒有。養成習慣：做完 → 驗證 → 下一題。沒驗證的答案不算完成。

## NetworkPolicy ingress.from 是 OR 關係

每一條 `- podSelector` 都是獨立放行規則，彼此是 OR。要縮減存取就砍條目，不是改條件。

## PVC Pending 診斷與 immutable 限制

診斷三要素：`storageClassName` 對不對、`accessModes` 符不符、capacity 夠不夠。

PVC spec 幾乎全部 immutable：

| 欄位 | 能否 edit | 備註 |
|------|-----------|------|
| `accessModes` | ✗ | immutable |
| `selector` | ✗ | immutable，漏寫只能 delete 重建 |
| `resources.requests.storage` | ⚠️ 只能擴 | 唯一可變欄位，但只能往上不能縮 |

改 accessModes、selector 或縮容 → delete 重建。

## RBAC 排查順序

Role 內容 → RoleBinding 接線 → Namespace 一致。

SA 驗證包含在 RoleBinding 的 subjects 裡，不用獨立查。

## 為什麼先查 Role

Role 出錯面最大：`apiGroups`、`resources`、`verbs` 三個欄位都可能寫錯或漏寫。RoleBinding 只是接線，SA 更簡單。

## Role 可以直接 k edit

Role 是 mutable 的，`k edit role <name>` 改完即生效，不用 delete 重建。跟 PVC 不一樣。

## YAML 多值要一行一個 - item

逗號分隔是字串不是陣列，Kubernetes 會找不到資源。

```yaml
# ✓ 正確
resources:
- pods
- services

# ✗ 錯誤（這是一個字串 "pods, services"）
resources:
- pods, services
```

## RBAC 驗證指令

```bash
# 單一權限檢查
k auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<name>

# 範例
k auth can-i create pods --as=system:serviceaccount:default:dev-sa

# 列出全部權限
k auth can-i --list --as=system:serviceaccount:default:dev-sa
```

## kubectl explain 不用記完整路徑

從記得的層級開始往下查，一層一層看：

```bash
k explain pod.spec.containers.env
```

會列出 `name`、`value`、`valueFrom`，看到名字就想起來了。

## Pod immutable ≠ Deployment template immutable

| 操作 | 能否 edit | 原因 |
|------|-----------|------|
| `k edit pod xxx` 改 env | ✗ 被擋 | 正在跑的 Pod，spec 幾乎不可改 |
| `k edit deploy xxx` 改 template 裡的 env | ✓ 可改 | 這是藍圖，改完重建新 Pod |

同一段 YAML 結構，放在不同資源層級，可變性完全不同。

## k exec 變數展開陷阱

```bash
# ✗ 錯誤：$VAR 被本機 shell 展開，本機沒這變數就是空的
k exec pod-name -- echo $APPLICATION

# ✓ 正確：讓容器內的 shell 展開
k exec pod-name -- sh -c 'echo $APPLICATION'
```

或直接 `k exec -it pod-name -- sh` 進去再 `echo`。

## envFrom vs valueFrom.configMapKeyRef

| 寫法 | 用途 | 層級深度 |
|------|------|----------|
| `envFrom` + `configMapRef` | 把 ConfigMap 所有 key 一次灌進來當環境變數 | 淺（一層） |
| `env[].valueFrom.configMapKeyRef` | 只取 ConfigMap 的某一個 key，可自訂環境變數名稱 | 深（兩層） |

```yaml
# envFrom（全灌）
envFrom:
- configMapRef:
    name: webapp-deployment-config-map

# valueFrom（挑單一 key）
env:
- name: APPLICATION
  valueFrom:
    configMapKeyRef:
      name: webapp-deployment-config-map
      key: APPLICATION
```

## ConfigMap 名稱對不上 → CreateContainerConfigError

`configMapKeyRef.name` 要跟實際 ConfigMap 名稱完全一致，差一個字就找不到，Pod 會卡在 `CreateContainerConfigError`。

## k exec -i -t 作用

| flag | 作用 | 沒加的話 |
|------|------|----------|
| `-i` | 保持 stdin 開啟 | 無法輸入，shell 立刻結束 |
| `-t` | 分配 TTY 終端 | 沒有提示符，某些功能壞掉 |

進入互動 shell → 兩個都要加 `-it`。單條命令直接 `-- command` 就好。

## 題目說「改用 ConfigMap」時看原本結構

原本是 `env` + `value` 就改成 `valueFrom`，保持同樣的 `env` 結構。不要跳到 `envFrom`，那是換了一整套寫法。

## kubectl create deployment 沒有 --labels

很多資源有 `--labels`（namespace、configmap），但 deployment 沒有。要加 label 只能產 YAML 再改，或建完後 `kubectl label`。

## Deployment 三處 label 要一致

```yaml
metadata:
  labels:
    app: cache  # Deployment 自己的 label

spec:
  selector:
    matchLabels:
      app: cache  # 用來選 Pod

  template:
    metadata:
      labels:
        app: cache  # Pod 實際會帶的 label
```

`kubectl label deployment xxx app=cache` 只改 metadata.labels，Pod 不會有這個 label。

## 需要自訂 label 的 Deployment 用 dry-run

```bash
kubectl create deployment xxx --image=yyy --dry-run=client -o yaml > deploy.yaml
# 編輯三處 label
kubectl apply -f deploy.yaml
```

這是 CKA 最穩的做法，不會漏 selector 或 template.labels。

## -it + 一次性指令必須配 --restart=Never

沒加的話終端會卡住：容器跑完 exit → kubelet 重啟 → 又 exit → 無限循環，你的終端永遠等不到 Pod「結束」。

加了 `--restart=Never`，容器 exit 後 Pod 狀態變 `Completed`，`-it` 偵測到進程結束就釋放終端。

## CKA DNS 驗證公式

```bash
# 即時看結果
k run test --image=busybox:1.28 --restart=Never -it --rm -- nslookup <svc-name>

# 不用 -it，事後看 logs
k run test --image=busybox:1.28 --restart=Never -- nslookup <svc-name>
k logs test
```

busybox:1.28 內建 nslookup，用 Service 名稱查 DNS 是標準驗證手法。

## kubectl create deploy 設 command 用 --

```bash
k create deploy xxx --image=yyy -- sleep 3600
```

`--` 是 shell 慣例，代表「後面都不是 flag」。kubectl 把 `--` 後的內容塞進 `spec.containers[].command`。沒有 `--command` 這個 flag。

## dry-run vs k edit 選擇

| 情況 | 做法 |
|------|------|
| 只差一兩個小欄位（如 container name） | 直接 create → `k edit` |
| 要加整段結構（volumes、probes、env） | `--dry-run -o yaml` → 改檔 → apply |

改越少，越適合 `k edit`。

## cluster 內部 DNS 只在 Pod 內生效

`kubernetes.default`、`<svc>.<ns>.svc.cluster.local` 這些名稱是 CoreDNS 解析的，只有 Pod 內的 `/etc/resolv.conf` 指向 CoreDNS。

在 node 上跑 `nslookup kubernetes.default` 會走 node 的 DNS（如 8.8.8.8），查不到。題目說「from the pod」就要 `k exec`。

## k exec 單次指令不需要 -it

| 場景 | 需要 -it | 原因 |
|------|----------|------|
| `k exec <pod> -- nslookup xxx` | ✗ | 單次指令，拿輸出就走 |
| `k exec <pod> -- cat /etc/resolv.conf` | ✗ | 同上 |
| `k exec -it <pod> -- sh` | ✓ | 要開互動式 shell |

`-it` 是給互動式 shell 用的，單次執行指令裸 `k exec <pod> -- <cmd>` 就夠。

## annotations 值必須是字串

`"false"`、`"true"`、`"123"` 要加引號，不加會被 YAML 解析成 bool/number，API 收到報 `json: cannot unmarshal`。Labels 同理。

## Ingress 一條龍指令

```bash
k create ingress name --rule="/path=svc:port" --annotation="key=value"
```

⭐️`--rule` 格式很單純，常見變體就這幾種：
| 場景 | `--rule` 寫法 |
|------|---------------|
| host + path | `--rule="example.com/shop=svc:80"` |
| 只有 path | `--rule="/shop=svc:80"` |
| 只有 host | `--rule="example.com/=svc:80"` |

pathType 預設 Prefix，annotation 在指令裡不用自己加引號。比建空殼再改 YAML 快很多。

## Service 類型是層層疊加

| 類型 | 組成 |
|------|------|
| ClusterIP | 集群內部 IP |
| NodePort | ClusterIP + 每個 node 開一個 port |
| LoadBalancer | ClusterIP + NodePort + 外部 LB |

NodePort 不是取代 ClusterIP，而是在上面多開入口。唯一沒有 ClusterIP 的是 ExternalName 和 Headless。

改 Service 類型時只改 `type` 欄位，不用刪 `clusterIP` 或 `port`，原本的設定會繼續用。

如果你手動把 `clusterIP` 欄位刪掉，Kubernetes 也只會自動重新分配一個新的 ClusterIP 給你——它不會變成「沒有 ClusterIP」。

## Ingress 實戰範例

```bash
k create ingress nginx-ingress-resource \
  --rule="/shop=nginx-service:80" \
  --annotation="nginx.ingress.kubernetes.io/ssl-redirect=false"
```

## expose --port 設兩個值

`--port` 同時設定 Service 的 `port` 和 `targetPort`（未指定 `--target-port` 時）。

流量路徑：`Node:nodePort` → `Service:port` → `Pod:targetPort`

## NodePort 骨架省時技巧

`expose --type NodePort` 骨架自帶三個 port 欄位（port / targetPort / nodePort），只需 `k edit` 改 nodePort 值。比從 ClusterIP 改省好幾行。

## targetPort 自動抓 containerPort

| 情況 | targetPort 行為 |
|------|-----------------|
| Deployment 有 `containerPort` | 自動抓過來 |
| Deployment 沒寫 | 預設 = `--port` |
| 手動 `--target-port` | 以你指定為準 |

## --port 永遠自己填

Service 對外 port 沒有自動填入機制，`kubectl expose` 時是必填參數。

## expose 完驗證三 port

```bash
k get svc <name>
```

確認 PORT(S) 欄位的 port/targetPort/nodePort 都是預期值。

## Endpoints 是 Service 和 Pod 的中繼站

Service 不直接連 Pod，中間有 Endpoints 層。`Endpoints <none>` + Pod Running = selector mismatch。

```bash
k get endpoints <svc-name>
k get svc <name> -o jsonpath='{.spec.selector}'
```

## DNS timeout 診斷流程

從 Pod 的 `/etc/resolv.conf` 開始追：nameserver IP → kube-dns Service → Endpoints → CoreDNS Pod → selector vs labels。

```bash
k exec <pod> -- cat /etc/resolv.conf
k get svc -n kube-system kube-dns
k get endpoints -n kube-system kube-dns
k get po -n kube-system -l k8s-app=kube-dns --show-labels
```

## 改 selector 對齊 label 優先改 Service

Pod label 是 controller 用 template 重建時帶的，直接改 Pod label 會被覆蓋回去。改 Service selector 比較安全。

## PV/PVC 沒有 kubectl create 捷徑

只能手寫 YAML，沒有 `kubectl create pv` 或 `kubectl create pvc`。

## hostPath 不強制 nodeAffinity 但必須加

hostPath 用的是節點本機路徑，但 PV 是 cluster-level 資源。不加 nodeAffinity，Pod 可能被排到沒有該目錄的 node，掛載失敗。

| 類型 | nodeAffinity | 不寫會怎樣 |
|------|--------------|------------|
| `local` | 強制要求 | API 報錯，建不起來 |
| `hostPath` | 不強制 | 能建但埋雷，Pod 可能排錯 node |

## 官方文件找 local 範例拿 nodeAffinity 骨架

官方文件 `local` volume type 有完整 nodeAffinity 範例，直接複製後把 `local:` 改成 `hostPath:` 即可。

```yaml
spec:
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node01
  hostPath:
    path: /opt/xxx
```

## PVC selector.matchLabels 指定綁定特定 PV

題目要求 PV 加 label + PVC 用 matchLabels = 配套寫法。

```yaml
# PV
metadata:
  labels:
    tier: white

# PVC
spec:
  selector:
    matchLabels:
      tier: white
```

## PV 中的 local 與 hostPath 寫法

```yaml
# local 寫法（文件範例）
  local:
    path: /mnt/disks/ssd1

# hostPath 寫法（題目要求）
  hostPath:
    path: /opt/gold-stc-cka
```

結構位置完全一樣，都在 `spec` 底下，跟 `nodeAffinity` 同層。其餘全部照抄不動。

## StorageClass 沒有 spec 區塊

關鍵欄位都在頂層，不包在 spec 裡。

唯一必填是 `provisioner`，CKA 常見值是 `kubernetes.io/no-provisioner`（靜態 PV，不自動建 volume）。

其餘選填（`volumeBindingMode` 預設 Immediate、`reclaimPolicy` 預設 Delete）。

## volumeName 繞過 WaitForFirstConsumer

PVC 設了 `volumeName` 會直接綁定指定 PV，不等 Pod 消費。硬指定優先級高於 `volumeBindingMode`。

## YAML 布林值：看 schema 不是看語法

| 欄位類型 | schema | 寫法 |
|----------|--------|------|
| annotations / labels | `map[string]string` | `"true"`（必須字串） |
| readOnly、privileged 等 | `boolean` | `true`（裸寫） |

annotations/labels 的 value 被定義成字串，YAML 裸 `true` 會被解析成布林，API 收到型別不符會報錯。其他布林欄位本來就期望布林，裸寫正確。

## READY 欄位讀法

| 指令 | READY 意義 |
|------|------------|
| `k get po` | ready containers / total containers |
| `k get deploy` | ready replicas / desired replicas |

Pod 層看的是 container，Deployment 層看的是 Pod 副本數。init container 不算在 Pod 的 READY 裡（跑完就消失）。

`kubectl get deploy` 沒有獨立的 `DESIRED` 欄位，只有 `kubectl get rs` 才有。`READY` 欄位分母本身就是 desired replicas（等同 `spec.replicas`），不要跟 `get rs` 的表格結構搞混。

## Deployment 卡住：READY 分母是否為 0 決定排查路徑

| 情況 | 根因方向 | 檢查方式 |
|------|---------|---------|
| 分母 = 0（`0/0`） | `spec.replicas: 0` 或 `spec.paused: true` | `k describe deploy` 的 Events 一定是空的（controller 根本沒嘗試建東西），直接查 spec |
| 分母 > 0 但分子 = 0（如 `0/3`） | 正常 Pod 故障排除場景 | `k describe pod` 走 Pending/ImagePullBackOff/CreateContainerConfigError/CrashLoopBackOff/readiness probe 路徑，Events 有料 |

`spec.paused: true` 容易被誤判成 `0/0` 情境，兩者 describe 的 Events 都是空的，差異只在 `replicas` 本身是不是 0。

## readOnly 寫在 volumeMounts 不是 volumes

```yaml
spec:
  volumes:
    - name: mnt
      hostPath:
        path: /mnt
  containers:
    - volumeMounts:
        - name: mnt
          mountPath: /mnt
          readOnly: true  # 在這裡
```

`readOnly` 是 container 層級的設定，同一個 volume 可以被不同 container 以不同權限掛載。

## command 兩種寫法

| 寫法 | 意義 |
|------|------|
| `command: ["tail", "-f", "/dev/null"]` | 直接執行，參數分開傳 |
| `command: ["/bin/sh", "-c", "tail -f /dev/null"]` | 啟動 shell 解析整句 |

行為一樣，真實考試兩種都會過。KillerCoda 驗證器會硬比對 YAML 結構，題目用引號包整句時偏好 `sh -c` 形式。

## 忘記 jsonpath 語法先 -o json 看結構

先把完整 JSON 印出來，照層級拼路徑。起點固定是 `{.`，不確定 array index 用 `[*]`。

```bash
k get svc redis-service -o json
k get svc redis-service -o jsonpath='{.spec.ports[0].targetPort}'
```

## jsonpath 報 unclosed action = 字串被斷行

引號內混進換行就會報 `unclosed action`。vim 游標移到斷行處按 `J` 合併回一行。

## kubeadm upgrade patch 版本不用改 apt source list

只有 minor 版本升級（如 1.27→1.28）才需要更新 `/etc/apt/sources.list.d/kubernetes.list`。patch 版本（如 1.27.1→1.27.2）不用改，apt source list 版本沒對齊時 `apt update` 才會找不到目標版本，這時才需要回頭檢查。

## 節點升級完整 SOP 順序

| 步驟 | 指令 | 節點 |
|---|---|---|
| 1. 更新 kubeadm | `apt-get install -y kubeadm=<version>` | control-plane |
| 2. 查看版本計畫 | `kubeadm upgrade plan` | control-plane |
| 3. 套用版本 | `kubeadm upgrade apply v<version>` | control-plane |
| 4. drain 節點 | `kubectl drain <node> --ignore-daemonsets` | 任一 |
| 5. 升級 kubelet + kubectl | `apt-get install -y kubelet=<version> kubectl=<version>` | control-plane |
| 6. 重啟 kubelet | `systemctl daemon-reload && systemctl restart kubelet` | control-plane |
| 7. uncordon | `kubectl uncordon <node>` | 任一 |
| 8. 驗證 | `kubectl get nodes` | 任一 |

## 考試策略：耗時指令下完就切題

遇到會卡住終端機的操作（版本升級、drain、etcd restore），下完指令確認已經開始跑（沒有立即性錯誤）就切到下一題，之後再回來驗證，不要乾等。避免因為等待而拖垮整場時間分配。

## 三種版本指令各自代表不同東西

| 指令 | 代表版本 |
|---|---|
| `kubectl get nodes` VERSION 欄位 | kubelet 版本 |
| `kubectl version` Client Version | kubectl 版本 |
| `kubectl version` Server Version | control plane（cluster）版本 |
| `kubeadm version` | kubeadm 本身版本 |

只看 `get nodes` 版本號就當升級完成是常見誤區，`kubeadm upgrade apply` 若實際失敗，這裡不會反映出來。四個都要確認才算完整驗證升級結果。

## kubectl help 語法方括號是文件標記

`--from-env-file=[]` 的 `[]` 只是 help 文件表示「這個 flag 可以有值」的語法標記，不是要你連同括號一起打進指令。

## --from-env-file 相對路徑以 pwd 為準

現場不確定目前所在目錄時，直接用絕對路徑，避免相對路徑找不到檔案。

## --from-file vs --from-env-file key 命名邏輯完全不同

| 用法 | key 從哪來 | value 是什麼 | 產生幾組 key |
|---|---|---|---|
| `--from-env-file=file` | 檔案每行 `=` 前的字串 | 每行 `=` 後的字串 | 多組 |
| `--from-file=file` | 檔案的 basename | 整個檔案內容當一份 | 一組 |
| `--from-file=key=file` | 自訂的 `key` | 整個檔案內容當一份 | 一組（自訂 key 名） |

沒有明確指定 key 名稱、也沒有多變數線索時，`--from-file` 是較安全的預設選項；題目提到 env 格式或多變數才用 `--from-env-file`。key 命名對不上是最容易誤判的坑，跟語法錯誤是兩回事。

## YAML 值裡的孤立多餘字元只在執行期爆炸

`mountPath: /config/log.txt'` 這種值尾端多一個引號字元，YAML parser 會照單全收（合法字串），`apply`、Pod 排程、image pull 都正常，錯誤只會在容器實際執行時（如 `tail` 找不到帶引號的路徑）以 Exit Code 1 呈現。同類陷阱：`env`/`envFrom` value 多餘引號、command/args 字串多餘空白、ConfigMap key 本身帶特殊字元——都是 YAML 值層級的問題，不是邏輯層級的問題。

## 排錯時 describe 輸出的多餘字元要對照 YAML 找

`describe` 輸出裡任何「看起來不該出現的符號」，都應該直接比對原始 YAML 值有沒有誤植，而不是懷疑掛載/資源關聯邏輯錯了。

## command 已指定 -c 時，args 整段指令要放單一字串元素

`command: ['bin/sh', '-c']` 時，`-c` 後面只吃一個字串參數，所以 `args: ['tail -f /config/log.txt']` 要整串放進一個元素，不能拆成多個 array 元素，否則語意錯亂。

## kubectl 是一次性 CLI，不是 daemon

改完 `kubeconfig` 不用 restart 任何東西，`kubectl` 每次執行都是重新啟動、重新讀設定檔、送一次 request、結束就釋放。

三種運作方式對照：

| 元件 | 屬性 | 改設定後要怎麼生效 |
|---|---|---|
| `kubectl` | 一次性 CLI，執行完就死 | 不用做任何事，下一次執行自動讀新值 |
| `kubelet` | 常駐 daemon | 要 `systemctl restart kubelet` |
| static pod（如 etcd） | 由 kubelet 監控 manifest 自動重建 | 改 manifest 後 kubelet 自動偵測，不用手動 restart |

## kubectl 連線錯誤三層診斷

`kubectl get node` 連不上時，依錯誤訊息關鍵字判斷卡在哪一層，錯誤訊息本身就是答案索引：

| 錯誤訊息關鍵字 | 對應層級 | 下一步 |
|---|---|---|
| `connection refused` / `no route to host` / `dial tcp ... timeout` | 連線層（port/IP） | 檢查 config 裡 `server` 欄位的 IP、port，`kube-apiserver` 有沒有在跑 |
| `x509: certificate signed by unknown authority` / `certificate is valid for ..., not ...` | 信任層（TLS cert） | 檢查 `certificate-authority-data` |
| `Unauthorized` / `Forbidden` / `invalid client certificate` | 認證層（client auth） | 檢查 `client-certificate-data`、`client-key-data` |
| `error loading config file` / `couldn't get current server API group list` | config 本身找不到或格式壞 | 檢查 `KUBECONFIG` 環境變數、檔案路徑、YAML 格式 |

## "unable to load XXX file: no such file or directory" 通用除錯公式

kubelet 啟動失敗常見這類錯誤，路徑本身就是被寫錯的設定值（如打錯字），不要臆測路徑本來就長那樣：

```
Step 1：錯誤訊息裡的路徑，就是「該查的」設定值（可能是錯的）
Step 2：ls 該目錄，找出「實際存在的」正確檔名
Step 3：回頭改錯誤訊息指出的設定檔，把路徑值改成實際值
```

適用範圍：

| 錯誤訊息關鍵字 | 通常在哪個設定檔 |
|---|---|
| `unable to load client CA file` | `/var/lib/kubelet/config.yaml` → `authentication.x509.clientCAFile` |
| `unable to load server certificate` | 同上 → `tlsCertFile` / `tlsPrivateKeyFile` |
| `couldn't get current server API group list` / 認證相關 | `/etc/kubernetes/kubelet.conf` → `client-certificate` / `client-key` |
| `no such file or directory`（static pod 相關） | `/etc/kubernetes/manifests/*.yaml` → `volumeMounts` 或 `command` 裡的 `--xxx-file` 參數 |

不需要背標準檔名，`journalctl -u kubelet -e --no-pager` 或 `describe` 直接把錯誤訊息印出來，照上面表格對照。
