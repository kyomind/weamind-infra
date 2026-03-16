# 2026-03-16 Deployment Basics Command

## 今日指令練習目標

把今天 lesson 的管理層級對到實際觀察：

1. 看出 Deployment、ReplicaSet、Pods 在叢集裡是怎麼串起來的。
2. 確認 `replicas: 2` 不是停在 YAML，而是真的反映成目前正在跑的 Pod 數量。
3. 練習用 rollout 指令觀察 Deployment 狀態，而不是只會看 Pod。

## 這次要驗證的路徑或問題

1. `weamind` Deployment 目前想維持幾個副本。
2. 它背後實際生成了哪個 ReplicaSet，以及這個 ReplicaSet 底下有哪些 Pods。
3. 如果要看 Deployment 是否完成 rollout，第一輪應看哪個指令。

## 今天要看的資源

1. weamind namespace 下的 Deployment
2. weamind namespace 下的 ReplicaSet
3. weamind namespace 下的 Pods

---

## Command 1

### 要驗證的問題

- `weamind` Deployment 目前宣告了多少副本，現在是否已經達成。

### 三個可選指令

```bash
kubectl get deployment -n weamind
kubectl get pods -n weamind
kubectl describe service weamind-line-bot -n weamind
```

### 為什麼這樣出題

- 這一輪的重點是先看 Deployment 自己宣告了多少副本，以及目前是否已達成，所以最直接的入口應該是 Deployment，而不是先看 Pods 或 Service。

### 指令

```bash
kubectl get pods -n weamind
kubectl get deployment -n weamind
```

### 關鍵輸出

```bash
NAME                       READY   STATUS    RESTARTS   AGE
weamind-5985b7f7f6-t2qpm   1/1     Running   0          55d
weamind-5985b7f7f6-wdptx   1/1     Running   0          55d

NAME      READY   UP-TO-DATE   AVAILABLE   AGE
weamind   2/2     2            2           59d
```

### 使用者選擇理由

- 使用者一開始在 `kubectl get pods -n weamind` 和 `kubectl get deployment -n weamind` 之間猶豫。
- 先看 Pods 後，發現雖然能看到有兩個 Pod 在跑，但這個畫面本身不直接告訴你「期望副本數是什麼」以及「目前是否達成 Deployment 想維持的數量」。
- 接著改看 Deployment，才發現這一層才是最直接能對照期望副本數、目前就緒數與可用數的入口。

### AI 判讀與修正

- 這次判斷方向是對的，而且你自己先試 Pod 再修正到 Deployment，這個修正過程本身就有學習價值。
- `kubectl get pods` 的價值在於看「現在有哪些實際執行個體」，但它不是第一眼最準確的管理層入口，因為它沒有直接告訴你 Deployment 宣告想維持幾個副本。
- `kubectl get deployment -n weamind` 才能直接看到 `READY 2/2`、`UP-TO-DATE 2`、`AVAILABLE 2`，也就是目前這個 Deployment 想維持 2 個副本，而且現況已經達成。
- 補一個更精準的說法：Pods 不是完全不能對照 Deployment，而是它們比較像「底層結果」；若題目是在問期望副本數與目前是否達成，Deployment 仍是更直接的入口。

### 一句話收斂

- 想確認 `weamind` 目前宣告幾個副本、是否已達成，第一眼應先看 Deployment，而不是先看 Pods。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- `weamind` Deployment 背後目前是哪個 ReplicaSet 在承接，想要的副本數與目前狀態是什麼。

### 三個可選指令

```bash
kubectl get rs -n weamind
kubectl get endpoints -n weamind
kubectl logs -n weamind deployment/weamind
```

### 為什麼這樣出題

- 這一輪要看的是 Deployment 底下的下一層管理資源，所以最該先看的應該是 ReplicaSet，而不是 Endpoints 或 logs。

### 指令

```bash
kubectl get rs -n weamind
```

### 關鍵輸出

```bash
待執行
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

- ReplicaSet 底下實際跑的是哪些 Pods，這些 Pod 名稱和 ReplicaSet 名稱之間有什麼關係。

### 三個可選指令

```bash
kubectl get pods -n weamind
kubectl get pods -n weamind --show-labels
kubectl describe deployment weamind -n weamind
```

### 為什麼這樣出題

- 這一輪需要先看到實際 Pod 名稱，再視需要補 labels；`describe deployment` 能補背景，但不是第一眼最直接的觀察點。

### 指令

```bash
kubectl get pods -n weamind
kubectl get pods -n weamind --show-labels
```

### 關鍵輸出

```bash
待執行
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

- 如果今天想看 Deployment 的 rollout 是否完成，第一輪最有價值的觀察指令是什麼。

### 三個可選指令

```bash
kubectl rollout status deployment/weamind -n weamind
kubectl get svc -n weamind
kubectl get configmap -n weamind
```

### 為什麼這樣出題

- 這一輪問題直接在問 rollout 狀態，所以最準確的入口就是 rollout status，而不是去看 Service 或 ConfigMap。

### 指令

```bash
kubectl rollout status deployment/weamind -n weamind
```

### 關鍵輸出

```bash
待執行
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

### 今天用哪些指令看懂了什麼

- 待補

### 練習後還不順手的地方

- 待補

### 補充

- 今天的重點不是背指令大全，而是把 Deployment、ReplicaSet、Pods 三層資源對成同一條管理鏈。
- 每一輪預設應由使用者先在三個可選指令中做判斷，再實際執行選中的指令並貼回輸出。