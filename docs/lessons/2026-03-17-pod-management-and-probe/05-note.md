# 2026-03-17 Pod Management And Probe Note

## 外部預習回帶重點

- liveness probe 的核心問題是「container 是否壞掉到該重啟」，readiness probe 的核心問題是「Pod 現在能不能接流量」，startup probe 則是保護慢啟動應用避免被 liveness 誤殺。
- readiness probe 失敗時，關鍵後果是 Pod 會先從可導流後端清單移除，而不是直接重啟 container。
- `nodeSelector` 是 Pod 對 scheduler 提出的 node label 限制；若找不到符合條件的 node，Pod 會停在 Pending。
- `kubectl logs` 主要看應用程式 stdout / stderr，`kubectl rollout status` 主要看 Deployment rollout 是否完成，兩者不是同一層的健康判斷。
- 最小執行鏈是 Pod 建立後先由 Scheduler 決定 node，再由該 node 上的 kubelet 協調 container runtime 啟動 container。

## 今天進 lesson 前先記住的邊界

- 管理鏈：`Deployment → ReplicaSet → Pod`
- 執行鏈：`Scheduler → kubelet → container runtime`
- probe 題目先處理「用途與失敗後行為」，不要一開始就跳進所有參數細節。
- rollout 題目先處理「它在觀察哪一層」，不要直接把 rollout、Pod events、app logs 混成同一種狀態。

## 待驗證的 repo 對照點

1. 為什麼 WeaMind 的 readiness probe 與 liveness probe 都打 `/health`，但 `initialDelaySeconds` 與 `periodSeconds` 不同。
2. `nodeSelector.nodepool=worker` 是否能直接對回這個專案的 control-plane / worker 分工。
3. 如果某個 Pod 因 probe 或 image 問題卡住，今天的第一個觀察指令應該先落在 Deployment、Pod 事件還是 logs。

## 暫時不在今天展開的點

- startup probe 的實際 YAML 設計與適用條件
- affinity / anti-affinity 與更進階排程策略
- rollout restart 的實作細節與 production 風險評估
