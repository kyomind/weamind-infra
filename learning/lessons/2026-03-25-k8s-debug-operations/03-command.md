# 2026-03-25 K8s Debug Operations Command

## 今日指令練習目標

1. 練習把故障情境先分層，再挑第一輪較合適的觀察指令。
2. 練習看完輸出後，能說出下一步為什麼改往那一層查。
3. 練習把每一輪操作收斂成一個可複習的 debug sequence，而不是指令流水帳。

## 這次要驗證的路徑或問題

1. 外層 routing 類問題，第一輪應先看哪一層的證據。
2. Pod / app 類問題，怎麼把 `describe` 和 `logs` 串成前後兩步。
3. Pod 到 VM 依賴類問題，`exec` 能幫你驗證什麼，不能直接證明什麼。

## 今天要看的資源

1. `weamind` Deployment 產生的 Pod
kubectl describe ingress weamind -n weamind
3. `k8s.kyomind.tw` 對應的 Ingress 與 `/health` 路徑

---

## Command 1
Name:             weamind
Namespace:        weamind
Address:          10.0.0.3,10.0.0.4,10.0.0.5
Ingress Class:    traefik
TLS:
	k8s-kyomind-tw-tls terminates k8s.kyomind.tw
Rules:
	Host            Path  Backends
	----            ----  --------
	k8s.kyomind.tw
									/   weamind-line-bot:80 (10.42.2.13:8000,10.42.1.14:8000)
Events:           <none>

### 要驗證的問題

- 某次 webhook Verify 回 `404`，但 `https://k8s.kyomind.tw/health` 正常。第一輪你比較想先驗證外層 routing 是否命中正確 host / path，哪個指令或觀察點更合適？
- 使用者先選 `kubectl describe ingress weamind -n weamind`。
- 理由是：這一輪想先確認 cluster 端宣告的 `host` / `path` 規則到底長什麼樣，看看它是否真的把 `k8s.kyomind.tw` 和 `/` 這條路徑導向預期的後端 `Service`。
- 使用者也觀察到：自己以前沒有真的用過這個指令，所以雖然直覺上知道它和 routing 有關，但還不確定這份輸出到底能證明多少事情。
### 三個可選指令

```bash
- **這個選擇是對的。** 因為這一輪題目要先驗證的是 cluster 端宣告的外層 routing 規則，而不是 app 內部狀態；在三個選項裡，`kubectl describe ingress` 的確最貼近這個問題。
- 從這份輸出裡，你現在**可以確定三件事**。第一，這個 `Ingress` 是交給 `traefik` 處理；第二，它宣告的 `Host` 是 `k8s.kyomind.tw`；第三，它把 `Path=/` 這個 `Prefix` 規則導到 `weamind-line-bot:80`，而這個 `Service` 背後目前對到兩個 `Pod` endpoint：`10.42.2.13:8000` 和 `10.42.1.14:8000`。
- **但這份輸出也有很重要的邊界：它只能證明 cluster 端「宣告了什麼規則」，不能單獨證明外部請求真的帶著正確的 `Host` / `path` 打進來。** 也就是說，它能回答「Kubernetes 這邊預期怎麼路由」，但不能單獨回答「LINE 平台實際送來的是不是同一個 URL」。
- 所以你剛剛那個疑問是對的：**光靠這份 `describe ingress`，還不能說 debug 已經充分完成。** 它只能幫你先確認 cluster 端沒有把 `host` / `path` 規則寫歪；接下來仍要把這份規則和外部 webhook URL、以及必要時的 app `logs` 一起對照。
- `Address` 這一欄，更精準地說，不是在告訴你 `Ingress` 會 lead to which node，而是在告訴你這個 `Ingress` 目前對外可由哪些 node IP / entrypoint 位址被看到。在 K3s + Traefik 的情境下，看到 control-plane 的 `10.0.0.3` 也不奇怪，這比較反映 Traefik / entrypoint 的可達位址，不等於你的應用 `Pod` 一定跑在那些 node 上。
- `Ingress Class: traefik` 代表這份 `Ingress` 規則是由 `traefik` 這個 `Ingress Controller` 來接手，而不是交給別的 controller。這一欄的重要性在於：如果 `Ingress Class` 不對，規則可能根本沒有人處理。
- `Events: <none>` 在這裡是正常的，而且它**不代表 routing 一定完全沒問題**。對 `Ingress` 來說，`events` 往往沒有 `Pod` 那麼常出現高價值錯誤訊息；很多像 `Host` / `path` 對錯、外部 webhook URL 填錯這種問題，本來就不一定會在 `Ingress` 的 `events` 裡留下明確提示。
- 如果 `Ingress` 真的有比較明顯的 controller 處理問題，有時可能會看到和同步、驗證或 controller 接手有關的事件；但像你這一題要查的「外部實際打進來的 URL 對不對」，通常**不會因為外部 path 填錯，就在這裡自動冒出一條超清楚的 `event`**。
- **所以這一輪最正確的收斂是：** `kubectl describe ingress` 讓我確認 cluster 端宣告的 `Host=k8s.kyomind.tw`、`Path=/`、後端 `Service=weamind-line-bot:80` 都合理；但它還不足以單獨證明外部 webhook URL 一定正確。下一步仍要回頭對照外部 webhook URL，必要時再看 app `logs` 確認請求是否真的進到應用。
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl logs <pod-name> -n weamind
```
- `kubectl describe ingress` 很適合先確認 cluster 端宣告的 `host` / `path` / backend 規則是否合理，但它不能單獨證明外部 webhook URL 一定正確；要完成這題，還要把外部 URL 和 app `logs` 一起對照。
### 指令

```bash
- 已完成
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

- 某個 Pod 看起來在反覆重啟，你第一輪想先拿 Kubernetes 對 Pod 狀態的描述，再決定是否往 app log 深挖，哪個指令比較合適？

### 三個可選指令

```bash
kubectl describe pod <pod-name> -n weamind
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl get ingress -n weamind
```

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

- Pod 已經 Running / Ready，但你懷疑 Pod 內部到 PostgreSQL 或 Redis 的依賴路徑有問題，想做最小內部驗證，哪個指令比較合適？

### 三個可選指令

```bash
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl describe service weamind-line-bot -n weamind
kubectl get ingress -n weamind
```

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

## 最後收斂

### 今天用哪些指令看懂了什麼

- 待補

### 練習後還不順手的地方

- 待補

### 補充

- 若 AI 為了環境驗證代跑指令，只算輔助，不等於使用者已完成 command drill。
