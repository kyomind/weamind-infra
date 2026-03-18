# 2026-03-18 K3s Concepts Notes

## 學習注意事項

### 外部預習回帶重點

- K3s 是 Kubernetes distribution，不是另一套不同的編排系統；重點是整合與輕量化，而不是脫離 Kubernetes。
- control-plane 主要負責叢集控制與決策，worker 主要負責實際執行 workload。
- Scheduler 屬於 control-plane，負責 Pod placement；kubelet 在 node 上負責把 Pod 真的跑起來。
- kubelet 是透過 watch API Server 得知哪些 Pod 已被指派到自己，而不是由 Scheduler 直接命令 kubelet 啟動 Pod。
- kubeconfig 至少要能回答三件事：連哪個 cluster、用哪個身分、目前預設用哪個 context。

### 今天進 lesson 前先記住的邊界

- 今天不是重學一般 Kubernetes 名詞，而是把 K3s 概念對回 WeaMind 的實際設計決策。
- kubeconfig 題目先聚焦在最小連線骨架，不先展開多 cluster 管理技巧。
- rollout 補強題先處理 `rollout status`、conditions、strategy 的邊界，不先延伸到所有 Deployment controller 細節。

### 待驗證的 repo 對照點

- README 與架構文件裡，K3s 被描述成什麼樣的設計取捨，而不是只寫成「因為輕量」。
- `PROGRESS.md` 裡的 kubeconfig 與 SSH tunnel 設定，如何對回外部預習中學到的 `cluster`、`user`、`context`。
- `manifests/deployment.yaml` 雖然沒有明寫 strategy，但在預設 rolling update 下，`rollout status` 與 conditions 應該怎麼理解。

### 暫時不在今天展開的點

- Scheduler 的具體調度演算法。
- kubelet 與 container runtime 更底層的 CRI 實作細節。
- 多 cluster kubeconfig 管理技巧。

## Notes

## Flashcards
