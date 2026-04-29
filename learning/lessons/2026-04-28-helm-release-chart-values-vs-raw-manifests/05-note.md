# 2026-04-28 Helm Release Chart Values vs Raw Manifests Note

## 學習注意事項

- 今天先把 Helm 的核心模型放回 WeaMind repo 與 W7 的真實操作經驗，不提前展開 CD 設計。
- 若討論中冒出 template 語法、subchart、chart publishing 或 chart repository 深水區，先記在這裡，不讓今天的 QA 膨脹。
- 若某個點更適合留到 W8 Day 2，先記錄為銜接點，不在今天一次補完。

## Notes

### Helm install 的最小鏈，為什麼值得單獨記

- 這條鏈值得單獨記，因為它剛好把 Helm 和「只是下了一條指令」切開。若只記得 `helm install ...`，很容易以為 Helm 只是比較方便的 `kubectl apply`；但真正多出來的是 render 與 release 管理這兩層。
- 目前最穩的最小鏈可以壓成：`chart + values -> render templates -> Kubernetes manifests -> 送進 Kubernetes API -> 記錄成 release`。
- 再白話一點講：Helm 不會直接拿 repo 裡現成 YAML 去套，而是先把 chart 裡的 templates 配上 values 展開成一批 manifests，再把那批結果送進 cluster。
- 這裡最容易忽略的最後一步是：**Helm 會把這次部署記成一個 release，並帶 revision 歷史。** 這也是為什麼後面會有 `helm status`、`helm history`、`helm rollback` 這整條 release 管理能力。
- 因此 `helm install` 的最小流程，不應只背成「下指令安裝」，而應記成：

```text
指定 chart 與 values
	-> render templates
	-> 產生 Kubernetes manifests
	-> 送進 cluster 建立資源
	-> 記錄成 release（含 revision）
```

- 這也回答了一個很重要的疑問：**render 出來的 YAML 通常不會自動寫回 infra repo。** 它主要是被送去建立叢集資源；而 release 對應的 manifest / revision 資訊，則由 Helm 存在 cluster 內。
- 所以如果之後想知道「Helm 當時到底套了什麼」，第一反應不應回 Git repo 找，而應先想到兩個方向：
- 看 cluster 內已經建立出的實際資源。
- 看 Helm release record，例如 `helm status`、`helm history`、`helm get manifest`。

### W7 當時手上到底有哪些東西

- 這題值得單獨整理，因為 `chart`、`chart repo`、`release`、`namespace` 很容易在第一次接觸 Helm 時混成一團。
- 先講概念層。W7 當時手上並不是 raw YAML，也不是「只有一條指令」。更準確地說，當時手上至少有這些東西：
- 一個遠端 chart repo：`prometheus-community`
- 一個要安裝的 chart：`prometheus-community/kube-prometheus-stack`
- 一個 release name：歷史 lesson 記錄裡是 `observability`
- 一個 target namespace：歷史 lesson 記錄裡是 `observability`
- 預設 values，或少量 override

- repo 內留下的 W7 證據鏈相當完整，至少能對回這組指令：

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo kube-prometheus-stack

helm upgrade --install observability prometheus-community/kube-prometheus-stack \
	-n observability --create-namespace
```

- 這組指令裡，最值得拆開看的有三個位置：
- `observability`：這是 release name。
- `prometheus-community/kube-prometheus-stack`：這是 chart 參考，表示 chart 來源是 `prometheus-community` 這個 repo，而實際要安裝的是 `kube-prometheus-stack`。
- `-n observability --create-namespace`：這表示把這個 release 安裝進 `observability` namespace；若 namespace 不存在，就先建立它。

- 所以 release 和 namespace 的關係，不是「兩個名字剛好一樣」而已，而是：**release 是 Helm 的部署實例名稱，namespace 是這個 release 裡大多數 namespaced 資源要被建立到哪裡。** 它們可以同名，但本質不是同一個概念。
- 這也解釋了當時 lesson 裡為什麼會看到 `NAME: observability` 和 `NAMESPACE: observability` 同時出現：前者在說 Helm release 叫什麼，後者在說這次部署主要落在哪個 namespace。

### 為什麼 W7 要先 `helm repo add` / `helm repo update` / `helm search repo`

- 這三行前置指令不是多餘儀式，而是在幫 Helm CLI 先建立「可解析的 chart 來源」。
- `helm repo add ...` 的作用，是把遠端 chart source 註冊到本機 Helm 設定裡，並給它一個別名 `prometheus-community`。沒有這一步，後面寫的 `prometheus-community/kube-prometheus-stack` 對 Helm 來說就只是陌生字串，它不知道 `prometheus-community` 是哪個來源。
- `helm repo update` 的作用，是把這個 repo 目前有哪些 chart、有哪些版本的索引抓到本機。沒有這一步，就算你加過 repo，本機也可能沒有最新 chart index，後面 install 或 search 時就可能找不到、或版本資訊過舊。
- `helm search repo kube-prometheus-stack` 嚴格來說不是 install 必要條件，但它很有實務價值，因為它是在安裝前先確認三件事：repo 有通、chart 名稱有對、目前可用版本是什麼。
- 所以如果你用的是 `repo-alias/chart-name` 這種 shorthand，例如 `prometheus-community/kube-prometheus-stack`，那至少前兩步通常不是可省略的。你不是直接拿某個 URL 或本地 chart package 安裝，而是先叫 Helm 去理解「`prometheus-community` 這個 repo 裡的 `kube-prometheus-stack` chart」。
- 只有在另一類做法裡，才可能跳過這種 repo 註冊流程，例如：
- 直接給 chart package 的 URL 或本地 `.tgz`
- 用 `oci://...` 這種 OCI registry 來源
- 但 W7 當時不是這兩種，所以先 `repo add`、再 `repo update`，是符合那次 install 寫法的。

### `repo add`、`repo update`、`install` 三者的分工

- 若再切細一點，`repo add` 比較像先把來源記進 Helm 的地址簿；`repo update` 才比較像把這個來源目前的 chart 清單與版本索引同步到本地 cache。
- 真的到 `helm install` / `helm upgrade --install` 時，Helm 才會去抓你指定的 chart 內容本體，而不是在 `repo add` 那一步就把整個 chart 包抓下來。
- 所以最短版可以記成：**`repo add` 記住來源，`repo update` 同步索引，`install` 才下載並使用指定 chart。**

### Helm revision 不是只記 diff，而是整個 release snapshot

- 這題值得單獨記，因為它剛好切開 Helm rollback 和 `kubectl rollout undo` 的思考方式。
- `kubectl rollout undo deployment/...` 回退的是 Deployment 這個 workload controller 的 rollout history；它主要把 Pod template 對回前一版，然後由 Deployment 控制器重新建立 Pods。
- Helm rollback 則不是只看單一 Deployment，而是看整個 release revision。只要某個資源屬於這個 release，而且在那個 revision 的 manifest 裡出現，它就屬於 Helm rollback 的概念範圍。
- 最重要的觀念是：**Helm revision 不是只記「這次有改的欄位」，而是更像記「這個 release 在那一版時的整體 manifest snapshot」。**
- 所以完全可能出現這種情況：某次 revision 實際只改了 Deployment / Pod 相關內容，Service 和 Ingress 跟上一版完全一樣；但它們仍然屬於這個 revision 的內容，只是內容剛好沒有差異。
- 因此 rollback 到某個 revision 時，Helm 的心智模型是「**把整個 release 對回那版 manifest state**」，不是只把最近那次 diff 過的幾個欄位反向操作一次。
- 這也解釋了為什麼某些 Helm rollback 在**體感上會很像**普通的 `rollout undo`：如果兩個 revision 之間真正有差異的只有 Deployment，那最後實際出現變動的可能也只有 Deployment；但概念上 Helm 仍是在對整個 release revision 回退，其他資源只是剛好沒有差異，所以結果接近 no-op。
- 最短版可記成：**`rollout undo` 回退的是 Deployment 的 rollout history；Helm rollback 回退的是整個 release revision，而 revision 比較像完整 snapshot，不只是 diff。**

### 為什麼 `rollout undo` 不是單純退回上一版 Pod

- 這題值得單獨記，因為初學者最容易把它想成「把新版 Pod 刪掉，換回舊版 Pod」。這樣抓到一半方向，但控制點還不夠準。
- 更精確的控制鏈是：**Deployment -> ReplicaSet -> Pods**。
- Deployment 自己不直接保存一堆「Pod 版本」讓你切換；⭐️它真正管理的是 Deployment spec 裡的 **Pod template**，也就是「**這一版應該長出什麼樣的 Pods**」。
- 每當 Deployment 的 Pod template 改變，Kubernetes 會為這個新 template **建出新的 ReplicaSet**；ReplicaSet 再負責實際維持對應數量的 Pods。
- 所以 `kubectl rollout undo deployment/...` 回退的核心，不是直接對 Pods 動手，而是：**把 Deployment 的 Pod template 對回前一版，然後讓 Deployment / ReplicaSet 控制鏈重新把對應 Pods 長回來。**
- 這也是為什麼更準確的說法是「回退 Deployment 的 rollout history」，而不是「回退 Pod 歷史」。Pod 比較像結果，不是主要版本控制單位。
- 若再講得更白話一點：

```text
你不是直接把某顆舊 Pod 從倉庫拿回來
而是把 Deployment 的規格退回舊版
然後讓 Kubernetes 根據那個舊規格重新長出一批 Pod
```

- 這也解釋了為什麼你有時候會直覺想到 ReplicaSet。這個直覺不算錯，因為 rollout undo 的過程確實和舊 ReplicaSet 有關；但最穩的講法仍然是：⭐️**使用者操作的是 Deployment，Deployment 再透過 ReplicaSet 對回舊版 Pod template。**
- 最短版可記成：**`rollout undo` 回退的是 Deployment 的 Pod template 歷史；Pods 不是被直接「切回舊版」，而是根據舊 template 被重新建立。**

## Flashcards

- Helm 不只是比較方便的 `kubectl apply`，真正多了哪三層？ #DevOps #card
	- 多了 `template`、`values`、`release state`
	- 先 render，再送進 cluster，最後記成可追 revision 的 release

- W7 安裝 `kube-prometheus-stack` 時，手上真正有的是什麼？ #DevOps #card
	- 是遠端 `chart repo` 裡的 chart 參考，不是 repo 內現成 raw YAML
	- 同時還有 release name、target namespace、預設 values 或少量 override

- `helm repo add`、`helm repo update`、`helm install` 各自負責什麼？ #DevOps #card
	- `repo add` 記住來源
	- `repo update` 同步 chart 索引
	- `install` / `upgrade --install` 才真的抓 chart、render 並建立 release

- 為什麼 Helm values 不是任意 yaml merge？ #DevOps #card
	- 只有 chart template 預先留出的入口，values 才有地方可以帶值
	- 這也是為什麼 `image.tag`、`replicaCount`、`ingress.host` 很適合 values 化，但 selector 或敏感值不應隨便暴露

- `kubectl rollout undo` 和 Helm rollback 的控制邊界差在哪？ #DevOps #card
	- `rollout undo` 回退的是 Deployment 的 Pod template 歷史
	- Helm rollback 回退的是整個 release revision
	- Helm revision 比較像完整 manifest snapshot，不只是 diff
