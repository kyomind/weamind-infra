# 2026-03-12 Pod To VM And Endpoints Notes

## Pod IP 是怎麼來的？在 cluster 裡是不是唯一？

使用者在 command drill 看到 `10.42.1.14` 與 `10.42.2.13` 之後，追問這些 Pod IP 是否是在啟動時自動分配，以及它們是否在 cluster 內唯一。

這題的較準確答案是：

- 是，Pod IP 通常是在 Pod 被建立並成功接入 cluster 網路時，由 CNI 網路層自動分配，不是手動寫死在 Deployment 裡。
- 在 Pod 存活的當下，這個 IP 會是整個 cluster Pod network 裡的唯一位址，否則路由無法正確運作。
- 但這個 IP 不是永久身分證；只要 Pod 被刪掉、重建、重新調度，新的 Pod 很可能拿到不同的 IP。
- 這也正是為什麼前面的元件不應直接依賴 Pod IP，而是應該依賴 Service。Service 提供穩定入口，Endpoints 則反映目前這一刻實際對到哪些 Pod IP。

一句話收斂：Pod IP 是執行期由 cluster 網路動態分配的、當下唯一但不保證永久不變，因此流量應依賴 Service，而不是直接綁定 Pod IP。

## Pod 可以怎麼被「特定」？

使用者在 command drill 中追問：Service 看起來很容易指定到某個特定資源，但 Pod 是否也能被特定，還是只能透過 label 來抓。

這題可以拆成兩層：

- Pod 當然可以被「特定」，最直接的方式是用 Pod 名稱，例如 `kubectl describe pod <pod-name>`。所以 Pod 不是不能特定，只是不是像 Service 那樣天然就有一個穩定入口角色。
- 但在 Kubernetes 的日常操作與設計裡，通常不應太依賴某個 Pod 名稱，因為 Pod 是可替換、可重建的執行個體；今天這個 Pod 被刪掉或重建後，名稱與 IP 都可能改變。
- 因此，若問題是「某一群 app Pods 是哪些」、「Service 會選到誰」、「Deployment 管的是哪批 Pods」，更常用也更穩定的方式會是透過 labels 去篩選與對應。
- Service 尤其明顯就是依賴 selector 去選符合 labels 的 Pods，而不是寫死某個 Pod 名稱。

一句話收斂：Pod 可以用名稱被特定，但在 Kubernetes 的穩定操作模型裡，真正可持續依賴的通常是 labels，而不是某個單一 Pod 名稱或 Pod IP。