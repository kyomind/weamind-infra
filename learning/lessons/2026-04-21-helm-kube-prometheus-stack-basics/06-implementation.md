# 2026-04-21 Helm Kube Prometheus Stack Basics Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 今天的主體是用 Helm 在 WeaMind 的 K3s 叢集完成 `kube-prometheus-stack` 最小安裝，並保留可複習的驗證脈絡。
- `07-implementation-note.md` 與本檔綁定，只承接本檔過程中的 implementation-specific 補充觀察。

## 今日實作主題

- 用 Helm 安裝 `kube-prometheus-stack`，先完成一版最小可工作的 observability baseline，並確認 Prometheus、Grafana 與 supporting components 已在叢集中建立。

## 今日實作順序

1. 先確認本機 Helm / kubectl 對遠端 K3s 叢集的控制鏈正常。
2. 確認 Helm repo、chart、release name、namespace 與最小安裝策略。
3. 執行 `kube-prometheus-stack` install 或 upgrade-install。
4. 驗證核心 workload 是否建立且狀態合理。
5. 若有失敗 workload，再縮圈到 `helm status`、`kubectl describe`、`events` 做最小判讀。

## 驗收訊號與回退點

### 驗收訊號

- Helm release 成功建立，且可由 `helm list` / `helm status` 觀察到。
- 叢集內可看到 `kube-prometheus-stack` 對應的核心 workload 已建立。
- 至少能辨識 Prometheus、Grafana、Prometheus Operator、Node Exporter、`kube-state-metrics` 這幾個元件的資源落點。

### 回退點

- 若本機 CLI 控制鏈不通，先回到 kubeconfig / SSH tunnel / Helm CLI 可用性，不進入 chart 問題。
- 若 Helm repo 或 chart 解析失敗，先縮回 repo add / repo update / chart 名稱與版本，不急著改 values。
- 若 release 建立但 workload 不健康，先補 Kubernetes runtime 證據，不急著把問題歸到 observability 設計層。

### Step 1

#### 這一步要驗證什麼

- 本機的 `kubectl` 與 Helm CLI 是否已能正確打到 WeaMind 的遠端 K3s 叢集，並具備今天 install 所需的最小前提。

#### 預計操作

```bash
kubectl config current-context
kubectl get ns
helm version
```

#### 實際輸出 / 操作結果

```bash
$ kubectl config current-context
default

$ kubectl get ns
NAME              STATUS   AGE
cert-manager      Active   90d
darkmind          Active   4d22h
default           Active   105d
kube-node-lease   Active   105d
kube-public       Active   105d
kube-system       Active   105d
net-test          Active   100d
weamind           Active   97d

$ helm version
version.BuildInfo{Version:"v4.1.3", GitCommit:"c94d381b03be117e7e57908edbf642104e00eb8f", GitTreeState:"clean", GoVersion:"go1.26.1", KubeClientVersion:"v1.35"}
```

#### AI 判讀與收斂

- `kubectl` 與 Helm CLI 都可正常執行，代表本機工具本身沒有缺失，今天可以進入 Helm repo / chart 這一層。
- `kubectl config current-context` 顯示 `default`，這代表目前 kubeconfig 至少有一個可用的 active context；雖然名稱不夠語意化，但它確實已經能對到正確叢集，因為後面的 namespace 列表明顯就是 WeaMind 這個 K3s 環境。
- `kubectl get ns` 看到 `weamind`、`darkmind`、`cert-manager` 等既有 namespace，這是高價值證據，表示我們現在不是打到錯的 cluster，也不是只讀到某個空環境。
- `helm version` 成功回傳 `v4.1.3`，表示 Helm CLI 已安裝可用；目前還沒看到 Helm 與 cluster 互動層的錯誤，因此下一輪可以直接檢查 repo 與 chart。
- 這一步的最小結論是：**本機到遠端 K3s 的控制鏈已成立，今天的 install 前提正常。**

#### 目前狀態

- 已完成

### Step 2

#### 這一步要驗證什麼

- 今天要用哪個 Helm repo / chart / release / namespace 組合來做最小安裝，並先確認 chart 基本資訊可正常取得。

#### 預計操作

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo kube-prometheus-stack
```

#### 實際輸出 / 操作結果

```bash
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
"prometheus-community" has been added to your repositories

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "kubernetes-dashboard" chart repository
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈

$ helm search repo kube-prometheus-stack
NAME                                       CHART VERSION APP VERSION DESCRIPTION
prometheus-community/kube-prometheus-stack 83.6.0        v0.90.1     kube-prometheus-stack collects Kubernetes manif...
```

#### AI 判讀與收斂

- `prometheus-community` repo 已成功加入並完成更新，代表 chart 來源這一層沒有阻塞，今天不需要先處理 repo 連線或索引快取問題。
- `helm search repo kube-prometheus-stack` 能查到目標 chart，表示我們現在用的 chart 名稱正確，下一輪可以直接用 `prometheus-community/kube-prometheus-stack` 做 install。
- 這裡同時拿到兩個版本訊號：`CHART VERSION` 是 Helm chart 本身的封裝版本，`APP VERSION` 則較接近上游應用堆疊版本。今天先把它當成辨識資訊即可，不需要在 W7D2 就展開 chart versioning 細節。
- 這一步的最小結論是：**repo、chart 名稱與可安裝來源都已確認，下一步可以進入真正的 release 安裝。**

#### 目前狀態

- 已完成

### Step 3

#### 這一步要驗證什麼

- 能否以最小設定成功安裝 `kube-prometheus-stack` release，且安裝流程本身沒有在 Helm 層直接失敗。

#### 預計操作

```bash
helm upgrade --install observability prometheus-community/kube-prometheus-stack \
  -n observability --create-namespace
```

#### 實際輸出 / 操作結果

```bash
$ helm upgrade --install observability prometheus-community/kube-prometheus-stack \
  -n observability --create-namespace
Release "observability" does not exist. Installing it now.
NAME: observability
LAST DEPLOYED: Tue Apr 21 11:51:27 2026
NAMESPACE: observability
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace observability get pods -l "release=observability"
```

#### AI 判讀與收斂

- 這一步已明確成功，因為 Helm 回傳的是 **`STATUS: deployed`**，而不是 `failed`、`pending-install` 或 template/render 類型錯誤。
- `NAME: observability`、`NAMESPACE: observability`、`REVISION: 1` 這三個欄位一起說明：這次 chart 已經正式成為叢集裡的一個 **release 實例**，而且目前是第一次部署。
- `DESCRIPTION: Install complete` 代表 Helm 這一層的 install 流程已經完成；接下來要看的不再是 repo / chart / release 參數，而是 **叢集裡的核心 workload 是否真的建立並健康運作**。
- `NOTES` 區塊很有價值，但今天先把它當成後續操作提示，不要被它帶去分心做 Grafana 密碼或 port-forward。W7D2 現在的主線仍是：**先驗證核心資源是否已成功建立。**
- 這一步的最小結論是：**Helm install 主線已打通，`kube-prometheus-stack` 已成功部署為 `observability` release。**

#### 目前狀態

- 已完成

### Step 4

#### 這一步要驗證什麼

- install 後，哪些核心 workload 真的起來了；若有異常，第一輪最小縮圈應該落在哪些資源。

#### 預計操作

```bash
helm status observability -n observability
kubectl get pods -n observability
kubectl get deploy,sts,ds -n observability
```

#### 實際輸出 / 操作結果

```bash
$ helm status observability -n observability
NAME: observability
NAMESPACE: observability
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete

Key resources observed from helm status:
- Alertmanager: observability-kube-prometh-alertmanager -> READY 1 / AVAILABLE True
- Prometheus: observability-kube-prometh-prometheus -> READY 1 / AVAILABLE True
- Deployment: observability-grafana -> READY 1/1
- Deployment: observability-kube-state-metrics -> READY 1/1
- Deployment: observability-kube-prometh-operator -> READY 1/1
- DaemonSet: observability-prometheus-node-exporter -> READY 3/3

$ kubectl get pods -n observability
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-observability-kube-prometh-alertmanager-0   2/2     Running   0          8m58s
observability-grafana-cbb9d6fd9-z7lg7                    3/3     Running   0          9m2s
observability-kube-prometh-operator-7bbc97b8c5-zjsjq     1/1     Running   0          9m2s
observability-kube-state-metrics-7cf68b47dc-lq7d7        1/1     Running   0          9m2s
observability-prometheus-node-exporter-7bbcf             1/1     Running   0          9m3s
observability-prometheus-node-exporter-8lmj5             1/1     Running   0          9m3s
observability-prometheus-node-exporter-xv882             1/1     Running   0          9m3s
prometheus-observability-kube-prometh-prometheus-0       2/2     Running   0          8m57s

$ kubectl get deploy,sts,ds -n observability
NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/observability-grafana                 1/1     1            1           9m3s
deployment.apps/observability-kube-prometh-operator   1/1     1            1           9m3s
deployment.apps/observability-kube-state-metrics      1/1     1            1           9m3s

NAME                                                                    READY   AGE
statefulset.apps/alertmanager-observability-kube-prometh-alertmanager   1/1     9m
statefulset.apps/prometheus-observability-kube-prometh-prometheus       1/1     8m59s

NAME                                                    DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/observability-prometheus-node-exporter   3         3         3       3            3           kubernetes.io/os=linux   9m6s
```

#### AI 判讀與收斂

- 這一步已經拿到足夠完整的成功證據，不只是 Helm 說 `deployed`，而是 Kubernetes runtime 也顯示核心 workload 已經各自落在合理的工作負載型別上，而且目前都進入 `Running` / `Ready` 狀態。
- 目前可以穩定辨識出這批核心元件的最小地圖：Grafana、`kube-state-metrics`、Prometheus Operator 走 `Deployment`；Prometheus 與 Alertmanager 走 `StatefulSet`；Node Exporter 走 `DaemonSet`。
- `DaemonSet` 的 `READY 3/3` 很有價值，因為它直接對回「每個 Linux node 一個 exporter」這個每節點型工作負載模型，也剛好呼應 W7 觀察點裡 Node Exporter 為什麼是第二個每節點型工作負載範例。
- `StatefulSet` 的 Prometheus / Alertmanager 也都已 `READY 1/1`，表示這次 install 不只把 stateless 元件拉起來，連較有狀態邊界的核心資料面元件也已正常建立。
- 這一步的最小結論是：**`kube-prometheus-stack` 的核心 workload 已成功建立並健康運作，W7D2 的最小安裝驗收已成立。**

#### 目前狀態

- 已完成
