# 2026-04-15 Darkmind Exec Port Forward Readiness Fail Notes

## 學習注意事項

### 今天進 lesson 前先記住的邊界

- `exec` 比較像 container 內部視角；`port-forward` 比較像臨時建立本機到 Pod 或 Service 的 tunnel；兩者都不能直接等同於正式流量路徑已經健康。
- `Running` 不等於 `Ready`；今天要把 Pod process 還活著，和 Service 願不願意把流量送進去，分開看。

### Repo 對照文件與觀察點

- 對照 `darkmind/healthy.yaml` 與 `darkmind/scenarios/readiness-fail.yaml` 的 readiness probe path 差異。
- 對照 `darkmind/README.md` 裡對 `readiness-fail` 的定位：重點不是 container crash，而是 Pod `Running` 但不 `Ready`，並且要把 `Service endpoints` 拉進排查鏈。

### 暫時不在今天展開的點

- 不延伸到 Ingress、Traefik 或正式 WeaMind 流量。
- 不把今天主題拉回 `logs --previous` 或 rollout rollback。

## Notes

### 為什麼多資源 `kubectl get` 會出現 `pod/`、`service/` 前綴

- 當 `kubectl get` 一次查多種資源，例如 `po,svc,endpoints`，輸出裡的名稱欄常會帶上 `pod/`、`service/`、`endpoints/` 這種前綴。
- 這樣做的目的不是資料變了，而是 **在同一份輸出裡明確標示資源種類，避免名稱歧義**。
- 若只查單一資源，例如單獨跑 `kubectl get endpoints -n darkmind`，通常就只顯示資源名稱本身，不再額外加前綴，因為當下上下文已經沒有歧義。

### 為什麼今天先用 Darkmind 練 `port-forward`

- 使用者之前沒有真正操作過 `kubectl port-forward`，這次是第一次把它正式放進 W6 command drill。
- 今天先用 `darkmind-healthy` 這種低風險、輸出面小的情境練，目標不是模擬正式 WeaMind 流量，而是先把 **工具邊界** 練清楚：它是在建立 debug 用的臨時 tunnel，不是在驗證 Ingress / LB / 正式外部流量是否健康。
- 這樣做的好處是可以先把 `exec`、`port-forward`、`readiness`、`endpoints` 四者分清楚，再決定是否把這個技能延伸到真正的 WeaMind Service。

### 後續可延伸的 `port-forward` 練習

- 若今天的 Darkmind 練習順利，後續可安排一輪延伸操作：對真實 WeaMind 的 line-bot Service 做 `kubectl port-forward`，再從本機用 `curl` 驗證應用回應。
- 那一輪延伸練習的重點不在「取代正式流量驗證」，而在 **快速確認某個 Service / Pod port 本身是否有回應**，並體會它和 Ingress 路徑驗證是兩件不同的事。
- 之後若進到 Phase 2 安裝 Grafana，`port-forward` 也會變成實用操作，而不只是 command drill 題材。

### `kubectl exec ... -- sh` 裡的 `--` 是什麼

- 在 `kubectl exec -it -n darkmind deploy/darkmind-healthy -- sh` 這種語法裡，`--` 的作用是 **分隔 `kubectl exec` 自己的參數** 和 **要在 container 裡實際執行的命令**。
- `--` 前面的部分，例如 `-it`、`-n darkmind`、`deploy/darkmind-healthy`，都還是 `kubectl exec` 這個 CLI 本身要解析的內容。
- `--` 後面的 `sh`，才是送進 container 裡執行的命令。所以中間一定要留空格，因為這裡不是一個特殊字串，而是 shell/CLI 解析時的兩個獨立 token：一個是 `--`，下一個是 `sh`。
- 可以把它記成：**`--` 前面是在描述怎麼連進去，`--` 後面才是在描述進去後要跑什麼。**

### 為什麼 `busybox wget -qO- http://127.0.0.1/` 有時能用

- `busybox` 是一個把很多常用 Unix 小工具打包在同一個可執行檔裡的程式，常見於 Alpine 或其他精簡 container 映像。
- 當環境裡沒有獨立的 `wget` 指令時，有些映像仍然會有 `busybox` 這個主程式；這時可以用 `busybox wget ...` 的形式，呼叫它內建的 `wget` applet。
- 原理上比較像是：**不是 shell 自動補出 `wget`，而是你明確要求 `busybox` 這個程式，用它內建的 `wget` 子工具來執行。**
- 所以 `busybox wget -qO- http://127.0.0.1/` 能成功的前提，是 container 裡真的有 `busybox` 這個執行檔，而且它內建了 `wget`。
- 今天這個 nginx:alpine 情境裡，你已經直接驗證到獨立的 `wget` 本身就存在，所以不需要 fallback 到 `busybox wget`；那個寫法只是常見精簡映像裡的備用招。

### `kubectl port-forward` 具體做了什麼

- `kubectl port-forward -n darkmind svc/darkmind-healthy 8080:80` 不會修改 Service 設定，也不會把 Service 暴露到外網。
- 它做的事情是：**在你本機先監聽 `127.0.0.1:8080`，再透過 `kubectl` 與 Kubernetes API 的連線，把這個本機 port 的流量轉送到叢集內目標資源的 `80` port。**
- 所以 `Forwarding from 127.0.0.1:8080 -> 80` 的意思不是「叢集節點開了 8080」，而是 **你自己的電腦現在有一個本地入口 `127.0.0.1:8080`**。
- `Forwarding from [::1]:8080 -> 80` 表示它同時也監聽本機 IPv6 loopback，也就是 `localhost` 這邊同時支援 IPv4 與 IPv6。
- `Handling connection for 8080` 表示真的有一條連線打進本機這個暫時入口；在這次練習裡，這條連線就是另一個終端送出的 `curl -I http://127.0.0.1:8080/`。
- 這個工具最重要的邊界是：**它驗證的是 debug 用的臨時通道，不等於正式 Service / Ingress / LB / 外部流量路徑都已驗證完成。**

### 實務上最常見的 forwarding 對象與情境

- 最常見的是 **forward 到 Service**。情境通常是：你想快速驗證某個應用的 HTTP / TCP port 是否有回應，但不想經過 Ingress、LB 或 DNS。這很適合本地 `curl`、臨時打 API、看內部 dashboard。
- 第二常見的是 **forward 到 Pod**。情境通常是：你要鎖定單一 Pod 做 debug，不想讓 Service 幫你做負載分流，或該 Pod 根本沒有對應的 Service。這對排查單顆 Pod 的差異特別有用。
- 也常見 **forward 到 Deployment**。這本質上是方便寫法，`kubectl` 會幫你找到某個符合條件的 Pod 再建立轉送。適合快速操作，但排查時若你很在意「到底是打到哪一顆 Pod」，通常還是直接指定 Pod 更準。
- ⭐️若是像 Grafana、Prometheus、Argo CD、Kubernetes Dashboard 這類 **叢集內管理 UI**，`port-forward` 幾乎是非常常見的日常操作，因為它能快速在本機瀏覽器打開介面，又不需要先把服務公開出去。
- 真正常見、值得優先熟的實務順序通常是：**Service first、Pod second**。因為 Service 比較接近一般應用入口；Pod 則比較偏向單點 debug。Deployment 類型可以會用，但通常不會是第一個要背熟的主力形態。

### W6D3 command drill 的核心邊界

- `Running`：Pod / container 還在跑。
- `exec`：我可以從 container 內部視角進去看。
- `port-forward`：我可以從本機建立 debug tunnel 打進去。
- `Ready`：Kubernetes 是否判定它已具備接流量能力。
- `endpoints`：Service 最終是否真的把它收進可送流量的後端名單。

- 這五件事必須拆開看，不能混成同一層結論。
- 一個 Pod 可以同時是 `Running`、`exec` 得進去、甚至 `port-forward` 打得到，但 **仍然不是 Ready，也仍然不在 Service 的 `endpoints` 裡**。
- 今天整份 lesson 的價值，就是把「container 還活著」和「Service 願不願意送流量給它」徹底分開。

### 為什麼這份 YAML 會穩定觸發 readiness fail

- 這份 `readiness-fail.yaml` 的主因，確實是 `readinessProbe` 去打了一個不存在的路徑：`/darkmind-missing-health`
- 這個情境之所以穩定成立，不只是一個 path 寫錯而已，而是整組條件有刻意配好：container 正常啟動、port 對得上、Service selector 對得上，但 readiness probe 會持續失敗
- `livenessProbe` 打的是 `/`，所以 container 不會因為 liveness fail 被重啟
- 因此最後會形成今天要的狀態：Pod / container 還活著，但 Pod 不 Ready，而且 Service 不會把它收進 `endpoints`

### `kubectl describe` 裡的 `#success=1 #failure=3` 代表什麼

- 在 `kubectl describe deploy` 或 `kubectl describe pod` 的 probe 顯示裡，`#success=1` 和 `#failure=3` 不是「目前已成功幾次、失敗幾次」的統計值
- 它們代表的是 probe 設定裡的 **`successThreshold`** 與 **`failureThreshold`**
- 所以 `Readiness: http-get ... #success=1 #failure=3` 的意思是：這個 probe 需要 **連續 1 次成功** 才算通過，連續 **3 次失敗** 才算失敗
- 這裡的 `#success=1` 是預設門檻，不代表這個不存在的端點真的成功過一次
- 也就是說，就算 `/darkmind-missing-health` 理論上不可能成功，`kubectl describe` 仍會印出 `#success=1`，因為它顯示的是 probe 規格，不是執行歷史

### 如何從 `readiness-fail.yaml` 直接推導出最後會看到什麼

- 第一個先看的是 container 本身會不會啟動。這份 YAML 用的是標準 `nginx:1.27-alpine`，port 也是常見的 `80`，所以沒有刻意設計成 crash 或 image pull fail 類問題
- 第二個看 `readinessProbe`。它打的是 `/darkmind-missing-health`，對標準 nginx 來說這不是預設存在的路徑，所以 probe 預期會持續失敗
- 第三個看 `livenessProbe`。它打的是 `/`，而 `/` 對 nginx 會正常回頁面，所以 liveness 不會失敗，container 也不會因為 liveness 被重啟
- 第四個看 Service selector 與 port。這份 YAML 的 selector 與 Pod label 是對得上的，Service port 與 targetPort 也對得上，所以不是 selector 寫錯或 port 接錯導致沒有後端
- 把前面四件事合起來，就能直接推導出最後狀態：**Pod / container 會活著，所以會看到 `Running`；但 readiness 會失敗，所以會看到 `0/1 Ready`；因為 Pod 不 Ready，所以 Service 的 `endpoints` 會是空的**
- 也就是說，這份 YAML 最值得練的不是「怎麼把 probe 寫壞」，而是 **如何從 probe、liveness、selector、Service 這幾塊配置，預先推導出 Pod 與 `endpoints` 會呈現什麼狀態**

## Flashcards

- `Running` 和 `Ready` 差在哪裡？ #DevOps #card
	- `Running` 比較接近 Pod / container 已啟動在跑
	- `Ready` 比較接近是否已具備接流量能力
	- Pod 可以是 `Running`，但仍然不是 `Ready`

- 為什麼 `readinessProbe` 失敗時一定要看 `endpoints`？ #DevOps #card
	- Pod 狀態只能回答它還活不活著
	- `endpoints` 才回答 Service 會不會真的送流量給它
	- `endpoints` 空白代表它不是目前可送流量的後端

- `kubectl exec` 真正證明的是什麼？ #DevOps #card
	- 它先證明 container 仍可互動、可進入內部視角
	- 單靠進得去 shell，不等於服務本身已正常回應
	- 還要在 container 內補打 `127.0.0.1` 或做最小服務驗證

- `kubectl port-forward` 真正證明的是什麼？ #DevOps #card
	- 它在本機建立 debug 用的臨時 tunnel
	- 證明我能從本機透過 `kubectl` 打到目標 Pod / Service port
	- 不等於正式 Ingress / LB / 外部流量路徑都已健康

- `readiness-fail` 情境最關鍵的判讀句是什麼？ #DevOps #card
	- Pod 可以是 `0/1 Running`
	- `exec` 也仍可能成功
	- 但 `endpoints` 依然可以是空的
	- 這表示 container 還活著，不代表 Service 會送流量給它

- 實務上最常見的 `port-forward` 對象是哪兩種？ #DevOps #card
	- `Service` 最常見，適合快速驗證應用入口或內部 UI
	- `Pod` 次常見，適合鎖定單顆 Pod 做單點 debug
	- 排查時若在意到底打到哪顆 Pod，直接指定 Pod 更準
