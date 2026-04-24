# 2026-04-24 Observability Targets ServiceMonitor Dashboard Implementation Notes

> 這份檔案與 `06-implementation.md` 綁定，只承接 `06` 過程中的 implementation-specific 關鍵觀察與決策討論。

## 為什麼可以直接 get Prometheus、ServiceMonitor、PodMonitor

- 這三種都不是 Kubernetes 內建的核心資源型別。它們屬於 `monitoring.coreos.com` API group，是 Prometheus Operator 提供的 CRD。
- 也就是說，今天不是因為 Kubernetes 原生就有 `Prometheus`、`ServiceMonitor`、`PodMonitor` 這些東西，而是因為我們安裝 `kube-prometheus-stack` 時，chart 一起把 Prometheus Operator 與相關 CRD 裝進了 cluster。
- 更精準地切層可以這樣講：
	- CRD 是「新增 API 型別」這一層，例如 `prometheuses.monitoring.coreos.com`、`servicemonitors.monitoring.coreos.com`、`podmonitors.monitoring.coreos.com`
	- Custom Resource 是這些型別的實例，例如 `observability-kube-prometh-prometheus` 這個 `Prometheus` resource，或一整排 `ServiceMonitor`
	- Operator 是 controller，負責 watch 這些 custom resources，然後替你生成或協調真正的 scrape config、Prometheus StatefulSet、service discovery 等落地行為
- 所以這題最穩的短版答案是：**它們不是內建 resource，也不是我們手動發明的型別；它們是 Prometheus Operator 帶進來的 CRD，而 chart 幫我們把這整套 API 與 controller 裝好了。**

## 為什麼 `alertmanager-operated` 與 `prometheus-operated` 的 ClusterIP 是 None

- `ClusterIP: None` 代表它們是 headless service，不是普通的 ClusterIP service。
- headless service 不是沒有作用，而是它**刻意不分配一個虛擬 service IP**。它的主要價值是讓 client 或 peer 可以直接透過 DNS 解析到後面的 Pod IP，這在 `StatefulSet` 場景特別常見。
- 這和 Prometheus / Alertmanager 的工作型態很吻合，因為它們都不是單純 stateless web app；它們更需要穩定身份、peer discovery，或至少保留 operator 協調 stateful workload 的空間。
- 這次查到的 YAML 也支持這個判讀：
	- `clusterIP: None`
	- Alertmanager 有 `publishNotReadyAddresses: true`
	- selector 直接指向 `app.kubernetes.io/name: alertmanager` / `prometheus`
- 所以這題不能解讀成「怎麼會沒有 IP，應該是壞了吧」；更準確的講法是：**這兩個 service 被設計成 headless service，目的是服務 stateful workload 的 DNS / peer discovery，不是提供一般 client 透過單一 VIP 存取。**

## 為什麼 Step 1 要順手看 Ingress

- 這一步不是因為我預設 observability namespace 一定會有 Ingress，而是因為它是一個便宜又高辨識度的驗證點。
- 我那時候真正想確認的是：`kube-prometheus-stack` 安裝完後，Grafana 或 Prometheus 有沒有被 chart 預設直接暴露成對外入口。
- 如果有 Ingress，後面做 dashboard 驗收時，路徑可能會是直接走 HTTP hostname 存取；如果沒有，後面的合理操作就會變成 `port-forward` 或另外自己補 ingress / auth 設計。
- 這一步的價值在於快速切掉一種錯誤假設：**不要先預設「既然 Grafana 已經裝了，應該也已經能直接從外面打開」。**
- 現在看到 `No resources found`，結論不是「這步白做」，而是：**目前 observability namespace 沒有現成 ingress，今天若要看 UI，預設走 `port-forward` 才是合理路徑。**

## 為什麼要把 `observability` 改名成 `watchmind`

- `observability` 這個名字雖然語意正確，但它太泛，拿來當 namespace 與 Helm release name 時，會讓資源名稱看起來像某種上游既有名詞，而不容易一眼分出哪些是我們自己安裝的前綴。
- 對學習來說，這會直接增加辨識成本。例如 `observability-grafana`、`observability-kube-prometh-prometheus` 這種名字，初看時不容易立刻分清楚哪一段是 chart 原生資源名，哪一段是我們自己取的 release 前綴。
- 改成 `watchmind` 的好處不是比較潮，而是**更強的識別性**：只要看到 `watchmind-...`，就能立刻知道那是這次學習環境自己建立出的資源前綴。
- 技術上這也屬於現在改最便宜的事情，因為 Helm release name 本來就不能原地 rename，namespace 也不能直接 rename。與其未來多加一堆 values、dashboard、ServiceMonitor 之後再重建，不如在 W7 還是 demo baseline 時就重建一次。
