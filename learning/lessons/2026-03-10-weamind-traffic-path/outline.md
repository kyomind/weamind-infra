# 2026-03-10 WeaMind Traffic Path Outline

## 今日主題

把 Day 1 與 Day 2 的 networking 概念，正式對到 WeaMind 專案裡的實際流量路徑。

## 這次要解的專案問題

1. WeaMind 的外部流量實際上先經過哪些層。
2. 為什麼 `weamind-line-bot` Service 用 `ClusterIP` 反而合理。
3. Traefik 在這個專案裡扮演的是什麼角色，而不是只停在名詞理解。

## 要對照的 repo 檔案

1. `manifests/service.yaml`
2. `manifests/ingress.yaml`
3. `README.md`
4. `docs/WeaMind Infra核心架構.md`

## 建議學習順序

1. 先跑 `qa.md` 中的 3 到 5 題小題，不一次問太大題。
2. 每一題都優先回到 repo 看實際 YAML 或文件，再回答。
3. 題目完成後，再回頭整理今天的流量骨架與角色邊界。
4. 最後才把這次真正確認過的理解寫進 `report.md`。

## 這次要追問的 Why / How 題

1. 為什麼在 WeaMind 這個專案裡，line-bot Service 用 ClusterIP 是合理的。
2. 如果 Service 已經會分配流量，為什麼還需要 Ingress 和 Traefik。
3. Hetzner LB、Traefik、Service 三者的責任邊界各是什麼。
4. 如果外部請求進不來，這條路徑上第一輪應該先查哪幾層。

## 這份 lesson 的完成標準

1. 能用自己的話講出 `Client / LINE → DNS → Hetzner LB → Traefik → Service → Pods`。
2. 能說明 `ClusterIP` 在這個架構裡為什麼不是限制，反而是合理分工。
3. 能分清楚 external LB、Ingress Controller、Service 各自在做什麼。
4. `qa.md` 中的題目至少完成 3 題，且每題都有回答摘要與修正紀錄。