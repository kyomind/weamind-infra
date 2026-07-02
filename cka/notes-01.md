# CKA Practice Notes

整理日期：2026-05-26

## kubectl run 不需要寫 type

`kubectl run <pod-name> --image=<image>` 直接產 Pod，不用指定 type。

對比 `kubectl create <type> <name>` 需要明確指定資源類型。

`kubectl create` **沒有** `pod` 子命令，建 Pod **只能**用 `run` 或 apply YAML。

`kubectl create` 支援的常見資源類型：

- `clusterrole`、`clusterrolebinding`、`role`、`rolebinding`
- `configmap`、`secret`
- `deployment`、`job`、`cronjob`
- `service`（含 `clusterip`、`nodeport`）
- `serviceaccount`
- `ingress`
- `namespace`

## kubectl flag 語法：多值與等號

多個 env 用重複 flag：`--env=A=a --env=B=b`，不是逗號分隔。

但 `--labels` 可以逗號分隔：`--labels="app=web,env=prod"`。

規律：label/selector 類支援逗號，env 類不行（value 本身可能含逗號）。

長 flag 的 `=` 可省略：`--image=nginx` 和 `--image nginx` 都行。

例外：`--dry-run=client` 必須用 `=`，否則 `client` 會被當成下一個參數。

注意：`--env A=a` 可以，但 `--env A a` 不行。flag 和 value 之間可用空格，value 內的 `KEY=VALUE` 不能拆。

以上規則是 kubectl 通用，不限於 `run`。

## Pod YAML 最小結構

官方範例，考試時手寫 Pod 可參考：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx  # 必填欄位
    image: nginx:1.14.2  # 必填欄位
    ports:
    - containerPort: 80
```

必填：`apiVersion`、`kind`、`metadata.name`、`spec.containers[].name`、`spec.containers[].image`。

`ports` 可省略，沒有預設值。省略 = 不宣告任何 port，`containerPort` 只是**文件性質**，省略不影響容器實際監聽。

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
    - protocol: TCP  # 預設值，可省略
      port: 80
      targetPort: 9376
```

`selector` 對應 Pod label，`port` 是 Service 對外埠，`targetPort` 是 Pod 實際埠。`protocol` 預設 TCP 可省略。

## Service selector 多 label 是 AND

```yaml
selector:
  app: myapp
  tier: frontend
```

選中**同時**有 `app: myapp` 和 `tier: frontend` 的 Pod。對比 NetworkPolicy `ingress.from` 每條是 OR。

## 每題第一步：切 context

CKA 考試有多個 cluster，每題操作不同 cluster。沒切 context 就做，答案寫到錯的 cluster，整題零分。

```bash
kubectl config use-context <題目給的 context 名稱>
```

坑：題目開頭會給 context 名稱（如 `k8s-c1-H`），照貼執行，不要跳過。

## context 名稱格式

context 名稱只是字串，**沒有固定格式**。

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

**無法指定**：
- `spec.containers[].name`：預設 = Pod name，題目要求不同名時要導 YAML 改

```bash
kubectl run app-pod --image=httpd:latest --port=80 --dry-run=client -o yaml > pod.yaml
# 改 containers[].name 後 apply
```

## 加 label 的兩種方式

問題：命令式 vs 宣告式哪個好？

- 命令式：`kubectl label pod app-pod app=app-lab`，Pod 已存在時最快
  - 必須指定目標
  - 全部加用 `--all`，即 `kubectl label pod --all app=app-lab`
- 宣告式：改 YAML 的 `metadata.labels` 再 apply，多一步

⭐️最佳做法：`kubectl run` 時直接帶 `--labels`，一次到位：

```bash
kubectl run app-pod --image=httpd:latest --labels="app=app-lab"  # 留意寫法
```

⭐️好處：後續 `kubectl expose` 的 selector 會**自動對上**。

## --show-labels 是複數

`kubectl get pod --show-labels`

## kubectl expose 建 Service

```bash
kubectl expose pod app-pod --name=app-svc --port=80 --target-port=80 --type=ClusterIP
```

- `pod app-pod`：對哪個資源建 Service（也可用於 `deployment`、`replicaset`）
- `--name`：Service 名稱
- `--port`：Service 對外埠
- `--target-port`：轉進 Pod 的埠
- `--type`：ClusterIP（預設）、NodePort、LoadBalancer

⭐️selector 會自動從 Pod 的**所有** label 抓。例如 Pod 有 `run=app-pod` 和 `app=app-lab`，expose 產出的 selector 會包含兩者。

坑：題目可能只要求特定 label 當 selector，但 expose 會塞全部。骨架生完第一件事檢查 selector，多的刪掉。

## kubernetes Service 是預設的

`kubectl get svc` 會看到 `kubernetes` 這個 Service，是叢集自帶的，**指向 API Server**。不用管它。

```bash
❯ kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP   174d
```

## kubectl port-forward

```bash
kubectl port-forward pod/app-pod 8080:80
```
🐱：注意，不是 `port-forward pod app-pod`！這裡**只能**使用這種寫法。反正主要也就兩種：pod、svc

把本機 `8080` 轉到 Pod 的 `80`，可用 `curl localhost:8080` 測試。

注意：終端會被佔住，要另開 terminal 測。

也可以 forward svc 或 deploy：
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
  replicas: 3  # 預設 1，可省略
  selector:
    matchLabels:  # 重要
      app: nginx
  template:
    metadata:
      labels:  # 必須與 matchLabels 一致
        app: nginx
    spec:
      containers:
      - name: nginx  # 必要欄位
        image: nginx:1.14.2  # 必要欄位
        ports:
        - containerPort: 80
```

必填：`apiVersion: apps/v1`、`kind`、`metadata.name`、`spec.selector.matchLabels`、`spec.template`（整個 Pod spec）。

注意：`selector.matchLabels` 必須和 `template.metadata.labels` 對上，否則 apply 會報錯。`replicas` **預設 1** 可省略，`ports` 可省略。

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
- `--port`：**containerPort**，與 run pod 時的 `--port` 參數類似

這三個最常用，能覆蓋大部分簡單 Deployment 題目。

## create/run 名稱是位置參數，不是 --name

```bash
kubectl create deployment nginx-app --image=nginx   # ✓
kubectl create deployment --name nginx-app --image=nginx   # ✗ unknown flag: --name
```

`kubectl run`、`kubectl create deployment`、`kubectl create configmap` 等，名稱都是緊跟在資源類型後面的位置參數。

對比 `kubectl expose` 用 `--name` 指定 Service 名稱，因為它已經有位置參數用於**指定來源**（如 `expose pod app-pod`）。

## kubectl create configmap --from-literal

```bash
kubectl create configmap webapp-config --from-literal APPLICATION=web-app
```

ConfigMap 也能一行 create，不用寫 YAML。**多個** key-value 就**重複** `--from-literal`。

## ⭐️kubectl set env 注入 ConfigMap

```bash
kubectl set env deployment/webapp-deployment --from=configmap/webapp-config
```

`--from=configmap/...` 的 `=` 同樣可用空格代替。

一行把 ConfigMap 所有 key-value 注入現有 Deployment 的環境變數，連 `edit` 都不用開。

注意：這會改 Pod template，觸發 rolling update。

## YAML 冒號後一定要空格

```yaml
# ❌ 不合法
APPLICATION:web-app

# ✅ 正確
APPLICATION: web-app
```

沒空格會被當成**一整個字串**，不是 key-value。

## --from-literal 用 =，YAML 用 :

`--from-literal=APPLICATION=web-app` 裡，`APPLICATION=web-app` 用 `=`，但生出來的 YAML 是 `APPLICATION: web-app`。

注意這裡有兩個 `=`：第一個是 flag 語法（**可用空格代替**），第二個是 key-value 分隔（不能省）。

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

位置：`spec.containers[].resources`，與 `name`、`image`、`env` 同層。

每個 container 各自設定。

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

## resources 是 per-container

`resources` 設定的是單一 container 的資源，不是整個 Pod 或 Deployment。

- 3 replicas = 3 個 Pod，總資源消耗是 3 倍
- 1 個 Pod 有多個 container，Pod 總資源 = 所有 container 加總

## Pod immutable 欄位

Pod 一旦建立，大部分欄位不能改。可變欄位白名單：

- `spec.containers[*].image`（改了不會立刻生效，要等容器重啟，實務上很少直接改裸 Pod 的 image，都是透過 Deployment，讓 rolling update 處理）
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

## Secret 掛載為 Volume

🐱：這個掛載方式比較沒那麼直觀、好理解

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
      volumeMounts:
        - name: secret-volume  # 對應上面 volumes[].name
          readOnly: true
          mountPath: "/etc/secret-volume"  # container 內的路徑
```

- Secret 的 `data` 值是 base64 編碼
- `spec.volumes[]`：定義 volume，用 `secret.secretName` 指定來源
- `volumeMounts`：掛進 container，`mountPath` 決定路徑
- ⭐️結果：Secret **每個 key 變成一個檔案**，檔名就是 key，value 是內容（自動 base64 decode）

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

`kubectl apply -f` 會**依序建立**全部資源。

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
| `kubernetes.io/tls` | TLS 憑證，必須有 `tls.crt` 和 `tls.key` 這兩個欄位（即 `tls.crt` 和 `tls.key` 兩個 key） |
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

`env` 會**覆蓋** `envFrom` 的同名變數。用 `envFrom` 整包灌時，記得刪掉原本硬編碼的 `env`。

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

# 多來源
envFrom:
- secretRef:
    name: db-secret
- configMapRef:
    name: app-config
```

多個來源的 key 若重複，後面的會覆蓋前面的。

## YAML 冒號結尾 = 下一行要縮排

冒號結尾代表「值在下一行」，下一行必須縮排。也可以冒號後直接接值不換行：

```yaml
# 換行寫法
configMapRef:
  name: app-config

# 行內寫法（flow style）
configMapRef: { name: app-config }
```

K8s YAML 幾乎都用換行寫法。

## secretRef 是 camelCase

小寫 `s` 開頭。寫成 `SecretRef` 會報錯，YAML key 是 case-sensitive。

## envFrom vs valueFrom 選擇

| 做法 | 寫法 | 適合場景 |
|------|------|----------|
| `envFrom.secretRef` | 一行整包灌 | 全部從 Secret 來，最快 |
| `valueFrom.secretKeyRef` | 逐個指定 | 題目已有 env 列表要你改來源 |

題目沒指定就挑最快的。

## Deployment 的 template 可以改

`kubectl edit deployment` 改 `spec.template`，存檔即生效，**自動觸發 rolling update**。

這是改 Deployment 資源本身，不是直接改 Pod。Deployment controller 會**建新 Pod、砍舊 Pod**。

對比：直接 `kubectl edit pod` 改 immutable 欄位會被擋。

## Job 的 spec.template 是 immutable

Deployment 的 template 隨時可改，Job 的不行。常搞混。

## kubectl scale 改 replicas 最快

```bash
kubectl scale deployment redis-deploy -n redis-ns --replicas=3
```

改 replicas 永遠優先用 `scale`，不要進 `kubectl edit` 改數字。`scale` 比 edit 快至少 10 秒，而且不會手滑改錯其他欄位。

## 非 default namespace 的 Tab 補全

要先把 `-n <ns>` 寫在前面，才能 Tab 自動補全後面的資源名稱。

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

`metadata.labels`、`selector.matchLabels`、`template.metadata.labels` 全改最保險。

`kubectl get deployment --show-labels` 看的是頂層 label。即 `metadata.labels`。

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

大小寫錯會靜默忽略，不報錯。`maxUnavailable` ✓。

## Vim undo/redo

`u` = undo，`Ctrl+r` = redo。

## Vim 執行外部指令

`:!kubectl explain deployment.spec.strategy --recursive`

Vim 內直接執行 shell 命令看結果，按 Enter 回到編輯，不用切 tab。

## kubectl set image 改 image

```bash
kubectl set image deployment/cache-deployment redis=redis:7.2.1
```

格式是 `容器名=新image`。用在有 Pod template 的**控制器**（Deployment、DaemonSet、StatefulSet），裸 Pod 不適用。

⭐️改 Deployment 的 `spec.template` 任何欄位都會**自動觸發** rolling update，`set image` 也不例外。

因此指令改完會 rolling update，可用 `kubectl rollout status deploy/<name>` 追蹤進度。

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
| Deployment selector ≠ template labels | ✅ 會 | apply 直接噴錯 |
| image 名稱拼錯 | ❌ 不會 | Pod 變 `ImagePullBackOff` |
| Service selector 和 Pod label 不匹配 | ❌ 不會 | Service 建成但選不到 Pod |

完整驗證流程：`apply` → `get pods` → `describe pod`。

## Pending + FailedScheduling 診斷

Pod 卡 Pending 時，`kubectl describe pod` 看 Events：

- `Insufficient cpu/memory`：node 資源不夠，降 requests 或清理其他 Pod
- ⭐️`had untolerated taint(s)`：目標 node 有 taint，Pod 沒 toleration

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

## Capacity vs Allocatable

kubelet 啟動時偵測節點硬體（CPU、memory），這是 **Capacity**。

Allocatable = Capacity − 系統預留，預留包含：
- `kube-reserved`：給 kubelet、container runtime
- `system-reserved`：給 OS 核心服務
- `eviction-threshold`：記憶體低於這值時驅逐 Pod

```bash
kubectl describe node <node> | grep -A6 Allocatable
```

排程器看 Allocatable 不是 Capacity，所以 4Gi node 實際能排給 Pod 的可能只有 ~3.5Gi。

## Rolling update 資源死鎖

改 Deployment 後 apply 觸發 rolling update，新舊 Pod **共存**會暫時多佔資源。

**死鎖**情境：新 Pod 因資源不足 Pending → 舊 Pod 不會被砍（要等新 Pod Ready）→ 卡住。

解法：**手動刪除**舊 Pod 以釋放資源。

```bash
kubectl delete pod <舊-pod-name>
```

## kubectl rollout undo 回滾

```bash
kubectl rollout undo deploy/redis-deployment
```

回滾到**前一版**，不用指定 revision。回滾到特定版本用 `--to-revision=N`：

```bash
kubectl rollout undo deploy/redis-deployment --to-revision=2
```

## 工具型 image 需要 sleep infinity

`ubuntu`、`busybox`、`alpine` 這類工具型 image 沒有前景進程，**預設 entrypoint 跑完就退出**，Pod 會不斷重啟進入 CrashLoopBackOff。

```bash
kubectl run ubuntu-pod --image=ubuntu --labels=app=os --command -- sleep infinity
```

注意：`--command` 要放在 `--` 之前，`sleep infinity` 放在 `--` 之後。

## -- 結束選項解析

`--` 是 CLI 標準慣例，意思是「選項結束，後面全是位置參數」。

⭐️`--command` 只是 **boolean flag**，告訴 kubectl 要**覆蓋 entrypoint**。`--` 告訴 parser **停止解析** flag，後面的內容原封不動傳給 container。

`-- <command>` 必須放**最後**，否則後面的 kubectl flag 會被當成容器命令的一部分：

```bash
kubectl run pod --command -- sleep infinity --labels=app=os  # ✗ --labels 被當成 sleep 的參數
kubectl run pod --labels=app=os --command -- sleep infinity  # ✓
```

## metadata 可以 edit

**labels 和 annotations 屬於 metadata**，不在 Pod immutable 範圍內。Pod 建完後可以 `kubectl edit pod` 改，或用 `kubectl label` 加。

但能一步到位就不要兩步：`kubectl run --labels=key=value` 直接帶。

## Service port 不檢查後端

Service 只是**路由規則**，設定 `port: 8080` 不代表後端 container 真的有在 8080 listen。題目怎麼說就怎麼設，不要因為「感覺不合理」就自己加戲。

## expose 報 port 錯就補 --port

```bash
kubectl expose pod nginx-pod --name nginx-svc --port 80
```

`kubectl expose` 需要知道 port。它會嘗試從 Pod spec 的 `containerPort` **自動偵測**，spec 沒有就會報錯。此時要手動加 `--port` 解決。

nginx 預設 listen 80，所以常用 `--port 80`。

## --port 同時設 port 和 targetPort

| 參數 | port | targetPort |
|------|------|------------|
| `--port 80` | 80 | 80（自動跟 port 一樣）|
| `--port 80 --target-port 8080` | 80 | 8080 |

單用 `--port` 時兩者相等，要分開設就加 `--target-port`。

注意：對兩者而言，`--port` 是**必填**，單用 `--target-port` 會報錯。

`--target-port` 依附於 `--port` 存在。

## kubectl run --restart=Never 跑一次性指令

```bash
kubectl run test --image=busybox:1.28 --restart=Never -- nslookup nginx-svc
```

`--restart=Never`：指令跑完就結束，不重啟。不加的話預設 `Always`，K8s 會一直重啟容器。

`=` 可省略，`--restart Never` 也行。

## --rm 需要搭配 -it

```bash
kubectl run test --image=busybox --rm -it --restart=Never -- nslookup nginx-svc
```

`--rm` 只能用在 attached 模式，要加 `-it` 才行。否則報 "should only be used for attached containers"。

`--rm`：Pod 結束後自動刪除。不加的話跑完的 Pod 會留著變 `Completed` 狀態。

## -it 即時看輸出 vs kubectl logs

| 模式 | 行為 |
|------|------|
| 沒有 `-it` | kubectl 立刻返回，輸出存在 Pod log 裡，事後用 `kubectl logs` 撈 |
| 有 `-it` | kubectl attach 上去等，即時把 stdout 印到終端 |

想即時看一次性 Pod 輸出 → 加 `-it`；忘了加 → 用 `kubectl logs` 補撈。

## kubectl run > 重導向抓的是 kubectl stdout

```bash
kubectl run test --restart=Never -- nslookup nginx-svc > out.txt
# out.txt 內容是 "pod/test created"，不是 nslookup 結果
```

`>` 重導向捕捉的是 kubectl 本身的訊息，不是容器輸出。容器輸出要用 `kubectl logs`。

## 存一次性 Pod 輸出最穩的方式

```bash
kubectl run test --image=busybox:1.28 --restart=Never -- nslookup nginx-svc
kubectl logs test > out.txt
```

`run` 完再 `logs > file`，比 `-it > file` 穩，不會混進 attach 訊息。

## containerPort 是文件性質

`containerPort` 欄位不開 port，純粹是**宣告**，屬於**文件性質**，告訴讀 YAML 的人「這個容器用哪個 port」。

真正讓 port 打開的是**容器裡的程式本身**（如 nginx 啟動時 bind 80）。

⭐️`containerPort` 沒寫**只影響**一件事：`kubectl expose` 的**自動偵測**失敗。

## Dockerfile EXPOSE vs containerPort

| | Dockerfile EXPOSE | Pod spec containerPort |
|--|-------------------|------------------------|
| 層級 | Image 層 | K8s Pod 層 |
| 實際效果 | 不開 port，純宣告 | 不開 port，純宣告 |
| 給誰看 | docker inspect | kubectl expose 自動偵測 |

**兩者都是 metadata**，真正開 port 的是**程式本身**。

## Service targetPort 才控制流量

| 層級 | 說明 |
|------|------|
| Container 實際監聽 | **程式啟動時 bind 的 port** |
| containerPort | 文件性質宣告，不影響網路 |
| Service targetPort | 決定流量送到 Pod 的哪個 port，這才控制路由 |

⭐️Service 的 `targetPort` 設對，不管 Pod spec 有沒有 `containerPort` 都能通。

## 叢集內 DNS 格式

```
<service-name>.<namespace>.svc.cluster.local
```

例：`nginx-service-cka.default.svc.cluster.local`

在叢集內可以直接用 Service 名稱（如 `nginx-service-cka`）解析到 ClusterIP，不用打完整 FQDN。

驗證 DNS：起一個臨時 Pod 跑 `nslookup <service-name>`。

## Service DNS 短名解析規則

同 namespace 內，短名（如 `nginx-svc`）和 FQDN 等價，都能解析到 ClusterIP。

跨 namespace 至少要帶 namespace：`nginx-svc.other-ns`。

| 寫法 | 適用情境 |
|------|----------|
| `nginx-svc` | 同 namespace |
| `nginx-svc.other-ns` | 跨 namespace |
| `nginx-svc.other-ns.svc.cluster.local` | 完整 FQDN，永遠能用 |

## -it 輸出和 logs 可能有微妙差異

理論上兩者都讀容器 stdout，應該一樣。但實際可能有差異：

- `-it` 會分配 TTY，某些程式在 TTY 模式下輸出格式不同（如多一個空行）
- stdout 緩衝時機不同

考試如果要存輸出，選一種方式用到底，不要混用。`logs` 通常比較穩：讀的是已寫入的日誌檔，容器跑完才讀不怕漏；不開 TTY，程式以非互動模式跑，輸出格式比較一致。
