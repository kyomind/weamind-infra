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
| `resources.requests.storage` | ⚠️ 只能擴 | 唯一可變欄位，但只能往上不能縮 |

改 accessModes 或縮容 → delete 重建。

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
