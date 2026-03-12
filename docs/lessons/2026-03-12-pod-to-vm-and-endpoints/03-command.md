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

- 使用者已完成 Command Q1：`kubectl get endpoints -n weamind`
- 這一輪使用者選的是先看 Endpoints，而不是先看 Pods 或 ConfigMap。
- 使用者已完成 Command Q2：先執行 `kubectl get pods -n weamind`，發現預設輸出看不到 Pod IP，接著改用 `kubectl get pods -n weamind -o wide`。
- 使用者已完成 Command Q3：`kubectl describe svc weamind-line-bot -n weamind`
- 使用者已完成 Command Q4：`kubectl get pods -n weamind --show-labels`

### 從輸出確認了什麼

- 使用者實際看到的輸出如下：

```bash
kubectl get endpoints -n weamind
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME               ENDPOINTS                         AGE
weamind-line-bot   10.42.1.14:8000,10.42.2.13:8000   54d
```

- 這個輸出讓使用者第一次把 Endpoints 的意思對清楚：`ENDPOINTS` 欄位列出的就是目前這個 Service 實際對到的後端位址，也就是 Pod IP 與 port。
- 更精準的說法是：`kubectl get endpoints -n weamind` 顯示的是這個 namespace 內的 Endpoints 資源清單；在這個案例裡，`weamind-line-bot` 這一列對應的就是 `weamind-line-bot` Service 的後端 Pod 位址。
- 因此，不是只有「一個 endpoint」這種概念，而是 namespace 內可能有多個 Endpoints 資源；每個資源再各自對應某個 Service 目前的後端清單。
- 看到 `10.42.1.14:8000,10.42.2.13:8000`，就可以直接判斷 `weamind-line-bot` 後面目前至少有 2 個可導流的 Pod 在接流量。
- 使用者在 Command Q2 先看到 `kubectl get pods -n weamind` 的預設輸出只列出 `NAME`、`READY`、`STATUS`、`RESTARTS`、`AGE`，因此還無法直接對到 Endpoints 裡的 Pod IP。
- 改用 `kubectl get pods -n weamind -o wide` 後，才看到兩個 Pod 的 IP 分別是 `10.42.1.14` 與 `10.42.2.13`，剛好對上前一題 Endpoints 的兩個後端位址。
- 這一輪的關鍵學習不是只記住 `-o wide` 這個選項，而是理解：如果問題是「這個 Pod 的 IP 是多少、跑在哪個 node」，預設輸出不夠時，就需要更完整的輸出格式。
- 使用者在 Command Q3 透過 `kubectl describe svc weamind-line-bot -n weamind` 成功看到這個特定 Service 的詳細資訊，其中最關鍵的是 `Selector: app=weamind`。
- 這個輸出把三件事串起來了：Service 用 `app=weamind` 選 Pod、Service 自己的 `ClusterIP` 是 `10.43.54.228:80`、而目前實際對到的後端 Endpoints 是 `10.42.2.13:8000` 與 `10.42.1.14:8000`。
- 這也讓使用者更清楚區分兩種位址：`IP` 欄位是 Service 自己的 cluster 內穩定入口；`Endpoints` 欄位則是目前這個入口背後實際接到的 Pod IP/port。
- 使用者在 Command Q4 透過 `kubectl get pods -n weamind --show-labels` 看到兩個 Pods 的 labels 都包含 `app=weamind`，也都帶有相同的 `pod-template-hash=5985b7f7f6`。
- 這一輪把 selector 與 labels 正式對起來了：前一題看到 Service 的 selector 是 `app=weamind`，這一題則看到兩個 Pods 身上真的有 `app=weamind`，因此可以直接解釋為什麼這個 Service 會選到這兩個 Pods。
- `pod-template-hash` 也順便說明了這兩個 Pods 來自同一個 Deployment / ReplicaSet 模板，但 Service 真正依賴的不是這個 hash，而是 `app=weamind` 這個 label。

- 使用者實際看到的輸出如下：

```bash
kubectl get pods -n weamind
NAME                       READY   STATUS    RESTARTS   AGE
weamind-5985b7f7f6-t2qpm   1/1     Running   0          51d
weamind-5985b7f7f6-wdptx   1/1     Running   0          51d

kubectl get pods -n weamind -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
weamind-5985b7f7f6-t2qpm   1/1     Running   0          51d   10.42.1.14   weamind-002   <none>           <none>
weamind-5985b7f7f6-wdptx   1/1     Running   0          51d   10.42.2.13   weamind-003   <none>           <none>

kubectl describe svc weamind-line-bot -n weamind
Name:                     weamind-line-bot
Namespace:                weamind
Labels:                   <none>
Annotations:              <none>
Selector:                 app=weamind
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.54.228
IPs:                      10.43.54.228
Port:                     http  80/TCP
TargetPort:               8000/TCP
Endpoints:                10.42.2.13:8000,10.42.1.14:8000
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

kubectl get pods -n weamind --show-labels
NAME                       READY   STATUS    RESTARTS   AGE   LABELS
weamind-5985b7f7f6-t2qpm   1/1     Running   0          51d   app=weamind,pod-template-hash=5985b7f7f6
weamind-5985b7f7f6-wdptx   1/1     Running   0          51d   app=weamind,pod-template-hash=5985b7f7f6
```

## 下一輪互動式練習題

### Command Q1

已完成。

### Command Q2

已完成。

### Command Q3

已完成。

### Command Q4

已完成。

### Command Q5

如果你現在想把今天四步練習收成一句執行期觀察，你會怎麼描述 `Service → Endpoints → Pods` 這條鏈？

A. 先用 `kubectl get endpoints` 找到後端位址，再用 `kubectl get pods -o wide` 與 `--show-labels` 對回 Pod IP 與 labels，最後用 `kubectl describe svc` 確認 selector 與 targetPort。

B. 只要看到 `kubectl get svc` 有輸出，就代表 Service 後面一定有正常 Pod。

C. 只要 Pod 是 Running，就不需要再看 Endpoints。

你先選一個，然後用你自己的話補 2 到 3 句理由即可。這題不需要再打指令。

這一題的重點是把今天 command drill 的觀察流程收成一句可講出口的排查骨架。

使用者最終選擇 A，原因是：

- `kubectl get endpoints` 可以先看到 Service 目前實際對到哪些後端位址。
- `kubectl get pods -o wide` 與 `--show-labels` 可以把這些位址對回 Pod IP 與 Pod labels。
- `kubectl describe svc weamind-line-bot -n weamind` 則補上 selector、Service IP、targetPort 與 Endpoints 的完整細節。

這一題也順便釐清兩個容易混淆的地方：

- 今天確實有實際執行 `kubectl describe svc weamind-line-bot -n weamind`，而且當時已看到 `Selector: app=weamind`、`TargetPort: 8000/TCP` 與 `Endpoints` 欄位。
- `kubectl get svc` 只代表 Service 資源存在，不代表它後面一定有正常 Pod；真正要確認後端是否有被選到、是否可導流，仍要看 Endpoints。

一句話收斂：先看 Endpoints 知道 Service 目前實際對到誰，再用 Pods 的 IP 與 labels 對回後端，最後用 `describe svc` 補齊 selector 與 port mapping，這樣才能把 `Service → Endpoints → Pods` 這條鏈看完整。

### 哪裡還不順手

- 這次暴露出一個流程問題：若只有 AI 代跑驗證，對使用者的 command 練習幫助有限。
- 後續若再次看到 `127.0.0.1:6443 connection refused`，第一輪要先提醒自己檢查 SSH proxy / 通道是否已逾時，而不是立刻懷疑 Service 或 Pod 壞掉。