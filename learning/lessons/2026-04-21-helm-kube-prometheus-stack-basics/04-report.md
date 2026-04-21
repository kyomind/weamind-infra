# 2026-04-21 Helm Kube Prometheus Stack Basics Report

## 今日主題

用 Helm 在 WeaMind 的 K3s 叢集完成一次 `kube-prometheus-stack` 最小安裝，並把 Helm / chart / release / 主要元件分工對回真實資源。

## 狀態

已完成 W7 Day 2 的最小安裝、驗證與 post-implementation QA 收斂。

## QA 收斂了什麼

- 我已把 `chart`、`release`、`values` 三者切開理解，知道 `chart` 是安裝藍圖、`release` 是安裝後的實例、`values` 是安裝時帶入的參數。
- 我已能把 `kube-prometheus-stack` 的核心元件對回今天真的看到的 workload：Grafana、Prometheus Operator、`kube-state-metrics` 是 `Deployment`；Prometheus 與 Alertmanager 是 `StatefulSet`；Node Exporter 是 `DaemonSet`。
- 我已能講出如果 release 建了但 Pod 起不來，第一輪應先切 release 邊界與 Kubernetes runtime 邊界，而不是直接跳去 app metrics 或 dashboard。

## 使用者原本卡住什麼

- 一開始對 Helm 幾乎沒有概念，不確定 `chart`、`release`、`values` 各自站在哪一層。
- 雖然能看到很多 workload，但還不能穩定把元件角色、workload 型別與這次 install 成功之間的關係講成一版清楚的說法。
- 對 observability stack 的 high-level picture 也還不夠穩，不確定哪些東西其實已經在運作，哪些只是今天先裝好、後面才會繼續設定與展示。

## 今日真正留下來的核心收穫

- 我已經親手在 WeaMind 的 K3s 叢集用 Helm 完成一次 `kube-prometheus-stack` 的最小安裝，而不是只停留在 prework 概念理解。
- 我已經看到一套標準 observability stack 在 cluster 內的最小落地形態，並能從真實 workload 證據分辨 stateless、stateful 與每節點型元件。
- 我也建立了今天最重要的邊界：W7 先把 observability stack 裝起來並驗證可用；Helm 深水區、dashboard 展示與 app metrics 接點留到後續 lesson。

## 學完後已能講清楚什麼

- 我已經能講清楚 Helm 不是單純另一種 `kubectl apply`，因為它多了模板、values、release、revision 與 upgrade / rollback 這一層。
- 我已經能用今天的實際輸出講清楚 `kube-prometheus-stack` 裡至少幾個核心元件各在做什麼，以及它們對應到哪些 Kubernetes workload 類型。
- 我已經能高層次說明：Prometheus 已在收集資料、Node Exporter 已在每個 node 運作、Grafana 服務已建立可登入，只是今天還沒有進一步做 UI 展示與 dashboard 驗證。

## 仍待補強什麼

- 還沒正式做 Grafana `port-forward` 與 dashboard 展示。
- 還沒把 WeaMind app metrics 與 `/metrics` endpoint 接進這套 stack。
- Helm release / chart / values 與 raw manifests 的比較，目前只到最小理解，完整模型要留到 W8 補強。

## 下一步

- 下一堂接 W7 Day 3：Targets / ServiceMonitor / PodMonitor / Grafana dashboard 最小骨架。
- 屆時要正式看 Grafana、確認 targets / discovery，並回到 WeaMind app 端補 metrics 邏輯與 endpoint。
