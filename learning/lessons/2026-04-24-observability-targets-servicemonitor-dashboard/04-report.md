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

## 今日最後確認的關鍵理解

- Prometheus 不是自己亂掃整個 cluster；在這套模型裡，它是依賴 Prometheus Operator、CRD 與 selector 規則形成 target 集合。
- `ServiceMonitor` 選的是 `Service`，不是直接選 Pod；真正的鏈路是 Pod 提供 `/metrics`，`Service` 導流到 Pod，`ServiceMonitor` 指定要抓哪個 `Service`，Operator 再把它轉成 scrape config。
- 這次 metrics 接入的重點不是多建一條 service 鏈，而是**重用既有的 application Service**，讓一般 API 與 `/metrics` 共用同一批 Pods。
- 站在 W7 demo MVP 角度，Node 3、App 4、1 個 dashboard 是最小完成線；若只有 scrape 鏈成立但沒有 dashboard，就只能算資料鏈路已通，還不能算完整 observability demo baseline。

## 還沒完成但已明確定位的缺口

- Grafana 的實際 dashboard 畫面、查詢與 panel 整理仍需要最後確認，不能只停在 Prometheus targets 與 `/metrics` endpoint 驗證。
- 目前已經能證明 app metrics scrape 鏈成立，但仍需要用實際展示面把 Node 3 與 App 4 收斂成一個可 demo 的 dashboard。

## 下一步

- 進入 Grafana，先確認登入與入口正常，再建立或檢視最小 dashboard。
- 用 Node 3 與 App 4 指標把展示面補齊，完成 W7 demo MVP 的最後一段驗收。
- 若 dashboard 畫面與 Prometheus 查詢結果一致，再把 Day 4 的重點放在理解加深、口述收斂與面試式重講。
