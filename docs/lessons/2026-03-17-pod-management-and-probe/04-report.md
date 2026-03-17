# 2026-03-17 Pod Management And Probe Report

## 今日主題

從 WeaMind 的 `manifests/deployment.yaml` 收斂 readiness probe、liveness probe、nodeSelector，以及 rollout 觀察指令與最小執行鏈的邊界。

## 狀態

已完成。

## QA 收斂了什麼

- readiness probe 與 liveness probe 雖然都打 `/health`，但差異不在應用額外回傳不同內容，而在 kubelet 會分別執行兩組 probe 設定，並套用不同後續處理。
- readiness probe 失敗時，重點是 Pod 先從可導流後端清單移除；liveness probe 失敗時，重點是 container 會被重啟。
- `nodeSelector.nodepool=worker` 在 WeaMind 裡不是抽象排程設定，而是用來把 line-bot workload 固定在 worker，避免 control-plane 同時承擔叢集控制與 app 負載。
- 管理鏈 `Deployment → ReplicaSet → Pod` 與執行鏈 `Scheduler → kubelet → container runtime` 已能分開講清楚，不再把控制器責任與節點執行責任混在一起。

## 使用者原本卡住什麼

- 雖然已能說出 probe 與 nodeSelector 的基本定義，但原本還不夠確定同一個 `/health` 如何被區分為 readiness 或 liveness。
- 一開始也對 `kubectl describe` 裡的 `http://:http/health` 顯示格式，以及 `name: http` 這種 port 命名方式感到混淆。
- 在 command 題目裡，使用者準確指出原本把 Deployment rollout、Pod Running 但 NotReady、app logs 三種問題混成同一題，導致指令選擇不夠乾淨。

## 今日 command 練習收斂

- `kubectl describe deployment weamind -n weamind` 最適合先確認 Deployment 模板裡是否真的有 readiness probe、liveness probe 與 `nodeSelector`。
- `kubectl get pods -n weamind -o wide` 先回答的是 Pod 落到哪些 nodes；若要證明符合 `nodeSelector.nodepool=worker`，仍需補看 `kubectl get nodes -L nodepool`。
- 在觀察層級上，已能穩定分開：`kubectl rollout status` 看 Deployment 交接、`kubectl describe pod` 看 Pod 狀態與事件、`kubectl logs` 看 container 內應用程式輸出。

## 今日真正留下來的核心收穫

- probe、nodeSelector 與 rollout 不只是 YAML 欄位名，而是可以對回具體觀察入口的執行期概念。
- 真正高價值的不是背指令，而是知道每個指令各自只能回答哪一層問題，不替它腦補超過證據邊界的結論。

## 學完後已能講清楚什麼

- 我已能講清楚 readiness probe 與 liveness probe 的差異，包含失敗後各自的直接後果。
- 我已能講清楚 `nodeSelector.nodepool=worker` 在 WeaMind 中的角色，以及為什麼還要另外去看 node labels 才算證據完整。
- 我已能講清楚三種常見觀察入口的分工：Deployment rollout、Pod 狀態與事件、應用程式 logs。
- 我也已能講清楚管理鏈與最小執行鏈是兩條不同的責任路徑。

## 仍待補強什麼

- 之後還需要補一輪真正有異常訊號的 Pod 觀察案例，讓 `describe pod`、`logs` 與 probe fail 的判讀更有手感。
- 還可以再補 Deployment 的 `conditions`、`rollout status` 與 rolling update strategy 之間更細的對照。

## 下一步

- 進入 W2 Day 3：K3s 概念篇，補 control-plane / worker 分工、為什麼選 K3s，以及 kubeconfig 的基本結構。
