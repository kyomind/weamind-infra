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

### NodeSelector 問題補充

- 使用者在 Q2 中追問：Kubernetes 到底怎麼知道哪個 node 是 worker、哪個是 control-plane，因為 `nodepool=worker` 看起來像自訂 label，而不是 Kubernetes 自己保證存在的固定欄位。
- 這題的最小收斂是：`nodeSelector` 比對的是 node labels。`worker` 不是 Kubernetes 自帶的必然身分；像 `nodepool=worker` 這種寫法，通常是叢集管理者額外加在 node 上的自訂 label。
- control-plane 比較常見會帶有內建角色 label，例如 `node-role.kubernetes.io/control-plane`，也常搭配 taint，避免一般 workload 被排上去；worker 端則常以自訂 label 來表達「這批 node 是給哪類 Pod 跑的」。
- 這也表示：Deployment YAML 只寫了 Pod 端的需求，真正的 label 來源是在 cluster node 物件上，而不是這個 app repo 裡另外一份 manifests。
- repo 內已找到直接證據：`PROGRESS.md` 記錄了「對 worker 節點加上 label（`nodepool=worker`），並於 Deployment 加入 `nodeSelector`」，因此這不是單純推測，而是這個專案確實做過的手動設定。
- 同一份 `PROGRESS.md` 也記錄了 K3s 裡 worker 節點的 `ROLES` 顯示為 `<none>` 屬正常行為。這說明 worker 不一定會自然出現在一個固定的內建 role 欄位裡，所以另外加自訂 label 來做排程限制，在這個專案裡是合理且可追溯的。
- `nodepool` 不是唯一正解，它只是這個專案採用的 label key。只要 Pod 端 selector 與 node 端 labels 對得上，像 `disktype=ssd`、`dedicated=ingress`、`topology.kubernetes.io/zone=...` 都可以拿來當排程條件。

## Flashcards

- 待補
