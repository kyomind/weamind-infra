# 2026-03-12 Pod To VM And Endpoints Command

## 今日指令練習目標

把今天 lesson 的兩條路徑各自對到實際觀察：

1. cluster 內的 `Service → Endpoints → Pods` 是否真的接得起來。
2. 確認哪些指令是在看 app 入口與 cluster 內轉送狀態，而不是 VM 上的資料庫連線本身。

## 這次要驗證的路徑或問題

1. `weamind-line-bot` Service 後面是否真的有可導流的 Pod。
2. Endpoints、Pod IP、Service selector 與 Pod labels 能不能互相對起來。

## 今天要看的資源

1. weamind namespace 下的 Pods
2. `weamind-line-bot` Service
3. `weamind-line-bot` Endpoints

---

## Command 1

### 要驗證的問題

- `weamind-line-bot` Service 後面目前有沒有真的對到後端 Pod。

### 指令

```bash
kubectl get endpoints -n weamind
```

### 關鍵輸出

```bash
NAME               ENDPOINTS                         AGE
weamind-line-bot   10.42.1.14:8000,10.42.2.13:8000   54d
```

### 使用者選擇理由

- 使用者這一輪先選 Endpoints，而不是先看 Pods 或 ConfigMap，因為想先確認 Service 後面到底有沒有實際後端可接流量。

### AI 判讀與修正

- `ENDPOINTS` 欄位列出的就是這個 Service 目前實際對到的後端位址，也就是 Pod IP 與 port。
- 更精準地說，這裡顯示的是 namespace 內的 Endpoints 資源清單；在這個案例裡，`weamind-line-bot` 這一列對應的就是 `weamind-line-bot` Service 的後端清單。
- 看到兩個位址，就可以先判斷目前至少有 2 個可導流的 Pod 在接流量。

### 一句話收斂

- 先看 Endpoints，可以最快知道 Service 後面目前實際對到哪些 Pod。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- Endpoints 裡看到的位址，能不能對回實際 Pod IP。

### 指令

```bash
kubectl get pods -n weamind
kubectl get pods -n weamind -o wide
```

### 關鍵輸出

```bash
kubectl get pods -n weamind
NAME                       READY   STATUS    RESTARTS   AGE
weamind-5985b7f7f6-t2qpm   1/1     Running   0          51d
weamind-5985b7f7f6-wdptx   1/1     Running   0          51d

kubectl get pods -n weamind -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP
weamind-5985b7f7f6-t2qpm   1/1     Running   0          51d   10.42.1.14
weamind-5985b7f7f6-wdptx   1/1     Running   0          51d   10.42.2.13
```

### 使用者選擇理由

- 使用者先看 `kubectl get pods -n weamind`，想先確認 Pod 狀態；發現預設輸出看不到 Pod IP 後，再補用 `-o wide`，因為要把 Endpoints 裡的位址對回實際 Pod。

### AI 判讀與修正

- 第一個指令只能確認 Pod 狀態是 Running，還無法把它們對回 Endpoints 裡的位址。
- 補上 `-o wide` 後，才看得到 Pod IP，並且可直接對上上一輪看到的 `10.42.1.14` 與 `10.42.2.13`。
- 這一輪真正要記住的不是 `-o wide` 這個技巧本身，而是當問題涉及 Pod IP 或 node 時，預設輸出常常不夠用。

### 一句話收斂

- 要把 Endpoints 對回 Pod，通常要從 `kubectl get pods -o wide` 補出 Pod IP。

### 狀態

- 已完成

---

## Command 3

### 要驗證的問題

- `weamind-line-bot` Service 是用哪個 selector 選 Pod，`port` 與 `targetPort` 又分別是什麼。

### 指令

```bash
kubectl describe svc weamind-line-bot -n weamind
```

### 關鍵輸出

```bash
Selector:                 app=weamind
IP:                       10.43.54.228
Port:                     http  80/TCP
TargetPort:               8000/TCP
Endpoints:                10.42.2.13:8000,10.42.1.14:8000
```

### 使用者選擇理由

- 使用者想直接看這個特定 Service 的完整細節，確認 selector、Service IP、port mapping 與目前對到的 Endpoints。

### AI 判讀與修正

- 這個輸出把三件事串起來了：Service 用 `app=weamind` 選 Pod、Service 自己有穩定的 ClusterIP 入口、而背後實際對到的是兩個 Pod IP。
- 這也順便釐清兩種位址：`IP` 欄位是 Service 自己的入口，`Endpoints` 欄位才是這個入口背後實際接到的 Pod IP/port。
- `Port: 80/TCP` 與 `TargetPort: 8000/TCP` 則回答了這個 Service 如何把進來的 80 port 流量轉到 Pod 的 8000。

### 一句話收斂

- `describe svc` 最適合一次補齊 selector、Service IP、port mapping 與目前對到的 Endpoints。

### 狀態

- 已完成

---

## Command 4

### 要驗證的問題

- `app=weamind` 這個 selector，是否真的對得到目前正在跑的 Pods。

### 指令

```bash
kubectl get pods -n weamind --show-labels
```

### 關鍵輸出

```bash
NAME                       READY   STATUS    RESTARTS   AGE   LABELS
weamind-5985b7f7f6-t2qpm   1/1     Running   0          51d   app=weamind,pod-template-hash=5985b7f7f6
weamind-5985b7f7f6-wdptx   1/1     Running   0          51d   app=weamind,pod-template-hash=5985b7f7f6
```

### 使用者選擇理由

- 使用者要確認前一輪看到的 `Selector: app=weamind` 不是只停在 Service 這邊，而是真的對到目前正在跑的 Pod labels。

### AI 判讀與修正

- 這一輪把 selector 與 labels 正式對起來了：前一輪看到 Service 的 selector 是 `app=weamind`，這一輪則看到兩個 Pods 身上真的有 `app=weamind`。
- `pod-template-hash=5985b7f7f6` 也順便說明這兩個 Pods 來自同一個 Deployment / ReplicaSet 模板，但 Service 真正依賴的不是這個 hash，而是 `app=weamind` 這個 label。

### 一句話收斂

- `--show-labels` 可以把 Service selector 和實際 Pod labels 對起來，補齊最後一段證據鏈。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- 先用 `kubectl get endpoints -n weamind` 找到 Service 目前實際對到的後端位址，確認後面有 2 個 Pod 在接流量。
- 再用 `kubectl get pods -n weamind -o wide` 把 Endpoints 裡的 IP 對回實際 Pod。
- 接著用 `kubectl describe svc weamind-line-bot -n weamind` 補齊 selector、Service IP、`port` 與 `targetPort`。
- 最後用 `kubectl get pods -n weamind --show-labels` 把 Service selector 與 Pod labels 正式對起來。
- 這一輪最後收成的排查骨架是：先看 Endpoints 知道 Service 目前實際對到誰，再用 Pods 的 IP 與 labels 對回後端，最後用 `describe svc` 補齊 selector 與 port mapping，這樣才能把 `Service → Endpoints → Pods` 這條鏈看完整。

### 練習後還不順手的地方

- 這次暴露出一個流程問題：若只有 AI 代跑驗證，對使用者的 command 練習幫助有限。
- 後續若再次看到 `127.0.0.1:6443 connection refused`，第一輪要先提醒自己檢查 SSH proxy / 通道是否已逾時，而不是立刻懷疑 Service 或 Pod 壞掉。

### 補充

- `kubectl get svc` 只代表 Service 資源存在，不代表它後面一定有正常 Pod；真正要確認後端是否有被選到、是否可導流，仍要看 Endpoints。