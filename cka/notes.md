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
