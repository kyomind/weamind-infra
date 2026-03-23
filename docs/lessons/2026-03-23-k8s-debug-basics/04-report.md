# 2026-03-23 K8s Debug Basics Report

## 今日主題

把 W3 Day 1 的 debug 概念篇正式落到 WeaMind repo：先用實際流量路徑、manifests 與踩坑故事，建立一套可對回專案的判讀框架。

## 狀態

已完成 Day 1 QA 收斂；今天不做 command drill，Day 2 再進工具語意與最小操作。

## QA 收斂了什麼

- 今天先把抽象 debug 骨架正式對回 WeaMind 的真實元件名稱：`LINE webhook → DNS → Hetzner LB → Traefik Ingress → weamind-line-bot Service → weamind Pods → app`。
- 已把 Ingress backend 的 `service.port.number: 80`、Service 的 `port: 80` 與 `targetPort: 8000` 切開理解，知道它們分別站在 Ingress → Service、Service 入口、Service → Pod 這三個不同層次。
- 已能把 Pending、ImagePullBackOff、CreateContainerError、CrashLoopBackOff 對回 WeaMind repo 裡不同的高價值入口，而不是把四種狀態混成同一種 Pod 故障。
- 已把兩個 WeaMind 真實案例掛回 debug 框架：`CreateContainerError (invalid UTF-8)` 屬於 Pod / Container 建立層；LB health check 未帶 Host header 導致 `/health` 回 404 則優先屬於 LB / Ingress 入口與 routing 層。
- 已明確區分今天的重點是判讀框架與 repo 對照，不是 describe / logs / exec 的工具操作。

## 使用者原本卡住什麼

- 一開始對 Ingress backend 的 `80`、Service 的 `port` 與 `targetPort` 站在哪一層並不穩，容易把它們混成同一個 port 概念。
- 對 Pod 常見異常狀態雖有直覺，但還不夠穩定地把 CreateContainerError 與 CrashLoopBackOff 分開。
- 對外層路由問題與內層 Pod / app 問題的排查起手式，原本還缺少一個可重複使用的判讀骨架。

## 今日真正留下來的核心收穫

- debug 的核心不是先開工具，而是先看最強的異常訊號落在哪一層。
- 同樣是 Pod 有問題，不同狀態其實在提示不同的故障階段，因此第一輪該回 repo 看的位置也不同。
- 外層路由問題與內層 Pod 建立 / app 問題，不能硬用同一條固定起手式；要先排最明顯、最直接的異常。

## 學完後已能講清楚什麼

- 我已能用 WeaMind 的實際元件名稱講出外部請求進到 line-bot Pod 的最小流量路徑。
- 我已能講清楚 Ingress backend 的 Service port、Service 的 `port` 與 `targetPort` 之間的分工。
- 我已能把 Pending、ImagePullBackOff、CreateContainerError、CrashLoopBackOff 對回 WeaMind repo 中最值得優先懷疑的設定區塊。
- 我已能說出 `CreateContainerError (invalid UTF-8)` 與 LB health check 404 各自在提示哪一層問題，以及為什麼不該用同一條排查起點。

## 仍待補強什麼

- Day 2 仍需把 `describe`、`logs`、`logs --previous`、`exec` 這些工具對回今天的分層框架，避免只停在概念判讀。
- 之後仍可補更多 HTTP 狀態碼、timeout 症狀與對應層級之間的直覺對照。
- 今天新增了 `resources.requests / limits` 後，後續可在 Pending / 資源排程題目裡更實際地對照資源設定與排程行為。

## 下一步

- 進入 W3 Day 2：Debug 工具篇。
- 以今天的框架為前提，補 `kubectl describe pod`、`kubectl logs`、`kubectl logs --previous`、`kubectl exec -it` 各自適合看什麼。
