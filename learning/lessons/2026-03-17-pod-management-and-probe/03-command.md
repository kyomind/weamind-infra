# 2026-03-17 Pod Management And Probe Command

## 今日指令練習目標

把今天 lesson 的 probe、排程與 rollout 觀察點對到實際資源：

1. 看出 `weamind` Deployment 現在有哪些 probe 與 `nodeSelector` 設定。
2. 看出 Pod 目前被排到哪個 node，以及這和 `nodeSelector` 的關係。
3. 區分 rollout 狀態、Pod 事件與應用程式 logs 各自在回答哪一層問題。

## 這次要驗證的路徑或問題

1. `readinessProbe`、`livenessProbe` 與 `nodeSelector` 在執行期如何對回 Deployment / Pod。
2. `weamind` Pod 目前跑在哪些 nodes，是否符合 worker-only 的預期。
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
kubectl describe deployment weamind -n weamind
```

### 關鍵輸出

```bash
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
Liveness:   http-get http://:http/health delay=15s timeout=1s period=20s #success=1 #failure=3
Readiness:  http-get http://:http/health delay=5s timeout=1s period=10s #success=1 #failure=3
Node-Selectors:     nodepool=worker
```

### 使用者選擇理由

- 使用者選擇 `kubectl describe deployment weamind -n weamind`，因為這一輪目標是直接確認 Deployment 本身的細節，而不是先看 Pod 所在 node 或 rollout 進度。
- 使用者也提到自己平常就常用 `describe` 來看 Deployment，因此直覺上會先從這裡切入。

### AI 判讀與修正

- 這個選擇是對的。這一輪的關鍵不是先看執行期分散在哪些 Pod，而是先確認 Deployment 模板裡是否真的有宣告 probe 與 `nodeSelector`。
- 你貼回的輸出也確實一次回答了三件事：有 readiness probe、有 liveness probe、而且有 `Node-Selectors: nodepool=worker`。
- `http://:http/health` 裡的 `:http` 指的是命名 port，不是 domain；host 留白代表 probe 預設對 Pod 自己發請求。

### 一句話收斂

- 要先確認 Deployment 是否真的宣告了 probe 與 `nodeSelector`，第一眼先看 `kubectl describe deployment` 最直接；其中 `:http` 指的是命名 port，不是 domain。

### 狀態

- 已完成

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
kubectl get pods -n weamind -o wide
```

### 關鍵輸出

```bash
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
weamind-5985b7f7f6-t2qpm   1/1     Running   0          56d   10.42.1.14   weamind-002   <none>           <none>
weamind-5985b7f7f6-wdptx   1/1     Running   0          56d   10.42.2.13   weamind-003   <none>           <none>
```

### 使用者選擇理由

- 使用者選擇 `kubectl get pods -n weamind -o wide`，因為這一輪題目是要先看 Pod 目前落在哪些 nodes，所以直覺上應先從 Pod 清單與 node 對應關係切入。
- 使用者也主動指出一個很關鍵的限制：這個指令雖然能看出 Pods 在 `weamind-002` 與 `weamind-003` 上執行，但它本身不能百分之百證明這兩台 node 真的帶有 `nodepool=worker` label。

### AI 判讀與修正

- 這個選擇是對的。`kubectl get pods -o wide` 可以先回答「目前 Pods 落在哪些 nodes」，但不能單靠這個輸出就證明「這些 nodes 符合 `nodeSelector.nodepool=worker`」。
- 所以這一輪最好的收斂不是「它已完整證明 nodeSelector 生效」，而是「它先提供了 Pod-to-node 對照，讓你知道接下來該往哪台 node 驗證 label」。

### 一句話收斂

- `kubectl get pods -o wide` 先回答的是 Pod 目前被排到哪些 nodes；若要進一步確認是否真的符合 `nodeSelector.nodepool=worker`，還要再補看 node labels。

### 狀態

- 已完成

---

## Command 3

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
kubectl get nodes -L nodepool
```

### 關鍵輸出

```bash
NAME          STATUS   ROLES           AGE   VERSION        NODEPOOL
weamind-001   Ready    control-plane   70d   v1.34.3+k3s1
weamind-002   Ready    <none>          69d   v1.34.3+k3s1   worker
weamind-003   Ready    <none>          69d   v1.34.3+k3s1   worker
```

### 使用者選擇理由

- 使用者指出這一輪目標是直接驗證 node 物件上的 label 是否存在，因此入口應該直接放在 nodes，而不是 Deployment 或 Pods。
- ⭐️使用者也進一步觀察到 `-L nodepool` 是在指定要**額外顯示哪個 label key**，並追問除了這種指定單一 label 的查法之外，是否也有更 general 的方式可以看所有 node labels。

### AI 判讀與修正

- 這個選擇是對的，而且你對 `-L` 的理解也正確。這份輸出把前一輪缺的證據補齊了：`weamind-002` 與 `weamind-003` 的 `NODEPOOL` 都是 `worker`，因此現在才可以更完整地說，weamind Pods 目前確實被排到符合 `nodeSelector.nodepool=worker` 的 nodes 上。
- `weamind-001` 的 `ROLES` 顯示為 `control-plane`，而兩台 worker 的 `ROLES` 是 `<none>`，這也再次說明 worker 不一定會自然出現在固定 role 欄位裡，所以另外加 `nodepool=worker` 這種自訂 label 來限制排程是合理做法。

### 一句話收斂

- `kubectl get nodes -L nodepool` 能補齊 node label 證據，證明 weamind Pods 落到的節點確實符合 `nodeSelector.nodepool=worker`。

### 狀態

- 已完成

---

## Command 4

### 要驗證的問題

- 情境 A：如果你要先確認 Deployment rollout 有沒有完成，第一個該跑哪個指令。

### 三個可選指令

```bash
kubectl rollout status deployment/weamind -n weamind
kubectl describe pod -n weamind <pod-name>
kubectl logs -n weamind <pod-name> --tail=30
```

### 為什麼這樣出題

- 原本「rollout、Running 但 NotReady、app 報錯」混在同一題，會把不同層級的問題混掉；這裡拆成單一情境。

### 指令

```bash
kubectl rollout status deployment/weamind -n weamind
```

### 關鍵輸出

```bash
deployment "weamind" successfully rolled out
```

### 使用者選擇理由

- 使用者先選 `kubectl rollout status deployment/weamind -n weamind`，因為若 Deployment 本身沒有順利交接完成，那麼服務不正常就不會太意外，應先確認 rollout 是否成功。
- 使用者也追問：若 Pod 明明是 Running 但還沒 Ready，是否也能只靠 `rollout status` 來推論。

### AI 判讀與修正

- 這個選擇在「先看 Deployment 交接有沒有完成」這個情境下是對的。`kubectl rollout status` 回答的是 Deployment controller 這一層：最新 rollout 是否已達到完成狀態。
- 但它不能直接等同於「應用一定正常」或「此刻所有 Pod 細節都完全沒問題」。若 rollout 正在進行中，而新 Pod 因 readiness 過不了所以遲遲無法變成可用，`rollout status` 常會卡住或顯示尚未完成；一旦它已回報 `successfully rolled out`，你只能先收斂成「這次 rollout 曾成功完成」，不能只靠這句話就對當下單一 Pod 的 readiness 狀態做完整推論。

### 一句話收斂

- `kubectl rollout status` 很適合先查 Deployment 交接是否完成，但不能取代對單一 Pod readiness 或 app logs 的排查。

### 狀態

- 已完成

---

## Command 5

### 要驗證的問題

- 情境 B：如果某個 Pod 明明 Running，但 READY 顯示 `0/1`，第一個該跑哪個指令。

### 三個可選指令

```bash
kubectl rollout status deployment/weamind -n weamind
kubectl describe pod -n weamind <pod-name>
kubectl logs -n weamind <pod-name> --tail=30
```

### 為什麼這樣出題

- 這一輪要先站在 Pod 層看 conditions、events、restart 與 probe 相關訊號，不先跳到 app logs。

### 指令

```bash
kubectl describe pod -n weamind weamind-5985b7f7f6-t2qpm
```

### 關鍵輸出

```bash
Status:           Running
Ready:            True
Restart Count:    0
Liveness:         http-get http://:http/health delay=15s timeout=1s period=20s #success=1 #failure=3
Readiness:        http-get http://:http/health delay=5s timeout=1s period=10s #success=1 #failure=3
Conditions:
	Ready                       True
	ContainersReady             True
Events:                      <none>
```

### 使用者選擇理由

- 使用者選擇先看 `kubectl describe pod`，因為若題目是 Pod Running 但還沒 Ready，會想先直接看 probe、conditions 與 Pod 狀態本身。
- 使用者也補充，若 `describe pod` 沒有給出足夠線索，下一步才會再看 `kubectl logs`。

### AI 判讀與修正

- 這個順序是合理的。若題目是「某個 Pod 明明 Running，但 READY 是 `0/1`」，第一個最穩的入口通常就是 `describe pod`，因為它最容易同時看到 Pod conditions、container state、restart count、probe 設定，以及 events。
- 這次因為觀察的是健康 Pod，所以輸出裡看到的是 `Ready: True`、`Restart Count: 0`、`Events: <none>`。這剛好說明健康 Pod 的 `describe` 主要是在告訴你「目前沒有異常跡象」，而不是主動展示失敗案例。

### 一句話收斂

- `kubectl describe pod` 是排查 Running 但 NotReady 的第一個狀態面板；若它沒有給足夠線索，再補看 logs。

### 狀態

- 已完成

---

## Command 6

### 要驗證的問題

- 情境 C：如果你高度懷疑問題在 container 內的應用程式本身，第一個該跑哪個指令。

### 三個可選指令

```bash
kubectl rollout status deployment/weamind -n weamind
kubectl describe pod -n weamind <pod-name>
kubectl logs -n weamind <pod-name> --tail=30
```

### 為什麼這樣出題

- 這一輪要刻意切到 app process 視角，而不是 Deployment 或 Pod 事件層。

### 指令

```bash
kubectl logs -n weamind weamind-5985b7f7f6-t2qpm --tail=30
```

### 關鍵輸出

```bash
INFO:     10.42.0.9:33476 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.1.1:50232 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.1.1:50248 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.1.1:40864 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.0.9:43164 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.1.1:44716 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.1.1:44718 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.0.9:51248 - "GET /health HTTP/1.1" 200 OK
```

### 使用者選擇理由

- 使用者表示，如果高度確定是 container 裡面的應用程式問題，第一個就會看 `kubectl logs`，因為這時它幾乎就是最直接的入口。
- 這次雖然 container 本身沒有異常，輸出主要只看到 `/health` 的 `200 OK`，但使用者也指出這仍然很重要，因為 logs 本來就是用來確認 app process 是否真的有報錯。

### AI 判讀與修正

- 這個選擇是對的。當懷疑點已經明確落在 app process 本身時，`kubectl logs` 就是最直接的第一步。
- 這次因為容器健康，所以只看到健康檢查相關的 `200 OK` 記錄；這反而能作為一個反向訊號，表示目前至少從應用程式輸出來看，沒有立即可見的 exception 或 crash 痕跡。
- 但也要記得：logs 主要回答的是 app 輸出，不直接取代 Pod events 或 rollout 狀態。若問題層級拿不準，仍然應先把「Deployment、Pod、app」三層切開再看。

### 一句話收斂

- 當懷疑點已經明確落在 container 內的應用程式時，第一眼先看 `kubectl logs`；它回答的是 app 自己輸出了什麼。

### 狀態

- 已完成

---

## 最後收斂

- 今天用 `kubectl describe deployment` 確認 probe 與 `nodeSelector` 設定，用 `kubectl get pods -o wide` 看 Pod-to-node 對照，用 `kubectl get nodes -L nodepool` 補齊 label 證據。
- 在觀察指令語意上，也把三種入口拆乾淨了：`rollout status` 看 Deployment 交接，`describe pod` 看 Pod 狀態與事件，`logs` 看應用程式輸出。

## 哪些地方還不順手

- 健康 Pod 的 `describe pod` 比較像狀態面板，未必會直接展示失敗案例；之後若要更熟 probe / restart 問題，還需要補一輪失敗案例導向的觀察題。
- `kubectl describe` 對命名 port 的渲染格式（例如 `http://:http/health`）第一次看仍容易混淆，但目前已能對回 YAML 理解它代表命名 port。
