# Lesson 複習筆記

## Helm 的 chart、release、values 各是什麼

- Chart：打包好的 Kubernetes 資源模板集合，類似 apt 的 .deb 或 npm 的 package
- Release：chart 安裝到 cluster 後產生的實例；同一個 chart 可以裝多次，每次都是獨立的 release，有自己的名字和版本歷史
- Values：安裝時傳入的參數，用來客製化 chart 行為；chart 提供預設值，用 `-f values.yaml` 或 `--set` 覆寫

一句話記法：chart 是模板，values 是參數，release 是模板 + 參數部署後的實例。

## kube-prometheus-stack 的主要元件

| 元件 | 角色 | workload 類型 |
|------|------|---------------|
| Prometheus | 抓 metrics、存 time series | StatefulSet |
| Alertmanager | 告警路由與通知 | StatefulSet |
| Grafana | 視覺化 dashboard | Deployment |
| Node Exporter | 抓節點層級 metrics | DaemonSet |
| kube-state-metrics | 把 K8s object 狀態轉成 metrics | Deployment |
| Prometheus Operator | 用 CRD 管理 Prometheus/Alertmanager lifecycle | Deployment |

Prometheus 和 Alertmanager 用 StatefulSet 是因為需要持久化資料；Node Exporter 用 DaemonSet 是因為每個節點都要跑一份。

一句話記法：Prometheus 抓存、Alertmanager 告警、Grafana 看圖、Node Exporter 抓節點、kube-state-metrics 抓 K8s 狀態、Operator 管生命週期。

## 用 Helm 看 release 狀態的指令

```bash
helm list -n <namespace>              # 看所有 release 的狀態（deployed/failed/pending）
helm status <release> -n <namespace>  # 看單一 release 詳細狀態，包含 Notes 和資源清單
helm history <release> -n <namespace> # 看版本歷史，確認是第幾次部署、有沒有 rollback
```

更深入時：

```bash
helm get values <release> -n <namespace>    # 看實際套用的 values
helm get manifest <release> -n <namespace>  # 看 Helm 產生的完整 K8s manifest
```

一句話記法：`helm list` 看全貌，`helm status` 看單一 release，`helm history` 看版本演進。

## Helm 指令能發現錯誤嗎

Helm 指令只能告訴你「Helm 層級」的狀態，不能看到 Pod 實際跑起來沒有。

能發現的：
- `helm list` 的 STATUS 欄：`deployed` 代表 Helm 認為部署完成，`failed` 代表 install/upgrade 本身失敗（values 格式錯、template render 失敗）
- `helm history` 能看到哪一版是 failed，判斷要不要 rollback

看不到的：
- Pod 是不是 Running
- ImagePullBackOff、CrashLoopBackOff
- 容器內部錯誤日誌
- PVC 綁定失敗

`helm status` 顯示 `deployed` 不代表服務正常，只代表 Helm 成功把 manifest 送進 K8s。接下來要用 `kubectl get pods`、`kubectl describe`、`kubectl logs` 看 runtime 層。

一句話記法：Helm 看「有沒有送進去」，kubectl 看「有沒有跑起來」。

## Grafana 和 Prometheus 更常 in-cluster 還是獨立部署

小規模單 cluster 通常 in-cluster，因為部署最直接、ServiceMonitor 自動發現最自然、網路邊界一致。

規模變大後常見的演進是「收集在 cluster 內，長期儲存或集中查詢在外部」，例如 Thanos、Mimir 或 managed service。這時 Prometheus 可能變成 remote-write 到外部，Grafana 可能集中管理多 cluster。

不是二選一的對錯題，是看規模和維運邊界。

一句話記法：小規模 in-cluster 最省事，規模變大再考慮集中化或 managed。

## Prometheus/Grafana in-cluster 的天然優勢

- ServiceMonitor 自動發現：Prometheus Operator 用 CRD 選 label，新服務加進來不用改 config
- 網路直通：同 cluster 內直接用 Service DNS 抓 metrics，不用開防火牆或設 ingress
- 權限一致：用 K8s RBAC 控制誰能看 Grafana、誰能改 alert rules
- 部署統一：一套 Helm chart 管完，升級、rollback 都走同一套流程

搬到 cluster 外，這四件事都要自己重建或妥協。除非有明確需求（跨 cluster 聚合、獨立維運、長期 retention），不然搬出去的成本通常大於收益。

## Prometheus target discovery 的路徑

這是 `kube-prometheus-stack` 的模型，其他部署方式不一定走這條路。

```
Pod 提供 /metrics
    ↓
Service 用 spec.selector 導流到 Pods
    ↓
ServiceMonitor 用 label selector 選 Service
    ↓
Prometheus Operator 把 ServiceMonitor 轉成 scrape config
    ↓
Prometheus 依 scrape config 去 scrape
```

三個角色各站哪一層：
- Prometheus：實際執行 scrape 的引擎
- Prometheus Operator：把 K8s CRD（ServiceMonitor/PodMonitor）翻譯成 scrape config
- ServiceMonitor/PodMonitor：用 K8s 原生的 label selector 描述「要抓誰」

為什麼不是 Prometheus 自己掃整個 cluster：這套模型依賴 Operator + CRD + selector 規則，形成明確且可控的 target 集合，不是無條件掃所有 Pod。

## Prometheus 最常用的 API 端點

先記三個就夠：

```bash
/api/v1/targets       # 看「抓誰」，確認 scrape 有沒有成功
/api/v1/query         # 問「現在值」
/api/v1/query_range   # 問「一段時間的值」，畫圖用
```

debug 順序：先 `targets` 確認抓得到，再 `query` 問值。不要跳過第一步直接查 metric。

## ServiceMonitor vs PodMonitor vs scrape config

| 名稱 | 是什麼 | 選誰 |
|------|--------|------|
| scrape config | Prometheus 真正執行的抓取設定 | - |
| ServiceMonitor | K8s CRD，描述「去抓某些 Service」 | 有穩定 Service 時優先 |
| PodMonitor | K8s CRD，描述「直接抓 Pod，跳過 Service」 | 沒有 Service 或要單獨看每個 Pod |

ServiceMonitor/PodMonitor 是給 Operator 看的 K8s 規格，Operator 會把它們轉成 Prometheus 的 scrape config。

一句話記法：有 Service 就用 ServiceMonitor，沒有才考慮 PodMonitor。

## 為什麼 prometheus-operated 和 alertmanager-operated 的 ClusterIP 是 None

一般 Service（有 ClusterIP）：K8s 分配一個虛擬 IP，client 打這個 IP，kube-proxy 幫你 load balance 到後面的 Pod。

Headless Service（ClusterIP: None）：K8s 不分配虛擬 IP，DNS 查詢直接回傳所有 Pod 的 IP。client 可以自己選要連哪一個。

為什麼 Prometheus/Alertmanager 用 headless：
- 它們是 StatefulSet，每個 Pod 有穩定身份（prometheus-0, alertmanager-0）
- 高可用模式下，peer 之間需要互相發現、互相溝通（例如 Alertmanager 的 gossip 協調）
- headless 讓每個 Pod 都能透過 DNS 找到其他 peer

一句話記法：headless service 是給 StatefulSet 做 peer discovery 用的，不是給外部 client 當入口。

## 新 image 上線後的最小驗證順序

先看 image tag 是哪種：

| image tag 類型 | 用什麼更新 |
|----------------|------------|
| 可變 tag（`latest`、branch name） | `kubectl rollout restart` |
| immutable tag（`v1.2.3`、commit sha） | `kubectl apply` 或 `kubectl set image` |

`rollout restart` 只是重建 Pod，Pod template 不變。它的前提是 tag 可變，重建時會重新 pull 拿到新內容。如果 tag 是 immutable，必須先改 manifest 再 apply。

```bash
# 1. 更新 deployment（依 tag 類型選一種）
kubectl rollout restart deployment/weamind -n weamind   # 可變 tag
# 或
kubectl apply -f manifests/deployment.yaml        # immutable tag
kubectl rollout status deployment/weamind -n weamind

# 2. 確認 Pod 起來
kubectl get pods -n weamind -o wide

# 3. 確認 app 有 /metrics
kubectl port-forward -n weamind svc/weamind-line-bot 18080:80
curl http://127.0.0.1:18080/metrics

# 4. 確認 Prometheus 有抓到
kubectl port-forward -n watchmind svc/watchmind-kube-prometheus-prometheus 19090:9090
# 查 /api/v1/targets
```

重點不是背指令，是記住這三層：
1. deployment/pod 有沒有吃到新 image
2. app 自己有沒有 expose `/metrics`
3. Prometheus 有沒有抓到 target

Grafana 沒資料時，從這三層切，不要一次懷疑所有東西。

## 為什麼要幫 Service 補 metadata labels

Service 有兩種 selector 相關欄位：
- `spec.selector`：Service 用來找 Pod
- `metadata.labels`：別的資源用來找這個 Service

以前只有 `Service → Pod`，所以 metadata.labels 可以空著。現在多了 `ServiceMonitor → Service`，ServiceMonitor 要靠 metadata.labels 才能選到 Service。

一句話記法：`spec.selector` 是往下找 Pod，`metadata.labels` 是讓別人往下找你。

## 為什麼這次重用原本的 Service 而不是另開

這次不是為 metrics 另開新 Service，而是重用原本的 application Service。

- 一般使用者透過 Service 打業務 API
- Prometheus 也透過同一個 Service 打 `/metrics`
- 兩種 request 最後都到同一批 Pod

只要 app 在同一個 HTTP port 提供 `/metrics`，既有 Service 就可以複用，不需要再切一條新的。

一句話記法：metrics 和業務 API 共用同一個 Service，不用另開。

## multi worker 造成 counter 失真

問題：`uvicorn --workers 2` 讓每個 worker 有自己的 in-memory counter，Prometheus scrape 時會隨機打到不同 worker，看到的值會跳動。`increase()` 把這種跳動誤判成 counter reset，算出假的增量。

解法：改成單一 worker，counter 就穩定了。

一句話記法：multi worker + in-memory counter = Prometheus 看到的數字會亂跳。

## Pod 重啟後 Prometheus 怎麼處理時間連續性

Prometheus 不會把舊 Pod 的 counter 接到新 Pod 上。Pod 換了 IP，對 Prometheus 來說就是「舊 series 結束、新 series 開始」。

連續性不是在 Prometheus 層保證的，是在 query 層用聚合做到的：

```promql
sum by (event_type) (increase(line_webhook_events_total[5m]))
```

`line_webhook_events_total` 這個 metric name 本身就代表服務邊界（只有 WeaMind LINE Bot 會產生）。

這樣寫不管 Pod 換幾次，只要屬於這個服務的 series 都會被納入計算。

一句話記法：Prometheus 保的是歷史資料，不是替你縫合 Pod identity。連續性靠 query 聚合。

## Helm chart 哪些欄位該做成 values

最值得做成 values 的 3 個欄位（以下是 values.yaml 變數名，不是 K8s 欄位名）：
- `image.tag` → 帶到 `spec.containers[].image`，對應 deploy version
- `replicaCount` → 帶到 `spec.replicas`，對應容量與可用性
- `ingress.host` → 帶到 `Ingress.spec.rules[].host`，環境差異明顯

不應輕易暴露成 values：
- 敏感值：Secret 裡的密碼、token
- 結構性邊界欄位：`selector`、`matchLabels` 這類牽涉 chart 內部一致性的欄位，亂改會拆壞資源關聯

values 不是任意 yaml merge：只有 chart template 事先暴露的欄位才能被帶值，不能憑空改 manifest 任意位置。

## helm rollback vs kubectl rollout undo

| 指令 | 回退範圍 | 回退什麼 |
|------|----------|----------|
| `kubectl rollout undo deployment/...` | 單一 Deployment | Deployment 的 rollout history，Pod 跟著舊版 template 重建 |
| `helm rollback <release> <revision>` | 整個 release | 該 revision 的整份 manifest 集合（Deployment、Service、Ingress 等） |

如果某次 Helm revision 只改了 Deployment，其他資源仍屬於該 revision 內容，只是 rollback 時它們和上一版沒差異，不會有可見變動。

一句話記法：`rollout undo` 只救 Deployment，`helm rollback` 救整個 release。

## Helm install 的最小流程

```
chart + values
    → render templates
    → 產生 Kubernetes manifests
    → 送進 cluster 建立資源
    → 記錄成 release（含 revision）
```

關鍵點：
- render 出來的 YAML 不會自動寫回 infra repo
- release/manifest 資訊存在 cluster 內
- 想知道「當時套了什麼」用 `helm get manifest`，不是找 Git repo

一句話記法：Helm 不是 kubectl apply 的語法糖，它多了 render 和 release 管理兩層。

## helm repo add / repo update / install 的分工

```bash
helm repo add prometheus-community https://...   # 把來源記進地址簿
helm repo update                                  # 同步索引（chart 清單與版本）
helm search repo kube-prometheus-stack           # 確認 repo 有通、chart 名稱對、版本對
helm install ...                                  # 才真正下載並使用 chart
```

為什麼不能跳過前兩步：用 `prometheus-community/kube-prometheus-stack` 這種寫法時，Helm 需要先知道 `prometheus-community` 是哪個來源、有哪些 chart 可用。沒有 `repo add`，它根本不認識這個名字。

一句話記法：`repo add` 記住來源，`repo update` 同步索引，`install` 才下載 chart。

## rollout undo 的本質

`rollout undo` 不是把舊 Pod 從倉庫拿回來，而是：

```
Deployment (Pod template) → ReplicaSet → Pods
```

- Deployment 管的是 Pod template（這一版應該長什麼樣的 Pod）
- 每當 template 改變，K8s 建出新的 ReplicaSet，ReplicaSet 再維持對應 Pods
- `rollout undo` 把 Deployment 的 template 對回前一版，然後讓控制鏈重新長出 Pods

一句話記法：Pod 不是被「切回舊版」，是根據舊 template 被重新建立。
