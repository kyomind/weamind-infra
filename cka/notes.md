# CKA Practice Notes

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
| `resourceVersion` | **所有** K8s 資源 | API server 的樂觀鎖，每次修改就遞增 |
| Revision (`rollout history`) | Deployment 專屬 | 記錄 Pod template 變更歷史，用於 rollback |

兩者無關。任何資源都可能遇到 `resourceVersion` 衝突，不是 Deployment 特有的。

## 導出 YAML 後要刪的欄位

```yaml
metadata:
  resourceVersion: "12345"  # 必刪，版本衝突的元兇
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

## Pod 可變欄位清單

| 可變欄位 | 說明 |
|----------|------|
| `spec.containers[*].image` | 最常用 |
| `spec.activeDeadlineSeconds` | 少見 |
| `metadata.labels` / `annotations` | metadata 層，不影響 spec |
| `spec.tolerations` | 只能加，不能改已有的 |

其他 spec（`command`、`args`、`resources`、`ports`、`volumeMounts`、`env`）全部不可變，改了 API server 會拒絕。

## 修改 Pod 的三種方式

| 方式 | 速度 | 適用場景 |
|------|------|----------|
| `k set image` | ⚡ 最快 | 只改 image |
| `k edit` | 🔧 快 | 改 image 或其他可變欄位 |
| export → delete → recreate | 🐢 慢 | 改不可變欄位，沒得選 |

能 `set image` 就不 `edit`，能 `edit` 就不 delete-recreate——考試省秒數。

## Pod spec 預設不可變，image 是例外

心智模型：把 Pod spec 當「幾乎凍結」，只有 `image` 是那個重要的例外。

遇到要改 Pod 時，先判斷欄位可不可變，再決定用哪種方式。

## Troubleshooting 起手式

| 資源 | 起手指令 |
|------|----------|
| Pod | `get pod` → `describe pod` → `logs` |
| Deployment | `get deploy` → `describe deploy` → `get rs -l app=xxx` |
| Service | `get svc` → `get ep`（看有沒有抓到 Pod IP）|
| Node | `get node` → `describe node` |
| 通用 | `k get events --sort-by='.lastTimestamp'` |

Deployment 問題通常是底層 Pod 或 RS 的問題，往下追。Service 不通先看 endpoints。

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

手動建 PV 時，storageClassName 只是「暗號」，不需要真的有那個 SC 物件。

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

後面逐一列出每個 node 被刷掉的原因：
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
