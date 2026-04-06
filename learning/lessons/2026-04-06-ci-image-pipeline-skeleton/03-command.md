# 2026-04-06 CI Image Pipeline Skeleton Command

> 提示：今天的 command drill 會放在 QA 後進行，重點不是背指令，而是用最少查找動作快速證明 workflow 觸發條件、image 引用方式與缺少的 deploy automation。

## 今日指令練習目標

1. 快速定位 CI 與 publish workflow 的關鍵觸發條件。
2. 快速定位 Deployment 引用的 image 與 imagePullPolicy。
3. 練習用 repo 證據判斷目前缺少哪段 CD automation。

## 這次要驗證的路徑或問題

1. publish-ghcr workflow 不是任何 push 都會直接執行，它有額外條件。
2. Deployment 雖然引用 latest 且設定 imagePullPolicy: Always，但這不會主動 rollout 現有 Pods。
3. repo 內沒有看到自動對 K8s 執行部署或重啟的證據。

## 今天要看的資源

1. reference/weamind-app-ci.yml
2. reference/weamind-app-publish-ghcr.yml
3. manifests/deployment.yaml
4. reference/weamind-ci-to-k8s-flow.md

---

## Command 1

### 要驗證的問題

- 待開始

### 三個可選指令

```bash

```

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

- 待開始

### 三個可選指令

```bash

```

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

### 今天用哪些指令看懂了什麼

- 待補

### 練習後還不順手的地方

- 待補

### 補充

- 視需要補最小上下文即可。
