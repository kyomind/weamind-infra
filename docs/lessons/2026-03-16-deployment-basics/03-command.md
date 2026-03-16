# 2026-03-16 Deployment Basics Command

## 今日指令練習目標

把今天 lesson 的管理層級對到實際觀察：

1. 看出 Deployment、ReplicaSet、Pods 在叢集裡是怎麼串起來的。
2. 確認 `replicas: 2` 不是停在 YAML，而是真的反映成目前正在跑的 Pod 數量。
3. 練習用 rollout 指令觀察 Deployment 狀態，而不是只會看 Pod。

## 這次要驗證的路徑或問題

1. `weamind` Deployment 目前想維持幾個副本。
2. 它背後實際生成了哪個 ReplicaSet，以及這個 ReplicaSet 底下有哪些 Pods。
3. 如果想直接從 Deployment 視角看目前承接中的 NewReplicaSet 與舊的 OldReplicaSets，該看哪個指令。
4. ReplicaSet 底下實際跑的是哪些 Pods，這些 Pod 名稱和 ReplicaSet 名稱之間有什麼關係。
5. 如果要看 Deployment 是否完成 rollout，第一輪應看哪個指令。

## 今天要看的資源

1. weamind namespace 下的 Deployment
2. weamind namespace 下的 ReplicaSet
3. weamind namespace 下的 Pods

---

## Command 1

### 要驗證的問題

- `weamind` Deployment 目前宣告了多少副本，現在是否已經達成。

### 三個可選指令

```bash
kubectl get deployment -n weamind
kubectl get pods -n weamind
kubectl describe service weamind-line-bot -n weamind
```

### 為什麼這樣出題

- 這一輪的重點是先看 Deployment 自己宣告了多少副本，以及目前是否已達成，所以最直接的入口應該是 Deployment，而不是先看 Pods 或 Service。

### 指令

```bash
kubectl get pods -n weamind
kubectl get deployment -n weamind
```

### 關鍵輸出

```bash
NAME                       READY   STATUS    RESTARTS   AGE
weamind-5985b7f7f6-t2qpm   1/1     Running   0          55d
weamind-5985b7f7f6-wdptx   1/1     Running   0          55d

NAME      READY   UP-TO-DATE   AVAILABLE   AGE
weamind   2/2     2            2           59d
```

### 使用者選擇理由

- 使用者一開始在 `kubectl get pods -n weamind` 和 `kubectl get deployment -n weamind` 之間猶豫。
- 先看 Pods 後，發現雖然能看到有兩個 Pod 在跑，但這個畫面本身不直接告訴你「期望副本數是什麼」以及「目前是否達成 Deployment 想維持的數量」。
- 接著改看 Deployment，才發現這一層才是最直接能對照期望副本數、目前就緒數與可用數的入口。

### AI 判讀與修正

- 這次判斷方向是對的，而且你自己先試 Pod 再修正到 Deployment，這個修正過程本身就有學習價值。
- `kubectl get pods` 的價值在於看「現在有哪些實際執行個體」，但它不是第一眼最準確的管理層入口，因為它沒有直接告訴你 Deployment 宣告想維持幾個副本。
- `kubectl get deployment -n weamind` 才能直接看到 `READY 2/2`、`UP-TO-DATE 2`、`AVAILABLE 2`，也就是目前這個 Deployment 想維持 2 個副本，而且現況已經達成。
- 補一個更精準的說法：Pods 不是完全不能對照 Deployment，而是它們比較像「底層結果」；若題目是在問期望副本數與目前是否達成，Deployment 仍是更直接的入口。

### 一句話收斂

- 想確認 `weamind` 目前宣告幾個副本、是否已達成，第一眼應先看 Deployment，而不是先看 Pods。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- `weamind` Deployment 背後目前是哪個 ReplicaSet 在承接，想要的副本數與目前狀態是什麼。

### 三個可選指令

```bash
kubectl get rs -n weamind
kubectl get endpoints -n weamind
kubectl logs -n weamind deployment/weamind
```

### 為什麼這樣出題

- 這一輪要看的是 Deployment 底下的下一層管理資源，所以最該先看的應該是 ReplicaSet，而不是 Endpoints 或 logs。

### 指令

```bash
kubectl get rs -n weamind
```

### 關鍵輸出

```bash
NAME                 DESIRED   CURRENT   READY   AGE
weamind-5985b7f7f6   2         2         2       55d
weamind-59d4666fc4   0         0         0       59d
weamind-6d7d894c59   0         0         0       59d
weamind-7459f5854c   0         0         0       59d
weamind-75f5579c8    0         0         0       59d
weamind-77dd8c5d49   0         0         0       59d
weamind-c4864fbc4    0         0         0       59d
weamind-f86bc7bdf    0         0         0       59d
```

### 使用者選擇理由

- 使用者選 `kubectl get rs -n weamind`，因為這題是在問 Deployment 背後由哪個 ReplicaSet 承接，以及目前副本數狀態如何。
- 使用者觀察到這個輸出沒有先指定某個 Deployment 名稱，因此進一步追問：為什麼只列 namespace 就能看到結果，是否代表它本來就是在列出該 namespace 內所有 ReplicaSets，再從名稱前綴辨識它們屬於哪個 Deployment。
- 使用者也注意到目前最上面的 ReplicaSet 顯示 `2 / 2 / 2`，其餘舊版本都已縮到 0，並追問 `CURRENT` 與 `READY` 的差別。

### AI 判讀與修正

- 這次選 ReplicaSet 是對的，因為題目就是要看 Deployment 下一層目前由誰承接。
- `kubectl get rs -n weamind` 的意圖，確實是列出 `weamind` namespace 內所有 ReplicaSets，而不是只列某一個 Deployment 底下的 ReplicaSet。之所以仍然有判讀價值，是因為名稱前綴 `weamind-...` 已經讓你看得出這批 ReplicaSet 都是同一個 Deployment rollout 歷史留下來的版本。
- 如果今天是 namespace 裡有很多不同 app，或你想更精準地只看某一個 Deployment 相關的 ReplicaSet，才會再往下用 label selector、owner reference，或 `kubectl describe deployment weamind -n weamind` 來縮小範圍。以 WeaMind 目前這個 namespace 幾乎只看同一個 app 的情境，先用 `get rs` 直接看全體是合理入口。
- `DESIRED` 表示這個 ReplicaSet 想維持幾個 Pod；`CURRENT` 表示它目前實際建立出多少個 Pod；`READY` 表示這些 Pod 裡有多少個已經 Ready、可接流量。
- 所以 `CURRENT` 和 `READY` 的差別在於：`CURRENT` 比較偏「物件數量已存在」，`READY` 比較偏「這些 Pod 已經通過就緒條件」。若某些 Pod 已經被建立但還沒通過 readiness probe，常見情況就是 `CURRENT` 大於 `READY`。
- 以這次輸出來看，`weamind-5985b7f7f6` 這個 ReplicaSet 是目前承接中的版本，因為它的 `DESIRED / CURRENT / READY` 都是 2；其餘舊 ReplicaSets 都還留著歷史紀錄，但目前副本數都降為 0。

### 一句話收斂

- `kubectl get rs -n weamind` 會列出 namespace 內所有 ReplicaSets；在這次輸出裡，可以看出目前由 `weamind-5985b7f7f6` 承接，而 `CURRENT` 是已建立數、`READY` 是已就緒數。

### 狀態

- 已完成

---

## Command 3

### 要驗證的問題

- 如果只想看某一個 Deployment 底下目前由哪個 ReplicaSet 承接，以及舊的 ReplicaSets 是哪些，哪個指令最直接。

### 三個可選指令

```bash
kubectl describe deployment weamind -n weamind
kubectl get rs -n weamind -l app=weamind
kubectl get pods -n weamind --show-labels
```

### 為什麼這樣出題

- 這一輪的重點是從 Deployment 自己的視角直接看 `NewReplicaSet` 與 `OldReplicaSets`，所以 `describe deployment` 是資訊最貼題的入口；其餘兩個指令可以幫助縮小範圍，但不是直接回答這個問題。

### 指令

```bash
kubectl describe deployment weamind -n weamind
```

### 關鍵輸出

```bash
Name:                   weamind
Namespace:              weamind
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 8
Selector:               app=weamind
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
StrategyType:           RollingUpdate
Conditions:
	Type           Status  Reason
	----           ------  ------
	Available      True    MinimumReplicasAvailable
	Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  weamind-c4864fbc4 (0/0 replicas created), weamind-75f5579c8 (0/0 replicas created), weamind-77dd8c5d49 (0/0 replicas created), weamind-f86bc7bdf (0/0 replicas created), weamind-7459f5854c (0/0 replicas created), weamind-59d4666fc4 (0/0 replicas created), weamind-6d7d894c59 (0/0 replicas created)
NewReplicaSet:   weamind-5985b7f7f6 (2/2 replicas created)
Events:          <none>
```

### 使用者選擇理由

- 使用者想直接確認某一個 Deployment 底下目前由哪個 ReplicaSet 承接，而不是再看整個 namespace 內所有 ReplicaSets。
- 實際跑完後，使用者確認這個輸出確實能直接看到 `NewReplicaSet` 和 `OldReplicaSets`。
- 使用者也觀察到：這個指令雖然很完整，但若目標只是快速看某個 ReplicaSet，雜訊會比 `get rs` 更高。

### AI 判讀與修正

- 這次補跑 `kubectl describe deployment weamind -n weamind` 很有價值，因為它把前一輪的延伸疑問直接收斂掉了。
- 和 `kubectl get rs -n weamind` 相比，這個指令的優勢是它直接站在 Deployment 視角，把 `NewReplicaSet`、`OldReplicaSets`、更新策略、selector、conditions 一次列出來，因此更貼近「某個 Deployment 底下 currently 由誰承接」這個問題。
- 代價也正如你觀察到的：它的資訊面比較廣，若只是想快速掃一眼目前有哪些 ReplicaSets，`get rs` 會更乾淨；若是要確認 owner 關係與 rollout 歷史，`describe deployment` 會更準。
- 以這次輸出來看，可以直接收斂出：目前 `weamind-5985b7f7f6` 是承接中的 `NewReplicaSet`，其餘列出的 `OldReplicaSets` 都是舊 rollout 留下來、但目前副本數已縮為 0 的版本。

### 一句話收斂

- 想直接看某個 Deployment 目前由哪個 ReplicaSet 承接，`kubectl describe deployment <name> -n <namespace>` 比 `get rs` 更貼題，但資訊也更雜。

### 狀態

- 已完成

---

## Command 4

### 要驗證的問題

- ReplicaSet 底下實際跑的是哪些 Pods，這些 Pod 名稱和 ReplicaSet 名稱之間有什麼關係。

### 三個可選指令

```bash
kubectl get pods -n weamind
kubectl get pods -n weamind --show-labels
kubectl describe deployment weamind -n weamind
```

### 為什麼這樣出題

- 這一輪需要先看到實際 Pod 名稱，再視需要補 labels；`describe deployment` 能補背景，但不是第一眼最直接的觀察點。

### 指令

```bash
kubectl get pods -n weamind --show-labels
```

### 關鍵輸出

```bash
NAME                       READY   STATUS    RESTARTS   AGE   LABELS
weamind-5985b7f7f6-t2qpm   1/1     Running   0          55d   app=weamind,pod-template-hash=5985b7f7f6
weamind-5985b7f7f6-wdptx   1/1     Running   0          55d   app=weamind,pod-template-hash=5985b7f7f6
```

### 使用者選擇理由

- 使用者選 `kubectl get pods -n weamind --show-labels`，因為這題是在問實際跑的是哪些 Pods，以及它們和 ReplicaSet 的對應關係。
- 使用者的直覺是：既然 repo 沒有手寫 ReplicaSet YAML，那這層關係應該還是得回到 Deployment 去理解；但只看 `describe deployment` 又不夠直接看到 Pod 和 ReplicaSet 的逐一對應。
- 使用者雖然從輸出看到 `pod-template-hash=5985b7f7f6`，但仍不確定這是否足以證明 Pod 對應到哪個 ReplicaSet，因此暫時無法自己收斂這題。

### AI 判讀與修正

- 這一輪選 `--show-labels` 是合理的，因為如果只看 Pod 名稱，能看到前綴相似，但還少一層更明確的對照訊號；labels 正好把這層訊號補出來。
- 這題的最小收斂要抓兩個對應點：第一，Pod 名稱 `weamind-5985b7f7f6-t2qpm`、`weamind-5985b7f7f6-wdptx` 前半段的 `weamind-5985b7f7f6`，已經和前一輪看到的 ReplicaSet 名稱 `weamind-5985b7f7f6` 對上。第二，Pods 上的 `pod-template-hash=5985b7f7f6`，也正好和這個 ReplicaSet 名稱尾段的 hash 一致。
- 所以雖然這個輸出沒有直接寫出「owner 是哪個 ReplicaSet」，但它已經給出足夠強的對照線索：目前這兩個 Pods 是由 `weamind-5985b7f7f6` 這個 ReplicaSet 建出來的。
- 你的直覺也對一半：因為 repo 沒有獨立手寫 ReplicaSet YAML，所以這層關係確實要回到 Deployment 的 rollout 結果去理解；但執行期要把 Pod 對回 ReplicaSet，最直接的觀察點不是 Deployment YAML 本身，而是 Pod 名稱前綴加上 `pod-template-hash` 這個 label。
- 如果之後要看更精準的 owner 關係，而不是靠名稱和 hash 判讀，可以再補看單一 Pod 的 `ownerReferences`；但對今天這題來說，先能用 Pod 名稱與 `pod-template-hash` 對回 ReplicaSet，就已經夠用了。

### 一句話收斂

- Pod 名稱前綴和 `pod-template-hash` 都能對回 ReplicaSet 名稱，因此這次輸出的兩個 Pods 都是由 `weamind-5985b7f7f6` 這個 ReplicaSet 建出來的。

### 狀態

- 已完成

---

## Command 5

### 要驗證的問題

- 如果今天想看 Deployment 的 rollout 是否完成，第一輪最有價值的觀察指令是什麼。

### 三個可選指令

```bash
kubectl rollout status deployment/weamind -n weamind
kubectl get svc -n weamind
kubectl get configmap -n weamind
```

### 為什麼這樣出題

- 這一輪問題直接在問 rollout 狀態，所以最準確的入口就是 rollout status，而不是去看 Service 或 ConfigMap。

### 指令

```bash
kubectl rollout status deployment/weamind -n weamind
```

### 關鍵輸出

```bash
deployment "weamind" successfully rolled out
```

### 使用者選擇理由

- 使用者選 `kubectl rollout status deployment/weamind -n weamind`，因為題目是在問某個 Deployment 的 rollout 是否完成，理應直接看和 deployment rollout 狀態最相關的指令。
- 使用者也同時意識到：自己雖然知道這是正確入口，但還不完全清楚 `rollout status` 真正代表什麼，以及 `successfully rolled out` 背後的成功條件是什麼。

### AI 判讀與修正

- 這次選 `rollout status` 是對的，因為它不是在看一般資源存在與否，而是在看這個 Deployment 的更新流程是否已收斂到成功狀態。
- 對 Deployment 來說，`rollout` 可以先理解成「把新的 Pod template 版本逐步推進到實際運行狀態」的過程；所以 `rollout status` 關注的不是 Service 或 ConfigMap 本身，而是 Deployment 這條更新鏈是否完成交接。
- `deployment "weamind" successfully rolled out` 可以先做最小理解：Deployment 目前期望的新版本已經成功推進，新的 ReplicaSet 已可用，所需副本數也已達到可接受狀態，因此這次 rollout 沒有停在半套狀態。
- 這不等於它在回答所有健康資訊，但至少表示 Deployment controller 觀察到這次 rollout 已完成，而不是仍在等待新 Pod 起來、等待 Ready，或卡在某個更新過程中。
- 你可以先把它白話記成：最新版本的 Pod template 已經成功接手，目前這個 Deployment 的更新流程已完成。

### 一句話收斂

- `kubectl rollout status deployment/<name> -n <namespace>` 是看 Deployment 更新是否已完成的直接入口；`successfully rolled out` 代表最新版本已成功接手。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- 用 `kubectl get deployment -n weamind` 確認 Deployment 想維持的副本數與目前是否達成。
- 用 `kubectl get rs -n weamind` 看出目前承接中的 ReplicaSet 與舊 rollout 歷史。
- 用 `kubectl describe deployment weamind -n weamind` 直接從 Deployment 視角確認 `NewReplicaSet`、`OldReplicaSets` 與 rolling update 狀態。
- 用 `kubectl get pods -n weamind --show-labels` 把 Pods 透過名稱前綴與 `pod-template-hash` 對回 ReplicaSet。
- 用 `kubectl rollout status deployment/weamind -n weamind` 確認目前這個 Deployment 的 rollout 已成功完成。

### 練習後還不順手的地方

- `kubectl get rs`、`kubectl describe deployment`、`kubectl get pods --show-labels` 三者各自適合拿來回答什麼問題，仍需要再多練幾次才會更直覺。
- `rollout status` 的精確語意，目前已抓到大方向，但之後還可以再和 rollout strategy、progressing condition 一起補強。

### 補充

- 今天的重點不是背指令大全，而是把 Deployment、ReplicaSet、Pods 三層資源對成同一條管理鏈。
- 每一輪預設應由使用者先在三個可選指令中做判斷，再實際執行選中的指令並貼回輸出。