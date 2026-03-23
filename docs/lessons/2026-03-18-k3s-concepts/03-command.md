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
kubectl get nodes -L nodepool
```

### 關鍵輸出

```bash
NAME          STATUS   ROLES           AGE   VERSION        NODEPOOL
weamind-001   Ready    control-plane   71d   v1.34.3+k3s1
weamind-002   Ready    <none>          70d   v1.34.3+k3s1   worker
weamind-003   Ready    <none>          70d   v1.34.3+k3s1   worker
```

### 使用者選擇理由

- 使用者選擇 `kubectl get nodes -L nodepool`，因為這一輪題目要先看節點本身長什麼樣，以及 control-plane 和 worker 在實際輸出中怎麼呈現。
- 使用者也觀察到 `NODEPOOL` 欄位裡只有 `weamind-002` 與 `weamind-003` 有值，而且值是 `worker`；`weamind-001` 沒有這個 label，因此該欄位留空。

### AI 判讀與修正

- 這個選擇是對的。這一輪的目標是先站在 node 視角辨識節點角色與 labels，所以最直接的入口就是 `kubectl get nodes -L nodepool`。
- 你的主判讀也是對的：`weamind-002` 和 `weamind-003` 確實帶有 `nodepool=worker` 這個 label；`weamind-001` 沒有這個 label，所以 `NODEPOOL` 欄位是空的。
- 還要再補一個更關鍵的邊界：在 WeaMind 這個專案裡，真正被拿來做排程限制的是 `nodepool=worker` 這個 node label，不是 `ROLES` 欄位本身。
- 也就是說，worker 節點即使在 `ROLES` 顯示成 `<none>`，仍然不影響它被 `nodeSelector.nodepool=worker` 選中；反過來說，control-plane 不會承接 line-bot workload，也不是因為表格裡寫了 `control-plane`，而是因為它不符合 `nodepool=worker` 這個條件。

### 一句話收斂

- 在 WeaMind 裡，worker 的可控辨識與排程依據是 `nodepool=worker` 這個 node label，不是 `ROLES` 欄位本身。

### 狀態

- 已完成

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
kubectl config view --minify
```

### 關鍵輸出

```bash
apiVersion: v1
clusters:
- cluster:
		certificate-authority-data: DATA+OMITTED
		server: https://127.0.0.1:6443
	name: default
contexts:
- context:
		cluster: default
		user: default
	name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
	user:
		client-certificate-data: DATA+OMITTED
		client-key-data: DATA+OMITTED
```

### 使用者選擇理由

- 使用者選擇 `kubectl config view --minify`，因為這一輪的目標是直接看目前 kubectl 正在使用的 kubeconfig 內容，而不是去看 nodes 或 Deployment。
- 使用者也主動指出一個還不夠確定的點：知道 `config view` 是在看設定，但還不清楚 `--minify` 這個參數代表什麼。

### AI 判讀與修正

- 這個選擇是對的。這一輪要回答的是「kubectl 目前正在用哪個 context，以及這份 kubeconfig 至少包含哪些核心資訊」，所以入口就該直接放在 `kubectl config view --minify`。
- 從你貼回的輸出，可以先收斂三個最小骨架：
- `current-context: default` 代表 kubectl 目前預設使用的是 `default` 這組 context。
- `clusters` 這段回答的是「要連哪個 API server，以及怎麼驗證它」，所以這裡會看到 `server: https://127.0.0.1:6443` 和 `certificate-authority-data`。
- `users` 這段回答的是「要用什麼身分登入」，所以這裡會看到 client certificate 與 client key。
- `contexts` 則是在把 `cluster` 和 `user` 組起來，回答「目前要用哪一組連線組合」。
- 你剛剛問的 `--minify`，更精準的意思是：只顯示目前 active context 相關的最小設定，而不是把 kubeconfig 裡所有 clusters、users、contexts 全部展開。若你的環境未來管理多個 cluster，這個參數會特別有價值，因為它能把你現在真的在用的那一組設定濃縮出來。
- 也就是說，`kubectl config view` 比較像看完整合併後的 kubeconfig；`kubectl config view --minify` 比較像只看「當前這條連線」需要的最小骨架。
- 回到 WeaMind，這份輸出也直接對回今天的 QA：`server` 之所以是 `https://127.0.0.1:6443`，不是因為 API server 跑在你的 Mac 上，而是因為 SSH tunnel 把遠端 control-plane 的 API 入口映射到了本機的 localhost:6443。

### 一句話收斂

- `kubectl config view --minify` 會把當前 active context 的最小 kubeconfig 骨架濃縮出來，讓你直接看出目前 kubectl 正在連哪個 API server、用哪個身分、走哪個 context。

### 狀態

- 已完成

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
kubectl rollout status deployment/weamind -n weamind
```

### 關鍵輸出

```bash
deployment "weamind" successfully rolled out
```

### 使用者選擇理由

- 使用者選擇 `kubectl rollout status deployment/weamind -n weamind`，因為這一輪的題目是要看 rollout 狀態本身，而不是一次把 Deployment 的所有資訊都攤開。
- 使用者也主動收斂出一個很重要的判斷原則：如果只是要看 rollout 狀態，就不應先用 `describe` 或 `get -o yaml` 去看 Deployment，因為那樣雜訊太多，不是這題的第一眼入口。

### AI 判讀與修正

- 這個選擇是對的，而且你的理由也很準。這一輪要回答的是「這次 Deployment rollout 有沒有完成」，所以最直接的入口就是 `kubectl rollout status`。
- 你貼回來的輸出 `deployment "weamind" successfully rolled out`，最小可以先收斂成：從 Deployment controller 的視角看，這次 rollout 已經成功完成，新版本已接手。
- 還要再補一個邊界，避免和今天 QA 的補強題混在一起：`rollout status` 回答的是「結果層」，不是在告訴你 strategy 怎麼設定，也不是在完整列出 Deployment conditions 或單一 Pod 的細節。
- 也就是說，如果今天題目改成「這個 Deployment 用的是哪種更新策略」或「目前有哪些 conditions」，那入口就不會是 `rollout status`，而會改看 Deployment spec / status。
- 但在這一輪這個問題下，你的判斷是最精準的：先用最短路徑確認 rollout 是否完成，再決定要不要往更細的 strategy 或 conditions 下鑽。

### 一句話收斂

- `kubectl rollout status` 最適合先回答「這次 Deployment rollout 有沒有完成」；strategy、conditions 與 Pod 細節則是下一層問題。

### 狀態

- 已完成
