# 2026-04-29 Helm In WeaMind Boundaries and Costs Note

## 學習注意事項

- 今天先把 Helm 放回 WeaMind 的 repo 邊界與 W8 CD 脈絡，不提前展開 Day 3 的 CD 設計細節。
- 若討論中冒出 Helm template 寫法、chart 結構細節或 GitOps 工具比較，先記在這裡，不讓今天 QA 膨脹。
- 若某個點比較像 Day 3 的 deploy source / repo boundary 延伸，先記錄為銜接點。

## Notes

### 為什麼「先做 CD，再考慮 Helm」值得單獨記

- 這是今天最重要的收斂之一，因為它剛好把 W8 的主問題和 Helm 工具討論切開。
- W8 當前最缺的，不是模板化能力，而是 `release image -> infra repo version state -> cluster update` 這條最後一跳還沒有被正式定清楚。
- 所以比較穩的順序不是「先把 repo Helm 化，再來做 CD」，而是：**先把 deploy source、repo boundary 與 CD state 做對，再判斷 Helm 是否真的能在下一步增加價值。**
- 這也解釋了為什麼 Helm 不是今天的前提條件。Helm 可以幫 release-level 管理，但不等於 CD 本身。

### ⭐️引入 Helm 後，更新一個版本的操作方式會怎麼不同

- 這題值得另外記，因為它正好對應今天回答時卡住的地方。
- 先故意把 CD 拿掉，只看「人手動更新版本」這件事，差異其實就已經很明顯。

#### 沒有 Helm 時，更新一個版本比較像什麼

- source of truth 比較直接：通常就是 repo 裡那份 raw manifest。
- 若今天只是更新 image tag，直覺做法通常是直接改 `Deployment` 裡的 `image`，例如 [manifests/deployment.yaml](manifests/deployment.yaml)。
- 若有其他欄位也要一起改，例如 `ConfigMap`、`Ingress` 或 annotations，也是一份份 manifest 直接改。
- ⭐️套用方式通常是 `kubectl apply -f ...`，或重新 apply 整個目錄。
- 這種路徑的優點是直觀：你在 Git 裡改的內容，和最後送進 cluster 的 YAML 幾乎是同一份東西。
- 但它的限制也很清楚：**你雖然可以用 Git 追 manifest 變更，卻⭐️沒有一個額外的 release 單位幫你把「這次一起變的 Deployment、ConfigMap、Ingress」打包成同一個 revision。**
- 所以沒有 Helm 時，更新比較像：**直接改最終資源定義，然後重新 apply。**

#### 有 Helm，但還沒有 CD 時，更新一個版本比較像什麼

- ⭐️source of truth 會**往前移一層**，不再只看最終 YAML，而是看 chart、templates 與 values。
- ⭐️如果今天只是更新 image tag，常見做法不再是去改 render 後的 Deployment YAML，而是改像 `values.yaml` 裡的 `image.tag`，或 upgrade 時用 override 帶進去。
- 接著不是直接 `kubectl apply` 那份最終 YAML，而是跑 `helm upgrade`，讓 Helm 重新 render templates，再把整個 release 更新進 cluster。
- 若這次除了 image tag，還一起調了環境值、annotations 或 Service / Ingress 的某些欄位，這些改動會一起落在同一個 Helm release revision 底下。
- ⭐️這種路徑的好處是：**更新的單位不再只是單一 manifest，而是整個 release。** 之後可以用 `helm history`、`helm status`、`helm rollback` 這些 release-level 工具去看待這次變更。
- 但**代價也很明顯**：你在 Git 裡看到的，不一定就是最後送進 cluster 的最終 YAML；中間還隔著一層 render。也因此 review 與 debug 時，常要多問一句：**這個 cluster state 是哪份 values 配哪組 templates render 出來的？**
- ⭐️所以有 Helm 但沒有 CD 時，更新比較像：**改 chart 輸入，然後用 `helm upgrade` 更新整個 release。**

#### 把兩者壓成最短差異

- **沒有 Helm**：直接改最終 manifest，直接 apply，Git 看到什麼通常就 deploy 什麼。
- **有 Helm**：改的是 chart 輸入，不一定是最終 manifest；再由 Helm render 後，用 release 為單位更新 cluster。
- 所以兩者最大的差別，不在於「有沒有自動化」，而在於：**⭐️更新時你操作的是最終資源定義，還是操作生成這批資源的輸入；以及 cluster 裡有沒有一個 release-level 的管理單位。**

#### 為什麼這題值得單獨記

- 因為它可以幫忙切開兩種常見混淆：
- Helm 不等於 CD。
- 就算沒有 CD，Helm 也已經會改變你的更新路徑、review 方式與 rollback 心智模型。
- 這也說明 Helm 的價值與成本，不應只在「自動化」角度看，而要看它是否真的值得讓團隊把操作入口從 raw manifests 換成 chart inputs。

### 可以只 chart 一部分，而不是整個 repo 嗎

- 可以，而且這通常比一開始就把整個 repo 全部 chart 化更穩。
- 這裡的重點不是「Helm 只能管部分資源」，而是：**chart 比較適合包住同一個 release 邊界內、會一起安裝、一起升級、一起回滾的那一組資源。**
- 所以所謂「只 chart 一部分」，通常是在說：只把某一組很像同一個 app release 的資源做成 chart，其他資源先維持 raw manifests，或由別的 chart / 別的管理方式處理。
- ⭐️這是常見實踐，因為 Helm 最擅長的是管理一個 release，而不是強迫你把整個叢集裡所有 YAML 都塞進同一個 chart。
- ⭐️但有一個邊界要守住：**同一個資源不要同時被 raw manifests 和 Helm 共同管理。** 否則 ownership 會混亂，後面很難判斷到底哪一邊才是 source of truth。
- 若把這個觀念對回 WeaMind，未來若真的要局部引 Helm，比較合理的方向會是先看 app release 附近的那一組資源，例如 `Deployment`、`Service`、部分 `ConfigMap`、`Ingress` 這類和應用版本比較靠近的東西；而不是先假設 namespace 或所有其他資源都要一起搬進同一個 chart。
- 所以「不要一口氣把整個 repo 全 chart 化」的真正意思是：**先找出哪一組資源真的有共同 release 邊界、共同 values 需求、共同升級節奏，再決定要不要把那一塊做成 chart。**

### 一個 repo 被 chart 化，具體到底是什麼意思

- ⭐️這句話容易被講得很抽象，但如果拆開來看，其實是在說 **repo 的某些 Kubernetes manifests，開始不再以「最終 YAML」為主要維護單位**，而改成**用 Helm chart 結構來維護**。
- 更具體地說，通常至少會發生這幾件事：
- 原本直接可 apply 的 YAML，改寫成 `templates/` 裡的模板。
- 常變的欄位，例如 `image.tag`、`replicas`、host、部分環境值，被抽到 `values.yaml` 或其他 values 檔。
- 部署方式從直接 `kubectl apply -f ...`，改成以 `helm install` / `helm upgrade` 為主，讓 Helm 先 render 再安裝。
- 從此之後，這一組資源會以 Helm release 的角度被追蹤，而不是只看單份 manifest。
- 所以「repo 被 chart 化」不一定表示整個 repo 只剩一個 chart，也不一定表示所有檔案都要搬進 Helm。更常見的意思是：**repo 裡有某一部分資源，開始改用 chart + values + release 這套結構與操作路徑管理。**
- 白話一點講：
- **沒 chart 化時**，你主要在維護最終 YAML。
- **chart 化之後**，你主要在維護「生成這些 YAML 的模板和輸入」。
- 這也是為什麼 chart 化不只是資料夾重組，而是整個操作入口、review 習慣與 debug 心智模型都會跟著改變。

### 混合式管理時，會同時出現 `helm upgrade` 和 `kubectl apply` 嗎

- ⭐️會，而且這其實就是混合式管理最自然的結果。
- 如果一個 repo 裡有一部分資源已經改由 Helm chart 管，另一部分仍然維持 raw manifests，那操作上本來就可能同時存在兩條路：
- Helm 管的那一塊，用 `helm upgrade`。
- raw manifests 管的那一塊，用 `kubectl apply -f ...`。
- 所以你剛剛的直覺是對的：**在同一個新部署或同一輪變更裡，兩者的確可能同時出現。**
- ⭐️但這裡最重要的前提不是「能不能混用」，而是 **混用的邊界要非常清楚**。

#### 可以混用的是「操作方式」，不能混用的是「同一個資源的 ownership」

- 混合式管理不代表同一個 `Deployment` 一下用 Helm 管、一下又直接 `kubectl apply` 那份 YAML。
- 比較穩的做法是：A 資源集合明確屬於 Helm release，B 資源集合明確屬於 raw manifests。
- 也就是說，可以同時存在兩種操作方式，但⭐️**同一個資源最好只有一個管理來源**。
- 否則最常見的後果就是：
- 你用 `kubectl apply` 改掉的東西，下一次 `helm upgrade` 又被 Helm render 回去。
- 或者你以為 Helm 在管某個欄位，但其實 raw manifest 也在另一邊維護同名資源，結果 ownership 變得很亂。

#### 在什麼情況下，同一輪部署真的會同時看到兩者

- 這通常出現在 repo 已經有明確分層時，例如：
- app release 那一塊資源用 Helm 管，所以升級 app 版本時跑 `helm upgrade`。
- 其他還沒 chart 化、或本來就不打算放進該 chart 的資源，仍用 `kubectl apply` 管。
- 這種情況下，同一輪變更裡先後出現兩種指令並不奇怪。奇怪的不是兩條命令同時存在，而是**你有沒有先定清楚哪一組資源屬於哪一條路徑。**

#### 如果未來 WeaMind 採混合式，心智模型應該怎麼抓

- 不要把 repo 想成「一半現代、一半過渡」這種模糊狀態。
- 更準確的想法是：**repo 內存在兩種已定義的 ownership 區塊，各自有自己的 source of truth 與更新方式。**
- 某一塊若已進 Helm，就用 chart / values / release 的邏輯管理。
- 某一塊若還是 raw manifests，就維持直接改 manifest 再 apply 的邏輯。
- 所以混合式不是不能做，而是要把「資源邊界」先畫清楚，否則操作上雖然看起來只是多兩條命令，實際上會變成誰都說自己是 source of truth。

#### 把這題壓成最短版

- **會，同一輪部署裡可能同時出現 `helm upgrade` 和 `kubectl apply`。**
- 但前提是：它們各自負責不同的資源集合。
- 真正不能混用的，不是命令本身，而是**同一個資源不能同時被 Helm 和 raw manifests 共同管理。**

## Flashcards

<!-- 待 lesson 過程補充 -->
