# 2026-04-24 Observability Targets ServiceMonitor Dashboard Report

## 今日主題

- 把 `kube-prometheus-stack` 從「已安裝」推進到「可講清楚 target discovery 鏈路、可讓 WeaMind app metrics 被 scrape、可收斂出 W7 demo MVP 驗收線」的狀態。

## 今日實際完成

- 釐清了這套 observability stack 的最小工作模型：Prometheus 負責 scrape，Prometheus Operator 負責把 `ServiceMonitor` / `PodMonitor` 轉成 scrape config。
- 將 observability stack 從 `observability` 重建為 `watchmind`，降低 release 與 namespace 命名辨識成本。
- 用 Prometheus targets API 確認 cluster baseline targets 已健康，並定位出 WeaMind app metrics 原本尚未接入的缺口。
- 在 WeaMind app repo 補出 `/metrics` 與 App 4 metrics，之後再根據 review 把 success / error / duration 從 request-level 修正為 event-level 記帳。
- 在 infra repo 補上 `ServiceMonitor` 與必要的 `Service.metadata.labels`，讓 Prometheus 能透過既有 `Service` scrape WeaMind app metrics。
- 完成 post-implementation QA，把 `ServiceMonitor` / `PodMonitor` 的邊界、target discovery 鏈路，以及 W7 demo MVP 的完成線整理成可口述答案。
- 已確認 Grafana 入口、Prometheus datasource 與現成 `node-exporter-mixin` dashboard 可用，Node 3 展示面可直接重用。
- 已在 Grafana Explore 與 panel 編輯畫面證明 App 4 metric 有真實 samples，且第一個 App 4 panel 已可開始成形。

## 今日最後確認的關鍵理解

- Prometheus 不是自己亂掃整個 cluster；在這套模型裡，它是依賴 Prometheus Operator、CRD 與 selector 規則形成 target 集合。
- `ServiceMonitor` 選的是 `Service`，不是直接選 Pod；真正的鏈路是 Pod 提供 `/metrics`，`Service` 導流到 Pod，`ServiceMonitor` 指定要抓哪個 `Service`，Operator 再把它轉成 scrape config。
- 這次 metrics 接入的重點不是多建一條 service 鏈，而是**重用既有的 application Service**，讓一般 API 與 `/metrics` 共用同一批 Pods。
- 站在 W7 demo MVP 角度，Node 3、App 4、1 個 dashboard 是最小完成線；若只有 scrape 鏈成立但沒有 dashboard，就只能算資料鏈路已通，還不能算完整 observability demo baseline。

## 還沒完成但已明確定位的缺口

- App 4 的 dashboard panel 雖已開始建立，但目前仍未收斂成最後可交付版。
- 更重要的是，今晚已浮出一個不能草率帶過的問題：在多 Pod 與多 worker 條件下，counter / increase 的數字語意是否能直接被解讀成精確 total。
- 這個問題已超出今晚原本想收尾的範圍，因此需要明天再接著判讀與決定是否回到 app metrics 實作層檢查。

## 下一步

- 今晚 stop 在這裡，不再新增新的實作 step。
- 明天先接這個明確缺口：釐清 App 4 counter 在多 Pod / 多 worker 下的解讀方式，再決定 dashboard 該怎麼收尾。
- 等這個語意問題釐清後，再完成 App 4 panel 與整體 W7 demo MVP 的最後驗收。
