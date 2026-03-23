# 2026-03-23 K8s Debug Basics Note

## 外部預習摘要

- 今天先建立的是通用 debug 心智模型，不是工具清單。
- debug 的核心不是先開 `logs`、`describe`、`exec`，而是先判斷自己正在驗證哪一層。
- 排查方向不是固定只由外到內或只由內到外，而是看目前最強的異常訊號在哪裡。
- Pod 狀態是第一個高價值訊號：Pending、ImagePullBackOff、CreateContainerError、CrashLoopBackOff 分別對應不同階段的問題。
- 若外部請求完全沒進來，通常先走外到內；若 Pod 自己已出現明顯異常訊號，通常可先把注意力收斂到 Pod / app 內層。

## 今天已先對齊的 repo 對照方向

- WeaMind 的外部流量骨架可先對回：LINE webhook → DNS → Hetzner LB → Traefik Ingress → `weamind-line-bot` Service → `weamind` Pods → app。
- `manifests/deployment.yaml` 內的 image、`envFrom`、command、probe 與 `nodeSelector`，都是 Day 1 判讀 Pod 問題時的高價值觀察點。
- `manifests/service.yaml` 與 `manifests/ingress.yaml` 則是切 Service / Ingress 層問題時最直接的 repo 入口。
- `PROGRESS.md` 已提供至少兩個可直接掛回今天框架的真實案例：`CreateContainerError (invalid UTF-8)` 與 LB health check 未帶 Host header 導致 `/health` 回 404。

## 待在 QA 中收斂的重點

- 抽象骨架如何完整對回 WeaMind 的真實元件名稱。
- 不同 Pod 狀態在這個 repo 裡各自應優先對照哪些設定。
- 哪些真實故事比較像外層流量路徑問題，哪些比較像內層 Pod / app 問題。

## 銜接 Day 2 的提醒

- 今天先不要把 `describe`、`logs`、`logs --previous`、`exec` 的細節全部混進來。
- Day 2 再把工具對回今天的框架，回答「當我懷疑這一層時，該用哪個工具拿證據」。
