# 2026-03-31 Secret Update And Encoding Debug Story Command

## 今日指令練習目標

1. 把「Secret 資源已更新」和「Pod 已吃到新值」拆成可觀察的兩件事。
2. 把 `rollout restart` 放回正確使用情境，而不是把它當萬用修復鍵。
3. 先建立一個最小觀念：Secret 不是只是本地 YAML 片段，而是叢集中的獨立資源物件。

## 這次要驗證的路徑或問題

1. 更新 Secret 後，應該先看 Secret 本身、Deployment 引用方式，還是 Pod 生命週期。
2. 若 Pod 內的環境變數來自 `envFrom + secretRef`，既有 Pod 為何常需要重建才會吃到新值。
3. `invalid UTF-8` 類型錯誤發生時，為什麼第一輪工具會偏向 `describe` / events，而不是 app logs。

## 今天要看的資源

1. Secret
2. Deployment
3. Pods
4. ReplicaSet

---

## Command 1

### 要驗證的問題

- Secret 值若有更新，第一步應如何確認更新真的進到 K8s 資源，而不是只停留在本地 YAML？

### 三個可選指令

```bash
kubectl describe secret weamind-secret -n weamind
kubectl get secret weamind-secret -n weamind -o yaml
kubectl get secret weamind-secret -n weamind -o jsonpath='{.data}'
```

### 指令

```bash
kubectl describe secret weamind-secret -n weamind
```

### 關鍵輸出

```bash
Name:         weamind-secret
Namespace:    weamind
Type:         Opaque

Data
====
POSTGRES_PASSWORD:          32 bytes
LINE_CHANNEL_ACCESS_TOKEN:  172 bytes
LINE_CHANNEL_SECRET:        32 bytes
```

### 使用者選擇理由

- 先建立最小觀念：Secret 是叢集中的獨立資源物件，不只是本地 YAML 內容。
- 想先確認 `weamind-secret` 是否真的存在於 `weamind` namespace，以及它大致包含哪些 key。

### AI 判讀與修正

- 這輪輸出已經回答了一個很重要的第一層問題：`weamind-secret` 確實是叢集裡存在的一個 Secret 物件，而不是只有本地檔案裡寫了一段 YAML。
- 你現在至少已能從輸出讀出四件事：它的名稱是 `weamind-secret`、它在 `weamind` namespace、型別是 `Opaque`，而且目前叢集裡這個物件有三個 data key。
- 這也正好補上你剛剛的盲點：既然 Secret 是叢集中的資源物件，就合理會有 `kubectl describe secret ...` 這種第一輪觀察入口。
- 但這輪輸出也有邊界。`describe secret` 很適合先確認物件存在、namespace 正確、key 數量與大致結構是否合理；它不能直接證明這些值是不是你剛剛最新 apply 的內容，也不會直接把敏感值明文顯示出來。
- 所以下一步若要回答「它到底有沒有更新成我預期的值」，就要進到更精細的觀察，例如 `kubectl get secret ... -o yaml` 或 `-o jsonpath=...`，必要時再對特定 key 做有意識的比對，而不是停在 `describe` 就以為內容已驗證完成。

### 一句話收斂

- `describe secret` 先建立資源物件觀念：它能證明 Secret 已存在於叢集並顯示基本結構，但還不能單靠它確認值內容是否已更新正確。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- 你已經確認 Secret 物件存在於叢集裡，但 app 表面上仍沒變。此時你第一步想先確認：`weamind` 這個 Deployment 到底是用什麼方式把 Secret 注入 Pod，判斷它是否屬於「Pod 建立時一次性注入」的型態。哪個指令最適合先看這件事？

### 三個可選指令

```bash
kubectl get deployment weamind -n weamind -o yaml
kubectl describe deployment weamind -n weamind
kubectl describe pod -n weamind <pod-name>
```

### 指令

```bash
kubectl get deployment weamind -n weamind -o yaml
```

### 關鍵輸出

```bash
spec:
	template:
		metadata:
			annotations:
				kubectl.kubernetes.io/restartedAt: "2026-01-15T23:13:38+08:00"
		spec:
			containers:
			- envFrom:
				- configMapRef:
						name: weamind-config
				- secretRef:
						name: weamind-secret
				name: app

status:
	availableReplicas: 2
	readyReplicas: 2
	updatedReplicas: 2
```

### 使用者選擇理由

- 一開始有在 `describe` 和 `get -o yaml` 之間猶豫，因為這題想看的是比較細的 Secret 注入方式，而不是單純摘要資訊。
- 實際看到完整 YAML 後，會比較容易直接對到 `envFrom`、`secretRef` 和 Pod template 這幾個欄位，所以這次改用 `get deployment ... -o yaml`。

### AI 判讀與修正

- 這輪已經把題目核心看到了：`weamind` 的 Secret 注入方式是在 Deployment 的 `spec.template.spec.containers[].envFrom[].secretRef` 裡定義，指向 `weamind-secret`。
- 這個位置很重要，因為它說明設定是寫在 Pod template 裡。也就是說，當 Deployment 之後建立新的 Pod 時，新的 container 才會依照這份 template 把 Secret 轉成環境變數帶進去；這不是 Secret 物件更新後就會即時回寫到既有 Pod 的模型。
- 你這次改用 `get -o yaml` 是對的，因為題目要的是「注入結構」而不是摘要。`describe deployment` 仍然有用，但它更適合看事件、目前副本數、條件與概況；要看 `envFrom` / `secretRef` 這種欄位層級，YAML 視角更直接。
- 補一個很值得保留的觀察：輸出裡也看得到 `kubectl.kubernetes.io/restartedAt` 這種 annotation。它本身不是 Secret 注入機制，但它提醒你這個 Deployment 曾被 `rollout restart` 過，正好能接到下一題要談的「什麼時候 restart 才合理」。
- 另外，`availableReplicas: 2`、`readyReplicas: 2`、`updatedReplicas: 2` 也說明目前工作負載處於穩定狀態。這表示此刻我們不是在處理 Deployment 壞掉，而是在判斷「設定更新是否已透過新 Pod 生效」這種更細的問題。

### 一句話收斂

- 要看 Secret 是怎麼注入 Pod 的，最直接的是 `get deployment weamind -o yaml`，因為它能直接看到 Pod template 裡的 `envFrom + secretRef`，也因此能判斷這是新 Pod 建立時才套用的設定。

### 狀態

- 已完成

---

## Command 3

### 要驗證的問題

- 什麼時候 `rollout restart` 才是合理的下一步，以及做完後應該觀察哪個層次的變化。

### 三個可選指令

```bash
kubectl rollout restart deployment/weamind -n weamind
kubectl rollout status deployment/weamind -n weamind
kubectl get rs -n weamind
```

### 指令

```bash

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

-

### AI 判讀與修正

-

### 一句話收斂

-

### 狀態

- 未開始

---

## 最後收斂

### 今天用哪些指令看懂了什麼

-
-

### 練習後還不順手的地方

-

### 補充

- 若今天未實跑 cluster 指令，需明確標記為「支援性設計」，不可當成已完成的使用者操作紀錄。
- 今天第一個 command drill 的重點不是背 Secret 指令，而是建立「先看資源物件，再看 Pod 狀態」的排查順序。
