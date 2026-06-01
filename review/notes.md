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

## Helm release 到底是什麼

Release 是「這次安裝」的名字和歷史紀錄，不是某個 K8s 資源。

用 WeaMind 當例子：

```bash
helm install weamind ./weamind-chart -f values.yaml
```

執行後 Helm 做三件事：
- 把 chart templates + values render 成 K8s manifests
- 送進 cluster 建立 Deployment、Service、Ingress 等資源
- 在 cluster 內記一筆：「有一個叫 `weamind` 的 release，目前是 revision 1」

之後 `helm upgrade weamind ...` 會變成 revision 2、3、4...

Release 是 Helm 自己維護的部署身份，讓你可以：
- `helm list` 看有哪些 release
- `helm history weamind` 看版本演進
- `helm rollback weamind 2` 把整批資源退回 revision 2

一句話記法：chart 是模板，release 是安裝後的實例名稱加歷史。

## Helm release 存在哪裡

Release 不是 K8s 原生物件，但資料確實存在 cluster 內。Helm 預設把 release state 存成 Secret：

```bash
kubectl get secrets -n weamind -l owner=helm
```

會看到類似 `sh.helm.release.v1.weamind.v1` 這種 Secret，裡面存著該 revision 的 manifest 和 values。

K8s 不認識 release 這個概念，`kubectl get release` 會報錯，但 Helm 把資料藏在 Secret 裡，所以 release state 確實活在 cluster 內。

一句話記法：release 是 Helm 層的抽象，但資料以 Secret 形式存在 cluster 裡。

## 為什麼 Helm release 存成 Secret 而不是 ConfigMap

Release 資料裡包含完整的 rendered manifest，可能包含 Secret 內容（密碼、token 等）。用 Secret 存至少有 K8s 層級的存取控制，比 ConfigMap 稍微安全一點。

Helm 可以改成用 ConfigMap 存，設環境變數 `HELM_DRIVER=configmap` 即可，但預設選 Secret 是比較保守的做法。

一句話記法：release 資料可能含敏感內容，所以預設存 Secret。

## raw manifests、Helm、Kustomize 怎麼選

Raw manifests（現況）：WeaMind 現在手寫的 YAML 已經能部署完整服務，直接、好讀、review 時一眼看懂。目前不缺這一層。

Helm 什麼時候值得引入：當你開始覺得「這幾個檔案應該綁在一起當一個版本」或「想用同一套模板部署到不同環境，只換幾個參數」時。它給你 release history 和 rollback 整批資源的能力，但代價是多了 template 語法和 release state 要維護。

Kustomize 什麼時候比 Helm 輕：如果需求只是「prod 和 staging 的 host 不一樣」或「某個環境要多加一個 annotation」，用 overlay/patch 就能搞定，不用引入整套 template 語法。

一句話記法：raw manifests 夠用就不動；Helm 管多資源版本化；Kustomize 處理小幅環境差異。

## Helm 的真實成本與 WeaMind 該不該現在引入

Helm 有四種成本：
- 看不懂成本：原本一眼能讀的 YAML 變成模板，要在腦中代換 `{{ .Values.xxx }}` 才知道最後長怎樣
- Review 成本：PR 時要同時看 template、values、render 結果，不像 raw YAML 直接比對
- 多一層要追：部署狀態不再只看 Git + cluster，還要追 Helm release/revision
- 操作路徑變了：更新不是改 YAML 然後 apply，而是改 values 然後 `helm upgrade`

WeaMind 現在該 Helm 化嗎？不急。現在最該解的是 CD 鏈路：app release 出新 image 後，怎麼更新 infra repo、怎麼觸發 deploy。這件事不需要 Helm 也能做。

如果未來要引入，不要一次全 repo Helm 化。先從最常變的那一塊開始（例如 Deployment 的 image tag、replicas），其他不常動的先不動。

一句話記法：Helm 有學習和維護成本，WeaMind 現在先把 CD 做對比較重要，Helm 以後再說。

## 有沒有 Helm，更新版本時在改什麼

沒有 Helm：直接改那份 YAML，比如換 image tag 就去 `deployment.yaml` 改 `image: xxx:v2`，然後 `kubectl apply`。Git 看到什麼，cluster 就吃什麼。

有 Helm：不是改最終 YAML，而是改 `values.yaml` 裡的 `image.tag: v2`，然後跑 `helm upgrade`。Helm 用 values 去 render 模板，產生最終 YAML 再送進 cluster。

| | 沒 Helm | 有 Helm |
|---|---|---|
| 改什麼 | 最終 YAML | values 或 chart 輸入 |
| 套用方式 | `kubectl apply` | `helm upgrade` |
| Git 看到的 | 就是最終結果 | 模板 + 參數，要 render 才知道 |

一句話記法：沒 Helm 你操作的是成品，有 Helm 你操作的是生成成品的材料。

## 可以只 chart 一部分嗎

可以，而且這樣比較穩。Chart 不是要你把整個 repo 的 YAML 都塞進去，它比較適合包住「會一起裝、一起升級、一起 rollback」的那一組資源。

以 WeaMind 為例，如果要局部引入 Helm，合理的做法是先把 app 相關的那組（Deployment、Service、Ingress、部分 ConfigMap）做成一個 chart，其他不常動的資源先維持 raw manifests。

但有一條線要守：同一個資源只能有一個 owner。不能今天用 Helm 管 Deployment，明天又直接 `kubectl apply` 另一份 `deployment.yaml` 去改它，這樣會搞不清楚誰才是 source of truth。

一句話記法：可以只 chart 一部分，但同一個資源只能被一邊管。

## repo 被 chart 化具體是什麼意思

「chart 化」就是把維護的對象從「最終 YAML」換成「模板 + 參數」。

具體會發生這幾件事：
- 原本直接能 apply 的 `deployment.yaml` 變成 `templates/deployment.yaml`，裡面有 `{{ .Values.image.tag }}` 這種佔位符
- 常變的欄位（image tag、replicas、host）被抽到 `values.yaml`
- 部署方式從 `kubectl apply` 變成 `helm install` / `helm upgrade`
- 這組資源從此用 release 角度被追蹤，有 revision history

chart 化不只是資料夾重組，而是操作入口、review 習慣、debug 方式都會跟著改。

一句話記法：chart 化就是把 source of truth 從成品 YAML 往前推一層到模板 + 參數。

## 混合式管理時 helm upgrade 和 kubectl apply 會並存嗎

會，而且這很正常。如果 repo 裡一部分資源用 Helm 管、一部分還是 raw manifests，同一輪部署就會出現兩種指令。

奇怪的不是兩種指令並存，而是同一個資源被兩邊搶著管。比如你用 Helm 管 Deployment，但有人又直接 `kubectl apply` 另一份 `deployment.yaml` 去改它。下次 `helm upgrade` 時，Helm 會把它 render 回原本的樣子，剛才的改動就被覆蓋掉了。

規則：
- 可以混用操作方式（兩種指令並存）
- 不能混用同一個資源的 ownership

一句話記法：`helm upgrade` 和 `kubectl apply` 可以同時存在，但同一個資源只能被一邊管。

## Helm 必知 6 點

1. Helm 不是讓 K8s 終於會部署。K8s 本來就能部署，Helm 多給的是把一組資源變成可安裝、可升級、可 rollback 的 release。

2. Helm ≠ CD ≠ GitOps。三者解不同問題：Helm 管 release，CD 管版本怎麼流到 cluster，GitOps 管誰是 source of truth。

3. Chart 邊界對齊 release，不是對齊 repo。不是放在同一個 repo 就該進同一個 chart，問自己：這些資源會一起裝、一起升、一起 rollback 嗎？

4. 同一個資源只能有一個 owner。可以一部分用 Helm、一部分用 raw manifests，但同一個 Deployment 不能兩邊都管。

5. Helm 最大成本是可讀性和心智模型。不是多學幾條指令，是你開始維護模板而不是成品，review 和 debug 都要多追一層。

6. `helm rollback` ≠ `kubectl rollout undo`。`rollout undo` 只退 Deployment，`helm rollback` 退整個 release。

一句話記法：Helm 是 release 管理工具，不取代 K8s 也不等於 CD，引入前要想清楚邊界和 ownership。

## app repo 和 infra repo 各管什麼

App repo：負責寫 code、build image、發 release。產出是「這個版本的 image 可以用了」。

Infra repo：負責宣告「cluster 現在要跑哪個版本」。部署狀態的歷史記錄在這裡。

第一版 CD 怎麼串：

```bash
app repo 發 release
    ↓
自動開 PR 到 infra repo（只改 image tag）
    ↓
人 review / merge
    ↓
infra repo 自己決定怎麼 deploy
```

為什麼不讓 app repo 直接改 cluster：如果 app repo 拿著 cluster credentials 直接部署，會把「產 image」和「決定跑哪個版本」混在一起。權限邊界模糊、部署歷史不在 infra repo 的 Git 裡、出事時搞不清楚是誰決定要部署這個版本。

一句話記法：app repo 負責「有什麼可以部署」，infra repo 負責「現在要跑什麼」，中間用 PR 隔開。

## PR-based deployment 是常見做法嗎

是的，這在 GitOps 模式下幾乎是標準路徑。

Renovate、Dependabot 做的事（自動開 PR 更新版本）是同一個概念。ArgoCD、Flux 這類 GitOps 工具也都預設 infra repo 的 Git 狀態是 source of truth。很多公司把「merge 到 main」當作 deploy 的觸發條件。

這個做法流行的原因：
- 有明確的 audit trail（誰 approve、誰 merge 都在 Git 歷史裡）
- 權限分離乾淨（寫 code 的人不需要 cluster credentials）
- rollback 就是 git revert

一句話記法：PR-based deployment 是 GitOps 的標準做法，用 Git 歷史當 audit trail。

## merge 後自動 deploy 是下一步

完整的 GitOps 流程：infra repo merge 後，有個東西（ArgoCD、Flux、或自己寫的 workflow）會自動把新狀態 apply 到 cluster。

WeaMind 目前停在「merge 後手動 deploy」。這是合理的第一版，先把「版本狀態由 infra repo 管」這件事做對，自動化之後再加。

一句話記法：先做對 PR-based 版本管理，自動 deploy 是下一步。

## Docker tag 會前移是 workflow 決定的

- Git tag 不會動，`v1.1.4` 打下去就是固定的
- 會動的是 Docker tag，workflow 可以同時把 `1.1.5`、`1.1`、`1` 指到同一個 image
- 舊 tag 不是先刪再新增，而是同名 tag 被重新指向新的 image digest
- GHCR 不會自己發明 tag，workflow push 什麼就存什麼

WeaMind 目前兩條路：
- main push → 產出 `latest` 和 `sha-xxx`
- release tag → 產出 `1.1.5`、`1.1`、`1`

一句話記法：tag 會不會前移、有哪些 tag，全看 workflow 怎麼 push，GHCR 只是存東西。

## main push 和 release tag 各自 build 是故意的

兩條 workflow（main push 產 `latest`/`sha`、release tag 產版本號）各自獨立 build。這樣設計比較直白、好懂、好 debug。代價是某些情況下同一份 code 會被 build 兩次。

什麼時候才值得優化成「一次 build，多處 reuse」：
- build 很慢
- release 很頻繁
- 開始在意「release 的 image 是不是和之前測過的那一份一模一樣」

WeaMind 目前規模，這是可接受的冗餘。

一句話記法：兩條路各自 build 是故意的設計，換取路徑清楚，等 build 成本變高再優化。

## PV 和 PVC 的基本定位

PersistentVolume (PV) 是 cluster 層級的儲存資源，由管理員預先建立或透過 StorageClass 動態產生。它和 Node 一樣是 cluster resource，生命週期獨立於任何 Pod。

PersistentVolumeClaim (PVC) 是使用者對儲存的請求。Pod 消耗 Node 資源，PVC 消耗 PV 資源。PVC 可以指定容量和 access mode。

一句話記法：PV 是「有什麼儲存可用」，PVC 是「我要用多少儲存」。

## PV 的 Provisioning：Static vs Dynamic

| 方式 | 誰建 PV | 什麼時候建 |
|------|---------|------------|
| Static | 管理員手動建 | 事先建好，等 PVC 來 claim |
| Dynamic | K8s 自動建 | PVC 建立時，依 StorageClass 自動產生 |

Dynamic provisioning 的前提：
- PVC 要指定 storageClassName
- 該 StorageClass 必須存在且支援 dynamic provisioning
- API server 要啟用 DefaultStorageClass admission controller

一句話記法：Static 是先備好 PV 等人用，Dynamic 是用的時候才生。

## PV 和 PVC 的 Binding

PVC 建立後，control plane 的 control loop 會找符合條件的 PV 綁定。綁定後是一對一關係，透過 ClaimRef 雙向指向。

綁定邏輯：
- Dynamic provisioning 的 PV 一定綁回觸發它的 PVC
- Static PV 配對時，使用者至少拿到要求的量，但可能拿到更大的
- 沒有符合的 PV 時，PVC 會一直 Pending，直到有符合的 PV 出現

一句話記法：PVC 和 PV 是一對一綁定，綁不到就 Pending。

## Pod 怎麼用 PVC

Pod 的 `volumes` 區塊用 `persistentVolumeClaim` 指向 PVC，K8s 會找到綁定的 PV 並 mount 給 Pod。

```yaml
volumes:
  - name: my-storage
    persistentVolumeClaim:
      claimName: my-pvc
```

如果 PV 支援多種 access mode，Pod 在使用時要指定要用哪一種。

一句話記法：Pod 不直接看 PV，透過 PVC 間接取得 volume。

## Storage Object in Use Protection

K8s 保護正在使用中的 PVC 和已綁定的 PV，不會讓它們被立即刪除。

- 刪除正在被 Pod 使用的 PVC：PVC 進入 Terminating，但實際刪除延後到 Pod 不再使用
- 刪除已綁定 PVC 的 PV：PV 進入 Terminating，但實際刪除延後到 PVC 解綁

辨識方式：status 顯示 Terminating，Finalizers 包含 `kubernetes.io/pvc-protection` 或 `kubernetes.io/pv-protection`。

一句話記法：K8s 用 Finalizer 擋住刪除，避免使用中的 storage 被誤殺。

## Reclaim Policy：PVC 刪除後 PV 怎麼處理

| Policy | 行為 | 資料去向 |
|--------|------|----------|
| Retain | PV 保留，狀態變 Released，不接受新 claim | 資料留著，需手動清理 |
| Delete | 刪除 PV，同時刪除底層儲存資源 | 資料一起刪掉 |

Dynamic provisioning 的 PV 預設繼承 StorageClass 的 reclaim policy，通常是 Delete。

Retain 後要重用同一塊儲存：刪 PV → 清資料 → 刪底層資源（或保留）→ 建新 PV。

一句話記法：Retain 留資料但要手動處理，Delete 連資料一起清掉。
