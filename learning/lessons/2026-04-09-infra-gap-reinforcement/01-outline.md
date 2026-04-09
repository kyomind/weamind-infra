# 2026-04-09 Infra Gap Reinforcement Outline

## 今日主題

用一個輕量 lesson，把先前較少展開的 K8s 基礎元件補齊，並回扣 WeaMind repo 裡真正看得到的架構與 debug 故事。

## 這次要解的專案問題

1. CoreDNS 在 Kubernetes 裡解的是什麼問題，為什麼它在 WeaMind 的 app manifests 裡相對不顯眼。
2. Flannel 在這個專案裡解的是哪一層問題，為什麼 `--node-ip` 與 `--flannel-iface` 會影響流量路徑與 cluster network。
3. 為什麼這個 repo 會用 K3s 內建 Traefik，而不是把比較重點放在 Nginx Ingress。
4. 為什麼 Secret 比較像適合存放敏感值的 Kubernetes 資源，而不是加密機制本身。

## 這份 lesson 是否需要外部預習

- 需要
- 原因：CoreDNS 與 Flannel 都屬於今天先前較少碰到的通用 K8s 基礎元件，直接在 lesson 內展開會讓 repo-backed QA 失焦；因此先用一份小型 prework 補最小骨架，再回 repo 做輕量 QA 收斂。

## 要對照的 repo 檔案

1. README.md
2. PROGRESS.md
3. manifests/configmap.yaml
4. manifests/deployment.yaml
5. manifests/ingress.yaml
6. docs/WeaMind Infra核心架構.md
7. docs/LINE-Webhook-切換流程.md
8. learning/lessons/2026-03-31-configmap-secret-basics/04-report.md

## 建議學習順序

1. 先完成 `learning/prework/2026-04-09-coredns-flannel-gap-fill.md`。
2. 回到 `README.md`、`PROGRESS.md` 與 `docs/WeaMind Infra核心架構.md`，把 CoreDNS / Flannel 放回 WeaMind 的實際脈絡。
3. 進入 QA，先講 CoreDNS 與 Flannel，再做 Traefik vs Nginx Ingress 的短比較與 Secret 觀念校正。
4. 不做 command drill，直接在 report 收斂成今天的缺口補強結論。

## 今日 command 練習

- 今天不建立 command drill。
- 原因：今天的目標是補齊少量概念缺口並回扣 repo，重點在答題邊界與分層校正，不在新增操作肌肉記憶。

## 文件分工

1. 01-outline.md：規劃今天主題、範圍與順序。
2. 02-qa.md：記錄今天的補強題、使用者回答摘要與 AI 修正。
3. 04-report.md：收斂今天真正補到的缺口與可口述結論。
4. 05-note.md：記錄延伸問答、暫時結論與後續可帶去 workshop 的補充。

## 這次要追問的 Why / How 題

1. 為什麼 WeaMind 的外部入口講到 Cloudflare / Hetzner LB / Traefik 時，不應把 CoreDNS 一起混進去。
2. 為什麼 `--node-ip` 與 `--flannel-iface` 的問題，一壞掉常常會先影響 cluster network，而不只是單一 app route。
3. 為什麼「Secret 不是加密」在面試裡常是陷阱題，但在這個 repo 裡仍然有明確的實務邏輯。

## 這份 lesson 的完成標準

1. 能用 WeaMind 脈絡講清楚 CoreDNS 與 Flannel 各自站在哪一層。
2. 能說出為什麼 CoreDNS 在這個專案裡相對不顯眼，但仍是 cluster 重要基礎元件。
3. 能用 2 到 3 句話比較 Traefik 與 Nginx Ingress，並說出這個 repo 為什麼以 Traefik 為主。
4. 能解釋 Secret 為什麼不是加密機制，而是較適合存放敏感值的資源型別。