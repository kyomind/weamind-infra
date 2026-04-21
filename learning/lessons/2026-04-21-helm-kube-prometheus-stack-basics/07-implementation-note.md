# 2026-04-21 Helm Kube Prometheus Stack Basics Implementation Notes

> 這份檔案與 `06-implementation.md` 綁定，只承接 `06` 過程中的 implementation-specific 關鍵觀察與決策討論。

## 為什麼 `helm status` 也會像卡前景一樣慢一下

- `helm status` 不是單純回一行「成功 / 失敗」而已。對 `kube-prometheus-stack` 這種大型 chart，它會整理 release metadata，還會把許多已建立的 resources 一起列出來。
- 所以它雖然不是 watch 指令，但也不像 `kubectl get ns` 這種很薄的查詢。chart 越大、資源越多，體感上越可能像前景卡一下。
- 這次的實際輸出也證明了這件事：它不只回 `STATUS: deployed`，還展開了 Alertmanager、Prometheus、Service、PrometheusRule、ServiceMonitor、Deployment、StatefulSet、DaemonSet 等大量資源資訊。

## install 後大量的 `observability-...` 名稱是怎麼來的

- 這些名稱主要不是 namespace 自動決定，而是 chart 依 Helm release name 組合出來的資源命名結果。
- 這次真正由我們手動決定的，至少有兩個重要值：release name `observability` 與 namespace `observability`。
- chart 模板通常會把 release name 拼進資源名，所以你才會看到像 `observability-grafana`、`observability-kube-state-metrics`、`observability-kube-prometh-operator` 這種前綴很一致的名字。
- 但它也不是只有簡單前綴拼接而已，像 `prometheus-observability-kube-prometh-prometheus`、`alertmanager-observability-kube-prometh-alertmanager` 這種名字，還混合了 chart 內部對元件角色的命名規則。
- 這也是為什麼這題應該被理解成「Helm release name 加上 chart 模板的命名策略」，而不是只看 namespace 一個因素。
