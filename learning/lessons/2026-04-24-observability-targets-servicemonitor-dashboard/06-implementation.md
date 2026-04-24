# 2026-04-24 Observability Targets ServiceMonitor Dashboard Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 今天的主體是把已安裝好的 `kube-prometheus-stack` 往前推到 target discovery、`ServiceMonitor` / `PodMonitor` 與 Grafana 最小 dashboard 驗收。
- 實作補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 檢查 Prometheus targets 與 CRD discovery 現況，確認 WeaMind app metrics 若要接進來的最小邊界，並在中途把 release / namespace 從 `observability` 重建為 `watchmind`，降低資源命名辨識成本。

## 今日實作順序

1. 先確認 `observability` namespace 內的 Prometheus / Grafana / `ServiceMonitor` / `PodMonitor` 現況。
2. 把 Helm release 與 namespace 從 `observability` 重建為 `watchmind`。
3. 釐清目前 Prometheus 已 scrape 到哪些 targets，哪些是 cluster baseline，哪些還不是 WeaMind app metrics。
4. 對照 WeaMind `Deployment` / `Service`，判斷 app metrics 若要被 scrape 的最小接法。
5. 視現況收斂一版 Grafana 最小 dashboard 驗收結果或缺口定位。

## 驗收訊號與回退點

### 驗收訊號

- 能拿到 Prometheus 目前 target 與監控 CRD 的最小現況證據。
- 能明確區分 cluster baseline metrics 與 WeaMind app metrics 的邊界。
- 至少完成一條可 demo 的 dashboard / metrics 驗收鏈，或明確定位今天卡點。

### 回退點

- 若 Prometheus target 頁或 API 不易直接查看，先用 Kubernetes 資源層證據縮圈，不急著做 UI 操作。
- 若 `ServiceMonitor` / `PodMonitor` 資源很多，先抓結構與 selector 模式，不要求今天一次逐個讀完。
- 若 app metrics 缺口落在 repo 外的應用程式碼，先把 infra 端邊界講清楚，不硬補不存在的觀測資料。

### Step 1

#### 這一步要驗證什麼

- `observability` namespace 內目前有哪些 `ServiceMonitor`、`PodMonitor`、Prometheus 與 Grafana 資源，確認 Operator discovery 模型已經落在叢集裡的哪一層。

#### 預計操作

```bash
kubectl get prometheus,servicemonitor,podmonitor -n observability
kubectl get svc -n observability
kubectl get ingress -n observability
```

#### 實際輸出 / 操作結果

```bash
$ kubectl get prometheus,servicemonitor,podmonitor -n observability
NAME                                                                     VERSION   DESIRED   READY   RECONCILED   AVAILABLE   AGE
prometheus.monitoring.coreos.com/observability-kube-prometh-prometheus   v3.11.2   1         1       True         True        3d

NAME                                                                                      AGE
servicemonitor.monitoring.coreos.com/observability-grafana                                3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-alertmanager              3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-apiserver                 3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-coredns                   3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-kube-controller-manager   3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-kube-etcd                 3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-kube-proxy                3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-kube-scheduler            3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-kubelet                   3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-operator                  3d
servicemonitor.monitoring.coreos.com/observability-kube-prometh-prometheus                3d
servicemonitor.monitoring.coreos.com/observability-kube-state-metrics                     3d
servicemonitor.monitoring.coreos.com/observability-prometheus-node-exporter               3d

$ kubectl get svc -n observability
NAME                                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                     ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP   3d
observability-grafana                     ClusterIP   10.43.50.8      <none>        80/TCP                       3d
observability-kube-prometh-alertmanager   ClusterIP   10.43.178.92    <none>        9093/TCP,8080/TCP            3d
observability-kube-prometh-operator       ClusterIP   10.43.215.137   <none>        443/TCP                      3d
observability-kube-prometh-prometheus     ClusterIP   10.43.87.155    <none>        9090/TCP,8080/TCP            3d
observability-kube-state-metrics          ClusterIP   10.43.191.200   <none>        8080/TCP                     3d
observability-prometheus-node-exporter    ClusterIP   10.43.115.212   <none>        9100/TCP                     3d
prometheus-operated                       ClusterIP   None            <none>        9090/TCP                     3d

$ kubectl get ingress -n observability
No resources found in observability namespace.
```

#### AI 判讀與收斂

- 這一步的核心收穫不是「看到很多奇怪資源名」，而是正式確認這套 stack 已經把 **Prometheus Operator 模型** 帶進叢集了。`prometheus.monitoring.coreos.com`、`servicemonitor.monitoring.coreos.com`、`podmonitor.monitoring.coreos.com` 都不是 Kubernetes 內建資源，而是 `monitoring.coreos.com` 這組 **CRD**。它們是 Prometheus Operator 提供的 API 類型，`kube-prometheus-stack` 安裝時一起帶進來。
- 所以比較精準的說法是：這些不是「我們自己手寫的自訂 resource」，但它們確實是 **安裝 chart 後由 chart 連同 Operator 一起安裝到 cluster 的 custom resources / custom resource definitions**。今天能直接 `kubectl get prometheus,servicemonitor,podmonitor`，正是因為 cluster 裡現在已經有這些 CRD。
- `servicemonitor` 清單也很有資訊量。它顯示這套 baseline 目前主要在觀測 **cluster / control plane / observability stack 本身**，例如 apiserver、coredns、kubelet、node-exporter、grafana、prometheus、operator。這也直接說明：**目前還看不到 WeaMind app-specific metrics 已經接進來的證據。**
- `alertmanager-operated` 與 `prometheus-operated` 的 `CLUSTER-IP` 是 `None`，不是壞掉，而是它們是 **headless service**。這類 service **不分配虛擬 IP**，主要用途是讓 `StatefulSet` 類型工作負載有穩定的 DNS / peer discovery 邊界。進一步看 service YAML 也能驗證：這兩個 service 都是 `clusterIP: None`，其中 Alertmanager 還有 `publishNotReadyAddresses: true`，這正是叢集內部 peer 協調常見的做法。
- `kubectl get ingress` 這一步看到空結果，其實也有價值。動機不是假設今天一定會用 Ingress，而是快速確認 **Grafana 或 Prometheus 有沒有被 chart 預設直接對外暴露**。現在答案是**沒有**，所以若後面要進 UI，合理路徑會是 `port-forward`、kubectl proxy，或之後再自己補 ingress / auth 設計，而不是期待 namespace 內已經有現成入口。
- 這一步的最小結論是：**Step 1 已確認 observability stack 的 discovery 與 API 模型已存在，cluster baseline targets 已有骨架，但 WeaMind app metrics 尚未從這些資源清單中自然浮現。**

#### 目前狀態

- 已完成

### Step 2

#### 這一步要驗證什麼

- 目前這套 demo stack 是否能安全地從 `observability` 重建為 `watchmind`，讓 release / namespace 前綴更明顯地表達「這是我們自己建立的學習用 observability stack」。

#### 預計操作

```bash
helm uninstall observability -n observability
kubectl delete namespace observability
helm upgrade --install watchmind prometheus-community/kube-prometheus-stack \
	-n watchmind --create-namespace
kubectl get pods -n watchmind
```

#### 實際輸出 / 操作結果

```bash
$ helm uninstall observability -n observability
release "observability" uninstalled

$ kubectl delete namespace observability
namespace "observability" deleted

$ helm upgrade --install watchmind prometheus-community/kube-prometheus-stack \
	-n watchmind --create-namespace
Release "watchmind" does not exist. Installing it now.
NAME: watchmind
LAST DEPLOYED: Fri Apr 24 12:51:50 2026
NAMESPACE: watchmind
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete

$ kubectl get pods -n watchmind
NAME                                                    READY   STATUS    RESTARTS   AGE
alertmanager-watchmind-kube-prometheus-alertmanager-0   2/2     Running   0          61s
prometheus-watchmind-kube-prometheus-prometheus-0       2/2     Running   0          60s
watchmind-grafana-84bf7db899-d6jrw                      3/3     Running   0          62s
watchmind-kube-prometheus-operator-54798d77c5-vzkh2     1/1     Running   0          62s
watchmind-kube-state-metrics-7ff886b755-fkzq6           1/1     Running   0          62s
watchmind-prometheus-node-exporter-8s5pq                1/1     Running   0          63s
watchmind-prometheus-node-exporter-mff6c                1/1     Running   0          63s
watchmind-prometheus-node-exporter-vc5m4                1/1     Running   0          63s

$ kubectl get svc -n watchmind
NAME                                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                    ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP   59s
prometheus-operated                      ClusterIP   None            <none>        9090/TCP                     58s
watchmind-grafana                        ClusterIP   10.43.169.168   <none>        80/TCP                       62s
watchmind-kube-prometheus-alertmanager   ClusterIP   10.43.26.233    <none>        9093/TCP,8080/TCP            62s
watchmind-kube-prometheus-operator       ClusterIP   10.43.120.103   <none>        443/TCP                      62s
watchmind-kube-prometheus-prometheus     ClusterIP   10.43.218.178   <none>        9090/TCP,8080/TCP            62s
watchmind-kube-state-metrics             ClusterIP   10.43.192.87    <none>        8080/TCP                     62s
watchmind-prometheus-node-exporter       ClusterIP   10.43.212.189   <none>        9100/TCP                     62s
```

#### AI 判讀與收斂

- 這次重建主線是成功的，而且比預期更乾淨：舊 `observability` release 已卸載、舊 namespace 已刪除，新的 `watchmind` release 也已在新 namespace 內完成 `STATUS: deployed`。
- 這證明了一件重要的實務事：**Helm release name 與 namespace 不適合原地硬改，最省事的方式就是 uninstall + 刪 namespace + 用新名字重裝。** 對現在這種 demo baseline 來說，這樣做的成本很低，而且辨識收益很高。
- 重建後的資源名稱已經明顯更好讀。像 `watchmind-grafana`、`watchmind-kube-prometheus-prometheus`、`watchmind-kube-prometheus-operator` 這類名字，一眼就看得出 `watchmind` 是我們自己的前綴，剩下才是 chart 生成的元件名稱。
- 這一步也順手驗證了另一個重要邊界：**Prometheus Operator 的 CRD 沒有因為 uninstall 舊 release 就消失。** 也就是說，這次重建主要換掉的是 namespace 內的 workload / service / custom resource 實例，而不是整個 cluster 的 API 擴充能力。
- 重建後所有核心 Pod 都已進入 `Running`，Grafana 也從一開始短暫的 `2/3` 很快收斂成 `3/3`。這表示目前 stack 已重新回到健康狀態，可以安全進入下一步 target 驗證。
- 這一步的最小結論是：**`watchmind` 重建成功，新的命名邊界已成立，後續 Step 3 起都應以 `watchmind` namespace 與對應 service 名稱為準。**

#### 目前狀態

- 已完成

### Step 3

#### 這一步要驗證什麼

- Prometheus 目前實際 scrape 到哪些 targets，並區分這些 target 主要是 node / Kubernetes baseline，還是已經包含 WeaMind app。

#### 預計操作

```bash
kubectl port-forward -n watchmind svc/watchmind-kube-prometheus-prometheus 9090:9090
```

#### 實際輸出 / 操作結果

```bash
$ curl -s http://127.0.0.1:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, namespace: .labels.namespace, health: .health, scrapeUrl: .scrapeUrl}'
{
	"job": "watchmind-grafana",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "http://10.42.2.27:3000/metrics"
}
{
	"job": "watchmind-kube-prometheus-alertmanager",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "http://10.42.0.12:9093/metrics"
}
{
	"job": "watchmind-kube-prometheus-alertmanager",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "http://10.42.0.12:8080/metrics"
}
{
	"job": "apiserver",
	"namespace": "default",
	"health": "up",
	"scrapeUrl": "https://10.0.0.3:6443/metrics"
}
{
	"job": "coredns",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "http://10.42.0.3:9153/metrics"
}
{
	"job": "kubelet",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "https://10.0.0.3:10250/metrics"
}
{
	"job": "kubelet",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "https://10.0.0.4:10250/metrics"
}
{
	"job": "kubelet",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "https://10.0.0.5:10250/metrics"
}
{
	"job": "kubelet",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "https://10.0.0.3:10250/metrics/cadvisor"
}
{
	"job": "kubelet",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "https://10.0.0.4:10250/metrics/cadvisor"
}
{
	"job": "kubelet",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "https://10.0.0.5:10250/metrics/cadvisor"
}
{
	"job": "kubelet",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "https://10.0.0.3:10250/metrics/probes"
}
{
	"job": "kubelet",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "https://10.0.0.4:10250/metrics/probes"
}
{
	"job": "kubelet",
	"namespace": "kube-system",
	"health": "up",
	"scrapeUrl": "https://10.0.0.5:10250/metrics/probes"
}
{
	"job": "watchmind-kube-prometheus-operator",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "https://10.42.1.39:10250/metrics"
}
{
	"job": "watchmind-kube-prometheus-prometheus",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "http://10.42.1.40:9090/metrics"
}
{
	"job": "watchmind-kube-prometheus-prometheus",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "http://10.42.1.40:8080/metrics"
}
{
	"job": "kube-state-metrics",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "http://10.42.1.38:8080/metrics"
}
{
	"job": "node-exporter",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "http://10.0.0.3:9100/metrics"
}
{
	"job": "node-exporter",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "http://10.0.0.4:9100/metrics"
}
{
	"job": "node-exporter",
	"namespace": "watchmind",
	"health": "up",
	"scrapeUrl": "http://10.0.0.5:9100/metrics"
}
```

#### AI 判讀與收斂

- 這一步最重要的訊號不是 target 很多，而是 **所有 active targets 目前都是 `health: up`**。這表示 `watchmind` 這套 baseline 的 scrape 鏈路已經成立，不只是資源存在，Prometheus 也真的抓得到資料。
- 目前 targets 可以很清楚地分成兩大類。第一類是 **cluster baseline / control plane / node 層**：`apiserver`、`coredns`、`kubelet`、`node-exporter`、`kube-state-metrics`。這些就是今天 W7 baseline 已經打通的主體。第二類是 **observability stack 自己的 self-monitoring**：`watchmind-grafana`、`watchmind-kube-prometheus-alertmanager`、`watchmind-kube-prometheus-operator`、`watchmind-kube-prometheus-prometheus`。
- 這個分類直接回答了一個關鍵問題：**目前仍然看不到 WeaMind app 自己的業務 metrics target。** 也就是說，Prometheus 現在已成功監控 cluster 與 observability stack 本身，但還沒有 scrape 到 WeaMind 應用程式。
- `kubelet` 看起來很多，不代表配置壞掉。進一步看 `watchmind-kube-prometheus-kubelet` 這個 `ServiceMonitor`，可以看到它對同一批 kubelet endpoints 定義了多個 scrape path，例如 `/metrics`、`/metrics/cadvisor`、`/metrics/probes`。所以同一個 node 會出現多個 kubelet-related target，這是正常的，因為它們代表不同 metrics surface，不是單純重複抓同一份東西。
- 這一步也順手對上 W7 的 Node 3 邏輯。像 `node-exporter` 與部分 kubelet / cadvisor 指標，已經足以支撐 node CPU、memory、filesystem 這類基礎觀測盤。也就是說，**Node 3 這一側其實已經有可觀察資料來源，真正還沒接上的主要是 App 4。**
- 這一步的最小結論是：**Prometheus targets 現在已成功覆蓋 cluster baseline 與 observability stack self-monitoring，但 WeaMind app-specific metrics 尚未出現在 target 清單中；下一步應直接回 repo 驗證 app 端目前有沒有 `/metrics` 暴露與可被 `ServiceMonitor` 接上的結構。**

#### 目前狀態

- 已完成

### Step 4

#### 這一步要驗證什麼

- 以 repo 內 WeaMind `Deployment` / `Service` 為錨點，判斷 app metrics 若要被 scrape，目前缺的是 `ServiceMonitor`、`/metrics` 暴露，還是兩者都缺。

#### 預計操作

```bash
rg -n "metrics|prometheus|port:" manifests/deployment.yaml manifests/service.yaml
```

#### 實際輸出 / 操作結果

```bash
$ rg -n "metrics|prometheus|port:" manifests/deployment.yaml manifests/service.yaml
manifests/service.yaml
12:      port: 80

manifests/deployment.yaml
54:              port: http
60:              port: http
```

#### AI 判讀與收斂

- 這個輸出本身很短，但訊息很夠。它顯示在這個 infra repo 裡，WeaMind 目前只有**一般 HTTP 服務埠與 `/health` probe** 的痕跡，沒有任何明確的 `metrics`、`prometheus`、`ServiceMonitor` 或 metrics-specific port 設定。
- 更具體地說，`service.yaml` 只有一個 `http` service，把 `80` 對到 container `8000`；`deployment.yaml` 命中的兩行則只是 readiness / liveness probe 都打在 `port: http`。這代表目前 manifest 已經準備好讓 app 提供一般 HTTP 流量與健康檢查，但**還沒有在 infra 層顯式宣告 Prometheus scrape 邊界。**
- 這一步至少可以確定一件事：**`ServiceMonitor` 在這個 repo 裡是缺的。** 因為如果 WeaMind app 已經要被 `kube-prometheus-stack` scrape，正常會在 infra repo 看得到對應的 `ServiceMonitor` 或其他監控資源定義，但目前沒有。
- 但這一步也有邊界，不能講過頭。從這個 infra repo 的 grep 結果，我們**不能 100% 證明 app 程式碼一定沒有 `/metrics` endpoint**，因為 `/metrics` 可能存在於另一個 application repo 裡，而且仍可能和一般 HTTP port 共用 `8000`。只是就目前這個 repo 來看，沒有任何顯式證據顯示這條 scrape 鏈已被設計好。
- 所以更準確的結論不是「兩者都缺」的絕對判決，而是：**在 infra repo 這一側，明確缺的是 `ServiceMonitor`；至於 app 是否已暴露 `/metrics`，目前仍未被這個 repo 證明，而且從現有 manifest 也看不到任何 scrape-ready 訊號。**
- 這一步的最小結論是：**W7 的 App 4 目前沒有在 infra 端打通。下一步若要繼續收斂，就要嘛去 app repo 驗證有沒有 `/metrics` instrumentation，要嘛先在這個 repo 補 `ServiceMonitor` skeleton，明確承認它目前仍是未完成缺口。**

#### 目前狀態

- 已完成

### Step 5

#### 這一步要驗證什麼

- WeaMind app repo 是否能先在不擴大業務邏輯重構的前提下，補出 W7 demo MVP 所需的 App 4 metrics，也就是 `request / success / error / latency` 這條最小 webhook 觀測鏈。

#### 預計操作

```bash
cd /Users/kyo/Code/WeaMind
uv add prometheus-client
uv run pytest tests/test_main.py tests/line/test_webhook.py tests/line/test_metrics.py
uv run ruff check app/main.py app/line/router.py app/line/metrics.py tests/test_main.py tests/line/test_webhook.py tests/line/test_metrics.py
uv run pyright app/main.py app/line/router.py app/line/metrics.py
```

#### 實際輸出 / 操作結果

- 已新增 `prometheus-client` 依賴，並更新 `uv.lock`。
- 已在 WeaMind app 補出 `/metrics` endpoint，掛點放在 `app/main.py`。
- 已新增 `app/line/metrics.py`，集中定義 W7 的 App 4 指標與最小 event type 分類邏輯。
- 已在 router 邊界接上第一版 instrumentation：驗簽後記錄 received，背景處理區塊記錄 success / error / duration。
- 已補 `/metrics` endpoint 測試、webhook metrics 測試與基本 helper 測試，先確認整條 app-side 鏈路能跑通。
- 實際驗證結果：
	- `uv run pytest tests/test_main.py tests/line/test_webhook.py tests/line/test_metrics.py` -> `16 passed`
	- `uv run ruff check ...` -> passed
	- `uv run pyright app/main.py app/line/router.py app/line/metrics.py` -> `0 errors`

#### AI 判讀與收斂

- 這一步代表 **App 4 在 application repo 這一側已經不是缺口**。現在 WeaMind app 已具備最小可 scrape 的 `/metrics` 入口，也已把 W7 要的四個 webhook 指標實際產生出來。
- 這一版的價值在於先把 app-side observability 鏈路打通，而不是一次做完整 production metrics 設計。
- 當時的判斷是：先用 router + metrics 模組這個最小改動，把 `/metrics`、App 4 指標與測試基線建立起來，再看 review 結果決定是否要下沉記帳邊界。
- 這一步的最小結論是：**WeaMind app 端現在已能產生 App 4 metrics，接下來真正剩下的缺口已收斂到 infra 端的 `ServiceMonitor` 與 Prometheus / Grafana 驗證，而不是 application instrumentation 本身。**

#### 目前狀態

- 已完成

### Step 6

#### 這一步要驗證什麼

- 第一版 App 4 metrics 雖然已經能 demo，但 success / error / duration 的記帳邊界是否真的和 metric 名稱一致；如果不一致，應該把記帳邏輯下沉到哪一層才合理。

#### 預計操作

```bash
cd /Users/kyo/Code/WeaMind
uv run pytest
```

#### 實際輸出 / 操作結果

- WeaMind repo 經 review 後，保留了 Step 5 已建立的整體方向：
	- 仍維持 Fast ACK
	- 仍保留 `/metrics` endpoint
	- 仍保留 App 4 指標名稱
	- 仍保留最小 `event_type` 分類策略
- 但 success / error / duration 的記帳邊界被修正了。原本這三個指標是包在 router 的整包 background task 外圍，實際語意比較接近 request-level / batch-level；修正後改為下沉到 service 的逐筆 event dispatch 邊界。
- 新增 `process_webhook_events(...)` 這條處理路徑，改為逐筆 event：
	- 解析 payload
	- 找出對應 handler
	- 呼叫 handler
	- 對單一 event 記錄 success / error / duration
- `router.py` 的責任因此被收斂成：
	- 驗證 request
	- 抽出 raw payload 的最小 event types
	- 記錄 received total
	- 把背景工作委派給 `process_webhook_events(...)`
- `metrics.py` 也同步補成兩層分類：
	- raw payload 分類，給 router 在背景任務前使用
	- runtime object 分類，給 service 在逐筆 dispatch 時使用
- 驗證結果依 WeaMind repo 的最終報告為準：
	- `uv run pytest` -> `236 passed`
	- total coverage -> `94%`
	- `app/line/metrics.py` -> `98%`
	- `app/line/router.py` -> `98%`
	- `app/line/service.py` -> `88%`
	- `app/main.py` -> `100%`

#### AI 判讀與收斂

- 我認同這個後續修正，而且它修的是根本問題，不是風格偏好。第一版做法的價值在於先把 W7 的 app-side 觀測鏈路跑通；但 review 指出的語意問題也成立：metric 名稱明明寫的是 `event`，success / error / duration 卻還停在整包 request 的外圍，這會讓資料模型和名稱不一致。
- 這次最重要的進步，不是「又多改了幾個檔案」，而是把記帳邊界放到正確位置。改完後，`line_webhook_events_success_total`、`line_webhook_events_error_total`、`line_webhook_event_duration_seconds` 才真的對應單一 event，而不是整包 request 的推估值。
- 我也同意沒有把 metrics 散進每個 business handler 這個決策。把它集中在 event dispatch 邊界，比塞進 `handle_message_event()`、`handle_follow_event()` 之類的函式乾淨得多，也更符合 cross-cutting concern 的處理方式。
- 這個修正同時保住了 W7 MVP 的節奏：沒有推翻 Fast ACK、沒有重做整套路由、沒有把 observability 擴張成 production redesign，只是把原本「能 demo」的版本校正成「仍然是 MVP，但語意正確」的版本。
- 這一步的最小結論是：**Step 5 建立了可跑通的 app metrics baseline，而 Step 6 則把 success / error / duration 從 request-level 修正成 event-level，讓 W7 的 App 4 指標在語意上真正站得住。**

#### 目前狀態

- 已完成

### Step 7

#### 這一步要驗證什麼

- 今天是否已具備一版可 demo 的 Grafana 最小觀測結果；若沒有，缺口究竟是在 datasource / target / app metrics 哪一層。

#### 預計操作

```bash
kubectl port-forward -n watchmind svc/watchmind-grafana 3000:80
```

#### 實際輸出 / 操作結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始
