# CKA Practice Notes

整理日期：2026-06-16

## resourceVersion 衝突

`apply` 報 "the object has been modified; please apply your changes to the latest version and try again" = 版本號不符。

原因：導出後 apply 成功，server 端 `resourceVersion` 就從 100 變 101；你手上的 YAML 還是 100，再 apply 就衝突。

解法：
- 每次 apply 成功後重新導出
- 或直接用 `k edit`（不會有版本衝突）
- 或刪掉 `resourceVersion` 欄位再 apply

## resourceVersion vs Revision

| 概念 | 層級 | 用途 |
|------|------|------|
| `resourceVersion` | **所有** K8s 資源 | API server 的**樂觀鎖**，每次修改就遞增 |
| Revision (`rollout history`) | Deployment 專屬 | 記錄 Pod template 變更歷史，用於 rollback |

兩者無關。任何資源都可能遇到 `resourceVersion` 衝突，不是 Deployment 特有的。

## 導出 YAML 後要刪的欄位

```yaml
metadata:
  resourceVersion: "12345"  # ⭐️必刪，版本衝突的元兇
  uid: "xxx"                # 選刪，留著會被忽略
  creationTimestamp: "..."  # 選刪，留著會被忽略
  generation: 1             # 選刪，留著會被覆蓋
status:                     # 選刪，read-only
  ...
```

考試時間緊迫，只刪 `resourceVersion` 就能 apply 成功。

## ConfigMap/Secret not found 先 get 確認

Events 看到 `FailedMount: configmap "nginx-configuration" not found` 時，先確認實際存在的名稱：

```bash
k get cm
```

比對實際名稱和 Deployment 裡引用的名稱，確認是誰寫錯再改。

## 一份導出只能成功 apply 一次

導出 → 改 → apply 成功後，YAML 裡的 `resourceVersion` 就過時了。

要再改就兩條路：
1. 重新 `k get -o yaml > file.yaml` 導出
2. 直接 `k edit`（改 live 資源，不經過本地檔案）

## 刪掉 resourceVersion 再 apply

沒有 `resourceVersion` 欄位時，API server 不比對版本，直接以你的 YAML 為準覆蓋。

這招可以讓一份 YAML 重複 apply 不衝突，但要注意可能蓋掉別人的修改。

## Troubleshooting 是迴圈

```
get → describe → fix → get → ...
```

一個資源可能有多個問題，修完一個要重新 `get` 確認狀態，沒變 Running 就繼續 `describe` 找下一個錯誤，直到 `1/1 Running`。

## Init container 狀態速查

這些狀態出現在 `k get pods` 的 STATUS 欄位。

| STATUS | 意思 |
|--------|------|
| `Init:0/1` | 卡在 init container 階段（還沒跑完或跑不起來）|
| `Init:RunContainerError` | init container 執行失敗 |
| `Init:CrashLoopBackOff` | init container 反覆 crash |
| `PodInitializing` | init 跑完了，主容器正在啟動 |

Init 階段的問題一樣用 `describe` 看 Events 找原因。

## ImagePullBackOff 先查 image 拼寫

Events 看到 `Failed to pull image "xxx": not found` 時，第一反應檢查 image 名稱和 tag 有沒有 typo。

常見：`nginx:ltest`（少打 a）、`nginx:latst`（少打 e）。

## Pod image 是少數可變欄位

`spec.containers[*].image` 可以直接改，不需要 delete-recreate：

```bash
k set image pod/nginx-pod nginx-container=nginx:latest
```

或用 `k edit pod/nginx-pod` 改 image 欄位，存檔後立即生效。

## 改 image 立刻生效，不需另外 apply

`k edit` 或 `k set image` 本身就是寫入 API server。存檔瞬間 kubelet 會停掉舊 container、拉新 image、用新 image **啟動新 container**。

Pod 層級不變（IP、volume mount 維持），但 container 是重建的。

**為什麼 image 可變？** 換 image 是常見的輕量更新（patch、rollback），省掉 delete-recreate 整個 Pod 的成本。其他欄位（command、resources、ports）改了可能影響排程或資源分配，所以鎖死。

## Pod 可變欄位清單

| 可變欄位 | 說明 |
|----------|------|
| `spec.containers[*].image` | 最常用 |
| `spec.activeDeadlineSeconds` | 少見 |
| `metadata.labels` / `annotations` | metadata 層，不影響 spec |
| `spec.tolerations` | 只能**加**，不能改已有的 |

其他 spec（`command`、`args`、`resources`、`ports`、`volumeMounts`、`env`）全部不可變，改了 API server 會拒絕。

## 修改 Pod 的三種方式

| 方式 | 速度 | 適用場景 |
|------|------|----------|
| `k set image` | ⚡ 最快 | 只改 image |
| `k edit` | 🔧 快 | 改 image 或其他可變欄位 |
| export → delete → recreate | 🐢 慢 | 改不可變欄位，沒得選 |

能 `set image` 就不 `edit`，能 `edit` 就不 delete-recreate——考試省秒數。

## 多 container Pod 的 set image 語法

```bash
# 改單一 container（指定 container name）
k set image pod/my-pod nginx=nginx:1.25

# 一次改多個 container
k set image pod/my-pod nginx=nginx:1.25 sidecar=fluent-bit:2.0
```

container name 是 `spec.containers[].name` 的值，不管 Pod 有幾個 container 都要指定。不確定時先 `k get pod xxx -o yaml | grep -A2 containers` 查。

## set image 適用於所有有 Pod template 的資源

```bash
k set image deployment/nginx nginx=nginx:1.25
k set image daemonset/fluentd fluentd=fluent/fluentd:v1.16
k set image statefulset/mysql mysql=mysql:8.0
```

Deployment、DaemonSet、StatefulSet、Job、CronJob 都能用。**考試最常遇到 Deployment**；直接改 Pod 反而少見，因為大部分 Pod 都由控制器管理。

`TYPE/NAME` 和 `TYPE NAME` 等價（`deployment/nginx` = `deployment nginx`），kubectl 通用語法。

例外：`port-forward` 只能用 slash 格式，因為 `port-forward` 後面直接接 port mapping，空格格式會造成**解析歧義**。

## Troubleshooting 起手式

| 資源 | 起手指令 |
|------|----------|
| Pod | `get pod` → `describe pod` → `logs` |
| Deployment | `get deploy` → `describe deploy` → `get rs -l app=xxx` |
| Service | `get svc` → `get ep`（看有沒有抓到 Pod IP）|
| Node | `get node` → `describe node` |
| 通用 | `k get events --sort-by='.lastTimestamp'` |

Deployment 問題通常是底層 Pod 或 RS 的問題，往下追。Service 不通先看 endpoints（`ep`）；新版 EndpointSlice 縮寫是 `eps`。

## apply 報 NotFound 先看缺什麼資源

`namespaces "xxx" not found` → 建 namespace，不要改 YAML 去配合環境。

```bash
k create ns nginx-ns
```

同理適用於 SA、ConfigMap、Secret 等依賴資源——缺什麼補什麼，別改 YAML 去遷就現有環境。

## Troubleshooting 題考的是診斷速度

題目本身可能很簡單（缺個 namespace 而已），重點是快速定位問題，不是解題難度。

## Pending Pod + Pending PVC = 兩層問題

看到 Pod Pending 且引用的 PVC 也 Pending，代表問題在更底層。

依賴鏈：Pod 等 volume mount → volume 來自 PVC → PVC 等 PV 綁定。PVC 沒 Bound，Pod 就無法啟動，一定 Pending。

修復順序：先解決 PVC（讓它 Bound），再回頭修 Pod。

## PVC 正常 vs 異常狀態對照

| 欄位 | Pending（異常） | Bound（正常） |
|------|-----------------|---------------|
| STATUS | Pending | Bound |
| VOLUME | （空） | 綁定的 PV 名稱 |
| CAPACITY | （空） | PV 提供的容量 |
| ACCESS MODES | （空） | RWO / RWX / ROX |

這些欄位全空 = PVC 找不到任何符合條件的 PV 可以綁。

## PVC Pending + PV Available = 匹配條件對不上

PV 明明 Available 但 PVC 綁不上，逐一比對這三項：

1. `storageClassName` — 最常見的坑
2. `accessModes` — 必須完全一致
3. `capacity` — PV 容量必須 >= PVC 請求

找到不一致的就是問題所在。

## storageClassName 的兩種角色

| 場景 | SC 物件需要存在？ | storageClassName 的作用 |
|------|-------------------|-------------------------|
| Static provisioning（手動建 PV） | ❌ | 純字串標籤，寫 `banana` 都行，只要 PV 和 PVC 一致 |
| Dynamic provisioning（自動建 PV） | ✅ | 必須指向真實的 SC，靠 provisioner 動態建立 PV |

手動建 PV 時，storageClassName 只是「**暗號**」，不需要真的有那個 SC 物件。

## Troubleshooting 傾向改消費端

Troubleshooting 題的常見設計：基礎設施沒問題，使用端寫錯了。

- PV vs PVC 對不上 → 通常改 PVC（消費端）
- ConfigMap/Secret 名稱不符 → 通常改 Pod/Deployment 的引用

不是絕對，但機率很高。題目有提示如 "a PV has been created for you" 就更確定了。

## Troubleshooting 缺資源時哪些能直接建

**可以直接建（空殼）：** Namespace、ServiceAccount

**有內容，不能憑空建：** ConfigMap、Secret、PV

ConfigMap、Secret、PV 有複雜內容，Troubleshooting 題如果缺這些，題目會給線索（告訴你內容，或有個名字打錯的版本可以參考），不會讓你憑空生。

## Troubleshooting = 追因果鏈

每一層的 "why" 都用 `describe` 或 `get` 來回答：

```
Pod Pending
 └─ why? → PVC not found
     └─ why? → 名稱不符 + PVC 本身也 Pending
         └─ why? → storageClassName 對不上 PV
             └─ 修 PVC → Bound → 修 Pod → Running
```

一直問 why 直到找到可以動手修的根因。

## FailedScheduling 訊息解讀

`0/N nodes are available` = scheduler 的淘汰報告，N 個 node 全部不合格。

⭐️後面逐一列出每個 node 被刷掉的原因：
- `didn't match Pod's node affinity/selector` → node 缺 label
- `had untolerated taint(s)` → node 有 taint，Pod 沒對應 toleration

## FailedScheduling 後段訊息可忽略

`no new claims to deallocate` 和 `preemption: 0/N ... not helpful` 不是根因。

這兩段是說「收回 PVC 或搶佔都沒用」，專注看前面的淘汰原因就好。

## 「Don't remove specification」= 可加可改不可刪

| 動作 | 是否算 remove |
|------|---------------|
| 加 tolerations | ✅ 不算 |
| 改 node label 讓 affinity 匹配 | ✅ 不算 |
| 刪 nodeSelector / nodeAffinity | ❌ 算 remove |

題目說不能刪 spec，不代表不能改 Pod 或 Node。

## nodeSelector vs nodeAffinity

`nodeAffinity` 是 `nodeSelector` 的**超集**——`nodeSelector` 能做的，`nodeAffinity` 全都能做；反過來不行。

| | `nodeSelector` | `nodeAffinity` |
|---|----------------|----------------|
| 語法 | key-value 直接寫 | matchExpressions 表達式 |
| 匹配邏輯 | 只能 `=`（完全匹配） | `In`, `NotIn`, `Exists`, `Gt`, `Lt` |
| 硬性/軟性 | 只有硬性 | `required`（硬性）+ `preferred`（軟性）|
| 多條件 | 全部 AND | 可 OR（多個 nodeSelectorTerms）+ AND |

K8s 保留 `nodeSelector` 純粹是語法簡單，簡單場景少打字。

## nodeAffinity 完整結構

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:  # 硬性：不符合就不排
        nodeSelectorTerms:
        - matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values:
            - antarctica-east1
            - antarctica-west1
      preferredDuringSchedulingIgnoredDuringExecution:  # 軟性：盡量但不強制
      - weight: 1  # 權重 1-100
        preference:
          matchExpressions:
          - key: another-node-label-key
            operator: In
            values:
            - another-node-label-value
  containers:
  - name: with-node-affinity
    image: registry.k8s.io/pause:3.8
```

`required` 用 `nodeSelectorTerms`，`preferred` 用 `preference` + `weight`。

## preferred weight 計分機制

`weight`（1-100）是偏好分數，scheduler 對每個 node 計分，挑總分最高的。

- 每條 `preferred` 規則，node 符合就加該規則的 weight
- 多條規則累加
- 最後選總分最高的 node（前提是通過所有 `required` 條件）

```yaml
preferredDuringSchedulingIgnoredDuringExecution:
- weight: 80
  preference:
    matchExpressions:
    - key: disk
      operator: In
      values: ["ssd"]
- weight: 20
  preference:
    matchExpressions:
    - key: region
      operator: In
      values: ["us-west"]
```

| Node | disk=ssd | region=us-west | 得分 |
|------|----------|----------------|------|
| A | ✓ | ✓ | 100 |
| B | ✓ | ✗ | 80 |
| C | ✗ | ✓ | 20 |

Scheduler 優先選 A，但 A 資源不夠時 B、C 也能用——這就是「偏好」而非「硬性」。

## weight 只在多條規則時有意義

只有一條 preferred 時，weight 寫 1 還是 100 結果一樣——符合就加分、不符合就不加，沒有比較對象。

weight 的用途是表達「哪個偏好更重要」，**只有多條規則才需要**。

總分相同時，scheduler 還有其他計分因素（資源平衡、Pod 分散等）。如果最終真的完全相同，會依處理順序選，實務上接近隨機。

## nodeAffinity required 結構

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:  # 硬性
      nodeSelectorTerms:
        - matchExpressions:
            - key: NodeName
              operator: In
              values: ["frontend"]
```

`required` = 不符合就不排，`preferred` = 盡量但不強制。

## 題目出現「偏好」→ preferred

看到「偏好排到某 node」「盡量但不強制」，用 `preferredDuringSchedulingIgnoredDuringExecution`。

```yaml
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 80
    preference:
      matchExpressions:
        - key: disk
          operator: In
          values: ["ssd"]
```

## 多條件排程失敗先解決硬性條件

`required` affinity 是硬性條件，必須先滿足。

修復順序：先讓一個 node 符合硬性條件（加 label），再看剩下的問題（taint）是否自動消失。

## 查 node taint 的指令

```bash
k describe node | grep -A 3 Taints
```

- Labels → `k get nodes --show-labels`
- Taints → `describe` + `grep`，沒有 `--show-taints` flag

## controlplane 預設有 taint

`controlplane` 通常有 `node-role.kubernetes.io/control-plane:NoSchedule`。

Worker node 沒特別設的話會顯示 `Taints: <none>`。

## grep -A/-B/-C 記憶法

| flag | 意思 | 記法 |
|------|------|------|
| `-A 3` | 匹配行 + 後 3 行 | **A**fter |
| `-B 3` | 匹配行 + 前 3 行 | **B**efore |
| `-C 3` | 匹配行 + 前後各 3 行 | **C**ontext |

常用 `-A` 來撈 `describe` 輸出裡的區塊。

## grep -i 當預設習慣

`grep` 預設區分大小寫，`-i` 忽略。

不確定 `Taints` 還是 `taints` 時直接加 `-i`，零成本防呆。

## k label 語法三態

```bash
# 加 label
k label node node01 key=value

# 改 label（已存在的 key）
k label node node01 key=newvalue --overwrite

# 刪 label
k label node node01 key-
```

報 `already has a value` → 加 `--overwrite`。

## nodeAffinity required vs preferred 語法差異

```yaml
# required — 用 nodeSelectorTerms
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions: ...

# preferred — 多 weight，改用 preference
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 80
    preference:
      matchExpressions: ...
```

`preferred` 比 `required` 多一層 `weight`（1-100），且 `nodeSelectorTerms` 變成 `preference`。

## CreateContainerConfigError 常見原因

| 原因 | 說明 |
|------|------|
| ConfigMap/Secret **名稱錯誤或不存在** | 最常見，拼錯或忘記建 |
| ConfigMap/Secret 中 **key 不存在** | 引用了 `configMapKeyRef.key` 但該 key 不在裡面 |
| Secret **type 不匹配** | 例如要 TLS Secret 但缺 `tls.crt`/`tls.key` |

範圍很窄，直接鎖定 ConfigMap/Secret 問題。

## CreateContainerConfigError 只跟設定載入有關

這個錯誤只發生在「容器建立前的設定載入」階段，跟 image、scheduling、runtime 無關。

看到它，直接查 `env` / `envFrom` / `volume` 引用的 ConfigMap 和 Secret 名稱、key 是否正確。

## 根據 Pod STATUS 選診斷工具

| STATUS | 工具 |
|--------|------|
| `Pending` | `k describe pod` 看 Events（scheduling、PVC） |
| `ImagePullBackOff` | `k describe pod` 看 image 名稱拼寫 |
| `CreateContainerConfigError` | `k describe pod` 看 ConfigMap/Secret 引用 |
| `CrashLoopBackOff` | `k describe pod` + `k logs` 看應用層錯誤 |

## 修 Deployment 引用錯誤用 k edit deploy

ConfigMap/Secret 名稱寫錯時，`k edit deploy xxx` 改完存檔，Deployment 自動觸發新 Pod。

比 delete Pod 再等重建快，也不用導出 YAML。

## Probe 三種類型的核心欄位

| Probe 類型 | 核心欄位 |
|------------|----------|
| `exec` | `command`（字串列表） |
| `tcpSocket` | `port`（整數或 port name） |
| `httpGet` | `path` + `port` |

欄位名混用就 `unknown field`，例如 `tcpSocket.command` 不存在。

## k explain 基本用法

```bash
k explain pod.spec.containers.livenessProbe.tcpSocket
```

考試中即時查欄位，不需開瀏覽器。任何 YAML 路徑都能查。

## k explain --recursive

```bash
k explain pod.spec.containers.livenessProbe --recursive
```

輸出純欄位樹，沒說明文字，快速找欄位名。找到後去掉 `--recursive` 看該欄位細節。

## k explain 支援資源縮寫

```bash
k explain po.spec.containers
k explain deploy.spec.strategy
k explain svc.spec.ports
k explain pvc.spec
```

縮寫同 `k api-resources` 的 shortname。

## 常用 explain 起點

| 起點 | 用途 |
|------|------|
| `pod.spec.containers` | image、command、env、ports、probes、resources |
| `pod.spec.volumes` | emptyDir、configMap、secret、pvc |
| `pod.spec.affinity` | 親和性規則 |
| `pod.spec.tolerations` | 容忍 taint |
| `deployment.spec.strategy` | 滾動更新策略 |
| `service.spec.ports` | Service port 映射 |
| `pv.spec` / `pvc.spec` | 儲存設定 |
| `ingress.spec.rules` | Ingress 路由 |
| `networkpolicy.spec` | 網路策略 |
| `role.rules` | RBAC 權限 |

## unknown field 錯誤解讀

`strict decoding error: unknown field "xxx"` = 欄位名不存在於該層級 schema。

常見原因：欄位名拼錯（`cmd` vs `command`）或放錯位置（`tcpSocket` 下寫 `command`）。

API server 一次列出所有錯誤位置，可一次修完。

## 錯誤路徑轉 explain 路徑

錯誤訊息：`spec.containers[0].livenessProbe.tcpSocket.command`

轉換方式：去掉 `[0]`，前面加 `pod.`

```bash
k explain pod.spec.containers.livenessProbe.tcpSocket
```

從報錯到查解一條龍。

## YAML 骨架三種來源

| 方式 | 適用場景 |
|------|----------|
| `--dry-run=client -o yaml` | 能用 kubectl create/run 生的資源 |
| 文件找範例 | 整塊結構都不確定時 |
| `k explain` | 知道路徑，只忘了欄位名 |

## Pod apiVersion 是 v1

Pod 屬於 core API group，用 `v1`。

`apps/v1` 是給 Deployment、StatefulSet、DaemonSet、ReplicaSet 這類控制器。

## k explain 最強場景

「知道路徑，只忘了欄位名」——路徑短、打錯機率低。

整塊結構都不確定時，文件範例更快（可直接複製貼上）。

## 刷題 vs k explain 定位

刷題練速度：常見題型靠肌肉記憶秒殺。

k explain 守正確率：冷門欄位、邊緣語法的保險。

兩條路並行，不互斥。

## 確認資源縮寫

```bash
k api-resources | grep ingress
```

不確定縮寫能不能用時，用這指令確認 shortname。

## node 上的 taint 格式

```bash
key=value:effect
```

toleration 對應填入這三個值。例如 `nodeName=workerNode01:NoSchedule`。

## toleration operator 差異

| operator | 匹配邏輯 | 需要寫 value |
|----------|----------|--------------|
| `Equal` | key + value + effect 三者完全匹配 | ✅ 必須 |
| `Exists` | 只看 key + effect，任意 value 都過 | ❌ 不寫 |

考試沒特別要求時 `Exists` 少寫一個欄位更快。

## tolerations 位置

寫在 `spec.template.spec`（和 `containers` 同層），不是 Deployment 的 `spec` 層級。

```yaml
spec:
  template:
    spec:
      tolerations:  # 這裡
        - key: "xxx"
          ...
      containers:
        - name: ...
```

## 查 node taint

```bash
k describe node node01 | grep -i taint
```

輸出格式：`key=value:effect`。

## 查 toleration 語法

```bash
k explain pod.spec.tolerations
```

欄位多（3+ 個）時直接查文件複製範例更快，`explain` 輸出不是可複製的 YAML。

## 欄位少用 explain，欄位多查文件

| 情境 | 最快方法 |
|------|----------|
| 只需確認 1-2 個欄位名 | `k explain` |
| 需要整塊結構（3+ 欄位） | 文件複製範例 |
| 能用指令生成 | `--dry-run=client -o yaml` |

## apply 後一定要驗證

考試沒有 Check 按鈕，每題結尾自己跑 validator：

```bash
k get <resource>  # 確認狀態符合預期再走
```

KillerCoda 有 Check，考試沒有——做完看起來對不代表真的對。

## port-forward 卡住 → 查 endpoints

```bash
k get endpoints nginx-service
```

| Endpoints 狀態 | 問題所在 |
|----------------|----------|
| `<none>` | selector 沒對上 Pod label |
| 有 IP | port / targetPort 沒對上 |

port-forward 卡住 = 流量根本沒到 Pod。

## label 屬於 metadata，隨時可改

Pod 不可變的是 `spec`（運行規格），`metadata`（labels / annotations）隨時可改。

labels 是給外部系統（Service、ReplicaSet）做篩選用的「標籤」，改標籤不影響 Pod 本身的運行規格。

## selector 是 live query

Service / ReplicaSet 的 selector 是**持續監聽**的，不是建立時的一次性綁定。

label 一改，關係立刻生效——不需要重建 Service、不需要重啟任何東西。

應用：改 Pod label 可以把它從 ReplicaSet 管轄中「摘出來」單獨 debug。

## label CRUD 都用指令

```bash
# 新增 / 覆蓋
k label pod nginx-pod app=nginx
k label pod nginx-pod app=nginx-v2 --overwrite

# 刪除（key 後加減號）
k label pod nginx-pod app-
```

適用所有資源類型（Pod、Node、Namespace...）。只有「建立時順便帶」才寫在 YAML。

## kubelet 故障診斷流程

1. `systemctl status kubelet` — 沒跑就 start
2. 跑了又掛 → `journalctl -u kubelet -e` — 錯誤訊息指向哪個檔案/欄位就改哪裡
3. 改完 restart（改 systemd 檔要先 daemon-reload）

不需要背壞法，journalctl 會直接告訴你答案。

## Node NotReady → kubelet 診斷起手式

1. `systemctl status kubelet`（看是沒啟動還是反覆 crash）
2. `journalctl -u kubelet`（看錯誤訊息定位 root cause）
3. 改設定
4. `systemctl restart kubelet`（改了 systemd 檔要先 daemon-reload）
5. `k get node` 確認 Ready

## journalctl -u 參數

`-u` = `--unit`，指定只看某個 systemd unit 的日誌。

```bash
journalctl -u kubelet  # 只看 kubelet.service 的 log
```

不加 `-u` 會輸出整台機器所有服務的日誌，根本找不到東西。

## journalctl -e 跳到最新

```bash
journalctl -u kubelet -e
```

`-e` = 直接跳到日誌最底部（最新），然後可以往上捲看上下文。

考試時比 `tail` 更實用，因為跳到底之後還能往回看歷史。

## kubelet 設定檔常見位置

| 檔案 | 用途 |
|------|------|
| `/var/lib/kubelet/config.yaml` | kubelet 主設定（憑證路徑、staticPodPath、cgroupDriver 等）|
| `/etc/kubernetes/kubelet.conf` | kubeconfig（CA、server URL）|
| `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf` | systemd drop-in（啟動參數）|

`systemctl status kubelet` 的 `Drop-In` 行會顯示實際 drop-in 路徑，有些環境是 `/usr/lib/...`。

## config.yaml vs kubelet.conf

`/var/lib/kubelet/config.yaml` 管 kubelet 本身怎麼跑（cgroupDriver、staticPodPath、port、認證授權設定）。

`/etc/kubernetes/kubelet.conf` 是 kubeconfig，管 kubelet 怎麼連 API server（server URL、client cert、CA）。

簡記：`config.yaml` 管運行，`kubelet.conf` 管連線。

**CKA 常見錯誤：**

- `config.yaml`：`staticPodPath` 被改錯（control plane Pod 起不來）、憑證路徑打錯字
- `kubelet.conf`：CA 路徑錯、server URL 錯

**修法：** `journalctl -u kubelet` 會直接報哪個路徑/欄位有問題，`cat` 打開檔案找到那行改回正確值，`systemctl restart kubelet`。

## 改 systemd drop-in 後要 daemon-reload

改了 `/etc/systemd/system/kubelet.service.d/` 下的檔案後：

```bash
systemctl daemon-reload   # 讓 systemd 重讀設定
systemctl restart kubelet # 重啟服務
```

少了 `daemon-reload`，systemd 讀的還是記憶體中的舊設定，改了等於白改。

## CKA kubelet 題 = 單點故障

CKA 的 kubelet troubleshooting 題通常就一個點壞，不會太複雜：

- 沒啟動 → start
- 路徑被改錯一個字 → 改回來
- drop-in 裡 flag 被改壞 → 改回來

`journalctl` 的錯誤訊息本身就是導航，會直接告訴你哪個檔案、哪個欄位出了問題。

## journalctl log level 前綴

| 前綴 | 意義 | 要看嗎 |
|------|------|--------|
| `E` | Error | 必看 |
| `W` | Warning | 次要 |
| `I` | Info | 通常忽略 |
| `Flag ... deprecated` | 廢棄警告 | 完全忽略 |

kubelet 日誌裡只需要關注 `E` 開頭的行。

## grep "E0" 找 kubelet 錯誤

```bash
journalctl -u kubelet --no-pager | grep "E0"
```

`-p err` 只過濾 systemd priority，kubelet 自己的 `E`/`W`/`I` 是應用層 log level，要用 grep 撈。

## journalctl --no-pager 防截斷

終端機太窄時，長行會被 `>` 截斷看不到關鍵資訊。

加 `--no-pager` 直接輸出完整內容，不進 pager 模式。

## PKI 檔名慣例

| 模式 | 意義 |
|------|------|
| `ca.crt` / `ca.key` | 叢集根 CA |
| `apiserver.crt` | API server 自己的憑證 |
| `X-Y-client.crt` | X 連 Y 用的客戶端憑證 |
| `.crt` | 公鑰憑證 |
| `.key` | 私鑰 |

例：`apiserver-kubelet-client.crt` = API server 連 kubelet 用的客戶端憑證。

## ls 看實際檔名比背檔名可靠

路徑錯誤題不用硬記正確檔名，直接：

```bash
ls /etc/kubernetes/pki/
```

看實際有什麼，比對日誌裡的錯誤路徑，改成正確的就好。

## API server 預設 port = 6443

看到 `64433333` 或其他奇怪數字就是被改壞了。

正確值：`https://<IP>:6443`

## 日誌 + grep 定位問題

1. `journalctl -u kubelet --no-pager | grep "E0"` — 日誌告訴你「什麼壞了」
2. `grep "錯誤關鍵字" /var/lib/kubelet/config.yaml /etc/kubernetes/kubelet.conf` — grep 告訴你「壞在哪個檔案」
3. 打開那個檔案改正確值，restart

不用猜，讓工具告訴你答案。

## kubelet 壞了但 kubectl 還能用

這不矛盾。API server 是獨立 process，kubelet 掛了它不會馬上死（只是沒人管它了）。

所以題目可以讓你在 controlplane kubelet 壞掉的情況下用 `kubectl get node` 看到 NotReady，然後再去修 kubelet。

## kubeconfig 問題分四層

| 層級 | 常見問題 | 錯誤訊息關鍵字 |
|------|----------|----------------|
| 連線層 | port 錯、IP 錯 | `invalid port`、`connection refused`、`no route to host` |
| TLS 層 | CA cert 路徑錯、cert 被換 | `certificate signed by unknown authority`、`x509` |
| 認證層 | client cert/key 路徑錯 | `unauthorized`、`403 Forbidden` |
| Context 層 | current-context 指向錯的 cluster | 能連但操作的是錯的 cluster |

除錯順序：連得上嗎 → 信得過嗎 → 認得出嗎。

## kubectl 錯誤訊息本身就是答案

`kubectl` 連不上時，錯誤訊息會直接告訴你問題在哪：

- `invalid port` → port 被改壞
- `connection refused` → API server 沒跑或 port 錯
- `x509` / `certificate` → cert 路徑或內容不對
- `unauthorized` → client 認證資訊有問題

不用猜，照訊息查對應的 kubeconfig 欄位。

## API server manifest 也可能被改壞

kubeconfig 沒問題但 API server 連不上時，檢查 static pod manifest：

```bash
cat /etc/kubernetes/manifests/kube-apiserver.yaml
```

常見被改壞的地方：
- `--secure-port` 被改成奇怪數字
- `--etcd-servers` URL 錯
- cert flag 路徑被改

改完後 kubelet 會自動重建 API server Pod，不用手動 restart。

## static pod manifest 路徑

```
/etc/kubernetes/manifests/
```

kubeadm 叢集的控制平面組件（apiserver、controller-manager、scheduler、etcd）全部是 static pod，manifest 都放這裡。

kubelet watch 這個目錄，manifest 一改就自動重建對應 pod——不用 `kubectl apply`，不用 restart。

## etcd 三個 port

| Port | 用途 | 誰連 |
|------|------|------|
| 2379 | client | apiserver 連這個 |
| 2380 | peer | etcd 節點間通訊 |
| 2381 | metrics / health probe | kubelet probe 用 |

考試常改 2379（client port），改錯了 apiserver 就連不上 etcd。

## API server 間歇性掛 → 查 etcd

apiserver log 看到 `dial tcp 127.0.0.1:2379: connection refused` 或類似 etcd 連線錯誤，問題不在 apiserver 本身。

往下游查 etcd：
1. `crictl ps -a | grep etcd` — 看 etcd 容器狀態
2. `cat /etc/kubernetes/manifests/etcd.yaml` — 看 manifest 有沒有被改壞
3. `ss -tlnp | grep 2379` — 確認 2379 有沒有人在聽

## kubectl 斷斷續續 vs 完全不能用

| 現象 | 代表什麼 |
|------|----------|
| 斷斷續續（等幾秒能用，再等又斷）| 依賴組件在 crash loop，短暫可用窗口 |
| 完全不能用（持續 connection refused）| 依賴組件根本起不來 |

前者用 `kubectl` 還有機會看 log；後者只能靠 `crictl`。

## crictl 是 kubectl 備案

API server 掛了時 `kubectl` 沒用，改用 container runtime 層工具：

```bash
crictl ps -a | grep kube-apiserver  # 看容器狀態
crictl logs <container-id>          # 看容器 log
```

`crictl` 直接跟 containerd 溝通，不經過 API server。

## 控制平面 troubleshooting 套路

1. **manifest** — `/etc/kubernetes/manifests/` 裡的 YAML 有沒有被改壞
2. **log** — `kubectl logs` 或 `crictl logs` 看錯誤訊息
3. **依賴組件** — apiserver 依賴 etcd，controller-manager/scheduler 依賴 apiserver

一條線交叉比對：manifest 對但 log 有錯 → 查依賴組件；依賴組件正常 → 回頭細看 manifest。

## rollout status 說 success 不代表正常

```bash
k rollout status deploy xxx
# "successfully rolled out" — 但可能 replicas=0
```

`rollout status` 只檢查「現有 Pod 是否都符合最新 spec」，0 個 Pod 當然全部符合。

健康檢查永遠用 `k get deploy` 看實際數字，不要只信 rollout status。

## UP-TO-DATE = 0 的兩種原因

| 情況 | DESIRED | 代表什麼 | 怎麼修 |
|------|---------|----------|--------|
| scale 問題 | 0 | 根本沒東西要更新 | `k scale deploy --replicas=N` |
| rollout 卡住 | >0 | 有東西但更新不動 | 查 RS / Pod 為什麼起不來 |

`k get deploy` 一看 DESIRED 就知道走哪條路。

## Deployment troubleshooting 分流

```bash
k get deploy xxx
```

先看 DESIRED 欄位：
- DESIRED = 0 → scale 問題，直接 `k scale`
- DESIRED > 0 但 UP-TO-DATE = 0 → rollout 問題，往下查 `k describe deploy` → `k get rs` → `k describe pod`

先分流，再深挖。

## describe deploy 看 Replicas 行

```
Replicas: 0 desired | 0 updated | 0 total | 0 available | 0 unavailable
```

這一行直接告訴你是 scale 問題——desired=0，沒有 Pod 該被建立。

不用再查 rollout、RS、Pod，直接 `k scale` 就完事。

## Controller Manager = 內建 control loop 集合

Controller = 持續監聯 apiserver，把 current state 推向 desired state 的迴圈。

Controller manager 是單一 daemon process，裡面用 goroutine 跑多個 controller。每個 controller 只管一種資源，但全部住在同一個 process 裡共享 API server 連線。

內建例子：replication controller、endpoints controller、namespace controller、serviceaccounts controller。

## status: {} + Events 空 = controller 沒在跑

API server 接受了 spec 變更（scale 成功、apply 成功），但沒有任何下游動作發生。

核心概念：寫 spec 是 API server 的事，執行 spec 是 controller 的事。

## 判斷 controller-manager 沒跑的線索

| 檢查項目 | 現象 | 意義 |
|----------|------|------|
| `k get deploy` | 0 updated / 0 total | 根本沒嘗試建 |
| `describe deploy` | Events: `<none>` | controller 沒發出任何事件 |
| YAML `status: {}` | 完全空白 | 沒有 controller 在觀察這個資源 |
| `rollout status` | "Waiting for spec update to be observed" | 沒有 controller 回報 `observedGeneration` |

## Deployment 沒動作的鑑別診斷

| 現象 | 問題在哪 |
|------|----------|
| Pod CrashLoopBackOff | controller 有在跑，問題在容器本身 |
| Pod 卡在 Pending | controller 有建 Pod，問題在 scheduler 或資源 |
| ReplicaSet 存在但 Pod 數不對 | ReplicaSet controller |
| 連 ReplicaSet 都沒建 | Deployment controller 沒跑 → controller-manager |

## CrashLoopBackOff 選 logs 還是 describe

| 情境 | 優先用 | 原因 |
|------|--------|------|
| StartError | `describe` | 容器沒跑過，沒 log |
| 其他 crash | `logs` | 程式層錯誤，log 資訊更多 |

實務：兩個都跑一遍，別糾結順序。

## Static pod command typo 是 CKA 經典考法

常見手法是把 `/etc/kubernetes/manifests/` 裡的 command 或路徑改成 typo。

定位方式：`k describe pod -n kube-system` 看 Events，錯誤訊息會直接告訴你「哪個指令找不到」或「executable not found」——不是用眼睛掃 manifest，而是讓錯誤訊息帶你去。

改完後 kubelet 會自動重建 Pod，不用手動 restart。

## CronJob 結構

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "* * * * *"  # cron 語法
  jobTemplate:
    spec:                # Job spec
      template:
        spec:            # Pod spec
          containers:
          - name: hello
            image: busybox:1.28
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure  # Job 只能 OnFailure 或 Never
```

三層巢狀：`CronJob.spec.jobTemplate.spec.template.spec` 才是 Pod spec。

## Job spec 常見欄位

```yaml
spec:
  backoffLimit: 4             # 失敗重試次數（預設 6）
  completions: 3              # 需要成功幾次才算完成（預設 1）
  parallelism: 2              # 同時跑幾個 Pod（預設 1）
  activeDeadlineSeconds: 120  # 超時秒數
  ttlSecondsAfterFinished: 60 # 完成後多久自動刪除
  template:
    spec:
      ...
```

| 欄位 | 預設值 | 用途 |
|------|--------|------|
| `backoffLimit` | 6 | 失敗重試次數 |
| `completions` | 1 | 需要成功幾次才算完成 |
| `parallelism` | 1 | 同時跑幾個 Pod |
| `activeDeadlineSeconds` | 無 | 超時秒數 |
| `ttlSecondsAfterFinished` | 無 | 完成後多久自動刪除 |

## Job parallelism 使用場景

批次處理大量獨立任務時會用：
- 處理 queue 裡的 N 個訊息，開多個 worker 並行消化
- 處理 N 個檔案/圖片/影片轉檔
- 平行跑測試套件的不同部分

重點是「任務可以拆成獨立單位」——每個 Pod 拿一份來做，互不干擾。

`completions=10` + `parallelism=3` = 總共要成功 10 次，同時最多跑 3 個 Pod。

## CronJob 排錯三層

| 層級 | 職責 | 出問題的徵兆 |
|------|------|--------------|
| CronJob | 按 schedule 產生 Job | 沒有 Job 被建立 |
| Job | 產生 Pod、管理重試 | Job 卡在某種狀態但沒有 Pod |
| Pod | 實際執行工作 | Pod 狀態 Error / CrashLoopBackOff |

Pod 有產生就看 Pod——錯誤永遠從執行層的末端追。

## CronJob 裡目標永遠用 Service name

Pod name 不進 DNS，只有 Service name 可解析。

`curl cka-pod` ✗ → `curl cka-service` ✓

## 控制器能 edit，Pod 要重建

| 方式 | 適用情境 |
|------|----------|
| `k edit` | 資源的目標本體是 mutable（Deployment、CronJob、Service…）|
| export → delete → apply | 資源幾乎不可變（Pod）|

CronJob 跟 Deployment 一樣是控制器層級，設計上就預期你會改設定。

## metadata 永遠可變，spec 看資源類型

| 區塊 | 可變性 | 例子 |
|------|--------|------|
| `metadata` | ✓ 可變（所有資源皆如此）| labels、annotations |
| `spec`（Pod）| ✗ 幾乎不可變 | containers、volumes |
| `spec`（控制器）| ✓ 大部分可變 | Deployment、CronJob 的 template |

## Completed 是 CronJob Pod 的正常結局

`Completed` = 容器正常退出（exit 0）。CronJob Pod 本來就該跑完就結束，不像長駐服務要維持 `Running`。

正常生命週期：`Pending` → `ContainerCreating` → `Running`（極短暫）→ `Completed`

## Troubleshooting 題預設多層錯誤

修一個就回去驗證，不是一次到位：改 → `k get pod` 看狀態 → 還是錯 → 看 logs → 發現新錯誤 → 往下一層追。

每次修完都要重新驗證到 Pod 正常為止。

## CronJob 完整排錯流程

1. `k get cj,job,pod` 看全貌，判斷問題卡在哪一層
2. CronJob 有觸發、Job 有產生、Pod 狀態 Error → 問題在 Pod 執行層
3. `k logs <pod>` 看錯誤訊息 → `Could not resolve host: cka-pod`
4. 判斷：command 裡用了 Pod name，但 Pod name 不進 DNS → 改成 Service name
5. `k edit cj xxx` 改 command，存檔
6. 等下一個 Pod 產生，`k logs <new-pod>` → `Failed to connect to cka-service port 80`
7. DNS 解析成功但連不上 → 問題從應用層轉到網路層
8. `k describe svc cka-service` 或 `k get ep` → Endpoints 空
9. Endpoints 空 = selector 沒對上 Pod labels
10. `k get pod cka-pod --show-labels` → Pod 沒有 labels
11. `k label pod cka-pod app=cka-pod` 補上 label
12. `k get ep cka-service` 確認有 IP 出現
13. 等下一個 Pod 產生 → `Completed` → 完成

## CronJob 自動清理歷史 Job/Pod

- `successfulJobsHistoryLimit`：預設 3
- `failedJobsHistoryLimit`：預設 1

舊的失敗 Pod 會逐漸消失，不用手動清。

## 改 CronJob 只影響之後的 Job/Pod

`k edit cj` 改完存檔，已經存在的舊 Job 和 Pod 不會被更新。要等下一次 schedule 觸發才會用新設定。

## KillerCoda validator 是字串比對

功能對但過不了時，重讀題目用字找線索。例如 `* * * * *` 和 `*/1 * * * *` 功能相同，但 validator 可能只認其中一種寫法。

真正 CKA 考試是行為驗證，不會有這種問題。
