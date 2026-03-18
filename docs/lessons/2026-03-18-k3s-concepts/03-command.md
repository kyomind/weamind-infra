# 2026-03-18 K3s Concepts Command

## 今日指令練習目標

把今天 lesson 的 K3s、kubeconfig 與 rollout 補強對到實際觀察入口：

1. 看出這個叢集目前有哪些 nodes，以及 control-plane / worker 在輸出上怎麼呈現。
2. 看出本機目前 kubectl 實際使用的 context 與 kubeconfig 最小內容。
3. 區分 rollout status、Deployment strategy 與更細的 Deployment 狀態訊號各自在看哪一層。

## 這次要驗證的路徑或問題

1. WeaMind 的 K3s 叢集在 `kubectl get nodes` 的輸出裡，control-plane 與 worker 具體長什麼樣。
2. kubeconfig 不是抽象設定檔，而是當前 kubectl 真正在用的連線入口。
3. rollout 補強題不是再背一次指令，而是把「交接結果」、「策略設定」與「狀態訊號」分開看。

## 今天要看的資源

1. cluster 內的 Nodes
2. 本機 kubectl 的 kubeconfig / context
3. `weamind` namespace 下的 Deployment

---

## Command 1

### 要驗證的問題

- 如果你想先確認這個 K3s 叢集目前有哪些 nodes，以及 control-plane / worker 在輸出上怎麼呈現，第一輪應先看哪個指令。

### 三個可選指令

```bash
kubectl get nodes -L nodepool
kubectl config view --minify
kubectl rollout status deployment/weamind -n weamind
```

### 為什麼這樣出題

- 這一輪要先站在叢集節點視角看角色與 labels，不先跳到 kubeconfig 或 Deployment。

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待回答

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 2

### 要驗證的問題

- 如果你想直接看出本機現在 kubectl 正在用哪個 context，以及 kubeconfig 至少包含哪些核心資訊，第一輪應先看哪個指令。

### 三個可選指令

```bash
kubectl config view --minify
kubectl get nodes -o wide
kubectl describe deployment weamind -n weamind
```

### 為什麼這樣出題

- 這一輪的重點是把 kubeconfig 的抽象名詞對回目前真的在用的連線設定。

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待回答

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## Command 3

### 要驗證的問題

- 如果你想先確認 Deployment rollout 是否完成，但又不把它和 strategy 或 Pod 細節混在一起，第一個該跑哪個指令。

### 三個可選指令

```bash
kubectl rollout status deployment/weamind -n weamind
kubectl get deployment weamind -n weamind -o yaml
kubectl describe pod -n weamind <pod-name>
```

### 為什麼這樣出題

- 這一輪要先把「rollout 是否完成」和「Deployment 裡到底怎麼設定 strategy」拆成兩層。

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待回答

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始
