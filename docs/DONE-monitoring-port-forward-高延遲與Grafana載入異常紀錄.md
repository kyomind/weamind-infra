# Monitoring Port-Forward 高延遲與 Grafana 載入異常紀錄

整理日期：2026-04-29

## 文件目的

這份文件記錄 watchmind 監控面板在本機透過 `kubectl port-forward` 存取時的高延遲、Grafana 前端載入異常、以及相關 root cause 判讀。

這份文件的用途不是宣告問題已完全解決，而是作為 handoff：下一次若有新的 AI 或新的 debug session，可以直接從這裡接手，不必重跑整段探索。

## 問題摘要

使用者原本透過 dotfiles 中的兩個 alias 存取監控頁面：

- `pf-grafana='while true; do kubectl port-forward -n watchmind svc/watchmind-grafana 3000:80; sleep 10; done'`
- `pf-prometheus='while true; do kubectl port-forward -n watchmind svc/watchmind-kube-prometheus-prometheus 9090:9090; sleep 10; done'`

2026-04-29 的問題不是「完全無法開啟」，而是：

1. 監控頁面載入很慢。
2. Grafana 在完整重新載入分頁時，常出現 `Unable to find application file` 的 fallback error page。
3. CLI 端會持續出現 `broken pipe`、`error creating forwarding stream`、`error creating error stream: Timeout occurred`。
4. 頁面有時最終仍能成功載入，但中間會經歷部分 stream timeout 與重試。

## 重要前提

這個 K3s control plane 位於德國 Hetzner 機房，使用者位於台灣。

已知前提：

- 跨洲 latency 約 `600ms` 到 `800ms`。
- 本機 `kubectl` 並不是直接打遠端 API，而是先打 `https://127.0.0.1:6443`。
- `127.0.0.1:6443` 背後是 dotfiles 中的 `kube-tunnel` alias：

```bash
autossh -M 0 -N -L 127.0.0.1:6443:127.0.0.1:6443 \
  -o ServerAliveInterval=10 \
  -o ServerAliveCountMax=2 \
  -o ExitOnForwardFailure=yes \
  weamind-001
```

所以整條路徑是：

```text
Browser -> localhost:3000/9090 -> kubectl port-forward -> localhost:6443 -> autossh tunnel -> weamind-001 -> remote 127.0.0.1:6443 -> k3s apiserver -> port-forward stream -> target Pod/Service
```

## 已驗證事實

### 1. Grafana 與 Prometheus 本體沒有壞

- `watchmind-grafana` Pod 為 `3/3 Running`。
- `watchmind-grafana` Service endpoint 指向 `10.42.2.27:3000`。
- 直接對 Grafana Pod 開新的 port-forward，`/api/health` 可回 `200`。
- Prometheus Pod 與 Service 也都可正常回應。

因此這不是 Grafana Pod crash、Service selector 錯誤、或 Prometheus 後端故障。

### 2. 壞掉的常常是「某一條既有 session」，不是整個服務

多次觀察到：

- 某條既有 `kubectl port-forward` 仍占住本機 port，例如 `3000`。
- 但對該 port 做 `curl` 時，TCP 能接上，HTTP 卻 timeout。
- 清掉該 `kubectl` PID 後，重新開新的 tunnel，有時又能暫時恢復。

這表示 session 本身可能老化、卡死、或在高延遲情境下進入半失效狀態。

### 3. `kubectl` 到 API server 的路徑是慢的，但不是完全斷的

量測結果：

- 在遠端 `weamind-001` 上直接打 `https://127.0.0.1:6443/readyz`，約 `0.01s`。
- 在本機透過既有 `127.0.0.1:6443` tunnel 打 `https://127.0.0.1:6443/readyz`，約 `1.35s` 到 `1.77s`。
- 額外新開一條 `127.0.0.1:6444` fresh tunnel 後，打 `https://127.0.0.1:6444/readyz` 仍約 `1.51s` 到 `1.63s`。

結論：

1. control plane 本身不慢。
2. 慢的是「本機 -> 跨洲 tunnel -> remote apiserver」這條路。
3. 問題不像是單純舊 autossh session 老化，而是整條存取路徑本來就有高延遲硬成本。

### 4. 單次 CLI request 通常可用，但互動式 GUI 容易放大問題

代表性量測：

- `http://127.0.0.1:9090/query` 約 `1.0s` 到 `1.6s`。
- `http://127.0.0.1:3002/login` 約 `1.7s`。
- Grafana Pod 直連 port-forward 的 `8` 條平行 `/login` 請求約 `1.3s` 到 `2.6s`。
- Grafana Service port-forward 的 `8` 條平行 `/login` 請求約 `3.0s` 到 `7.2s`。

這表示：

1. 單次 request 雖慢，但還可用。
2. 一旦是瀏覽器完整重載分頁，因為要抓很多資產與 API，整體延遲會被明顯放大。
3. Service-based port-forward 比 Pod-based port-forward 更脆弱。

### 5. Grafana 的錯誤頁不是因為檔案真的不存在，而是前端 bundle 沒完整載入

從 `http://127.0.0.1:3004/login` 抓回來的 HTML 可確認：

- HTML 本身正常。
- HTML 會引用多個 `public/build/*.js` 與 `public/build/*.css`。
- HTML 內有 `window.__grafana_load_failed()` 的 fallback 機制。
- 若 `window.__grafana_app_bundle_loaded` 沒被設起來，頁面就會顯示 `Unable to find application file`。

實際資產下載測到：

- `public/build/runtime.53d05df664792bede5c3.js` 約 `1.6s`
- `public/build/6029.ced17922ce65e4fd1ef9.js` 約 `4.7s`
- `public/build/2108.1eca34080b36690d7ac7.js` 約 `13.2s`

因此這個畫面真正代表的是：

`login HTML 已回來，但前端 JS/CSS assets 載入不完整或過慢，導致 React app boot 失敗，最後掉進 Grafana fallback error page。`

### 6. cache 不是零影響，但也不是主因

使用者觀察：

- 無痕模式有時可成功。
- 原本的普通頁面較容易失敗。
- 已開啟的 dashboard 若只是維持觀看更新，通常還能撐；但若完整 reload 分頁，危險性顯著升高。

目前判讀：

1. cache / 既有 session 狀態 / 已載入的部分資產，會影響「最後是慢慢成功，還是落到 fallback error page」。
2. 但 cache 只像是助燃因素，不是起火點。
3. 主因仍是高延遲 `kubectl port-forward` 路徑對 full page reload 很不友善。

## 代表性錯誤訊息

實際在 CLI 看到的錯誤包含：

```text
E0429 ... portforward.go:391] "Unhandled Error" err="error copying from remote stream to local connection: ... write: broken pipe"
E0429 ... portforward.go:380] "Unhandled Error" err="error creating forwarding stream for port 3000 -> 3000: Timeout occurred"
E0429 ... portforward.go:357] "Unhandled Error" err="error creating error stream for port 3000 -> 3000: Timeout occurred"
```

這些錯誤不一定表示整個服務已死，而更像是：

`同一輪頁面載入裡，部分 forwarding stream 成功，部分 forwarding stream timeout。`

因此最後呈現會是：

1. 體感非常慢。
2. 某些靜態資產或 API 先失敗。
3. 瀏覽器靠重試與後續補載，頁面有時仍能成功打開。

## 目前最合理的 root cause

### 主因

以 `kubectl port-forward` 經由高延遲、跨洲、SSH tunnel 包起來的 control-plane 路徑去承載 Grafana / Prometheus 這種互動式 GUI，本身就接近使用邊界。

更具體地說：

1. `kubectl port-forward` 的資料流不是單純本地 TCP 直通，而是需要透過 apiserver 建立 stream。
2. Grafana / Prometheus 的完整 GUI 載入會產生多個並行連線。
3. 在高延遲情境下，不是每個 stream 都能順利建立成功。
4. 因此結果會呈現為「部分成功、部分 timeout、最後慢慢湊出頁面或落到 fallback error page」。

### 次因

- 瀏覽器本地 cache
- 既有分頁狀態
- 舊 session 殘留的資產引用或半完成狀態

這些因素會影響最後成功率，但不是根本原因。

## 已排除事項

目前可合理排除：

- Grafana Pod crash 或啟動失敗
- Prometheus Pod crash 或啟動失敗
- Grafana Service endpoint 配錯
- Prometheus Service endpoint 配錯
- 前端檔案在容器裡真的不存在
- control plane 在機房內部本身很慢
- `pf-grafana` / `pf-prometheus` alias 指向錯誤 resource

## 現階段操作建議

### 短期 workaround

1. 盡量避免完整 reload Grafana / Prometheus 分頁。
2. 若頁面已成功打開，只維持 dashboard 更新，比重新載入穩定。
3. 若要重新測試，優先用無痕模式，避免瀏覽器已累積的半成功 cache 狀態干擾判讀。
4. 若一定要用 port-forward，Grafana 優先考慮直連 Pod，而不是透過 Service。

### 中期方向

不建議長期把 Grafana / Prometheus GUI 存取建立在這條 control-plane `port-forward` 路徑上。

較合理的方向：

1. 提供正式 Ingress 或受保護的 GUI 入口。
2. 改走 VPN / Tailscale / 其他更接近 data-plane 的路徑。
3. 若只是看 dashboard，可考慮在更靠近叢集的位置開瀏覽器或遠端桌面。

## 待處理事項

目前仍有待決定的事項如下：

1. 是否要把 `pf-grafana` 從 Service port-forward 改成自動抓 Grafana Pod 的 Pod port-forward。
2. 是否要同樣調整 `pf-prometheus`，或至少新增一條 pod-based 備用 alias。
3. 是否要為 Grafana / Prometheus 提供正式且較穩定的 GUI 入口，取代長期依賴 `kubectl port-forward`。
4. 是否要把這次經驗整理進 lesson / troubleshooting 筆記，作為「control-plane path 不適合互動式 GUI」的案例。

## 若下次要繼續查，建議從哪裡開始

若下一次新的 AI 或新的 session 要接手，建議先做以下最小確認：

1. 確認 `watchmind-grafana` 與 `prometheus-watchmind-kube-prometheus-prometheus-0` 仍為 `Running`。
2. 量測本機 `https://127.0.0.1:6443/readyz` 與遠端 `weamind-001` 上 `https://127.0.0.1:6443/readyz` 的時間差。
3. 重新比較一條 fresh service port-forward 與一條 fresh pod port-forward。
4. 若 Grafana 又出現 `Unable to find application file`，直接抓 `/login` HTML 與 `public/build/*.js` 的下載時間，不要先假設是版本或 cache 問題。

## 一句話結論

這次問題不是 Grafana 或 Prometheus 壞掉，而是高延遲跨洲 control-plane `kubectl port-forward` 路徑在 full page reload 情境下會讓部分 forwarding stream timeout，導致前端資產載入不完整，頁面有時慢到最後才成功、有時則掉進 Grafana 的 fallback error page。
