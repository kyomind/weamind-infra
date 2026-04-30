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

### 為什麼 `1.1` 這種 minor tag 會自動追到新 patch

- 這是 Q2 的延伸追問，應放在 note，不塞回主答案。
- 關鍵不是 Git tag 自己會變，而是 registry 端的 docker tag 可以被 release workflow 重新貼到新的 image digest 上。
- 例如 Git 裡的 `v1.1.4` 仍然是固定的 tag，不會自己移動。
- 但 release image publish workflow 可以在發佈 `1.1.4` 時，同時把同一個 image 標成 `1.1.4`、`1.1`、`1`。
- 這樣之後，registry 裡的 `1.1` 就會前移到最新的 `1.1.x` patch。
- 所以會移動的是 docker tag，例如 `1.1`；不會移動的是 Git tag，例如 `v1.1.4`。
- 若 release 流程沒有額外把 `1.1` 或 `1` 這些 tag 一起推上去，它們就不會自動追到新的 patch 版本。
- 這也正是為什麼 minor / major 雖然方便，但仍然不是最穩的正式 deploy source：它們本質上是會前移的別名，不是固定版本點。

### 這是 GHCR 自己會做，還是 workflow 設定出來的

- 這也是 Q2 的延伸追問，應放在 note，不塞回主答案。
- 更準確的答案是：**不是 GHCR 自己幫你維護 minor / major tag，而是 image publish workflow 主動把這些 tag push 上去。**
- GHCR / registry provider 做的事情比較像「保存你 push 上來的 image 與 tags」。
- 如果 workflow 只 push `1.1.4`，GHCR 不會自己額外幫你生出 `1.1` 或 `1`。
- ⭐️如果 workflow 在發佈 `1.1.4` 時，同時 push `1.1.4`、`1.1`、`1`，GHCR 就會把這些 tag 都指到同一個 image digest。
- 所以 minor / major 之所以會前移，不是 registry provider 自動幫你升級，而是 **release workflow 在新版本發佈時，主動把舊 tag 重新指向新 image。**
- 最短版可收成：**GHCR 不負責決定 tag 策略；真正決定哪些 tag 存在、哪些 tag 會前移的是 publish / release workflow。**

### WeaMind 目前是哪一種情況

- 這也是獨立 note，因為它是在把上面的通用機制對回 WeaMind 現況。
- 目前手上已經有兩份 app repo 帶回來的 workflow 快照。
- 第一條是 [references/weamind-app-publish-ghcr.yml](references/weamind-app-publish-ghcr.yml)，對應 main push 後的持續發佈路徑。
- 這條路徑會 push：
	- `latest`
	- `sha-<short_sha>`
- 第二條是 [references/weamind-app-publish-release.yml](references/weamind-app-publish-release.yml)，對應 release tag 發佈路徑。
- 這條路徑會在 push `v*` tag 時產出：
	- 完整版本 tag，例如 `1.1.4`
	- minor tag，例如 `1.1`
	- major tag，例如 `1`
- 所以 WeaMind 目前的情況已經可以講得很直接：
	- main push 會推 `latest` 與 `sha`
	- release tag 會另外推完整版、minor、major
- 這也代表 minor / major 的前移不是 GHCR 自動處理，而是 workflow 明確設定出來的結果。
- 最短版可收成：**WeaMind 已實作兩條 image publish 路徑：main push 產出 `latest` 與 `sha`，release tag 產出完整版、minor、major；tag 的存在與前移都來自 workflow，不是 GHCR 自動處理。**

## Flashcards
