# 2026-03-25 K8s Debug Operations Command

## 今日指令練習目標

1. 練習把故障情境先分層，再挑第一輪較合適的觀察指令。
2. 練習看完輸出後，能說出下一步為什麼改往那一層查。
3. 練習把每一輪操作收斂成一個可複習的 debug sequence，而不是指令流水帳。

## 這次要驗證的路徑或問題

1. 外層 routing 類問題，第一輪應先看哪一層的證據。
2. `Pod` / app 類問題，怎麼把 `describe` 和 `logs` 串成前後兩步。
3. `Pod` 到 VM 依賴類問題，`exec` 能幫你驗證什麼，不能直接證明什麼。

## 今天要看的資源

1. `weamind` Deployment 產生的 `Pod`
2. `weamind-line-bot` `Service`
3. `k8s.kyomind.tw` 對應的 `Ingress` 與 `/health` 路徑

---

## Command 1

### 要驗證的問題

- 某次 webhook Verify 回 `404`，但 `https://k8s.kyomind.tw/health` 正常。第一輪你比較想先驗證外層 routing 是否命中正確 `host` / `path`，哪個指令或觀察點更合適？

### 三個可選指令

```bash
kubectl describe ingress weamind -n weamind
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl logs <pod-name> -n weamind
```

### 指令

```bash
kubectl describe ingress weamind -n weamind
```

### 關鍵輸出

```bash
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
```

### 使用者選擇理由

- 使用者先選 `kubectl describe ingress weamind -n weamind`。
- 理由是這一輪想先確認 cluster 端宣告的 `host` / `path` 規則到底長什麼樣，看看它是否真的把 `k8s.kyomind.tw` 和 `/` 導向預期的後端 `Service`。
- 使用者也觀察到：自己以前沒有真的用過這個指令，所以雖然直覺上知道它和 routing 有關，但還不確定這份輸出到底能證明多少事情。

### AI 判讀與修正

- **這個選擇是對的。** 因為這一輪題目要先驗證的是 cluster 端宣告的外層 routing 規則，而不是 app 內部狀態；在三個選項裡，`kubectl describe ingress` 的確最貼近這個問題。
- 從這份輸出裡，你現在**可以確定三件事**：第一，這個 `Ingress` 是交給 `traefik` 處理；第二，它宣告的 `Host` 是 `k8s.kyomind.tw`；第三，它把 `Path=/` 這個 `Prefix` 規則導到 `weamind-line-bot:80`，而這個 `Service` 背後目前對到兩個 `Pod` endpoint：`10.42.2.13:8000` 和 `10.42.1.14:8000`。
- **但這份輸出也有很重要的邊界：它只能證明 cluster 端宣告了什麼規則，不能單獨證明外部請求真的帶著正確的 `Host` / `path` 打進來。** 它能回答「Kubernetes 這邊預期怎麼路由」，但不能單獨回答「LINE 平台實際送來的是不是同一個 URL」。
- 所以你剛剛那個疑問是對的：**光靠這份 `describe ingress`，還不能說 debug 已經充分完成。** 它只能幫你先確認 cluster 端沒有把 `host` / `path` 規則寫歪；接下來仍要把這份規則和外部 webhook URL、以及必要時的 app `logs` 一起對照。
- `Address` 這一欄更精準地說，不是在告訴你 `Ingress` 會 lead to 哪些 node，而是在告訴你這個 `Ingress` 目前對外可由哪些 node IP / entrypoint 位址被看到。在 K3s + Traefik 的情境下，看到 control-plane 的 `10.0.0.3` 也不奇怪，這比較反映 Traefik / entrypoint 的可達位址，不等於你的應用 `Pod` 一定跑在那些 node 上。
- `Ingress Class: traefik` 代表這份 `Ingress` 規則是由 `traefik` 這個 `Ingress Controller` 來接手，而不是交給別的 controller。這一欄的重要性在於：如果 `Ingress Class` 不對，規則可能根本沒有人處理。
- `Events: <none>` 在這裡是正常的，而且它**不代表 routing 一定完全沒問題**。對 `Ingress` 來說，`events` 往往沒有 `Pod` 那麼常出現高價值錯誤訊息；很多像 `Host` / `path` 對錯、外部 webhook URL 填錯這種問題，本來就不一定會在 `Ingress` 的 `events` 裡留下明確提示。
- **這一輪最正確的收斂是：** `kubectl describe ingress` 讓我確認 cluster 端宣告的 `Host=k8s.kyomind.tw`、`Path=/`、後端 `Service=weamind-line-bot:80` 都合理；但它還不足以單獨證明外部 webhook URL 一定正確。下一步仍要回頭對照外部 webhook URL，必要時再看 app `logs` 確認請求是否真的進到應用。

### 一句話收斂

- `kubectl describe ingress` 很適合先確認 cluster 端宣告的 `host` / `path` / backend 規則是否合理，但它不能單獨證明外部 webhook URL 一定正確；要完成這題，還要把外部 URL 和 app `logs` 一起對照。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- 某個 `Pod` 看起來在反覆重啟，你第一輪想先拿 Kubernetes 對 `Pod` 狀態的描述，再決定是否往 app log 深挖，哪個指令比較合適？

### 三個可選指令

```bash
kubectl describe pod <pod-name> -n weamind
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl get ingress -n weamind
```

### 指令

```bash
kubectl describe pod -n weamind weamind-5985b7f7f6-t2qpm
```

### 關鍵輸出

```bash
Status:           Running
Containers:
  app:
    State:          Running
      Started:      Mon, 19 Jan 2026 23:27:59 +0800
    Ready:          True
    Restart Count:  0
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Events:           <none>
```

### 使用者選擇理由

- 使用者先選 `kubectl describe pod <pod-name> -n weamind`，而且理由正確：這一輪想先拿 Kubernetes 對 `Pod` 狀態的描述，而不是直接跳進 container 內部。
- 使用者也能說出 `describe pod` 不只看單一欄位，而是會同時看到 `Conditions`、`Events`、container 狀態與整體 `Pod` 狀態，能從多個面向理解 Kubernetes 目前怎麼看這個 `Pod`。
- 雖然這次實際拿到的是健康 `Pod` 的輸出，但使用者已能用這份輸出去對照：如果未來真的是反覆重啟中的 `Pod`，該優先注意哪些欄位會變化。

### AI 判讀與修正

- **這個選擇是對的。** 因為這一輪題目要的就是 Kubernetes 對 `Pod` 狀態的描述性證據，而不是 app 內部視角或 `Ingress` 規則。
- 你這次貼到的是一個**健康 `Pod` 的基準輸出**，所以它不會直接示範 `CrashLoopBackOff`。但這份基準反而很有價值，因為你現在知道健康狀態通常長什麼樣：`Status=Running`、container `State=Running`、`Ready=True`、`Restart Count=0`、`Conditions` 幾乎全 `True`、`Events=<none>`。
- **也就是說，這一輪雖然沒有看到錯誤本身，但你已經學到異常時要優先掃哪些欄位。** 如果未來真的是反覆重啟中的 `Pod`，你最該優先找的通常會是：container `State` 是否變成 `Waiting` 並帶 `Reason: CrashLoopBackOff`、`Last State` 裡上一輪怎麼結束、`Restart Count` 是否持續增加，以及 `Events` 裡是否有像 `Back-off restarting failed container` 這類訊號。
- 你剛剛提到 `Conditions`、`Events`、`ContainerStatus` 這幾層一起看，這個理解是對的。可以再收得更精準一點：`Conditions` 比較像目前這一刻的狀態快照；container `State` / `Last State` 比較像單個 container 的生命週期訊號；`Events` 則比較像時間序列上的事件紀錄。三者合起來，才會形成 Kubernetes 視角的第一輪判讀。
- `Events: <none>` 在這裡也很正常，而且**不代表 `describe pod` 沒資訊**。即使沒有 `Events`，你仍然可以從 `State`、`Restart Count`、`Ready`、`Conditions` 判斷這個 `Pod` 現在是不是處在穩定狀態。
- **所以這一輪最重要的收穫不是你找到了錯誤，而是你建立了健康基準。** 有了這個基準，你之後看到異常 `Pod` 時，才知道哪些欄位偏離正常，值得立刻追下去。
- **這一輪最短可講版可以收斂成：** `kubectl describe pod` 是第一輪很好的 Kubernetes 視角工具；即使當下拿到的是健康 `Pod`，也能先建立基準，知道未來若真的遇到 `CrashLoopBackOff`，應該優先看 `State`、`Last State`、`Restart Count`、`Conditions` 和 `Events`。

### 一句話收斂

- `kubectl describe pod` 適合第一輪先拿 Kubernetes 對 `Pod` 狀態的描述；就算當下看到的是健康 `Pod`，也能先建立基準，知道異常時該優先掃哪些欄位。

### 狀態

- 已完成（以健康 `Pod` 建立基準）

---

## Command 3

### 要驗證的問題

- `Pod` 已經 `Running` / `Ready`，但你懷疑 `Pod` 內部到 `PostgreSQL` 或 `Redis` 的依賴路徑有問題，想做最小內部驗證，哪個指令比較合適？

### 三個可選指令

```bash
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl describe service weamind-line-bot -n weamind
kubectl get ingress -n weamind
```

### 指令

```bash
kubectl exec -it weamind-5985b7f7f6-t2qpm -n weamind -- /bin/sh
printenv | grep POSTGRES
printenv | grep REDIS
```

### 關鍵輸出

```bash
# printenv | grep POSTGRES
POSTGRES_PASSWORD=<略>
POSTGRES_HOST=10.0.0.2
POSTGRES_USER=wea_bot
POSTGRES_PORT=5433
POSTGRES_DB=weamind
# printenv | grep REDIS
REDIS_URL=redis://10.0.0.2:6379/0
```

### 使用者選擇理由

- 使用者先選 `kubectl exec -it <pod-name> -n weamind -- /bin/sh`。
- 理由是這一輪要做的是最小內部驗證，而若要確認環境變數是否真的被正確注入、值是否正確，就必須進到 container 內部看 `printenv` 或其他最小驗證結果。
- 使用者也能正確排除另外兩個選項：`kubectl describe service` 與 `kubectl get ingress` 都無法直接驗證 container 內部看到的 `PostgreSQL` / `Redis` 相關設定是否正確。

### AI 判讀與修正

- **這個選擇是對的。** 因為這一輪題目要驗證的是 `Pod` / container 內部視角，而不是 `Service` 或 `Ingress` 這種外層資源描述。
- **你這裡抓到的核心很準：如果你要驗證的不只是設定有沒有宣告，而是它在 container 內部最終呈現的值對不對，那就必須用 `kubectl exec -it` 進去看。** 這也是為什麼 `kubectl describe service` 和 `kubectl get ingress` 在這一輪價值很低，它們回答的是外層資源長什麼樣，不是 app 進程實際看到什麼。
- 這次實際輸出已經讓這一輪可以正式收斂：`POSTGRES_HOST=10.0.0.2`、`POSTGRES_PORT=5433`、`POSTGRES_DB=weamind`、`POSTGRES_USER=wea_bot`、`REDIS_URL=redis://10.0.0.2:6379/0`，都和 [manifests/configmap.yaml](manifests/configmap.yaml) 一致；而 `POSTGRES_PASSWORD` 也確實存在，代表對應的敏感值有被注入進 container。
- **這表示目前至少可以確認一件事：container 內部實際看到的 DB / Redis 設定值是正確的。** 所以如果之後 app 還是連不上 `PostgreSQL` 或 `Redis`，第一輪嫌疑就不該再放在「環境變數根本沒進來」或「host / port 明顯寫錯」這種層次。
- 但這裡也要守住邊界：**`printenv` 只能證明設定值被正確注入，不能單獨證明網路連線一定成功。** 它不能直接回答 `10.0.0.2:5433` 或 `10.0.0.2:6379` 此刻是否真的可達，也不能替代 app 自己的連線錯誤訊息。
- 所以若未來還懷疑依賴連線，下一步通常會是回到 app `logs` 看實際錯誤，或在 container 內做更進一步的最小連線驗證；但就今天這題而言，**你已經完成了「設定注入層」的最小驗證。**
- **這一輪最短可講版可以收斂成：** 若我要驗證 `Pod` 內部到 `PostgreSQL` / `Redis` 的依賴設定是否真的進到 container，第一輪先用 `kubectl exec -it` 加 `printenv` 檢查最終值；這能證明設定注入正確，但不能單獨證明連線成功。

### 一句話收斂

- `kubectl exec -it` 搭配 `printenv` 能驗證 container 內部最終收到的 `DB` / `Redis` 設定是否正確，但它只能證明設定注入，不等於已證明依賴連線成功。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- `kubectl describe ingress weamind -n weamind`：先確認 cluster 端宣告的 `Host`、`Path`、backend `Service` 與 `Ingress Class` 是否合理，回答的是外層 routing 規則長什麼樣。
- `kubectl describe pod -n weamind weamind-5985b7f7f6-t2qpm`：先拿 Kubernetes 視角的 `Pod` 狀態基準，回答的是 `State`、`Restart Count`、`Conditions`、`Events` 目前看起來是否穩定。
- `kubectl exec -it weamind-5985b7f7f6-t2qpm -n weamind -- /bin/sh` 加 `printenv`：拿 container 內部視角，回答的是 app 進程實際看到的 `POSTGRES_*` 與 `REDIS_URL` 是否正確注入。

### 練習後還不順手的地方

- `kubectl exec` 這種內部驗證工具，很容易被誤用成萬用 debug 起手式；之後仍要持續練習先判斷「這題到底是在驗證外層 routing、Kubernetes 狀態，還是 container 內部設定」。
- 即使今天已驗證設定注入正確，之後仍要繼續分清楚「設定正確」和「依賴真的可連」是兩個不同層次，避免把 `printenv` 的成功誤讀成連線成功。

### 補充

- 若 AI 為了環境驗證代跑指令，只算輔助，不等於使用者已完成 command drill。
