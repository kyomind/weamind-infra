# 2026-04-09 Infra Gap Reinforcement Report

## 今日主題

- 以缺口補強日的方式，補齊 `CoreDNS` / `Flannel` / `Ingress Controller` / `Secret` 這幾個先前較少被正式展開，但在 WeaMind 架構理解與後續 workshop 前很值得收斂的觀念。

## 狀態

- 已完成

## QA 收斂了什麼

- 今天的互動 QA 主要完成了 `Q2` 到 `Q4`，重點不在重跑舊 lesson，而在把幾個容易混層的基礎概念講準。
- 在 `Flannel` 題裡，已把 `--node-ip` 與 `--flannel-iface` 的作用正式切開，知道前者修 node identity，後者修 overlay 網路承載要走哪張私網介面，也知道底層 Pod 網路壞掉時，外部入口雖然可能跟著出症狀，但不是 `Ingress` 規則本身先壞。
- 在 `Traefik vs Nginx Ingress` 題裡，已把 `Ingress Controller` 的責任收斂成叢集入口層的 `L7 HTTP/HTTPS routing`，並補清楚單機版 `Nginx reverse proxy` 和 Kubernetes `Ingress Controller` 不是同一種東西。
- 在 `Secret` 題裡，已把「`Secret` 不是加密」講準：`base64` 只是表示形式；`ConfigMap` 與 `Secret` 在 API 模型上都屬於配置型資源，但 `Secret` 是被整個系統以敏感資料語意處理的配置資源。
- `Q1` 的 `CoreDNS` 主題今天沒有走完整互動 QA，但已由今日 prework 補起骨架，並和 WeaMind 的 VM 私網依賴脈絡連回「為什麼它在 app YAML 裡相對不顯眼」。

## 使用者原本卡住什麼

- 雖然已經能大致描述 `Flannel`、`Traefik`、`Secret` 這些名詞，但它們各自到底站在哪一層、彼此的責任邊界怎麼切，還不夠穩。
- 對 `--node-ip` 與 `--flannel-iface` 的作用只有直覺，還沒有真的連到「當時的實際指令長什麼樣」與「修完後哪一段路徑恢復」這個層級。
- 對 `Ingress Controller` 的理解接近正確，但還容易把單機版 `Nginx reverse proxy`、Kubernetes `Ingress Controller`，以及 `ingress-nginx` 專案生命週期混在一起講。
- 對 `ConfigMap` 與 `Secret` 的分類判準已經有感覺，但還沒完全語言化「兩者在 Kubernetes 裡作為 resource kind 到底本質差在哪裡」。

## 今日真正留下來的核心收穫

- 我今天真正補起的不是更多名詞，而是幾條很重要的分層邏輯：`overlay network` 和入口 routing 不在同一層、controller 專案和 API 資源不在同一層、`ConfigMap` / `Secret` 的差別也不只是欄位名字不同。
- 我把 `--node-ip` / `--flannel-iface` 這個舊 debug story 從抽象參數，重新拉回成「實際 systemd override 指令 + 修復效果」的可重講故事。
- 我也把 `Secret` 從「比較敏感所以放 Secret」這種直覺，往前推到「Kubernetes 用獨立 kind 明確標示敏感資料，並對它套用不同語意與處理慣例」這一層。

## 學完後已能講清楚什麼

- 能更準確地講清楚 `Flannel`、`--node-ip`、`--flannel-iface`、`Service -> Pod`、`Ingress` 之間的分層與故障傳導關係。
- 能用 2 到 3 句話比較 `Traefik` 與 `Nginx Ingress Controller`，並說明 WeaMind 為什麼以 `Traefik` 為主。
- 能講清楚單機版 `Nginx reverse proxy` 和 Kubernetes `Ingress Controller` 的本質差別。
- 能講清楚 `Secret` 為什麼不是加密、`ConfigMap` / `Secret` 作為 resource kind 的本質差異，以及 WeaMind 目前的分類判準。

## 仍待補強什麼

- `CoreDNS` 今天主要靠 prework 補骨架，若之後要更完整收斂，仍可再補一輪 repo-backed 的短 QA 或觀察題。
- `kube-proxy`、`iptables` / `IPVS`、`etcd encryption` 這些更底層實作還沒有正式展開，目前只建立了邊界與判斷軸。
- `Gateway API`、`ingress-nginx` retirement 後的遷移思路，今天只做到術語校正，還沒有展開成完整主題。

## 下一步

- 用今天收斂出的 flashcards 做短版複習，讓這幾個容易混層的觀念先穩住。
- 若 W5 要正式收尾，可把今天的補強點併入最後的總整理或短版答題稿。
- 之後轉進 W6 `kubectl` workshop 時，今天這些分層邊界會直接變成你判讀輸出與縮圈排查的前置骨架。