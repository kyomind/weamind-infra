# 2026-03-11 K3s Traffic Path And Node IP Debug Outline

## 今日主題

把 WeaMind Day 2 的重點正式收斂成一個 repo 內 lesson：完整流量路徑、Traefik 的實際位置，以及 `--node-ip` / `--flannel-iface` 為什麼會成為這個專案的關鍵 debug 點。

## 這次要解的專案問題

1. LINE webhook 請求進來時，實際上是怎麼一路走到 line-bot Pod。
2. Hetzner Load Balancer、Traefik、Service 各自的責任邊界是什麼。
3. 為什麼 K3s 節點必須綁定私有網路介面，而不是讓元件自己抓到公網 IP。
4. `--node-ip` 與 `--flannel-iface` 沒設好時，症狀會出現在流量路徑的哪一段。

## 這份 lesson 是否需要外部預習

這份 lesson 以 repo 內檔案、既有架構文件與真實 debug 脈絡為主，預設不需要先做外部預習。

只有在下面情況才補外部預習：

1. 對 TCP passthrough、TLS termination、overlay network 這些名詞本身完全沒有骨架。
2. 對 `--node-ip` 與 `--flannel-iface` 的作用範圍完全沒有概念，導致無法把症狀對回專案。

## 要對照的 repo 檔案

1. `README.md`
2. `docs/WeaMind Infra核心架構.md`
3. `manifests/ingress.yaml`
4. `manifests/service.yaml`
5. `manifests/deployment.yaml`
6. `docs/LINE-Webhook-切換流程.md`

## 建議學習順序

1. 先用 `README.md` 和 `docs/WeaMind Infra核心架構.md` 確認完整流量骨架。
2. 再對照 `manifests/ingress.yaml` 與 `manifests/service.yaml`，確認 Traefik 後面實際接的是哪個 Service、哪個 port。
3. 接著看 `manifests/deployment.yaml`，把 Service 後面接到的 Pods 與 container port 補齊。
4. 再進入 `qa.md` 的小題，把每一跳的責任邊界和故障現象講清楚。
5. 最後才收斂 `--node-ip`、`--flannel-iface` 與私網綁定的 debug 故事。

## 這次要追問的 Why / How 題

1. 為什麼 Hetzner LB 在這裡做的是 TCP passthrough，而不是直接在 LB 終止 TLS。
2. 為什麼 Traefik 會是流量路徑裡的關鍵點，但 app Service 仍然只需要 `ClusterIP`。
3. 為什麼 K3s 節點若抓錯 IP，問題不只是「網路怪怪的」，而是會直接影響叢集內外的連線路徑。
4. `--node-ip` 與 `--flannel-iface` 各自修的是哪一層問題，它們為什麼常一起出現。
5. 為什麼這個專案特別需要強調「綁定私網介面」這個決策，而不是把它當成安裝細節帶過。

## 這份 lesson 的完成標準

1. 能用自己的話完整講出 `LINE → DNS → Hetzner LB → Traefik → Service → Pod → VM(PostgreSQL/Redis)`。
2. 能說出每一跳是誰在接流量、怎麼決定下一跳、壞掉時大概會看到什麼現象。
3. 能解釋 `--node-ip` 與 `--flannel-iface` 和「綁內網介面」之間的關係。
4. `qa.md` 至少完成 4 題，且每題都有 repo 對照與修正紀錄。