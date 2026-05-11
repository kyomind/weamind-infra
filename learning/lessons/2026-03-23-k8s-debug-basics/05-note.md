# 2026-03-23 K8s Debug Basics Note
複習：2026-05-11
## 學習注意事項

### 外部預習回帶重點

- 今天先建立的是通用 debug 心智模型，不是工具清單。
- debug 的核心不是先開 `logs`、`describe`、`exec`，而是先判斷自己正在驗證哪一層。
- 排查方向不是固定只由外到內或只由內到外，而是看目前最強的異常訊號在哪裡。
- Pod 狀態是第一個高價值訊號：Pending、ImagePullBackOff、CreateContainerError、CrashLoopBackOff 分別對應不同階段的問題。
- 若外部請求完全沒進來，通常先走外到內；若 Pod 自己已出現明顯異常訊號，通常可先把注意力收斂到 Pod / app 內層。

### 今日先對齊的 repo 入口

- WeaMind 的外部流量骨架可先對回：LINE webhook → DNS → Hetzner LB → Traefik Ingress → `weamind-line-bot` Service → `weamind` Pods → app。
- `manifests/deployment.yaml` 內的 image、`envFrom`、command、probe 與 `nodeSelector`，都是 Day 1 判讀 Pod 問題時的高價值觀察點。
- `manifests/service.yaml` 與 `manifests/ingress.yaml` 則是切 Service / Ingress 層問題時最直接的 repo 入口。
- `PROGRESS.md` 已提供至少兩個可直接掛回今天框架的真實案例：`CreateContainerError (invalid UTF-8)` 與 LB health check 未帶 Host header 導致 `/health` 回 404。

### 今日 lesson 邊界

- 今天先把抽象骨架對回 WeaMind 的真實元件名稱。
- 今天先把不同 Pod 狀態在這個 repo 裡應優先對照哪些設定釘穩。
- 今天先分清哪些真實故事比較像外層流量路徑問題，哪些比較像內層 Pod / app 問題。
- 今天先不要把 `describe`、`logs`、`logs --previous`、`exec` 的細節全部混進來。
- Day 2 再把工具對回今天的框架，回答「當我懷疑這一層時，該用哪個工具拿證據」。

## Notes

### Ingress backend 的 80 與 Service port 的關係

- Ingress 不會直接把請求送到 Pod 的 8000，它先把請求交給某個 Service。
- 在 [manifests/ingress.yaml](manifests/ingress.yaml) 裡看到的 `backend.service.port.number: 80`，意思是「這條 Ingress 規則要把流量交給 `weamind-line-bot` 這個 Service 的哪一個 Service port」，不是在指 Pod port，也不是單純在描述外部使用者原始打進來的 port。
- 在 [manifests/service.yaml](manifests/service.yaml) 裡，`port: 80` 代表這個 Service 自己在叢集內提供的入口 port；其他元件若要把流量交給這個 Service，就要打這個 port。
- 同一份 Service YAML 裡的 `targetPort: 8000`，才是在說這個 Service 收到流量後，最後要把流量導到 Pod / container 的哪個 port。
- 所以這一段的正確分層是：Traefik 依照 Ingress 規則，把流量交給 `weamind-line-bot:80`；然後 Service 再把流量轉給被 selector 選到的 Pod 的 8000。
- 若某個 Service 同時暴露多個 ports，Ingress backend 這裡的 port 就很重要，因為它是在告訴 Ingress Controller：這次應該選這個 Service 的哪一個入口，而不是讓它自己猜。

### Host / path 規則與 Service 多 port 的理解

- 目前這份 [manifests/ingress.yaml](manifests/ingress.yaml) 的規則，是把 host `k8s.kyomind.tw`、path `/` 命中的請求，統一交給 `weamind-line-bot` 這個 Service 的 `80`。
- 這條 Ingress 規則主要看的是 host 與 path，不是在用外部請求原本的 port 來做應用層分流；在 WeaMind 這個案例裡，外部通常是走 443 進來，但真正讓這條規則命中的關鍵是 Host header 與 path。
- 一個 Service 可以定義不只一個 `port`，但在一般 selector-based Service 裡，這些 ports 仍然是面向同一組被 selector 選到的 Pods，不是每個 port 自動對應不同的一組 Pods。
- 比較典型的用法是：同一組 Pods 同時暴露多個協定或入口，例如 `http:80 -> targetPort 8000`、`metrics:9090 -> targetPort 9090`；或同一個應用同時提供對外流量與監控端點。
- 若真的要讓不同 port 對應不同的 Pod 群，通常會拆成不同的 Services，因為 selector、責任邊界與 debug 路徑會更清楚；單一 Service 硬承接多組後端，複雜度通常會明顯上升。

### Secret invalid UTF-8 為什麼會造成 CreateContainerError

- 這個案例的根因可直接對回 [PROGRESS.md](PROGRESS.md)：當時錯誤使用了 Secret 的 `data` 欄位，但放進去的值不是合法的 base64 字串。
- Kubernetes 的 Secret 若寫在 `data` 底下，值必須先是 base64；若直接把普通明文或帶有非 base64 內容的字串塞進去，就會在解碼或注入階段出問題。
- WeaMind 後來的修正是改用 `.privatedocs/secrets/secret.yaml` 裡的 `stringData`，讓 Kubernetes 代為處理編碼，避免手動 base64 與 UTF-8 錯誤。
- 所以這個錯誤不是 app 啟動後才掛掉，而是在 container 建立與注入環境變數的前置階段就卡住，這也是它更像 CreateContainerError 而不是 CrashLoopBackOff 的原因。

## Flashcards

- Ingress backend 裡的 `service.port.number: 80` 代表什麼？ #DevOps #card
	- 它指定的是這條 Ingress 規則要把流量交給哪個 Service port
	- 在 WeaMind 裡就是把命中 `k8s.kyomind.tw` + `/` 的請求交給 `weamind-line-bot:80`
	- 它不是 Pod port，也不是單純外部 client 原始打進來的 port

- Service 的 `port` 與 `targetPort` 在 WeaMind 裡怎麼分工？ #DevOps #card
	- `port: 80` 是 Service 自己在叢集內提供的入口
	- `targetPort: 8000` 是 Service 最後把流量導到 Pod / container 的 port
	- 所以路徑是 Traefik → `weamind-line-bot:80` → Pod:8000

- 一個 Service 可以有多個 ports，但通常代表什麼？ #DevOps #card
	- 通常仍是面向同一組被 selector 選到的 Pods
	- 常見用途是同一組 Pods 同時暴露 http、metrics 或不同協定入口
	- 若要對不同 Pod 群導流，通常拆成不同 Services 比較清楚

- Pending 在 WeaMind 這個 repo 第一輪應先看什麼？ #DevOps #card
	- 先看 `manifests/deployment.yaml` 裡的排程條件與資源設定
	- WeaMind 目前的高價值入口是 `nodeSelector: nodepool=worker` 與 `resources.requests`
	- 它代表 Pod 還沒真正被放上可執行的 node，不是 app 本身先壞掉

- ImagePullBackOff 在 WeaMind 第一輪應先看哪裡？ #DevOps #card
	- 先看 `manifests/deployment.yaml` 裡的 `containers.image` 與 `imagePullPolicy`
	- WeaMind 例子是 `ghcr.io/kyomind/weamind:latest` 與 `Always`
	- 這一層在問的是 image 拉不拉得下來，不是 app 啟動邏輯

- 為什麼 `CreateContainerError (invalid UTF-8)` 比較像 Pod / Container 建立層問題？ #DevOps #card
	- 因為錯誤發生在 container 建立與注入環境變數的前置階段
	- WeaMind 的根因是 Secret 錯用 `data` 並放入非 base64 字串
	- 後來改用 `stringData` 才修好，所以它不是 app 啟動後才掛掉

- CrashLoopBackOff 在 WeaMind 第一輪應優先懷疑什麼？ #DevOps #card
	- 先回 `manifests/deployment.yaml` 看 `command`、`envFrom`、probes 與依賴連線設定
	- 它代表 container 已經起來，但 app 活不下來
	- 這是比 CreateContainerError 更內層、也更接近 app 執行期的訊號

- LB health check 未帶 Host header 導致 `/health` 回 404，為什麼應先由外到內排查？ #DevOps #card
	- 因為最強的異常訊號先出現在外層入口與 routing 規則命中
	- 在 WeaMind 裡第一輪應先查 LB health check、Host header 與 Ingress 規則
	- 不是先證明 Pod 一定沒問題，而是先排掉更直接的外層異常訊號

- 為什麼 `CreateContainerError` 與 LB health check 404 不該用同一條排查起點？ #DevOps #card
	- 因為兩者最強的異常訊號出現在不同層
	- `CreateContainerError` 先指向 Pod / Container 建立層
	- LB health check 404 先指向 LB / Ingress 入口與 routing 層
