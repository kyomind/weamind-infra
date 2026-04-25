# 2026-04-24 Observability Targets ServiceMonitor Dashboard Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天先做 W7 demo MVP 所需的 target discovery、`ServiceMonitor` / `PodMonitor` 與 dashboard 最小骨架，不追 production-grade observability。
- 今天可以接受先把 cluster metrics 與 app metrics 的邊界切清楚；如果 WeaMind app 尚未暴露 `/metrics`，重點是定位缺口，而不是硬補一整套應用程式重構。
- 今天優先保住一條可 demo、可面試重講的證據鏈，不追求把 PromQL、Alertmanager 與 dashboard 視覺設計一次做滿。

### Repo 對照文件與觀察點

- `.privatedocs/Phase2三週計畫.md`：確認今天是 W7 Day 3、`implement-heavy`，以及最低驗收標準。
- `references/phase2/w7-observability-minimum-spec.md`：固定今天的 Node 3、App 4、1 個 dashboard MVP 邊界。
- `learning/lessons/2026-04-21-helm-kube-prometheus-stack-basics/05-note.md`：回收前一天已確認的 operator / workload / install 邊界。
- `manifests/deployment.yaml`、`manifests/service.yaml`：對照 WeaMind app 若要被 scrape，最小可能修改點在哪。

### 暫時不在今天展開的點

- PromQL 深水區與 recording rules
- Alertmanager routing 與通知策略
- Production-grade dashboard folder / RBAC / provisioning 設計

## Notes

### 這份 note 現在也承接實作補充

- 從這堂開始，實作過程中冒出的補充觀察、設計取捨與一般 lesson 延伸問答，統一併入 `05-note.md`，不再額外拆 `07-implementation-note.md`。

### Observability UI 在實務上最常怎麼暴露

- 學習、個人維運、小團隊臨時 debug 時，`port-forward` 很常見，因為它最保守、暴露面最小，也最適合像今天這樣一步一步驗證 Prometheus / Grafana。
- 但如果講到真實 production，**最常見的正式做法通常不是長期靠 `port-forward`**，而是把 Grafana 這類 UI 放在受控的內網入口後面，例如 internal ingress、internal load balancer、VPN 後面，或 Zero Trust / bastion 保護後的入口。
- ⭐️Prometheus UI 本身在 production 裡通常比 Grafana **更少直接開給大量使用者**，常見做法是只給維運人員內網存取，甚至平常只在需要時 `port-forward`。
- 直接暴露到公網不是完全不可能，但它不應是預設。若真的要公網暴露，通常也不會只靠 Grafana 內建帳密，而會再疊 SSO、auth proxy、IP allowlist、TLS 與審計。
- 所以更穩的短版收斂是：**`port-forward` 常見於學習、debug、break-glass；內網暴露是 production 最常見的正式方案；公網暴露是高風險例外，不應當成預設。**

### 這條 `curl | jq` 指令到底在做什麼

- 指令本體：`curl -s http://127.0.0.1:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, namespace: .labels.namespace, health: .health, scrapeUrl: .scrapeUrl}'`
- 這條指令不是在查 Kubernetes API，也不是在查 manifest；它是在**直接問 Prometheus server 本身**：「你現在正在抓哪些 target？它們健康嗎？你實際打的是哪個 URL？」
- 可以拆成四段理解：
	- `curl -s http://127.0.0.1:9090/api/v1/targets`：對本機 `9090` 上的 Prometheus API 發 HTTP request。這個 `9090` 來自前一步的 `port-forward`。
	- `|`：把前面回來的 JSON 輸出傳給後面的 `jq`。
	- `.data.activeTargets[]`：進到 Prometheus API 回傳 JSON 裡的 `data.activeTargets` 陣列，然後把每一筆 target 都攤開。
	- `{job: .labels.job, namespace: .labels.namespace, health: .health, scrapeUrl: .scrapeUrl}`：不要把整份 JSON 全印出來，只挑目前最適合第一輪判讀的四個欄位。
- 這四個欄位各自回答的問題是：
	- `job`：這個 target 被歸在哪個監控工作名稱下，例如 `kubelet`、`node-exporter`、`watchmind-grafana`
	- `namespace`：這個 target 大致對應哪個 namespace，方便先切 cluster baseline、observability stack 本身，或應用程式
	- `health`：Prometheus 認為這個 target 現在是 `up` 還是 `down`
	- `scrapeUrl`：Prometheus 真正去抓 metrics 的 URL 是哪一條
- 所以這條指令最穩的短版理解是：**先用 Prometheus API 看 target discovery 結果，再用 `jq` 把輸出縮成可讀的第一輪觀察欄位。**

### 看這條 targets 指令時，第一輪應先看哪三件事

- 第一先看 `health`，因為它先回答 scrape 鏈路有沒有成立。若一堆 `down`，就還不適合往 metrics 值或 dashboard 走。
- 第二看 `job`，因為它幫你快速分群，判斷現在看到的是 control plane、node、observability stack 本身，還是 app。
- 第三看 `scrapeUrl`，因為它直接暴露 Prometheus 實際打去哪個 endpoint，也最容易幫你發現 port、path、scheme 是否合理。
- `namespace` 很重要，但通常是第二層輔助資訊，用來幫你快速定位這個 target 比較像 cluster resource 還是某個 app namespace 裡的資源。

### Prometheus 常用 API 端點要不要知道一點

- 要，但在 W7 先知道「它們各自在回答什麼問題」就夠了，不需要把整份 API 文件背下來。
- 最常用、最值得先記住的可以收斂成這幾個：
	- `/api/v1/targets`：看 Prometheus 目前抓哪些 targets、它們健康嗎。今天用的就是這個。
	- `/api/v1/query`：做即時查詢，適合問「這個 metric 現在的值是多少」。
	- `/api/v1/query_range`：做一段時間範圍的查詢，適合圖表或趨勢。
	- `/api/v1/label/__name__/values`：列出目前有哪些 metric 名稱，適合你不知道有哪些 metrics 可查時先探路。
	- `/api/v1/series`：看有哪些 time series 存在，常用來確認某個 metric 搭哪些 labels。
	- `/api/v1/status/config`：看 Prometheus 目前吃進去的設定內容，偏 debug / 進階用途。
	- `/api/v1/rules`：看 recording rules / alerting rules 是否存在與目前狀態。
- 如果只記一句話，可以這樣記：
	- `targets` 看「抓誰」
	- `query` 看「現在值」
	- `query_range` 看「一段時間的值」
	- `label values / series` 看「有哪些資料可查」
	- `status / rules` 看「Prometheus 自己目前怎麼配置、在跑哪些規則」

### W7 階段最值得先會的 Prometheus API 使用順序

- 第一步先用 `/api/v1/targets` 確認 scrape 鏈路有沒有成立。
- 第二步若鏈路成立，再用 `/api/v1/label/__name__/values` 或 UI 的 metric explorer 看有哪些 metric 名稱。
- 第三步才進 `/api/v1/query` 或 `query_range`，開始問具體指標值與時間趨勢。
- 這個順序的好處是：**先確認 Prometheus 抓得到，再去問抓到了什麼與值是多少；不要一開始就把 `query` 當成萬用入口。**

### 這條 `rg` 指令到底在做什麼

- 指令本體：`rg -n "metrics|prometheus|port:" manifests/deployment.yaml manifests/service.yaml`
- 這條指令不是在執行 Kubernetes，也不是在問叢集現況；它是在 **repo 檔案內容裡做快速文字搜尋**。
- `rg` 是 ripgrep，作用很像速度更快的 `grep`。
- `-n` 代表把命中的行號一起印出來，方便你回頭對照檔案。
- `"metrics|prometheus|port:"` 是正則表達式，意思是只要命中 `metrics`、`prometheus`、或 `port:` 任一種字樣，就列出來。
- 後面的 `manifests/deployment.yaml manifests/service.yaml` 則是限制只搜這兩個檔案，不去整個 repo 全掃。

### 為什麼 Step 4 要用這條 `rg`

- 這一步真正想問的不是「app 現在有沒有 metrics 值」，而是更前一層：**這個 infra repo 有沒有任何跡象顯示 WeaMind 已準備好被 Prometheus scrape。**
- 所以這條搜尋先故意很粗：先找 `metrics`、`prometheus`、`port:` 這些關鍵字，快速判斷目前 manifest 裡有沒有明顯的 metrics exposure、監控資源命名，或至少有哪些 port 是相關候選點。
- 它的價值不是直接得出最終答案，而是用很低成本把問題縮成：
	- 目前只有一般 HTTP / health check
	- 還是已經有 metrics / prometheus 相關結構

### 這條 `rg` 的結果能證明什麼，不能證明什麼

- 它能證明：在這個 infra repo 裡，目前沒有看到明顯的 `metrics`、`prometheus`、`ServiceMonitor` 類型設定；有看到的只是一般 HTTP service 與 probe 使用的 port。
- 它也能幫你快速抓到一個現實：目前 `service.yaml` 只有一個一般 HTTP service，`deployment.yaml` 命中的 `port: http` 也只是 `/health` probes 在用。
- 但它不能單獨證明：WeaMind app 程式碼一定沒有 `/metrics` endpoint。因為那一層可能存在於另一個 application repo，而且甚至可能和一般 HTTP port 共用。
- 所以更穩的說法是：**這條 `rg` 能證明 infra 端目前沒有顯式的 scrape 設計訊號，但不能單靠它就判 app code 端一定沒有 `/metrics`。**

### ServiceMonitor vs PodMonitor vs scrape config 的白話版

- 先講最短版：
	- `scrape config` 是 Prometheus 真正用來抓 metrics 的設定結果
	- `ServiceMonitor` 是在 Kubernetes 裡用來描述「請去抓某些 Service」的高階規格
	- `PodMonitor` 是在 Kubernetes 裡用來描述「請直接去抓某些 Pod」的高階規格
- 如果把它們放進同一條鏈看，順序比較像這樣：
	- app 先真的提供 `/metrics`
	- Kubernetes 裡有 `Service` 或 `Pod` 可被選到
	- 你寫 `ServiceMonitor` 或 `PodMonitor`
	- Prometheus Operator 看到這些 CRD
	- Operator 幫你產生 Prometheus 最終會吃的 `scrape config`
	- Prometheus 才真的照設定去抓 metrics
- 所以 `ServiceMonitor` / `PodMonitor` 不是 Prometheus 最底層的原生設定檔，而是 **Operator 模型裡的 Kubernetes 友善入口**。它們的價值是讓你不用直接手寫一大段 Prometheus scrape YAML。
- `ServiceMonitor` 比較像是在說：
	- 「去找符合某些 labels 的 `Service`」
	- 「抓它暴露的某個 port / path / interval」
	- 它比較適合已經有穩定 `Service` 的 app
- `PodMonitor` 比較像是在說：
	- 「不要先經過 `Service`，直接去找符合條件的 `Pod`」
	- 它適合沒有穩定 `Service`，或每個 Pod 本身就是你要直接看的目標
- 如果只問 WeaMind 這種一般 web app 比較常用哪個，答案通常是 `ServiceMonitor`。因為它本來就有穩定 `Service`，而且也比較符合「先有 service boundary，再做 scrape」的習慣。
- 如果只記一句話，可以這樣記：**`ServiceMonitor` / `PodMonitor` 是給 Operator 看的 Kubernetes 規格；`scrape config` 是 Prometheus 最後真正執行的抓取設定。**

### 為什麼今天先更適合 `ServiceMonitor`

- WeaMind 目前在 infra repo 裡已經有 `Service`，名字是 `weamind-line-bot`，而且也有穩定的 `Deployment` / `Service` 結構。
- 這代表如果之後 app 真的暴露 `/metrics`，最自然的接法通常不是直接上 `PodMonitor`，而是補一份 `ServiceMonitor`，讓 Prometheus 經由既有 `Service` 去抓。
- `PodMonitor` 不是不能用，而是對今天這個 case 來說，它比較不像第一個最自然的入口。

### 為什麼可以直接 get Prometheus、ServiceMonitor、PodMonitor

- 這三種都不是 Kubernetes 內建的核心資源型別。它們屬於 `monitoring.coreos.com` API group，是 Prometheus Operator 提供的 CRD。
- 也就是說，今天不是因為 Kubernetes 原生就有 `Prometheus`、`ServiceMonitor`、`PodMonitor` 這些東西，而是因為我們安裝 `kube-prometheus-stack` 時，chart 一起把 Prometheus Operator 與相關 CRD 裝進了 cluster。
- 更精準地切層可以這樣講：
	- CRD 是「新增 API 型別」這一層，例如 `prometheuses.monitoring.coreos.com`、`servicemonitors.monitoring.coreos.com`、`podmonitors.monitoring.coreos.com`
	- Custom Resource 是這些型別的實例，例如 `observability-kube-prometh-prometheus` 這個 `Prometheus` resource，或一整排 `ServiceMonitor`
	- Operator 是 controller，負責 watch 這些 custom resources，然後替你生成或協調真正的 scrape config、Prometheus StatefulSet、service discovery 等落地行為
- 所以這題最穩的短版答案是：**它們不是內建 resource，也不是我們手動發明的型別；它們是 Prometheus Operator 帶進來的 CRD，而 chart 幫我們把這整套 API 與 controller 裝好了。**

### 為什麼 `alertmanager-operated` 與 `prometheus-operated` 的 ClusterIP 是 None

- `ClusterIP: None` 代表它們是 headless service，不是普通的 ClusterIP service。
- headless service 不是沒有作用，而是它**刻意不分配一個虛擬 service IP**。它的主要價值是讓 client 或 peer 可以直接透過 DNS 解析到後面的 Pod IP，這在 `StatefulSet` 場景特別常見。
- 這和 Prometheus / Alertmanager 的工作型態很吻合，因為它們都不是單純 stateless web app；它們更需要穩定身份、peer discovery，或至少保留 operator 協調 stateful workload 的空間。
- 這次查到的 YAML 也支持這個判讀：
	- `clusterIP: None`
	- Alertmanager 有 `publishNotReadyAddresses: true`
	- selector 直接指向 `app.kubernetes.io/name: alertmanager` / `prometheus`
- 所以這題不能解讀成「怎麼會沒有 IP，應該是壞了吧」；更準確的講法是：**這兩個 service 被設計成 headless service，目的是服務 stateful workload 的 DNS / peer discovery，不是提供一般 client 透過單一 VIP 存取。**

### 為什麼 Step 1 要順手看 Ingress

- 這一步不是因為我預設 observability namespace 一定會有 Ingress，而是因為它是一個便宜又高辨識度的驗證點。
- 我那時候真正想確認的是：`kube-prometheus-stack` 安裝完後，Grafana 或 Prometheus 有沒有被 chart 預設直接暴露成對外入口。
- 如果有 Ingress，後面做 dashboard 驗收時，路徑可能會是直接走 HTTP hostname 存取；如果沒有，後面的合理操作就會變成 `port-forward` 或另外自己補 ingress / auth 設計。
- 這一步的價值在於快速切掉一種錯誤假設：**不要先預設「既然 Grafana 已經裝了，應該也已經能直接從外面打開」。**
- 現在看到 `No resources found`，結論不是「這步白做」，而是：**目前 observability namespace 沒有現成 ingress，今天若要看 UI，預設走 `port-forward` 才是合理路徑。**

### 為什麼要把 `observability` 改名成 `watchmind`

- `observability` 這個名字雖然語意正確，但它太泛，拿來當 namespace 與 Helm release name 時，會讓資源名稱看起來像某種上游既有名詞，而不容易一眼分出哪些是我們自己安裝的前綴。
- 對學習來說，這會直接增加辨識成本。例如 `observability-grafana`、`observability-kube-prometh-prometheus` 這種名字，初看時不容易立刻分清楚哪一段是 chart 原生資源名，哪一段是我們自己取的 release 前綴。
- 改成 `watchmind` 的好處不是比較潮，而是**更強的識別性**：只要看到 `watchmind-...`，就能立刻知道那是這次學習環境自己建立出的資源前綴。
- 技術上這也屬於現在改最便宜的事情，因為 Helm release name 本來就不能原地 rename，namespace 也不能直接 rename。與其未來多加一堆 values、dashboard、ServiceMonitor 之後再重建，不如在 W7 還是 demo baseline 時就重建一次。

### 為什麼 `kubelet` targets 看起來很多，而且像重複

- 這不是 Prometheus 壞掉，也不是 chart 重複亂抓。原因是 `watchmind-kube-prometheus-kubelet` 這個 `ServiceMonitor` 本來就定義了多個 endpoint path。
- 這次直接查 `ServiceMonitor` 可以看到至少三類路徑：
	- `/metrics`
	- `/metrics/cadvisor`
	- `/metrics/probes`
- 因為 cluster 有三個 node，而每個 node 的 kubelet 又會對這幾種路徑各自形成 target，所以在 Prometheus target 頁面上看起來就會很多筆，而且 job 名稱都還叫 `kubelet`。
- 更精準地說，這裡的「多」來自兩個維度同時展開：
	- 多個 node
	- 同一個 kubelet 暴露多個 metrics surface
- 所以這題的最穩短版答案是：**`kubelet` target 多是正常現象，因為同一組 kubelet endpoints 會被分別抓 `/metrics`、`/metrics/cadvisor`、`/metrics/probes` 等不同路徑，不是單純重複。**

### ⭐️新 image 上線後，最小應該怎麼重啟與驗證

- 這次最值得記住的不是單一指令，而是**驗證順序**。新 image 已經 push 後，不要一上來就先看 Grafana；先把「deployment 是否更新」「service `/metrics` 是否可達」「Prometheus target 是否 `up`」這三層拆開驗。
- 一個夠穩的最小順序可以收斂成：
	- 若 manifest 有變更，先 `kubectl apply -f ...`
	- `kubectl rollout restart deployment/weamind -n weamind`
	- `kubectl rollout status deployment/weamind -n weamind`
	- `kubectl get pods -n weamind -o wide`
	- `kubectl port-forward -n weamind svc/weamind-line-bot 18080:80` 後直接看 `curl http://127.0.0.1:18080/metrics`
	- `kubectl port-forward -n watchmind svc/watchmind-kube-prometheus-prometheus 19090:9090` 後直接查 `/api/v1/targets`
- 這個順序的好處是：如果 Grafana 沒資料，你不用一次懷疑所有東西，而是可以很快切成三層：
	- deployment / pod 有沒有真的吃到新 image
	- app 自己有沒有真的 expose `/metrics`
	- Prometheus 有沒有真的抓到 target
- 對新手來說，最重要的不是背很多命令，而是先記住這個判斷順序。因為真正卡住時，問題通常不是「少打一條命令」，而是**沒有先切清楚自己現在在驗哪一層。**

### 為什麼這次要幫 Service 補 metadata labels

- 這次新增 `ServiceMonitor` 之後，`Service` 不只是在做「把流量導到 Pod」這件事，還多了一個新角色：**被 `ServiceMonitor` 選到，讓 Prometheus 知道該抓哪個 Service。**
- 這裡要刻意分清楚兩種 selector：
	- `Service.spec.selector`：這是 `Service` 用來找 Pod 的
	- `Service.metadata.labels`：這是別的資源拿來找這個 `Service` 的
- 以前沒有 `ServiceMonitor` 時，`Service` 只需要靠 `spec.selector` 把流量導到帶 `app: weamind` 的 Pods，所以 metadata labels 可以完全沒有也照樣正常工作。
- 但這次多了一條新關係：`ServiceMonitor -> Service`。所以 `Service` 本身也必須在 `metadata.labels` 上提供可被 selector 命中的標記，不然 `ServiceMonitor` 根本找不到它。
- 這也是為什麼這次會補：
	- `app: weamind`
	- `app.kubernetes.io/name: weamind`
- 其中真正讓這次 `ServiceMonitor` 選到 Service 的關鍵，是 `app: weamind`；因為目前 `ServiceMonitor.spec.selector.matchLabels` 就是靠這個值在選。
- `app.kubernetes.io/name: weamind` 不算這次功能成立的必要條件，比較像順手補上的標準化 label，讓後面如果想改成更偏標準 label 的 selector，不用再補一次。
- 所以最穩的短版收斂是：**以前不需要，是因為只有 `Service -> Pod` 這條關係；現在需要，是因為多了 `ServiceMonitor -> Service` 這條關係。**

### 這次其實是在重用原本的 Service

- 對，這次不是為了 metrics 另外做一個新的 `Service`，而是**重用原本已經存在的 application Service**。
- `manifests/service.yaml` 裡的 `weamind-line-bot` 本來就已經在把流量導到同一批 WeaMind Pods；這次新增的只是 `ServiceMonitor`，不是另一條新的 app 流量拓樸。
- 更精準地說，這次多出來的是一條 `Prometheus -> ServiceMonitor -> Service -> Pod` 的 scrape 鏈，而不是多一組 `Service -> Pod` 業務鏈。
- 所以可以把它想成：
	- 一般使用者或外部系統透過原本的 `Service` 打一般 API
	- Prometheus 也透過同一個 `Service` 打 `/metrics`
	- 這兩種 request 最後都會到同一批 Pod
- 這也是為什麼你會感覺「本質上都是同一個 pod 提供的 API」；這個判斷是對的。更準確地說，是**同一個應用同時提供一般業務 endpoint 和 metrics endpoint，而它們共用同一個 Service 與同一批 Pod。**
- 這裡要避免的一個小誤解是：`ServiceMonitor` 不是自己去 attach 在 Pod 上監視；它比較像是在描述「Prometheus 應該透過哪個 Service、哪個 port、哪個 path 去 scrape」。
- 所以這次值得記的設計點不是「我們為 metrics 額外建了一套服務」，而是：**只要 app 已經在同一個 HTTP surface 上提供 `/metrics`，既有的 Service 就可以被複用，不需要再額外切一條新的 Service。**
- 這也順手解釋了為什麼這次只需要補 `Service.metadata.labels` 給 `ServiceMonitor` 選，而不是重做 `Service.spec.selector` 或重開一組 deployment。

### ⭐️從 Pod 的 `/metrics` 到 Prometheus scrape 的完整鏈路

- 如果要把這次的邏輯一口氣講順，可以收斂成這條鏈：
	- Pod 內的 app 先真的提供 `/metrics`
	- `Service` 把流量導到這批 Pods
	- `ServiceMonitor` 描述 Prometheus 應該抓哪個 `Service`
	- Prometheus Operator 讀取 `ServiceMonitor`，轉成 Prometheus 可執行的 scrape 設定
	- Prometheus 依照設定去 scrape target
- 這條鏈裡每一層的責任不一樣，不能混成一句「Prometheus 自己會找到 Pod」。

#### 第一層：Pod / app 本身要先真的提供 `/metrics`

- 最底層的前提永遠是：**應用程式自己要先能回應 `/metrics`**。
- 如果 Pod 裡的 app 根本沒有這個 endpoint，那後面就算有 `Service`、`ServiceMonitor`、Prometheus，也只會 scrape 失敗。
- 所以 `/metrics` 是資料出口，負責把 app 內部已註冊的 metrics 以 Prometheus 看得懂的格式輸出。

#### 第二層：Service 負責把請求導到正確的 Pods

- `Service.spec.selector` 會去選到帶 `app: weamind` 的 Pods。
- `Service` 的 port 叫 `http`，對外是 `80`，最後轉到 Pod 的 `8000`。
- 這一層的責任不是「告訴 Prometheus 監控規則」，而是提供一個穩定的 Kubernetes 網路入口，讓打到這個 `Service` 的 request 能進到正確的 Pods。
- ⭐️所以不論是一般 API request，還是 Prometheus 對 `/metrics` 的 scrape，本質上都是先經過這個 `Service`，再到 Pod。

#### 第三層：ServiceMonitor 負責描述「該抓哪個 Service、抓哪個 endpoint」

- `ServiceMonitor` 不直接選 Pod，它先選的是 `Service`。
- ⭐️這次的 `ServiceMonitor.spec.selector.matchLabels.app: weamind`，就是在找帶有這個 metadata label 的 `Service`。
- ⭐️它同時還定義了 scrape 細節：
	- 抓 `port: http`
	- 抓 `path: /metrics`
	- `interval: 30s`
	- `scrapeTimeout: 10s`
- 所以 `ServiceMonitor` 的角色比較像「⭐️**Kubernetes 世界裡的 scrape 規格**」，而不是實際去送 request 的元件。

#### 第四層：Prometheus Operator 負責把 CRD 規格轉成實際 scrape 設定

- `ServiceMonitor` 只是 custom resource，不是 Prometheus 最終直接執行的原生設定格式。
- ⭐️真正把這些 **Kubernetes 資源**讀進來、轉成 Prometheus **scrape config** 的，是 Prometheus **Operator**。
- 這也是為什麼我們會說：`ServiceMonitor` 是給 Operator 看的高階入口，而不是 Prometheus 自己手寫的最底層 YAML。
- ⭐️如果少了 Operator，cluster 裡就算存在 `ServiceMonitor`，Prometheus 也不會自動理解它。

#### 第五層：Prometheus 依照 scrape config 去真的抓 metrics

- 到這一步，Prometheus 才會真的定期發 HTTP request 去 scrape target。
- 它不是憑空「掃整個 cluster 找所有 Pod」，而是依照 Operator 幫它整理好的目標集合去抓。
- **所以最後看到 target `up`，代表的是**：
	- Pod 的 `/metrics` 存在
	- `Service` 可以把請求導過去
	- `ServiceMonitor` 有正確選到 `Service`
	- Operator 有把它轉進 Prometheus 設定
	- Prometheus 真的抓成功

#### 這條鏈最值得記的短版

- `Pod` 負責提供 `/metrics`
- `Service` 負責把流量導到 Pod
- `ServiceMonitor` 負責描述 scrape 規則與選哪個 Service
- Prometheus Operator 負責把 `ServiceMonitor` 轉成 scrape config
- Prometheus 負責真的去抓
- 所以更準的說法不是「Prometheus 找到 Pod」，而是：**Prometheus 透過 Operator 理解 `ServiceMonitor`，再經由 `Service` 去 scrape 那些實際提供 `/metrics` 的 Pods。**

### 怎麼拿到 Grafana 初始登入密碼

- 這次 Grafana 的 admin 帳密不是我憑空知道的，而是從 Kubernetes 裡的 `Secret` 讀出來。
- `kube-prometheus-stack` 這類 Helm chart 安裝 Grafana 時，通常會把 admin username / password 放進對應 namespace 內的 secret。
- 這次實際可用的查法是：

```bash
kubectl get secret watchmind-grafana -n watchmind -o go-template='{{index .data "admin-user" | base64decode}} {{index .data "admin-password" | base64decode}}'
```

- 這條指令做的事可以拆成三段：
	- `kubectl get secret watchmind-grafana -n watchmind`：讀取 `watchmind` namespace 裡的 Grafana secret
	- `.data "admin-user"` / `.data "admin-password"`：取出 secret 裡儲存的帳號與密碼欄位
	- `base64decode`：把 Kubernetes Secret 預設的 base64 編碼值解回原文
- 如果終端機輸出最後多一個 `%`，那通常不是密碼內容，而是 zsh prompt 接在輸出後面顯示出來；這次真正的密碼本身**不包含**最後那個 `%`。
- 所以這題最穩的短版記法是：**Grafana 初始帳密通常放在 Kubernetes Secret；要拿密碼，不是去猜，而是去查 chart 建出的 secret 並做 base64 decode。**

## Flashcards
