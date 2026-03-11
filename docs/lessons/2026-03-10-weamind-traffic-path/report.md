# 2026-03-10 WeaMind Traffic Path Report

## 今日主題

把 Day 1 與 Day 2 的 networking 概念，正式對到 WeaMind 專案裡的實際流量路徑。

## 狀態

這份 report 已開始依照實際對話回填。

目前已完成第一輪 repo 對照與問答，主軸聚焦在 Service、Ingress、Deployment 的角色分工，以及 Service 為什麼不直接對 Pod 以外的外部流量負責。

## 這次對話實際學了什麼

- WeaMind 的 line-bot Service 使用 ClusterIP 是合理的，因為外部入口已由 Hetzner Load Balancer 與 Traefik 承接，Service 在這裡主要負責 cluster 內穩定入口與後端 Pod 分流。
- Traefik 不直接把流量送到 Pod，而是透過 Service 轉送，因為 Pod 是動態資源，會因為重建、擴縮或更新而改變。
- Service 的另一個重要責任是把流量分配到後面符合 selector 的多個 Pods，但它不負責決定 Pod 數量。
- 在 WeaMind repo 中，Ingress 會把流量送到 `weamind-line-bot` Service，Service 再依照 selector 對到 Deployment 建出的 Pods。

## 使用者原本卡住什麼

- 一開始比較容易把 Service 說成「只對 Traefik 暴露」，後來已修正為「Service 是 cluster 內的穩定入口，Traefik 只是這條外部流量路徑上的主要呼叫者」。
- 對 Endpoints 的概念還不熟，先前外部預習沒有正式碰到這一層。
- 一度把 Service 和 Deployment 的責任混在一起，後來已較清楚分開：Deployment 負責維持 Pod 副本，Service 負責找到 Pods 並轉送流量。

## 對話中釐清的關鍵點

- 在 [manifests/service.yaml](manifests/service.yaml#L1) 中，Service selector 是 `app: weamind`。
- 在 [manifests/deployment.yaml](manifests/deployment.yaml#L1) 中，Pod template label 也是 `app: weamind`，因此 Service 可以對到這批 Pods。
- 在 [manifests/ingress.yaml](manifests/ingress.yaml#L1) 中，Ingress 會把 `k8s.kyomind.tw` 的流量送到 `weamind-line-bot:80`。
- 如果 Service 的 Endpoints 是空的，第一輪應優先回頭檢查 Service selector 與 Deployment Pod labels 是否一致，而不是先去看 Deployment 名稱。

## 學完後已能講清楚什麼

- 為什麼 WeaMind 的 line-bot Service 使用 ClusterIP 是合理設計。
- 為什麼 Traefik 不直接把流量送到 Pod，而是先經過 Service。
- Service、Deployment、Ingress Controller 三者在這個專案中的責任邊界。
- 如果 Service 層出問題，第一輪應先檢查 selector、Pod labels 與 Endpoints。

## 仍待補強什麼

- 仍需要把 Endpoints 與 readiness 的關係再補清楚，避免只停在 selector 層面。
- 還需要把 `port` 與 `targetPort` 對不上時的症狀和 Endpoints 為空的症狀切開理解。
- 下一輪應補上實際 `kubectl get endpoints` 或相關觀察，讓 YAML 與動態狀態連起來。

## 下一步

- 完成這次 lesson 對話。
- 將對話中真正確認過的理解與仍有疑問的點寫回本檔。
