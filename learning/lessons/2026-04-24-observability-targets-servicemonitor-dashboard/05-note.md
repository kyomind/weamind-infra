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

## Flashcards
