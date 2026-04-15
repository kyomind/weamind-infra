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

### 為什麼今天先用 Darkmind 練 `port-forward`

- 使用者之前沒有真正操作過 `kubectl port-forward`，這次是第一次把它正式放進 W6 command drill。
- 今天先用 `darkmind-healthy` 這種低風險、輸出面小的情境練，目標不是模擬正式 WeaMind 流量，而是先把 **工具邊界** 練清楚：它是在建立 debug 用的臨時 tunnel，不是在驗證 Ingress / LB / 正式外部流量是否健康。
- 這樣做的好處是可以先把 `exec`、`port-forward`、`readiness`、`endpoints` 四者分清楚，再決定是否把這個技能延伸到真正的 WeaMind Service。

### 後續可延伸的 `port-forward` 練習

- 若今天的 Darkmind 練習順利，後續可安排一輪延伸操作：對真實 WeaMind 的 line-bot Service 做 `kubectl port-forward`，再從本機用 `curl` 驗證應用回應。
- 那一輪延伸練習的重點不在「取代正式流量驗證」，而在 **快速確認某個 Service / Pod port 本身是否有回應**，並體會它和 Ingress 路徑驗證是兩件不同的事。
- 之後若進到 Phase 2 安裝 Grafana，`port-forward` 也會變成實用操作，而不只是 command drill 題材。

## Flashcards

<!-- lesson 收尾後若有穩定卡片素材，再補在這裡 -->
