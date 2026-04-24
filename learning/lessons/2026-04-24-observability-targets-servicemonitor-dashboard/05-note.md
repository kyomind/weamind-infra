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

## Flashcards
