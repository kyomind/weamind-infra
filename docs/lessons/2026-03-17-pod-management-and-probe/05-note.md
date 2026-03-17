# 2026-03-17 Pod Management And Probe Notes

## 學習注意事項

### 外部預習回帶重點

- liveness probe 的核心問題是「container 是否壞掉到該重啟」，readiness probe 的核心問題是「Pod 現在能不能接流量」，startup probe 則是保護慢啟動應用避免被 liveness 誤殺。
- readiness probe 失敗時，關鍵後果是 Pod 會先從可導流後端清單移除，而不是直接重啟 container。
- `nodeSelector` 是 Pod 對 scheduler 提出的 node label 限制；若找不到符合條件的 node，Pod 會停在 Pending。
- `kubectl logs` 主要看應用程式 stdout / stderr，`kubectl rollout status` 主要看 Deployment rollout 是否完成，兩者不是同一層的健康判斷。
- 最小執行鏈是 Pod 建立後先由 Scheduler 決定 node，再由該 node 上的 kubelet 協調 container runtime 啟動 container。

### 今天進 lesson 前先記住的邊界

- 管理鏈是 `Deployment → ReplicaSet → Pod`。
- 執行鏈是 `Scheduler → kubelet → container runtime`。
- probe 題目先處理用途與失敗後行為，不要一開始就跳進所有參數細節。
- rollout 題目先處理它在觀察哪一層，不要直接把 rollout、Pod events、app logs 混成同一種狀態。

### 待驗證的 repo 對照點

- 為什麼 WeaMind 的 readiness probe 與 liveness probe 都打 `/health`，但 `initialDelaySeconds` 與 `periodSeconds` 不同。
- `nodeSelector.nodepool=worker` 是否能直接對回這個專案的 control-plane / worker 分工。
- 如果某個 Pod 因 probe 或 image 問題卡住，今天的第一個觀察指令應該先落在 Deployment、Pod 事件還是 logs。

### 暫時不在今天展開的點

- startup probe 的實際 YAML 設計與適用條件。
- affinity / anti-affinity 與更進階排程策略。
- rollout restart 的實作細節與 production 風險評估。

## Notes

### Probe 問題補充

- 使用者在 Q1 後追問：readiness probe 與 liveness probe 都打同一個 `/health`，Kubernetes 到底怎麼分辨這次失敗該算 readiness fail 還是 liveness fail。
- 這題的最小收斂是：差異不是由應用在 response 裡主動標記，而是 kubelet 本來就分別執行兩組不同的 probe 設定。即使 path 相同，kubelet 仍知道這次檢查屬於 readiness 還是 liveness，並套用不同後續處理。
- readiness 失敗的直接後果是 Pod 被標成 NotReady，先從可導流後端清單移除；liveness 失敗的直接後果則是 kubelet 依探針結果觸發 container restart。
- 同一路徑同時承擔 readiness 與 liveness，代表「停止導流」與「觸發重啟」兩種責任被綁在一起。對簡單服務可以接受，但系統變複雜後，常會拆成不同判斷邏輯以降低耦合。

## Flashcards

- 待補
