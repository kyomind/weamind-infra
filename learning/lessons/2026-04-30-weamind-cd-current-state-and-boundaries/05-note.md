# 2026-04-30 WeaMind CD Current State and Boundaries Note

## 學習注意事項

- 今天先把上午的 `CD` 骨架對回 WeaMind repo 現況，不提前展開明天 implement 的 workflow 細節。
- 若討論中冒出 GitHub token、PR automation、deploy workflow、GitOps controller 或 rollback 進階設計，先記在這裡，不讓今天 QA 膨脹。
- 明天 implement 只做最小可落地方向，今天先收斂責任邊界與版本策略。

## Notes

### 為什麼 `kubectl apply` 搭配 `latest` 不是「一定更新」，而是「不一定」

- 這是今天 Q1 裡很值得獨立記的一個盲點。
- 直覺上很容易以為：image 已經更新到 registry，Deployment 又寫 `latest`，再加上 `imagePullPolicy: Always`，所以只要 `kubectl apply` 就會吃到最新版本。
- ⭐️但更準確的說法是：**`Always` 只影響 Pod 在建立或重新建立時要不要重新 pull image，不負責決定 Pod 會不會被重建。**

### 先把兩件事拆開

- **image pull**：kubelet 在建立 Pod 時，決定要不要去 registry 拉 image。
- **Pod 重建 / rollout**：Deployment controller 判斷是否需要建立新 Pod、替換舊 Pod。
- `imagePullPolicy: Always` 只影響第一件事，不直接觸發第二件事。

### 什麼情況下，新的 image 真的比較可能被拉下來

- 最常見的前提是：**有新的 Pod 被建立。**
- 新 Pod 可能來自幾種情況：
	- Deployment 的 Pod template 真的變了，觸發 rollout
	- 手動 `rollout restart`
	- 舊 Pod 壞掉後被 controller 重建
	- Pod 被刪除、節點漂移、eviction 後重新建立
	- `replicas` 增加，新增出來的 Pod 會建立
- 只要是新建立的 Pod，且 policy 是 `Always`，它就會重新嘗試拉 `ghcr.io/kyomind/weamind:latest`。

### 為什麼這裡要說「不一定」

- 因為 `kubectl apply` 本身只是在說：把這份 manifest 再送進 API Server。
- 它**不保證** Deployment 一定會 rollout。
- Deployment 會不會建立新 Pod，關鍵通常在於 **Pod template 有沒有變**。
- 若你 apply 之後，Pod template 沒變，Deployment 往往不會建立新的 ReplicaSet，也不會替換現有 Pod。
- 沒有新 Pod，就沒有新的 image pull；這時即使 registry 裡的 `latest` 已經換內容，現有 Pod 也可能完全不動。

### 什麼叫 Pod template 變了，什麼叫沒變

- 像 [manifests/deployment.yaml](manifests/deployment.yaml) 裡的 `spec.template` 底下內容，才是會影響 rollout 的關鍵區塊。
- 例如改了這些東西，通常會讓 Pod template 改變：
	- `image`
	- container command
	- env / envFrom
	- probe 設定
	- `spec.template.metadata.annotations`
- 但如果只是重新 apply 同一份內容，或改的是 template 以外的欄位，情況就不同。

### 為什麼不是單純說「不會」

- 因為還是有些 apply 的情境，會間接導致新 Pod 被建立。
- 例如你雖然還是寫 `latest`，但同時改了 Pod template 裡其他欄位，Deployment 就可能 rollout，新的 Pod 這時會重新 pull `latest`。
- 又例如你把 `replicas: 2` 改成 `replicas: 3`，新長出來的那顆 Pod 會 pull 最新的 `latest`；但原本那兩顆既有 Pod 不一定會換掉。
- 所以這題不能簡化成「apply 一定會更新」，也不能粗暴講成「apply 一定不會更新」，更準確的答案才是：**是否更新，要看 apply 後有沒有導致新 Pod 被建立。**

### 最短版收斂

- `imagePullPolicy: Always` 不等於自動更新。
- 它只保證新 Pod 建立時重新拉 image。
- `kubectl apply` 也不等於一定 rollout。
- 若 apply 後沒有新 Pod，被更新的 `latest` 也不一定會進到現有 Pod。
- 所以真正要問的不是「有沒有 apply」，而是：**這次 apply 之後，有沒有導致新的 Pod 被建立。**

## Flashcards
