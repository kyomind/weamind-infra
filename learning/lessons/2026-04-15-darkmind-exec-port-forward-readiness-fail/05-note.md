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

<!-- lesson 過程中若出現延伸問答，再補在這裡 -->

## Flashcards

<!-- lesson 收尾後若有穩定卡片素材，再補在這裡 -->
