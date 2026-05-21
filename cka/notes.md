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
