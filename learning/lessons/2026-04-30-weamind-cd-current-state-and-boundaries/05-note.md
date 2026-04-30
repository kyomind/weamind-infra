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

### Publish GHCR 與 Publish Release 是並行、串接，還是不同入口

- 這也是延伸追問，應放在 note，不塞回主答案。
- 更準確地說，它們不是同一條鏈上的前後步驟，而是 **兩個不同觸發入口的 workflow**。
- [references/weamind-app-publish-ghcr.yml](references/weamind-app-publish-ghcr.yml) 是 main push 路徑。
- 它的觸發條件是 `workflow_run`，也就是等 `CI` 完成後，再 publish `latest` 與 `sha-<short_sha>`。
- [references/weamind-app-publish-release.yml](references/weamind-app-publish-release.yml) 是 release tag 路徑。
- 它的觸發條件是 push `v*` tag，會直接 build 並 push 完整版、minor、major。
- 所以這兩條路徑不是互相串接，也不是固定先後順序，而是 **你做了哪種事件，就進哪條路徑。**

### 它們是在重複 publish 兩份 image 嗎

- 不是「兩份不同 image」這種概念，比較準確的是：**同一次 build 出來的 image 內容，可以同時被貼上多個 tag。**
- tag 比較像是同一個 image digest 的多個名字。
- 例如 release workflow 發佈 `v1.1.4` 時，可以把同一個 build 結果同時標成：
	- `1.1.4`
	- `1.1`
	- `1`
- 它不是三個不同版本內容，而是三個 tag 都指向同一個 image digest。
- 同理，main push 路徑裡的 `latest` 與 `sha-<short_sha>`，也通常是在同一次 build-and-push 裡一起被貼到同一個 image 上。

### 最短版收斂

- Publish GHCR 與 Publish Release 是兩條不同入口的 workflow，不是同一條路徑的前後步驟。
- 進哪一條，取決於觸發事件：main push 走一條，push release tag 走另一條。
- 它們做的不是複製出很多份不同 image，而是把同一次 build 出來的 image 內容貼上不同 tag。
- 所以 tag 是名稱層，image digest 才是底下真正的內容指標。

### 為什麼看起來像重複，因為它們其實真的各自會 build

- 這也是很合理的追問，而且不只是你會卡住。
- 直接看這兩份 workflow，任何人都很容易先得到同一個直覺：**它們都在 build，那不就是重複做了兩次嗎？**
- 這個直覺沒有錯，因為從 workflow 定義來看，兩條路徑確實都是各自 build。
- main push 路徑會 build 一次，然後 push `latest` 與 `sha-<short_sha>`。
- release tag 路徑也會再 build 一次，然後 push 完整版、minor、major。

### 所以它們不是「不重複 build」，而是「不是同一條流程內的重複步驟」

- 更準確的說法不是「它們沒有重複」，而是：**它們是兩條分開觸發的 publish workflow，各自有自己的 build-and-push。**
- 也就是說，從 CI/CD pipeline 設計角度看，它們是兩個入口，不是一個 workflow 裡先 build 再把同一份產物拿去不同地方 reuse。
- 所以如果只問「這兩個 YAML 會不會各自 build」，答案其實是：**會。**

### 什麼情況下只會走一條

- 若今天只是一般 main push，沒有建立 release tag，那通常只會走 main push 這條路。
- 這時只會 build 一次，push `latest` 與 `sha`。

### 什麼情況下兩條都可能走

- 若某個 commit 先進到 main，之後你又替這個 commit 打了 `v1.1.4` 這種 release tag，那兩條路就可能都跑。
- 第一條先因為 main push 而 build 一次。
- 第二條再因為 push release tag 而 build 一次。
- 這種情況下，**兩條 workflow 確實可能對同一份程式碼各 build 一次。**

### 那這樣算不算浪費，或設計錯誤

- 不一定算錯，而是取決於團隊想優化哪一件事。
- 這種設計的好處是：
	- main push 與 release tag 可以各自獨立運作
	- 每條路徑的觸發條件與 tag 策略很清楚
	- workflow 比較直白，不需要先引入跨 workflow 共用 artifact 的複雜設計
- 代價也很明確：
	- 某些情況下會對同一份程式碼重複 build
	- build 時間與 compute 會多花一份
	- 若未來很在意效率，才可能再往「一次 build，多處 reuse」的方向優化

### 在真實團隊裡，這種重複 build 算不算問題

- 不一定，而且很多團隊一開始都會接受這種設計。
- 如果專案規模不大、release 頻率不高、build 時間也不長，那它通常比較像「可接受的冗餘」，不是立即要解的問題。
- 這種情況下，大家通常更在意的是：
	- 路徑是不是清楚
	- 版本語意是不是清楚
	- release 與 main push 的責任有沒有切開
	- 壞了之後好不好查
- 但如果出現下面幾種訊號，它就會開始變成值得處理的問題：
	- Docker build 很慢，常常拖長 pipeline
	- build 成本高，multi-arch image 特別花時間與 compute
	- release 很頻繁，重複 build 的浪費開始累積
	- 團隊開始在意「同一個 release artifact 是否一定和先前驗證過的是同一份」
	- 供應鏈 / provenance / artifact traceability 變得更重要

### 什麼時候值得優化成「一次 build，多個 tag 共用」

- 通常是在團隊已經確認版本策略穩定之後，才值得往這邊優化。
- 比較常見的時機是：
	- 已經確定 main push 與 release 的邊界
	- 開始覺得重複 build 的時間或成本明顯可感
	- 想保證 release tag 指到的是某個已驗證過的固定 artifact，而不是再重建一次的新結果
- 這時候就會比較有理由把流程改成：
	- 先 build 一次
	- 產出固定 digest / artifact
	- 後續只是在不同時機補貼不同 tag，或重用同一份產物

### 對 WeaMind 目前算不算急問題

- 以 WeaMind 目前規模來看，這不是最急著先優化的點。
- 現在更重要的仍然是：
	- deploy source 要先收斂清楚
	- infra repo 與 app repo 的責任邊界要先定清楚
	- 第一版 CD 鏈路要先能成立
- 換句話說，**現在比較像是「可知道的設計代價」，還不是最優先要處理的工程缺口。**

### 最短版收斂

- 在真實團隊裡，重複 build 不一定是問題，要看 build 成本、release 頻率與 artifact 一致性需求。
- 小型專案或早期流程階段，很多團隊會先接受這種冗餘，換取路徑清楚。
- 當 build 成本變高、release 變頻繁、或團隊更在意 artifact 一致性時，才更值得優化成「一次 build，多個 tag 共用」。
- 對 WeaMind 目前來說，這是可理解的設計代價，但不是眼前最優先要解的問題。

### 目前這兩條路比較像什麼

- 它們比較像兩個獨立窗口：
	- 一個窗口負責持續交付中的 `latest` / `sha`
	- 一個窗口負責正式 release 的 version tags
- 兩個窗口都會各自做一次 build-and-push。
- 所以如果你覺得「看起來就是分開進行的」，這個感覺其實是對的。

### 最短版收斂

- 對，這兩條 workflow 目前是分開進行的，而且都各自會 build。
- 它們不是共享同一次 build 結果的設計。
- 若只有 main push，通常只跑第一條。
- 若某個 commit 後續又被打成 release tag，兩條都可能跑，於是同一份程式碼可能被 build 兩次。
- 這不是你看錯，而是目前 workflow 設計本來就比較偏「路徑清楚」而不是「避免重複 build」。

### 當 `1.1.4` 發佈後，舊的 `1` / `1.1` tag 會發生什麼事

- 這也是很自然的追問，因為一旦接受 minor / major 會前移，下一個問題一定是：**舊的 tag 會被怎麼處理？**
- 更準確的說法是：通常不是先把舊 tag 顯式刪掉，再新增新 tag。
- 比較接近實際機制的是：**同名 tag 被重新指向新的 image digest。**
- 也就是說，當 release workflow 把 `1.1.4`、`1.1`、`1` 一起 push 上去時：
	- `1.1.4` 會成為新的固定版本點
	- `1.1` 這個 tag 會從原本指向舊 digest，改成指向 `1.1.4` 對應的新 digest
	- `1` 也會一樣前移到新的 digest

### 那舊 image 上的 `1` / `1.1` 算不算被刪掉

- 從「tag 關聯」的角度看，可以說 **舊 image 失去了 `1` 或 `1.1` 這些 tag**。
- 也就是說，舊 digest 不再被這些 mutable tag 指著。
- 但這不等於整個舊 image 內容立刻從 registry 消失。

### 舊 image 會不會還留在 registry 裡

- 要看它是否還有其他引用。
- 如果舊 image 還有別的 tag 指著它，例如完整版本 tag `1.1.3`，那它當然還在。
- 如果舊 image 沒有任何 tag 了，registry 可能把它視為 untagged manifest。
- 這種 untagged 內容通常也不是當下立刻物理刪除，而是之後由 registry 的清理 / garbage collection / retention 規則決定何時清掉。

### 所以具體機制比較像什麼

- 不要把它想成「先 delete 舊 tag，再 create 新 tag」的手動流程。
- 更接近的心智模型是：**tag 是指標，push 同名 tag 的新 image 時，registry 會把這個指標改指到新 digest。**
- 舊 digest 若還有其他 tag 或 digest reference，就繼續存在。
- 舊 digest 若不再被任何 tag 指到，就變成 untagged，之後是否清理要看 registry 規則。

### 最短版收斂

- `1` 和 `1.1` 這種 tag 前移時，本質上是「重新指向新 digest」。
- 舊 image 不一定立刻被刪掉；只是舊 digest 不再被這些 tag 指向。
- 如果舊 image 還有完整版本 tag，例如 `1.1.3`，它就還在。
- 如果它沒其他 tag 了，才可能在之後被 registry 視為 untagged 內容並逐步清理。

## Flashcards
