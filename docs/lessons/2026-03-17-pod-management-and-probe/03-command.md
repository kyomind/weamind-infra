# 2026-03-17 Pod Management And Probe Command

## 今日指令練習目標

把今天 lesson 的 probe、排程與 rollout 觀察點對到實際資源：

1. 看出 `weamind` Deployment 現在有哪些 probe 與 nodeSelector 設定。
2. 看出 Pod 目前被排到哪個 node，以及這和 `nodeSelector` 的關係。
3. 區分 rollout 狀態、Pod 事件與應用程式 logs 各自在回答哪一層問題。

## 這次要驗證的路徑或問題

1. `readinessProbe`、`livenessProbe` 與 `nodeSelector` 在執行期如何對回 Deployment / Pod。
2. `weamind` Pod 目前跑在哪些 node，是否符合 worker-only 的預期。
3. 當你要看部署交接、Pod 狀態或應用程式錯誤時，第一個該選哪類指令。

## 今天要看的資源

1. `weamind` namespace 下的 Deployment
2. `weamind` namespace 下的 Pods
3. cluster 內的 Nodes

---

## Command 1

### 要驗證的問題

- 如果你想先確認 `weamind` Deployment 真的有設定 readiness probe、liveness probe 與 `nodeSelector`，第一輪應先看哪個指令。

### 三個可選指令

```bash
kubectl describe deployment weamind -n weamind
kubectl get pods -n weamind -o wide
kubectl rollout status deployment/weamind -n weamind
```

### 為什麼這樣出題

- 這一輪要先站在 Deployment 視角看設定本身，而不是先看 rollout 進度或 Pod 所在 node。

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待補

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 2

### 要驗證的問題

- 如果你想知道目前 `weamind` Pods 被排到哪些 node，以及這是否符合 `nodeSelector.nodepool=worker` 的預期，第一輪應先看哪個指令。

### 三個可選指令

```bash
kubectl get pods -n weamind -o wide
kubectl logs -n weamind deployment/weamind --tail=20
kubectl rollout status deployment/weamind -n weamind
```

### 為什麼這樣出題

- 這一輪的重點是先看到 Pod 與 node 的對應，再視需要補看 node labels。

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待補

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 3

### 要驗證的問題

- 如果部署交接看起來不順，或某個 Pod 明明 Running 卻還沒 Ready，第一輪應優先看哪個指令。

### 三個可選指令

```bash
kubectl rollout status deployment/weamind -n weamind
kubectl describe pod -n weamind <pod-name>
kubectl logs -n weamind <pod-name> --tail=30
```

### 為什麼這樣出題

- 這一輪的重點不是只有一個標準答案，而是要練習先分辨你要驗證的是 Deployment rollout、Pod 事件，還是應用程式輸出。

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待補

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 4

### 要驗證的問題

- 如果你想確認 `nodeSelector.nodepool=worker` 不是空寫在 YAML，而是 cluster 內的 nodes 真的有這個 label，第一輪應先看哪個指令。

### 三個可選指令

```bash
kubectl get nodes -L nodepool
kubectl get deployment weamind -n weamind -o yaml
kubectl get pods -n weamind -o wide
```

### 為什麼這樣出題

- 這一輪要直接驗證 node 物件上的 label 是否存在，所以最直接的入口應該是 nodes，而不是 Deployment 或 Pods。

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待補

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## 最後收斂

- 待完成：今天用哪些指令分開看懂了 probe、nodeSelector、rollout 與 logs。

## 哪些地方還不順手

- 待回填
