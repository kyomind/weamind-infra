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

- 你已經確認 Secret 資源存在於叢集，也知道 `weamind` 是用 `envFrom + secretRef` 把值在 Pod 建立時注入。此時若要先看 Deployment 底下是否曾出現新舊版本切換、Pod 重建痕跡，哪個指令最適合當第一眼觀察入口？

### 三個可選指令

```bash
kubectl rollout restart deployment/weamind -n weamind
kubectl rollout status deployment/weamind -n weamind
kubectl get rs -n weamind
```

### 為什麼這樣重設題目

- 這一輪先只問「觀察哪個層次最對題」，不把「要不要立刻觸發 restart」和「restart 後怎麼追蹤」混在同一題。
- 三個選項分別落在不同層次：`rollout restart` 是主動觸發變化、`rollout status` 是看 rollout 摘要、`get rs` 才比較直接對到 Deployment 底下版本切換與 Pod 重建痕跡。

### 指令

```bash
kubectl get rs -n weamind
```

### 關鍵輸出

```bash
NAME                 DESIRED   CURRENT   READY   AGE
weamind-5985b7f7f6   2         2         2       70d
weamind-59d4666fc4   0         0         0       74d
weamind-6d7d894c59   0         0         0       74d
weamind-7459f5854c   0         0         0       74d
weamind-75f5579c8    0         0         0       74d
weamind-77dd8c5d49   0         0         0       74d
weamind-c4864fbc4    0         0         0       74d
weamind-f86bc7bdf    0         0         0       74d
```

### 使用者選擇理由

- 使用者選擇先看 `kubectl get rs -n weamind`，因為 ReplicaSet 本來就是 Deployment 版本迭代與 Pod 重建痕跡的核心資源，所以想先從這一層看叢集裡是否存在新舊版本切換的跡象。
- 使用者也主動提出一個很好的懷疑：雖然輸出看得到多個舊 RS 與一個目前 active 的 RS，但光靠 `AGE` 和 `DESIRED` 這些欄位，是否真的足以明確證明「剛剛這次 Secret 變更已經帶來新的版本切換」，其實沒有那麼穩。

### AI 判讀與修正

- 這個選擇是對的，而且你的懷疑也對。`kubectl get rs` 很適合當這一輪的第一眼入口，因為它直接站在 Deployment 底下的版本物件層，看目前哪個 ReplicaSet 是 active、哪些是歷史版本。這正好對應到題目要的「先看有沒有版本切換與 Pod 重建痕跡」。
- 你這份輸出至少已經回答兩件事。第一，`weamind-5985b7f7f6` 目前是 active 的 RS，因為它的 `DESIRED/CURRENT/READY` 都是 `2`。第二，這個 Deployment 歷史上確實經過多次變更，所以殘留多個 `DESIRED=0` 的舊 RS，這和前面的 debug story 也是一致的。
- 但你後面的不安非常關鍵：**`get rs` 能提供「版本切換痕跡」的入口，卻不能單靠它證明「你眼前這次 Secret 更新已經觸發了新的 Pod 建立流程」。** 原因是這份輸出只有 RS 名稱、副本數與大略年齡；它沒有直接告訴你這些 RS 是因哪一次變更產生，也沒有直接把 Secret 更新事件和某一個新的 RS 綁在一起。
- 換句話說，`get rs` 在這一題的價值是「先把觀察層次放對」，不是「一次把因果鏈證明完」。如果你真的要更穩地確認某一次變更是否帶來新的 rollout，後面通常還要再補其他證據，例如 Deployment 的 Pod template 是否真的改變、是否出現新的 `restartedAt`、或 Pod / RS 的建立時間是否和這次操作對得上。
- 所以這一輪最好的收斂不是說「看 RS 就能完全證明 Secret 已經生效」，而是說：**當你要先看 Deployment 底下有沒有版本迭代痕跡，`kubectl get rs` 是對題的第一眼入口；但若要把它提升成完整證據，還需要再補其他層次的觀察。**
- 這也正是為什麼 `kubectl rollout status` 不適合當這題第一個答案。它只能回答 rollout 摘要是否完成，卻不如 RS 視角那樣直接呈現「有哪些歷史版本、目前 active 的是哪一個」。而 `kubectl rollout restart` 則更不是第一眼觀察，因為那是主動觸發變化，不是先看現況。

### 一句話收斂

- `kubectl get rs` 很適合先看 Deployment 底下是否存在版本切換與 Pod 重建痕跡，但它單獨不能完整證明這次 Secret 變更已經帶來新的 rollout，後面仍要補其他證據。

### 狀態

- 已完成

---

## Command 4

### 要驗證的問題

- 你已先確認 Secret 資源已存在於叢集，也知道 `weamind` 是用 `envFrom + secretRef` 在新 Pod 建立時才注入環境變數。若此時你的判斷是「要讓既有工作負載用新的值，下一步應主動觸發新的 Pod 建立流程」，哪個指令最符合這個目的？

### 三個可選指令

```bash
kubectl rollout restart deployment/weamind -n weamind
kubectl rollout status deployment/weamind -n weamind
kubectl get rs -n weamind
```

### 為什麼這樣出題

- 這一輪不再問「先看哪一層」，而是明確切到「在什麼判斷前提下，`rollout restart` 才是合理動作」。
- `rollout restart` 是主動觸發新的 Pod 建立流程；`rollout status` 與 `get rs` 都是觀察指令，本身不會讓既有 Pod 吃到新值。

### 指令

```bash
kubectl rollout restart deployment/weamind -n weamind
```

### 關鍵輸出

```bash
deployment.apps/weamind restarted

Waiting for deployment "weamind" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "weamind" rollout to finish: 1 old replicas are pending termination...
```

### 使用者選擇理由

- 使用者選擇 `kubectl rollout restart deployment/weamind -n weamind`，因為只有這個動作會真正觸發 Deployment 底下既有 Pod 走新的建立流程，讓新建的 container 有機會重新吃到目前 Secret 的值。
- 使用者也在 rollout 進行中補跑 `kubectl rollout status deployment/weamind -n weamind` 觀察現況，並發現它會持續占住前景直到 rollout 結束，而不是只瞬間印出一個摘要結果。

### AI 判讀與修正

- 這個選擇是對的。這一輪題目問的是「在什麼判斷前提下，哪個指令才是合理的下一步」，而不是「先觀察哪一層」。既然前面已經確認 Secret 是獨立資源、Deployment 又是用 `envFrom + secretRef` 在 Pod 建立時一次性注入，那麼當你的目標是讓既有工作負載重新建立 Pod、重新注入環境變數時，`kubectl rollout restart` 就是對題的動作。
- 你補跑 `kubectl rollout status` 的做法也合理，而且你觀察到的「它會占住前景」正是這個指令的正常語意。`rollout status` 本質上不是單次快照查詢，而是偏向 watch 的等待型指令；它會持續追蹤 Deployment rollout 是否完成，所以在前景停住、反覆更新訊息，是預期行為，不是 kubectl 卡住。
- 你貼回的訊息也剛好讓這兩個指令的邊界更清楚。`deployment.apps/weamind restarted` 代表你已成功送出「重新滾動這個 Deployment」的指令；後面的 `Waiting for deployment ...` 則是在告訴你 rollout 還在進行中，目前新副本尚未全部更新完、舊副本也尚未完全終止。
- 這也幫你補上一個很實務的認知：**`rollout restart` 負責觸發變化，`rollout status` 負責等待並回報 rollout 是否完成。** 前者會改變系統狀態，後者只是觀察這個變化有沒有順利走完；單靠 `rollout status` 或 `get rs` 都不會讓舊 Pod 自己吃到新值。
- 若要再講得更精準一點，這一輪真正的使用前提不是「Secret 一改就 restart」，而是：**你已先確認 Secret 資源本身有更新，而且這次設定是透過 Pod 建立時注入的環境變數模型，這時 `rollout restart` 才是合理的下一步。** 不然太早 restart，會把「Secret 根本沒更新成功」和「只是 Pod 還沒重建」兩種問題混在一起。

### 一句話收斂

- 在已確認 Secret 更新成功、且設定是透過 `envFrom + secretRef` 於新 Pod 建立時注入的前提下，`kubectl rollout restart` 才是合理的下一步；`rollout status` 則是會在前景持續等待 rollout 完成的追蹤指令。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- `kubectl describe secret weamind-secret -n weamind` 先建立了最小觀念：Secret 是叢集中的獨立資源物件，可以先確認它是否真的存在於正確 namespace，以及 key 結構是否合理。
- `kubectl get deployment weamind -n weamind -o yaml` 讓我們直接看到 `envFrom + secretRef` 寫在 Pod template 裡，因此能判斷這種設定屬於新 Pod 建立時才會套用的注入模型。
- `kubectl get rs -n weamind` 幫我們先站到正確的觀察層次，看 Deployment 底下有哪些歷史版本、目前哪個 ReplicaSet 是 active；但它只能提供版本切換痕跡，不能單靠自己證明這次 Secret 更新已經觸發新的 rollout。
- `kubectl rollout restart deployment/weamind -n weamind` 讓我們把 `rollout restart` 放回正確情境：只有在已確認 Secret 資源已更新、而且目前設定是靠新 Pod 建立時重新注入的前提下，它才是合理的下一步。
- 補跑 `kubectl rollout status deployment/weamind -n weamind` 也順手釐清了一個常見誤解：它不是瞬間摘要查詢，而是會在前景持續等待 rollout 完成的追蹤指令。

### 練習後還不順手的地方

- 雖然已知道 `get rs` 是版本切換的第一眼入口，但還要再更熟悉：哪些證據只能算「痕跡」，哪些證據才足以把 Secret 更新、Pod 重建與新值生效串成比較完整的因果鏈。
- `rollout status` 的 watch / blocking 語意先前不夠熟，所以一開始會以為它只會立刻印出一次結果；這次已補上這個認知，但之後仍值得再和 `get pods`、`describe pod` 的觀察節奏一起對照。

### 補充

- 若今天未實跑 cluster 指令，需明確標記為「支援性設計」，不可當成已完成的使用者操作紀錄。
- 今天第一個 command drill 的重點不是背 Secret 指令，而是建立「先看資源物件，再看 Pod 狀態」的排查順序。
