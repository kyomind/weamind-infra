# 2026-03-12 Pod To VM And Endpoints Command

## 今日指令練習目標

把今天 lesson 的兩條路徑各自對到實際觀察：

1. cluster 內的 `Service → Endpoints → Pods` 是否真的接得起來。
2. 確認哪些指令是在看 app 入口與 cluster 內轉送狀態，而不是 VM 上的資料庫連線本身。

## 今天要看的資源

1. weamind namespace 下的 Pods
2. `weamind-line-bot` Service
3. `weamind-line-bot` Endpoints

## 今天預計要練的指令

### 1. 看 app Pods

```bash
kubectl get pods -n weamind
```

要看什麼：

- 目前有幾個 app Pods
- 狀態是不是 Running
- 是否有異常重啟

### 2. 看 Service

```bash
kubectl get svc -n weamind
```

要看什麼：

- `weamind-line-bot` 是否存在
- Service type 是否為 `ClusterIP`
- 對外提供的 port 是多少

### 3. 看 Endpoints

```bash
kubectl get endpoints -n weamind
```

要看什麼：

- `weamind-line-bot` 後面是否真的列出 Pod IP
- Endpoints 是正常有值，還是空的

### 4. 深看 Service 細節

```bash
kubectl describe svc weamind-line-bot -n weamind
```

要看什麼：

- selector 是什麼
- service port 與 targetPort 是什麼
- endpoints 區塊是否有對到後端 Pod

## 練習後要回答的問題

1. 目前 `weamind-line-bot` 後面有幾個 Pod 在接流量。
2. Service 是用哪個 selector 去選 Pod。
3. `port` 和 `targetPort` 在這個專案裡分別是什麼。
4. 如果 Endpoints 是空的，第一輪應該先查哪一層，而不是先查 VM 資料庫連線。

## 實際練習紀錄

### 實際敲了哪些指令

- 待補

### 從輸出確認了什麼

- 待補

### 哪裡還不順手

- 待補