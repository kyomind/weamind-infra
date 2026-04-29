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

## Flashcards

<!-- 待 lesson 過程補充 -->
