# 2026-04-21 Helm Kube Prometheus Stack Basics Command

> 今天的 command 不是主戰場，重點是承接實作前後的最小驗證證據，讓 install 結果有可複習的觀察鏈。

## 今日指令練習目標

1. 在實作前確認本機 Helm / kubectl 對遠端 K3s 的控制鏈正常。
2. 在實作後驗證 `kube-prometheus-stack` 的核心資源是否真的建立並進入穩定狀態。

## 這次要驗證的路徑或問題

1. 今天的 Helm install 是否站在正確的 cluster context 與 namespace 邊界上。
2. install 完成後，Prometheus、Grafana 與 supporting components 是否能在 workload 層看到成功建立的證據。

## 今天要看的資源

1. `helm repo list` / `helm list`
2. `kube-prometheus-stack` release 與 namespace 內 workload
3. install 後的 Pod、`StatefulSet`、`Deployment`、`DaemonSet` 與 events

---

## Command 1

### 要驗證的問題

- 在真正安裝前，現在的本機 CLI 是否已站在正確的 cluster context，而且 Helm 是否可正常操作這個叢集。

### 三個可選指令

```bash
kubectl config current-context
helm version
kubectl get ns
```

### 指令

```bash
kubectl config current-context
kubectl get ns
helm version
```

### 關鍵輸出

```bash
default

NAME              STATUS   AGE
cert-manager      Active   90d
darkmind          Active   4d22h
default           Active   105d
kube-node-lease   Active   105d
kube-public       Active   105d
kube-system       Active   105d
net-test          Active   100d
weamind           Active   97d

version.BuildInfo{Version:"v4.1.3", GitCommit:"c94d381b03be117e7e57908edbf642104e00eb8f", GitTreeState:"clean", GoVersion:"go1.26.1", KubeClientVersion:"v1.35"}
```

### 使用者選擇理由

- implement 階段改採協作模式，這一輪直接把三個前置驗證指令都跑完，先一次確認 active context、namespace 證據與 Helm CLI 可用性。

### AI 判讀與修正

- `default` 雖然不是很好讀的 context 名稱，但後續 namespace 證據已足夠證明目前連到的是 WeaMind 叢集。
- `weamind`、`darkmind`、`cert-manager` 都存在，代表今天 install 的操作前提正常，不是在空叢集上練習。
- Helm CLI 已安裝可用，下一步可以直接進 repo / chart 驗證，不需要先處理本機工具缺失。

### 一句話收斂

- Helm install 的最外層前提已確認成立：工具可用、context 可用、目標叢集正確。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- `kube-prometheus-stack` install 後，哪些 workload 真正起來了，這些工作負載又分別對回哪個元件角色。

### 三個可選指令

```bash
helm list -A
kubectl get pods -A
kubectl get deploy,sts,ds -A
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
- 待補

### 練習後還不順手的地方

- 待補

### 補充

- 若某些 Pod 沒起來，優先補 `helm status`、`kubectl describe` 與 `kubectl get events` 的最小證據，不直接擴成第二份 implementation transcript。
