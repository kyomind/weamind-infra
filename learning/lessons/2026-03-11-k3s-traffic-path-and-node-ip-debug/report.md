# 2026-03-11 K3s Traffic Path And Node IP Debug Report

## 今日主題

把 WeaMind Day 2 的主題正式收斂成 repo 內 lesson：完整流量路徑、Traefik 的實際角色，以及 `--node-ip` / `--flannel-iface` 的 debug 故事。

## 狀態

這份 report 已依本次 lesson 的實際對話回填完成。

## 這次對話實際學了什麼

- 我把 Day 2 的完整流量路徑正式收斂到 WeaMind 專案脈絡裡，能從 repo 檔案與既有文件出發，完整講出 `LINE → DNS → Hetzner LB → Traefik → weamind-line-bot Service → Pods`。
- 我更精準地釐清了 Hetzner LB、Traefik、`weamind-line-bot` Service 三者的責任邊界：LB 接外部流量，Traefik 依 Ingress 規則做 L7 路由，Service 在 cluster 內提供穩定入口並把流量分到 Pods。
- 我把 Traefik 的對外入口這件事補回了歷史實作脈絡，知道目前正式 repo 文件雖然沒有直接管理 Traefik service YAML，但從歷史對話可補到它曾以 `LoadBalancer` type 出現，並伴隨 K3s ServiceLB / NodePort 類入口。
- 我也正式補上 `--node-ip` 與 `--flannel-iface` 的作用，理解它們不是在修 Ingress 或 app，而是在修 node address 與 overlay 網路介面。
- 最後，我建立了這個專案在 webhook 進不來時的第一輪排查順序：先看 nodes / pods / endpoints，再看 Ingress / Traefik，最後才看 DNS、Hetzner LB、Webhook URL。

## 使用者原本卡住什麼

- 一開始對 Traefik 在這個專案裡的實際入口形式沒有把握，容易把歷史記憶中的 NodePort、LoadBalancer、worker 節點入口混在一起講。
- 對 `--node-ip` 與 `--flannel-iface` 的參數作用沒有穩定理解，知道它們很重要，但無法清楚拆成各自修哪一層問題。
- 面對較大的 debug 題時，容易因為題目範圍太大而卡住，不知道應該先從哪一層開始思考。

## 對話中釐清的關鍵點

- [manifests/ingress.yaml](manifests/ingress.yaml#L1) 只負責宣告 `k8s.kyomind.tw` 應轉到 `weamind-line-bot:80`；真正執行規則的是 Traefik。
- [manifests/service.yaml](manifests/service.yaml#L1) 的 `ClusterIP` 在這個專案裡是合理設計，因為外部入口已由 Hetzner LB 與 Traefik 承接。
- [manifests/deployment.yaml](manifests/deployment.yaml#L1) 與 Service selector 對得起來，表示 app Service 後面實際依賴的是 Deployment 建出的 Pods。
- [README.md](README.md#L84) 與 [docs/WeaMind Infra核心架構.md](docs/WeaMind%20Infra核心架構.md#L12) 支撐目前正式架構說法：Hetzner LB 做 TCP passthrough，TLS termination 在 Traefik。
- 歷史對話可補到更細的實作細節：Traefik service 曾顯示為 `LoadBalancer`，對外入口為 `80:30417/TCP,443:31051/TCP`，且有 `svclb-traefik` Pods 參與節點入口建立。
- `--node-ip` 修的是 node 宣告自己的位址，`--flannel-iface` 修的是 Flannel / overlay 網路走哪張私網介面；兩者常要一起設定。
- 若 node 誤抓成公網 IP，最早出事的是節點彼此與叢集網路層；外部流量失敗通常只是後續可見症狀。

## 學完後已能講清楚什麼

- 能完整講出 WeaMind 的 Day 2 流量路徑，且不再把 DNS、LB、Traefik、Service、Pods 的責任混在一起。
- 能說清楚為什麼 `weamind-line-bot` 使用 `ClusterIP` 是合理的，以及為什麼 Traefik 不直接依賴 Pod IP。
- 能更精準地說明 Traefik 在這個專案裡的角色與入口形式，並區分正式 repo 文件與歷史對話補到的細節。
- 能解釋為什麼這個專案要強調綁定私有網路介面，以及 `--node-ip` / `--flannel-iface` 各自在修哪一層問題。
- 能講出 webhook 進不來時，第一輪排查順序為什麼應先內後外，而不是直接從 DNS 開始。

## 仍待補強什麼

- 還沒有把 Pod 如何透過私網連到原 VM 上的 PostgreSQL / Redis 正式收斂成 Day 3 的 lesson。
- 還需要把 Service、Endpoints、Pod 三者在執行期如何對應的觀察再和實際 `kubectl` 輸出連得更緊。
- 之後可再補一版更短的面試口語版答案，讓 Day 2 的重點能在 30 到 60 秒內講完。

## 下一步

- 進入 Day 3，處理 Pod 如何連到 VM 上的 PostgreSQL / Redis。
- 補 Service、Endpoints、Pod 的動態對照與最小排查操作。