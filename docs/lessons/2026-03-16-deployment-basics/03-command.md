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

### 指令

```bash
kubectl get deployment -n weamind
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

## Command 2

### 要驗證的問題

- `weamind` Deployment 背後目前是哪個 ReplicaSet 在承接，想要的副本數與目前狀態是什麼。

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