# CKA Practice Notes

## kubectl run 不需要寫 type

`kubectl run <pod-name> --image=<image>` 直接產 Pod，不用指定 type。
寫 `kubectl run pod mc-pod` 會讓 `pod` 變成 Pod 名稱。

對比 `kubectl create <type> <name>` 需要明確指定資源類型。

## kubectl flag 語法：多值與等號

多個 env 用重複 flag：`--env=A=a --env=B=b`，不是逗號分隔。

長 flag 的 `=` 可省略：`--image=nginx` 和 `--image nginx` 都行。

例外：`--dry-run=client` 必須用 `=`，否則 `client` 會被當成下一個參數。

注意：`--env A=a` 可以，但 `--env A a` 不行。flag 和 value 之間可用空格，value 內的 `KEY=VALUE` 不能拆。

## Pod YAML 最小結構

官方範例，考試時手寫 Pod 可參考：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
```

必填：`apiVersion`、`kind`、`metadata.name`、`spec.containers[].name`、`spec.containers[].image`。`ports` 可省略。

## Service YAML 最小結構

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app.kubernetes.io/name: MyApp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 9376
```

`selector` 對應 Pod label，`port` 是 Service 對外埠，`targetPort` 是 Pod 實際埠。`protocol` 預設 TCP 可省略。

## 每題第一步：切 context

CKA 考試有多個 cluster，每題操作不同 cluster。沒切 context 就做，答案寫到錯的 cluster，整題零分。

```bash
kubectl config use-context <題目給的 context 名稱>
```

坑：題目開頭會給 context 名稱（如 `k8s-c1-H`），照貼執行，不要跳過。

## context 名稱格式

context 名稱只是字串，沒有固定格式。

- `kubernetes-admin@kubernetes`：kubeadm 預設慣例，`user@cluster`
- `k8s-c1-H`：考試環境自訂名稱

不用解析它，照貼就好。

## kubectl run 可自動生成的欄位

```bash
kubectl run app-pod --image=httpd:latest --port=80 --dry-run=client -o yaml
```

可自動生成：
- Pod name（直接接在 `run` 後面）
- `spec.containers[].image`（`--image`）
- `spec.containers[].ports[].containerPort`（`--port`）

無法指定：
- `spec.containers[].name`：預設 = Pod name，題目要求不同名時要導 YAML 改

```bash
kubectl run app-pod --image=httpd:latest --port=80 --dry-run=client -o yaml > pod.yaml
# 改 containers[].name 後 apply
```

## 何時需要 dry-run

問題：直接 apply 不就好了？錯了會報錯。

- 單一資源（Pod、Service）：直接 apply，錯了刪掉重來很快
- 多資源 YAML（`---` 分隔）：先 `--dry-run=server`，避免前面建了、後面才報錯，造成半成品要清理

清理半成品：`kubectl delete -f pod.yaml`，不存在的資源會跳過（NotFound 不影響）。

## 加 label 的兩種方式

問題：命令式 vs 宣告式哪個好？

- 命令式：`kubectl label pod app-pod app=app-lab`，Pod 已存在時最快
  - 必須指定目標，全部加用 `--all`，即 `kubectl label pod --all app=app-lab`
- 宣告式：改 YAML 的 `metadata.labels` 再 apply，多一步

最佳做法：`kubectl run` 時直接帶 `--labels`，一次到位：

```bash
kubectl run app-pod --image=httpd:latest --labels="app=app-lab"
```

好處：後續 `kubectl expose` 的 selector 會自動對上。

## --show-labels 是複數

`kubectl get pod --show-labels`，不是 `--show-label`。

## kubectl expose 建 Service

```bash
kubectl expose pod app-pod --name=app-svc --port=80 --target-port=80 --type=ClusterIP
```

- `pod app-pod`：對哪個 Pod 建 Service
- `--name`：Service 名稱
- `--port`：Service 對外埠
- `--target-port`：轉進 Pod 的埠
- `--type`：ClusterIP（預設）、NodePort、LoadBalancer

selector 會自動從 Pod 的**所有** label 抓。例如 Pod 有 `run=app-pod` 和 `app=app-lab`，expose 產出的 selector 會包含兩者。

坑：題目可能只要求特定 label 當 selector，但 expose 會塞全部。骨架生完第一件事檢查 selector，多的刪掉。

## kubernetes Service 是預設的

`kubectl get svc` 會看到 `kubernetes` 這個 Service，是叢集自帶的，指向 API Server。不用管它。

## kubectl port-forward

```bash
kubectl port-forward pod/app-pod 8080:80
```
🐱：注意，不是 `port-forward pod app-pod`！

把本機 `8080` 轉到 Pod 的 `80`，用 `curl localhost:8080` 測試。

注意：終端會被佔住，要另開 terminal 測。

也可以 forward svc 或 deploy，省得查 Pod name：
- `kubectl port-forward svc/app-svc 8080:80`
- `kubectl port-forward deploy/app-deploy 8080:80`

## port 對應順序：本機:目標

`8080:80` = 本機 8080 → 目標 80

Docker `-p`、SSH `-L`、kubectl port-forward 都是這個順序。

## 核心操作流程

不用硬記太多命令式操作，一套流程打天下：

1. `kubectl run/create/expose --dry-run=client -o yaml > x.yaml` 生骨架
2. `vi x.yaml` 改
3. `kubectl apply -f x.yaml`

`kubectl edit` 是捷徑，改單一欄位快，但不是必須。

## kubectl edit 基本操作

```bash
kubectl edit <resource> <name>
kubectl edit svc app-svc
kubectl edit pod app-pod
```

開啟預設編輯器（通常是 vi），直接改 YAML，存檔退出即生效。

vi 速查：`/keyword` 搜尋、`dd` 刪整行、`i` 進入編輯、`Esc` 退出編輯、`:wq` 存檔離開、`:q!` 不存檔離開。

## kubectl edit vs vi 本地檔案

- `kubectl edit svc app-svc`：改 cluster 裡的 live 物件，存檔即生效，不動本地檔案
- `vi svc.yaml` + `kubectl apply -f`：改本地檔案，apply 後才生效

坑：用 `kubectl edit` 改完後，本地 YAML 檔還是舊的。如果之後又 `kubectl apply -f svc.yaml`，會把改動蓋回去。

選一條路走：要嘛全用 edit，要嘛全用本地檔案 + apply。

## port-forward 只能用 type/name 語法

大多數指令兩種寫法都行：
```bash
kubectl describe pod app-pod      # ✓ 兩個欄位
kubectl describe pod/app-pod      # ✓ 一個欄位
```

但 `port-forward` 只接受 `type/name`：
```bash
kubectl port-forward pod/app-pod 8080:80   # ✓
kubectl port-forward pod app-pod 8080:80   # ✗ pod 被當成名稱
```

坑：寫成兩個欄位會直接報錯或行為錯誤。

## logs、exec、attach 也不能 type name 分開

```bash
kubectl logs app-pod           # ✓ 直接名稱
kubectl logs pod/app-pod       # ✓ type/name
kubectl logs pod app-pod       # ✗ app-pod 被當成 container name
```

規律：「對單一資源操作」的指令（logs、exec、attach、port-forward）第一個參數就是目標，不接受 `type name` 分開。

對比 `get`、`describe`、`delete` 是 `<command> <type> <name>` 結構，兩種寫法都行。

## Deployment YAML 最小結構

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

必填：`apiVersion: apps/v1`、`kind`、`metadata.name`、`spec.selector.matchLabels`、`spec.template`（整個 Pod spec）。

注意：`selector.matchLabels` 必須和 `template.metadata.labels` 對上，否則 apply 會報錯。`replicas` 預設 1 可省略，`ports` 可省略。

## 判斷要不要產 YAML

拿到題目先看：題目要求的欄位，`kubectl create/run` 的參數能不能全覆蓋？

- 能全覆蓋 → 直接 `create`/`run`，一行搞定
- 有參數蓋不到的欄位 → `--dry-run=client -o yaml` 產骨架再改

例：`Create a deployment named nginx-app-deployment using nginx image, scale to 3`

```bash
kubectl create deployment nginx-app-deployment --image=nginx --replicas=3
```

三個欄位都有參數，直接執行，不需要繞 YAML。

## kubectl create deployment 支援的參數

```bash
kubectl create deployment <name> --image=<image> --replicas=<n> --port=<port>
```

- `--image`：container image（必填）
- `--replicas`：副本數，預設 1
- `--port`：containerPort

這三個最常用，能覆蓋大部分簡單 Deployment 題目。

## create/run 名稱是位置參數，不是 --name

```bash
kubectl create deployment nginx-app --image=nginx   # ✓
kubectl create deployment --name nginx-app --image=nginx   # ✗ unknown flag: --name
```

`kubectl run`、`kubectl create deployment`、`kubectl create configmap` 等，名稱都是緊跟在資源類型後面的位置參數。

對比 `kubectl expose` 用 `--name` 指定 Service 名稱，因為它已經有位置參數指定來源（如 `expose pod app-pod`）。

## kubectl create configmap --from-literal

```bash
kubectl create configmap webapp-config --from-literal=APPLICATION=web-app
```

ConfigMap 也能一行 create，不用寫 YAML。多個 key-value 就重複 `--from-literal`。

## kubectl set env 注入 ConfigMap

```bash
kubectl set env deployment/webapp-deployment --from=configmap/webapp-config
```

`--from=configmap/...` 的 `=` 同樣可用空格代替。

一行把 ConfigMap 所有 key-value 注入現有 Deployment 的環境變數，連 `edit` 都不用開。

## YAML 冒號後一定要空格

```yaml
# ❌ 不合法
APPLICATION:web-app

# ✅ 正確
APPLICATION: web-app
```

沒空格會被當成一整個字串，不是 key-value。

## --from-literal 用 =，YAML 用 :

`--from-literal=APPLICATION=web-app` 裡用 `=`，但生出來的 YAML 是 `APPLICATION: web-app`。

注意這裡有兩個 `=`：第一個是 flag 語法（可用空格代替），第二個是 key-value 分隔（不能省）。

```bash
--from-literal=APPLICATION=web-app   # ✓
--from-literal APPLICATION=web-app   # ✓
```

坑：手寫 YAML 時容易把 `=` 帶進去，直接報錯。能讓 kubectl 生的就別手打。

## value vs valueFrom 互斥

```yaml
# 硬寫值
env:
- name: APPLICATION
  value: web-app

# 從 ConfigMap 讀
env:
- name: APPLICATION
  valueFrom:
    configMapKeyRef:
      name: webapp-config
      key: APPLICATION
```

題目說用 ConfigMap 就要換成 `valueFrom`，不能留著 `value`，兩者互斥。

## valueFrom.configMapKeyRef 結構

三層巢狀：`valueFrom` → `configMapKeyRef` → `name` + `key`。

- `name`：ConfigMap 名稱
- `key`：ConfigMap 裡的 key

Secret 同理，換成 `secretKeyRef`。

## Pod resource requests 與 limits

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

- `requests`：保證給 container 的資源，scheduler 用來決定放哪個 node
- `limits`：container 能用的上限，超過 memory 會被 OOMKilled，超過 CPU 會被 throttle

單位：
- memory：`Mi`（mebibytes，≈ MB）、`Gi`（≈ GB），K8s 用二進位制
- cpu：`m`（millicores），`250m` = 0.25 核，`1000m` = 1 核

CPU 換算：小數和 millicores 可互換，`0.4` = `400m`，`0.5` = `500m`，`1` = `1000m`。YAML 裡兩種寫法都合法。

位置在 `spec.containers[].resources`，每個 container 各自設定。

## Pod immutable 欄位

Pod 一旦建立，大部分欄位不能改。可變欄位白名單：

- `spec.containers[*].image`
- `spec.initContainers[*].image`
- `spec.activeDeadlineSeconds`
- `spec.tolerations`（只能加，不能刪）
- `spec.terminationGracePeriodSeconds`

其餘都是 immutable，包括 resource limits/requests。`kubectl edit` 會被 API server 擋。

## 改 Pod immutable 欄位：先 delete 再 apply

```bash
kubectl get pod my-pod -o yaml > my-pod.yaml
vim my-pod.yaml   # 改目標欄位
kubectl delete pod my-pod
kubectl apply -f my-pod.yaml
```

順序不能反。Pod 還活著時 `apply` 等於「更新」，一樣會被擋。

## kubectl replace --force（參考）

```bash
kubectl get pod my-pod -o yaml | sed 's/100Mi/50Mi/' | kubectl replace --force -f -
```

一行搞定刪除重建。熟 sed 的話最快，不熟就走四步流。

## vim 搜尋跳轉

在 vim 裡按 `/keyword` 然後 Enter，直接跳到該關鍵字。

例：`/100Mi` 可以快速定位到要改的那行。大檔案必備。

## Secret 掛載為 Volume

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dotfile-secret
data:  # data 的值必須是 base64 編碼
  .secret-file: dmFsdWUtMg0KDQo=  # key 會變成檔名，value 解碼後變成檔案內容
---
apiVersion: v1
kind: Pod
metadata:
  name: secret-dotfiles-pod
spec:
  volumes:  # 先在 Pod 層級定義 volume
    - name: secret-volume  # volume 名稱，volumeMounts 要對應
      secret:
        secretName: dotfile-secret  # 指向上面的 Secret 名稱
  containers:
    - name: dotfile-test-container
      image: registry.k8s.io/busybox
      command:
        - ls
        - "-l"
        - "/etc/secret-volume"
      volumeMounts:  # container 層級掛載 volume
        - name: secret-volume  # 對應上面 volumes[].name
          readOnly: true
          mountPath: "/etc/secret-volume"  # container 內的路徑
```

- Secret 的 `data` 值是 base64 編碼
- `spec.volumes[]`：定義 volume，用 `secret.secretName` 指定來源
- `volumeMounts`：掛進 container，`mountPath` 決定路徑
- 結果：Secret 每個 key 變成一個檔案，value 是內容（自動 base64 decode）

ConfigMap 同理，把 `secret` 換成 `configMap`，`secretName` 換成 `name`。

## Secret vs ConfigMap 注入方式比較

| 方式 | 用途 | 結構 |
|------|------|------|
| `valueFrom.secretKeyRef` | 單一 key → env 變數 | `env[].valueFrom` |
| `envFrom.secretRef` | 全部 key → env 變數 | `envFrom[]` |
| `volumes[].secret` | 掛載為檔案 | `volumes[]` + `volumeMounts[]` |

ConfigMap 同理，把 `secret` 相關字眼換成 `configMap`。

## YAML 多資源分隔符

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
---
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
```

`---` 是 YAML 標準的文件分隔符，一個檔案放多個資源就這樣隔開。

`kubectl apply -f` 會依序建立全部資源。

## Secret type

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque  # 省略時預設就是 Opaque
data:
  username: YWRtaW4=
```

| type | 用途 |
|------|------|
| `Opaque` | 通用，任意 key-value（預設）|
| `kubernetes.io/tls` | TLS 憑證，必須有 `tls.crt` 和 `tls.key` |
| `kubernetes.io/dockerconfigjson` | Docker registry 認證 |
| `kubernetes.io/service-account-token` | ServiceAccount token |
| `kubernetes.io/basic-auth` | 帳密認證，`username` + `password` |

CKA 最常考 `Opaque` 和 `kubernetes.io/tls`。

## stringData vs data

題目給明文用 `stringData`，K8s 自動幫你 base64。或直接 imperative 最快：

```bash
kubectl create secret generic db-secret \
  --from-literal=DB_Host=mysql-host \
  --from-literal=DB_User=root \
  --from-literal=DB_Password=dbpassword
```

## create secret 後面要接類型

```bash
kubectl create secret generic db-secret ...  # ✓
kubectl create secret db-secret ...          # ✗ unknown flag
```

99% 的題目都是 `generic`。

## env 優先於 envFrom

`env` 會覆蓋 `envFrom` 的同名變數。用 `envFrom` 整包灌時，記得刪掉原本硬編碼的 `env`。

## envFrom 是 array

```yaml
# ✗ 少了 -
envFrom:
  secretRef:
    name: db-secret

# ✓ 正確
envFrom:
- secretRef:
    name: db-secret
```

## secretRef 是 camelCase

小寫 `s` 開頭。寫成 `SecretRef` 會報錯，YAML key 是 case-sensitive。

## envFrom vs valueFrom 選擇

| 做法 | 寫法 | 適合場景 |
|------|------|----------|
| `envFrom.secretRef` | 一行整包灌 | 全部從 Secret 來，最快 |
| `valueFrom.secretKeyRef` | 逐個指定 | 題目已有 env 列表要你改來源 |

題目沒指定就挑最快的。

## Deployment 的 template 可以改

`kubectl edit deployment` 改 `spec.template`，存檔即生效，自動觸發 rolling update。

這是改 Deployment 資源本身，不是直接改 Pod。Deployment controller 會建新 Pod、砍舊 Pod。

對比：直接 `kubectl edit pod` 改 immutable 欄位會被擋。

## Job 的 spec.template 是 immutable

Deployment 的 template 隨時可改，Job 的不行。常搞混。

## kubectl scale 改 replicas 最快

```bash
kubectl scale deployment redis-deploy -n redis-ns --replicas=3
```

改 replicas 永遠優先用 `scale`，不要進 `kubectl edit` 改數字。`scale` 比 edit 快至少 10 秒，而且不會手滑改錯其他欄位。

## 非 default namespace 的 Tab 補全

要先把 `-n <ns>` 寫在前面，才能 Tab 補全後面的資源名稱。

```bash
kubectl scale -n redis-ns deployment <Tab>  # 這樣才補得到
```

## 考試環境複製貼上是標準流程

CKA 是瀏覽器終端機，滑鼠選取題目名稱 → 複製 → 貼進終端機，不用硬背硬打長名稱。

## 資源名稱優先 Tab，補不出來當警報

Tab 補全多一層即時驗證：補不出來 = 資源不存在、namespace 錯、類型錯，還沒執行就知道有問題。

複製貼上沒這層保護，錯了要等指令跑完才報錯。

考試環境是瀏覽器終端機，名稱太長或 Tab 補不出來時再切滑鼠複製。

## kubectl create deployment 的 label 限制

自動產生的 label 是 `app=<deployment-name>`，題目要不同 label 必須改 YAML。

## 題目說 label 沒指定位置，三個全改

`metadata.labels`、`selector.matchLabels`、`template.metadata.labels` 全改最保險。閱卷用 `kubectl get deployment --show-labels` 看的是頂層 label。

## kubectl explain --recursive 查結構

```bash
kubectl explain deployment.spec.strategy --recursive
```

考試即時文件。`--recursive` 一次展開所有子層級，只顯示欄位名和型別，不帶說明。

解讀輸出：
- 縮排 = YAML 層級，照著寫就對
- `FIELDS:` = 該物件底下有哪些欄位
- `<IntOrString>` = 可填數字或百分比字串
- `enum: A, B` = 這個欄位只能填 A 或 B

用來看結構，不拿來複製貼上——手打比修格式快。

## maxSurge/maxUnavailable 是 camelCase

大小寫錯會靜默忽略，不報錯。`MaxUnavailable` ✗，`maxUnavailable` ✓。

## Vim undo/redo

`u` = undo，`Ctrl+r` = redo。

## Vim 執行外部指令

`:!kubectl explain deployment.spec.strategy --recursive`

Vim 內直接執行 shell 命令看結果，按 Enter 回到編輯，不用切 tab。

## kubectl set image 改 image

```bash
kubectl set image deployment/cache-deployment redis=redis:7.2.1
```

格式是 `容器名=新image`。用在有 Pod template 的控制器（Deployment、DaemonSet、StatefulSet），裸 Pod 不適用。

## kubectl rollout history 看版本歷史

```bash
kubectl rollout history deployment/cache-deployment
```

輸出幾行 REVISION，total revision count 就是幾。

## --revision=N 查歷史版本詳情

```bash
kubectl rollout history deploy/video-app --revision=3
```

不帶參數只列版號，加 `--revision=N` 才顯示該版本的 image 等詳細資訊。

坑：`kubectl get deploy -o yaml` 只能看當前 live spec，查不到歷史版本。題目問過去某版的 image，必須用 `--revision`。

## requests > limits 是規格違規

`kubectl apply` 直接報錯，不用等 Pod 建出來。看到 requests 比 limits 大就對調或調小 requests。

## apply 只擋規格錯，語意錯要靠 describe

| 錯誤類型 | apply 會報錯？ | 怎麼抓 |
|----------|----------------|--------|
| requests > limits | ✅ 會 | apply 直接噴錯 |
| YAML 語法錯誤 | ✅ 會 | apply 直接噴錯 |
| image 名稱拼錯 | ❌ 不會 | Pod 變 `ImagePullBackOff` |
| label selector 不匹配 | ❌ 不會 | Pod 可能不被管理 |

完整驗證流程：`apply` → `get pods` → `describe pod`。

## Pending + FailedScheduling 診斷

Pod 卡 Pending 時，`kubectl describe pod` 看 Events：

- `Insufficient cpu/memory`：node 資源不夠，降 requests 或清理其他 Pod
- `had untolerated taint(s)`：目標 node 有 taint，Pod 沒 toleration

Events 的 Message 會直接告訴你是哪個原因。

## describe node 看剩餘資源

```bash
kubectl describe node <node-name>
```

看 `Allocated resources` 區段：

```
Resource   Requests    Limits
cpu        600m (60%)  6 (600%)
memory     110Mi (6%)  2024Mi (112%)
```

剩餘可排程 = Allocatable - Allocated。百分比 60% 表示已用 60%，還剩 40%。

排程問題不要猜數字，算完再改 requests。

## Rolling update 資源死鎖

改 Deployment 後 apply 觸發 rolling update，新舊 Pod 共存會暫時多佔資源。

死鎖情境：新 Pod 因資源不足 Pending → 舊 Pod 不會被砍（要等新 Pod Ready）→ 卡住。

解法：手動刪舊 Pod 釋放資源。

```bash
kubectl delete pod <舊-pod-name>
```

## kubectl rollout undo 回滾

```bash
kubectl rollout undo deploy/redis-deployment
```

回滾到前一版，不用指定 revision。回滾到特定版本用 `--to-revision=N`：

```bash
kubectl rollout undo deploy/redis-deployment --to-revision=2
```

## 工具型 image 需要 sleep infinity

`ubuntu`、`busybox`、`alpine` 這類工具型 image 沒有前景進程，預設 entrypoint 跑完就退出，Pod 會不斷重啟進入 CrashLoopBackOff。

```bash
kubectl run ubuntu-pod --image=ubuntu --labels=app=os --command -- sleep infinity
```

注意：`--command` 要放在 `--` 之前，`sleep infinity` 放在 `--` 之後。

## -- 結束選項解析

`--` 是 CLI 標準慣例，意思是「選項結束，後面全是位置參數」。

`--command` 只是 boolean flag，告訴 kubectl 要覆蓋 entrypoint。`--` 告訴 parser 停止解析 flag，後面的內容原封不動傳給 container。

`-- <command>` 必須放最後，否則後面的 kubectl flag 會被當成容器命令的一部分：

```bash
kubectl run pod --command -- sleep infinity --labels=app=os  # ✗ --labels 被當成 sleep 的參數
kubectl run pod --labels=app=os --command -- sleep infinity  # ✓
```

## metadata 可以 edit

labels 和 annotations 屬於 metadata，不在 Pod immutable 範圍內。Pod 建完後可以 `kubectl edit pod` 改，或用 `kubectl label` 加。

但能一步到位就不要兩步：`kubectl run --labels=key=value` 直接帶。

## Service port 不檢查後端

Service 只是路由規則，設定 `port: 8080` 不代表後端 container 真的有在 8080 listen。題目怎麼說就怎麼設，不要因為「感覺不合理」就自己加戲。
