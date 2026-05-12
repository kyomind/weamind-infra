# 2026-03-24 K8s Debug Tools Command
複習：2026-05-12
## 今日指令練習目標

1. 練習在不同情境下，先選較合適的第一個工具，而不是固定只開同一種指令。
2. 練習把指令輸出和 debug 分層框架接起來，知道自己拿到的是哪一層的證據。
3. 練習 `describe`、`logs`、`logs --previous`、`exec` 的最小使用情境。

## 這次要驗證的路徑或問題

1. CrashLoopBackOff / 重啟類問題，第一輪應先拿哪種證據。
2. Pod 內部最小驗證能證明什麼，不能證明什麼。
3. 工具選擇如何接回昨天的外到內 / 內到外 debug 骨架。

## 今天要看的資源

1. `weamind` Deployment 產生的 Pod
2. `weamind-line-bot` Service
3. WeaMind app 的 `/health` 與 webhook 路徑

---

## Command 1

### 要驗證的問題

- 某個 Pod 正在 CrashLoopBackOff，第一輪你想先拿到「Kubernetes 怎麼描述這個 Pod」這種證據，哪個工具比較合適？

### 三個可選指令

```bash
kubectl describe pod <pod-name> -n weamind
kubectl logs <pod-name> -n weamind
kubectl exec -it <pod-name> -n weamind -- /bin/sh
```

### 指令

```bash
kubectl -n weamind describe pod weamind-5985b7f7f6-t2qpm
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
Events:                      <none>
```

### 使用者選擇理由

- 雖然 CrashLoopBackOff 往往也會留下 app log，但這一輪題目要先拿的是「Kubernetes 怎麼描述這個 Pod」的證據，所以使用者先選 `kubectl describe pod`。
- 使用者的判斷是：第一輪應先看 Kubernetes 怎麼認定 Pod 的狀態，並特別留意 events 是否直接提示錯誤。
- 目前叢集中沒有真的 CrashLoopBackOff 的 Pod，因此這次先對健康 Pod 執行 describe，練習辨識正常輸出與之後若出現異常時要看哪些欄位。

### AI 判讀與修正

- 這個選擇是對的，因為這一輪題目要的是 Kubernetes 視角的證據，而不是 app 自己的 log。
- 你這次貼的是健康 Pod 的輸出，所以它不能直接模擬 CrashLoopBackOff 的錯誤內容，但仍然很有價值，因為它讓我們知道健康基準長什麼樣：`State=Running`、`Ready=True`、`Restart Count=0`、`Conditions` 幾乎全為 True、`Events=<none>`。
- 若今天真的是 CrashLoopBackOff，你在 `describe pod` 裡最該優先看的通常不是整份輸出全部，而是幾個欄位：`State` 是否為 `Waiting` 並帶 `Reason: CrashLoopBackOff`、`Last State` 裡上一輪 container 怎麼結束、`Restart Count` 是否持續增加，以及 `Events` 裡是否出現 `Back-off restarting failed container` 等訊號。
- 這也補強了今天早上談過的一件事：`Events=<none>` 不代表 `describe` 沒資訊；健康 Pod 依然可以從 `Conditions`、`State`、`Restart Count` 這些欄位看出它目前處在什麼生命週期狀態。
- 如果你真的拿到 CrashLoopBackOff 的 Pod，`describe` 幫你回答的是「Kubernetes 看到它正在反覆失敗重啟」，但它不一定告訴你 app 為什麼崩；那時下一步才常接 `kubectl logs` 或 `kubectl logs --previous` 去拿 app 視角的證據。
- 這一輪做得對的地方，不是因為你找到了錯誤，而是你先選到了正確類型的第一個工具。

### 一句話收斂

- 當我想先拿 Kubernetes 對 Pod 狀態與重啟情況的描述時，第一輪先用 `kubectl describe pod`；若之後要追 app 為什麼崩，再接 `logs` 或 `logs --previous`。

### 狀態

- 已完成（以健康 Pod 代理觀察）

---

## Command 2

### 要驗證的問題

- Pod 反覆重啟，你想看「上一個已經死掉的 container 最後吐了什麼」，哪個工具比較合適？

### 三個可選指令

```bash
kubectl logs <pod-name> -n weamind --previous
kubectl describe pod <pod-name> -n weamind
kubectl exec -it <pod-name> -n weamind -- printenv
```

### 指令

```bash
kubectl logs <pod-name> -n weamind --previous
```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 使用者先選 `kubectl logs <pod-name> -n weamind --previous`。
- 理由是：如果 Pod 反覆 crash 並重啟，每次重啟後目前這一輪的 log 會重新開始；這時 `--previous` 可以把視角拉回上一個已經死掉的 container，去看它在掛掉前最後留下了什麼訊息。
- 使用者目前手邊沒有真的反覆重啟中的 Pod，因此這一輪先用口頭方式說明為什麼會選 `--previous`，而不做實際輸出貼回。

### AI 判讀與修正

- 這個選擇是對的，而且你已經抓到 `--previous` 最重要的價值：它不是單純「舊一點的 log」，而是**上一個已經結束的 container 的最後輸出**。
- 你說「每重啟一次，這次的 log 會重新開始，所以要回頭看上一輪」這個理解是對的。更精準地說，當 container 因 CrashLoopBackOff 反覆被重啟時，`kubectl logs` 預設拿到的是目前這一輪 container 的輸出；如果你真正想找的是上一輪剛死掉前吐的 exception 或退出訊息，就要改看 `--previous`。
- 這也正是為什麼這一輪題目不是選 `describe`。`describe` 會告訴你 Kubernetes 看見它在反覆重啟，但如果你要追「上一輪 app 到底吐了什麼錯」，`logs --previous` 才更貼近 app 視角的證據。
- 如果之後真的遇到反覆重啟中的 Pod，一個很實用的組合是：先用 `describe` 確認它確實在 Back-off restarting，接著立刻用 `logs --previous` 看上一輪死前最後訊息。這樣就把 Kubernetes 視角與 app 視角接起來了。

### 一句話收斂

- 當 Pod 反覆重啟、我想看上一個已死 container 最後吐了什麼時，優先用 `kubectl logs --previous`，因為它拿的是上一輪失敗前的 app 證據。

### 狀態

- 已完成（口頭判讀）

---

## Command 3

### 要驗證的問題

- 你懷疑 Pod 內部的環境變數、DNS 解析或對 Service / VM 的基本連線是否正常，想做最小內部驗證，哪個工具比較合適？

### 三個可選指令

```bash
kubectl exec -it <pod-name> -n weamind -- /bin/sh
kubectl logs <pod-name> -n weamind
kubectl describe pod <pod-name> -n weamind
```

### 指令

```bash
kubectl exec -it weamind-5985b7f7f6-t2qpm -n weamind -- /bin/sh
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

# wget -qO- http://weamind-line-bot/health
/bin/sh: 4: wget: not found

# nc -zv 10.0.0.2 5433
/bin/sh: 6: nc: not found

command terminated with exit code 127
```

### 使用者選擇理由

- 使用者先選 `kubectl exec -it <pod-name> -n weamind -- /bin/sh`。
- 理由是：這一輪要驗證的是 Pod 內部環境，所以需要進 container 裡直接下指令，觀察環境變數與內部視角看到的連線條件。
- 使用者也正確補出一個細節：若 Pod 只有一個 container，通常指定 Pod 名稱即可；若 Pod 有多個 containers，則要再指定 container 名稱。

### AI 判讀與修正

- 這個選擇是對的，因為這一輪要的正是 Pod 內部最小驗證，而不是 Kubernetes 狀態視角或 app log 視角。
- 你這次已經成功驗證兩件很有價值的事情：第一，環境變數確實有注入到 container 內；第二，Pod 內部看到的 PostgreSQL / Redis 連線目標和 manifests / ConfigMap 設計一致，也就是 `POSTGRES_HOST=10.0.0.2`、`POSTGRES_PORT=5433`、`REDIS_URL=redis://10.0.0.2:6379/0`。
- `wget` 和 `nc` 這兩個測試沒有成功，但這裡要非常小心判讀：你拿到的 `/bin/sh: wget: not found`、`/bin/sh: nc: not found` 和 exit code `127`，代表的是這個容器映像裡沒有安裝這兩個工具，不代表 Service 或 PostgreSQL 連不通。
- 這一輪因此多學到一個很實務的判讀原則：在 slim / production image 裡，常見 debug 工具不一定存在；如果命令不存在，先把它判讀成「工具缺失」，不要誤判成「網路失敗」。
- 若之後要在這個容器裡補做最小連線測試，應先選容器內實際存在的工具，例如 Python 單行程式、應用本身已有的模組，或改用專門的臨時 debug Pod；不要直接把 `wget` / `nc` 不存在解讀成系統異常。
- 這也再次說明 `exec` 的邊界：它很適合做內部驗證，但你能不能成功驗證某個連線，也會受限於容器裡到底有沒有合適的工具。

### 一句話收斂

- 當我想確認 Pod 內部的環境變數與內部視角設定時，先用 `kubectl exec -it`；若容器內缺少 `wget` / `nc` 這類工具，應先判讀為工具不存在，而不是直接判成連線失敗。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- `kubectl describe pod` 適合先拿 Kubernetes 對 Pod 狀態、conditions、restart count 與 events 的描述性證據。
- `kubectl logs --previous` 適合在反覆重啟時，回頭看上一個已死 container 最後吐出的 app 錯誤訊息。
- `kubectl exec -it` 適合做 Pod 內部最小驗證，例如環境變數與內部視角設定；但容器內缺少工具時，要先分清楚那是 binary 不存在，不是網路失敗。

### 練習後還不順手的地方

- 當容器映像較精簡時，要先想清楚容器內可用什麼工具做最小連線測試，而不是預設 `wget` / `nc` 一定存在。

### 補充

- 今天的重點不是把四個工具排出絕對唯一順序，而是理解它們各自更擅長提供哪一種證據。
