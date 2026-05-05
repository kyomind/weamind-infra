# Kubernetes Dashboard 臨時安裝紀錄

## 文件目的

這份文件記錄一次以學習為目的的 Kubernetes Dashboard 安裝與觀察流程。

重點不是把 Dashboard 當成長期方案，而是釐清下面幾件事：

1. 本機 CLI 如何透過 SSH tunnel 控制遠端 K3s cluster
2. Helm 安裝的實際作用位置在哪裡
3. Dashboard 會在 cluster 內建立哪些資源
4. 為什麼這類 browser-based in-cluster dashboard 現在比較不像主流做法
5. 之後如果要清理，該刪哪些東西

## 背景

當時目標很單純：想快速用 GUI 看遠端 Kubernetes cluster 的狀態。

當前連線前提是：

```bash
ssh -N -L 6443:127.0.0.1:6443 <control-plane-node>
```

這條 SSH tunnel 的作用是：

```text
本機 localhost:6443 -> 遠端 control plane 的 127.0.0.1:6443
```

也就是說，本機上的 kubectl 與 Helm 並不是直接打某個公開 Kubernetes API 位址，而是先經過 SSH tunnel，再到遠端 K3s API Server。

## 這次實際做了什麼

### 1. 在本機確認可以連到遠端 cluster

先用 kubectl 驗證 API 可達，例如：

```bash
kubectl get --raw=/version
kubectl get ns -o name
```

這一步的目的只是確認：

1. SSH tunnel 是通的
2. kubeconfig 指向的是正確的 cluster
3. 本機對遠端 cluster 有正常讀取權限

### 2. 在本機安裝 Helm CLI

本機原本沒有 Helm，所以先透過 Homebrew 安裝：

```bash
brew install helm
```

這一步只改到本機環境，還沒有改動遠端 cluster。

### 3. 由本機的 Helm 對遠端 cluster 安裝 Dashboard

這次不是把 Helm 裝到遠端 control plane 主機上，而是：

1. 在本機執行 Helm CLI
2. Helm 透過 kubeconfig 連到遠端 Kubernetes API Server
3. API Server 在遠端 cluster 內建立 Dashboard 相關資源

因為官方原始 chart repo 已失效，這次使用的是 archived repo：

```bash
helm repo add kubernetes-dashboard https://kubernetes-retired.github.io/dashboard/
helm repo update
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  -n kubernetes-dashboard --create-namespace
```

### 4. 建立登入用的 ServiceAccount 與管理權限

為了能進入 Dashboard UI，另外建立：

1. `admin-user` ServiceAccount
2. `admin-user` 對應的 `cluster-admin` ClusterRoleBinding

概念上等同於：

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
```

接著透過下面指令取得登入 token：

```bash
kubectl -n kubernetes-dashboard create token admin-user
```

### 5. 在本機建立暫時的 GUI 存取通道

Dashboard 並沒有被公開暴露到網際網路，而是透過本機的 `kubectl port-forward` 暫時打通：

```bash
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

之後在本機瀏覽器開：

```text
https://localhost:8443
```

整體流量路徑如下：

```text
Browser
-> localhost:8443
-> kubectl port-forward
-> localhost:6443
-> SSH tunnel
-> remote K3s API Server
-> kubernetes-dashboard-kong-proxy Service
-> Dashboard components
```

## 這次在遠端 cluster 建立了哪些資源

主要建立在 `kubernetes-dashboard` namespace：

1. `kubernetes-dashboard-api`
2. `kubernetes-dashboard-auth`
3. `kubernetes-dashboard-kong`
4. `kubernetes-dashboard-metrics-scraper`
5. `kubernetes-dashboard-web`

可用下面指令確認：

```bash
kubectl get po -n kubernetes-dashboard
```

安裝完成後，當時看到的結果如下：

```text
NAME                                                    READY   STATUS    RESTARTS   AGE
kubernetes-dashboard-api-78dddd8559-zwbsv               1/1     Running   0          23m
kubernetes-dashboard-auth-654f6b6756-gjfnn              1/1     Running   0          23m
kubernetes-dashboard-kong-9849c64bd-896l4               1/1     Running   0          23m
kubernetes-dashboard-metrics-scraper-7685fd8b77-z8fwg   1/1     Running   0          23m
kubernetes-dashboard-web-5c9f966b98-mngcx               1/1     Running   0          23m
```

另外還有：

1. `admin-user` ServiceAccount
2. `admin-user` ClusterRoleBinding

## 這件事最容易誤解的地方

### 不是把 Helm 裝進遠端 control plane

更準確的說法是：

1. Helm CLI 裝在本機
2. 本機 Helm 透過 kubeconfig 打到遠端 Kubernetes API
3. 真正被建立的是遠端 cluster 內的 Kubernetes 資源

所以這次被改動的對象分成兩類：

### 本機改動

1. 安裝 Helm CLI
2. 啟動 `kubectl port-forward`

### 遠端 cluster 改動

1. 新增 `kubernetes-dashboard` namespace
2. 新增 Dashboard Deployments、Pods、Services
3. 新增 `admin-user` ServiceAccount
4. 新增 `admin-user` ClusterRoleBinding

## 為什麼說這種做法比較像上一代方案

這次操作本身是有效的，也很適合學習，但它確實透露出一些現在比較不受歡迎的特徵：

1. 需要在 cluster 內額外部署一整套 Web UI 元件
2. 需要額外處理登入 token 與 RBAC
3. 若要長期使用，還要處理公開入口、TLS、認證方式與維護成本
4. 它偏向「在 cluster 內架一個通用 browser dashboard」，這不是現在最主流的方向

更重要的是，Kubernetes Dashboard 專案本身已在 2026-01-21 封存，進入 read-only 狀態。官方現在也已將它標示為 deprecated / unmaintained，並建議考慮 Headlamp。

所以比較精準的定位應該是：

1. 可以拿來學習與短期體驗
2. 不建議作為新的長期主力管理介面
3. 不應輕易作為公開暴露的正式入口

## 清理方式

如果只是先關掉本機 GUI 通道：

```bash
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

執行中的 terminal 直接 `Ctrl+C` 即可。

如果要完整移除 Dashboard：

```bash
helm uninstall kubernetes-dashboard -n kubernetes-dashboard
kubectl delete clusterrolebinding admin-user
kubectl delete serviceaccount admin-user -n kubernetes-dashboard
kubectl delete namespace kubernetes-dashboard
```

說明：

1. `helm uninstall` 會刪除 Helm release 管理的 Dashboard 資源
2. `clusterrolebinding admin-user` 與 `serviceaccount admin-user` 是另外建立的 RBAC 資源，也要一起清
3. 最後刪掉 `kubernetes-dashboard` namespace，讓環境回到安裝前狀態

## 對學習真正有價值的部分

這次練習最值得保留的，不是 Dashboard 本身，而是這些理解：

1. 本機 CLI 工具如何透過 SSH tunnel 控制遠端 cluster
2. Helm 的本質是用本機 CLI 對遠端 Kubernetes API 送出一組資源宣告
3. Kubernetes 資源是安裝到 cluster，不是安裝到某一台主機
4. `port-forward` 是本機暫時存取通道，不是正式對外暴露方案
5. 現代 Kubernetes 工具鏈通常更偏向 `kubectl + k9s + metrics/observability + desktop client`，而不是在 cluster 內長期維護一個通用 Dashboard

## 後續建議

如果目標是觀察狀態而不是做重型管理，較合理的方向通常是：

1. `kubectl`
2. `k9s`
3. `stern`
4. 之後補 `Prometheus + Grafana`
5. 若仍需要 GUI，優先考慮 Headlamp Desktop，而不是回頭投入 Kubernetes Dashboard
