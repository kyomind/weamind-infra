# 2026-04-26 Observability Counter Semantics and Closeout Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 今天的主體是釐清 WeaMind app metrics 在目前 deployment 條件下的 counter 語意，並決定 W7 observability demo MVP 的收尾方式。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 用最小診斷實驗驗證 Grafana 上持續出現的 `postback` 數字，判斷它是來自真實流量、PromQL 解讀，還是多 worker 下的 Prometheus metrics runtime 問題，並在問題收斂後完成 W7 dashboard 收尾。

## 今日實作順序

1. 先整理目前最可疑的根因假設，並確認要看的 raw counter / `increase()` / `resets()` / `changes()` 查詢。
2. 對照 WeaMind app metrics 實作與目前 deployment 命令，確認多 worker + 預設 registry 是否成立。
3. 做 `workers: 2 -> 1` 的最小 deployment 診斷實驗，並確認 rollout 已完成。
4. 用受控的 rich menu / postback 操作重測，確認 ghost traffic 是否消失、序列是否恢復可解讀。
5. 先把 dashboard 收尾策略定稿，決定是單一 dashboard 還是拆成 Node / App 兩個 dashboard。
6. 先完成 Node dashboard：從內建 node-exporter / mixin panels 裡挑出 W7 需要的 3 個指標。
7. 再完成 Node dashboard 的實際整理與搬運。
8. 再完成 App dashboard：先決定 panel inventory。
9. 逐一替 App dashboard 的 panels 定 query。
10. 把 App dashboard 實際做完並驗收。

## 驗收訊號與回退點

### 驗收訊號

- 能說清楚目前 `postback` 長時間持續出現數值的主要根因。
- 能用 deployment、app code 與 PromQL 證據支持這個判斷。
- 能決定 App 4 panel 與 W7 收尾是直接完成，還是以保守設定先完成。

### 回退點

- 若改 `workers` 後圖仍異常，先回 raw counter、`resets()`、`changes()` 查詢，不急著擴大程式碼修改。
- 若 rollout 後結果沒有變化，先驗證 Pods 是否真的套用新命令與新 image，再判讀 Grafana。
- 若今天不能把 App 4 圖做到最終版，也至少要把不可信的根因與下一步保守方案寫清楚。

### Step 1

#### 這一步要驗證什麼

- 先把今天的問題從「Grafana 很怪」縮成幾個可測的假設，並整理要看的 PromQL 證據。

#### 預計採取的動作

- 對照目前 panel query 與現象，列出 raw counter、`increase()`、`resets()`、`changes()` 的最小查詢組。
- 定義今天第一輪判讀標準：哪些結果更像真實流量，哪些更像 counter reset / worker 切換。

第一輪最小查詢組先固定如下：

```promql
line_webhook_events_total{event_type="postback"}
```

- 用途：先看 raw counter 本身是否在不同序列間跳動，而不是一開始就只看 `increase()`。

```promql
sum by (event_type) (increase(line_webhook_events_total[5m]))
```

- 用途：對照目前 Grafana panel 的主要異常現象，確認問題重現的是哪一條 query。

```promql
resets(line_webhook_events_total{event_type="postback"}[30m])
```

- 用途：看 Prometheus 是否頻繁把這條序列判定成 counter reset。

```promql
changes(line_webhook_events_total{event_type="postback"}[30m])
```

- 用途：看這條序列在沒有真實流量時，是否仍持續發生大量值變化。

第一輪判讀標準先收斂成：

- 若 raw counter 看起來平穩，只在真實操作後才增加，則比較像 query window 或 panel 解讀問題。
- 若 raw counter 在沒有真實操作時仍反覆跳動，且 `resets()` / `changes()` 明顯偏高，則更像 worker 切換或 runtime aggregation 問題。
- 若 `increase()` 長時間有值，但 raw counter 與 `resets()` 也顯示不穩定，則不應把這些數字當成真實 5 分鐘流量。

#### 實際執行內容與結果

- 第一張 raw counter 圖：`line_webhook_events_total{event_type="postback"}` 回來兩條序列。
- 其中一條序列大致穩在 `5`，另一條則在 `3` 到 `4` 之間反覆跳動；這代表問題不是只有 `increase()` 在放大噪音，而是 raw counter 本身就已經不穩定。
- 第二張 `increase()` 圖：`sum by (event_type) (increase(line_webhook_events_total[5m]))` 的 `postback` 長時間落在約 `10` 到 `30` 之間，與目前真實使用情境不符，重現了原本 panel 的異常現象。
- 第三張 `resets()` 圖：`resets(line_webhook_events_total{event_type="postback"}[30m])` 顯示其中一條序列接近 `0`，另一條卻長時間落在約 `20` 到 `30`。這代表 Prometheus 在 30 分鐘視窗內，持續把其中一個 target 判成反覆 reset。
- 第四張 `changes()` 圖：`changes(line_webhook_events_total{event_type="postback"}[30m])` 其中一條序列約落在 `40` 到 `60`，另一條接近 `0`；這代表那個有問題的 target 在沒有真實流量對應的情況下，仍持續發生大量值變動。
- 這四張圖合在一起的訊號是：不是只有 panel query 很怪，而是某一條 `postback` counter 序列本身就不是可被 `increase()` 信任的單調遞增序列。

#### AI 判讀與收斂

- Step 1 已經拿到很強的第一輪證據，方向比原本更清楚。
- 最關鍵的不是第二張 `increase()` 圖，而是第一張 raw counter 圖。因為它顯示兩條 `postback` 序列裡，至少有一條 target 的原始 counter 自己就在 `3` 與 `4` 間來回跳；對真正的 counter 來說，這種下降本身就不合理。
- 第三張 `resets()` 與第四張 `changes()` 進一步把這件事坐實了：Prometheus 對其中一條序列觀察到大量 reset 與變動，而另一條幾乎沒有。這很符合「某個 scrape target 背後其實不是單一穩定 source，而是在不同 in-memory 狀態之間切換」的模型。
- 換句話說，現在最合理的判讀不是「半夜真的有很多 postback」，也不是「`increase()` 天生不準」，而是：Prometheus 正在對一條已經失真的 counter 序列做 `increase()`，所以才會算出長時間持續存在的假流量。
- 這也帶出一個更精準的定位：問題不是單純出在 panel 聚合；因為 raw counter、`resets()`、`changes()` 都已經在單條 `postback` 序列層級暴露異常。接下來最合理的下一步，就是回到 deployment 與 app metrics 實作，確認這是否正是 `uvicorn --workers 2` 搭配預設 in-process registry 造成的 runtime 問題。

#### 目前狀態

- 已完成

### Step 2

#### 這一步要驗證什麼

- WeaMind app 目前的 metrics 實作與 deployment 命令，是否真的構成「多 worker + in-process registry」這個高風險組合。

#### 預計採取的動作

- 對照 `/Users/kyo/Code/WeaMind/app/line/metrics.py` 與 `manifests/deployment.yaml`。
- 確認是否使用預設 `prometheus_client` registry、是否沒有 multiprocess collector、以及 deployment 是否仍以 `--workers 2` 啟動。

#### 實際執行內容與結果

- 對照 `/Users/kyo/Code/WeaMind/app/line/metrics.py`，目前 `line_webhook_events_total`、`line_webhook_events_success_total`、`line_webhook_events_error_total` 與 `line_webhook_event_duration_seconds` 都直接使用 `prometheus_client` 的預設 registry。
- 同一個檔案裡還有一段很直接的註解：`This W7 MVP uses the default in-process registry to keep instrumentation minimal. Cross-worker aggregation can be added later if the deployment moves to Prometheus multiprocess mode.` 這代表目前實作本來就沒有打算支援 cross-worker aggregation。
- 在這份實作裡，沒有看到 `MultiProcessCollector`、`PROMETHEUS_MULTIPROC_DIR`、或其他 multiprocess aggregation 相關設計；目前 `/metrics` 回傳的是單一 process 眼中的 registry 狀態。
- 再對照 `manifests/deployment.yaml`，當時 `weamind` deployment 明確以 `uvicorn --workers 2` 啟動，而且 `replicas` 也仍是 `2`。
- 換句話說，原始問題發生時的 runtime 組合是：每個 Pod 內有 2 個彼此獨立的 Python worker process，而每個 process 又各自持有自己的 in-memory Prometheus registry。

#### AI 判讀與收斂

- Step 2 基本上已經把 Step 1 的推測坐實了。
- Step 1 從 PromQL 端看到的是：某條 `postback` raw counter 序列本身就不穩、`resets()` 與 `changes()` 異常偏高。Step 2 則從 runtime 端補上了解釋：目前 metrics 實作確實是 in-process registry，而 deployment 也確實還在多 worker 模式下運作。
- 這兩組證據拼起來後，最合理的診斷就是：當時 Prometheus 抓到的 `line_webhook_events_total`，不是來自單一穩定的 counter source，而是來自多個彼此不共享 registry 的 process 狀態；因此 `increase()` 算出的長時間流量不可信。
- 這也讓今天的下一步非常清楚：先不要再糾結 panel 調法，而是把 deployment 的 `--workers` 從 `2` 降到 `1`，做一輪最小控制變數實驗。若異常數字明顯收斂，就可以把這題正式收斂成「multi-worker + in-process registry」造成的 runtime 問題。

#### 目前狀態

- 已完成

### Step 3

#### 這一步要驗證什麼

- 把 `workers` 降到 1 之後，異常的 `postback` 長時間數值是否明顯收斂。

#### 預計採取的動作

- 將 deployment 的 `--workers` 從 `2` 改為 `1`，rollout 並確認 Pods 已更新。
- 在 rollout 後先重看同一組 query，確認異常數字是否至少出現第一輪收斂跡象。

#### 實際執行內容與結果

- 已將 `manifests/deployment.yaml` 裡的 `uvicorn --workers` 從 `2` 改為 `1`，作為最小控制變數實驗。
- `kubectl apply -f /Users/kyo/Code/weamind-infra/manifests/deployment.yaml` 成功，deployment 已重新配置。
- `kubectl rollout status deployment/weamind -n weamind` 最終回報 `deployment "weamind" successfully rolled out`。
- 進一步用 `kubectl get deployment weamind -n weamind -o jsonpath='{.spec.template.spec.containers[0].command}'` 確認目前 template command 已變成 `"--workers","1"`。
- 再用 `kubectl get pods -n weamind -l app=weamind -o wide` 確認新的兩個 Pods 都已為 `1/1 Running`，表示目前 deployment 已在 `replicas=2`、`workers=1` 的條件下穩定運作。
- 到這一步為止，deployment 控制變數已經成功切換；下一步只剩重新觀察 `/metrics`、Prometheus query 與 Grafana panel 是否明顯收斂。
- rollout 完成約 5 分鐘後，重新執行同一組 4 個 query：
  - `line_webhook_events_total{event_type="postback"}` 仍會看到兩條序列，但這在 `replicas=2` 的情況下本來就正常；現在的重點不再是「有兩條」，而是它們是否各自呈現合理的 per-pod 累積行為。
  - `sum by (event_type) (increase(line_webhook_events_total[5m]))` 的 `postback` 值已明顯往下掉，從原本常見的 `20` 到 `40+` 開始滑到接近個位數，這代表異常幅度有收斂訊號。
  - 但 `resets(...[30m])` 與 `changes(...[30m])` 目前仍然偏高，而且兩條序列的數值差異很大。
- 這一組結果不能直接拿來當最終判決，因為現在距離 rollout 只有約 5 分鐘，而我們看的 query window 仍是 `[5m]` 與 `[30m]`；它們一定還混著 rollout 前的舊資料，`resets()` 也會把這次正常 rollout 造成的 counter reset 算進去。

#### AI 判讀與收斂

- Step 3 的第一半已完成，而且結果很乾淨：我們沒有改動 replicas、metrics code 或 query，只改了單一控制變數 `workers`。
- 這代表接下來如果圖表行為明顯變正常，因果鏈會相對乾淨，足以支持「問題主要來自 multi-worker + in-process registry」這個診斷。
- 反過來說，如果圖還是維持原樣，那也代表我們該回頭檢查更細的 scrape target / runtime 行為，而不是再懷疑 rollout 有沒有真的生效。這一層現在已經驗證完了。
- 目前看到的第二輪結果，比較像「已有改善訊號，但觀察窗還不乾淨」，而不是「已經推翻原本假設」。
- 第二張 `increase()` 圖往下掉，這其實是好訊號，因為它表示原本那種長時間維持高值的假流量正在收斂。
- 但第三、四張圖現在還不能用來反證或證成太多，因為 `[30m]` 視窗裡必然同時包含 rollout 前的壞資料，以及 rollout 本身造成的合法 reset。
- 所以 Step 3 最穩的結論應該是：`workers=1` 後，異常數字已有明顯收斂跡象；但若要正式下結論，下一輪應改看更乾淨的時間窗，例如等觀察窗完全跨過 rollout 之後，再用較短範圍重看 raw counter 與 `increase()`，而不要急著拿目前的 `resets(...[30m])` / `changes(...[30m])` 做最終裁決。

#### 目前狀態

- 已完成

### Step 4

#### 這一步要驗證什麼

- 在 `workers=1` 的條件下，用一輪受控的 rich menu / postback 操作，確認新的 raw counter 與 `increase()` 是否只對真實操作產生反應，並據此判斷 App 4 panel 與 W7 demo MVP 能否合理收尾。

#### 預計採取的動作

- 先等 rollout 後觀察窗滿 15 分鐘，避免 `Last 15 minutes` 仍混入 rollout 前資料。
- 在沒有其他干擾操作的前提下，固定用 rich menu 觸發 `6` 次 `postback`，節奏盡量平均，例如每 `5` 到 `8` 秒按一次。
- 按完後先重看兩個主查詢：

```promql
line_webhook_events_total{event_type="postback"}
```

```promql
sum by (event_type) (increase(line_webhook_events_total[5m]))
```

- 這一輪的主判準不是數字是否剛好等於 `6`，而是：raw counter 是否只往上加、`increase()` 是否只在這 6 次操作後短暫上升，而不再像之前那樣在沒有操作時長時間維持高值。
- 若這一輪結果可信，再往 W7 demo MVP 的 App 4 panel 收尾走；若仍不可信，則把今天結論收斂成已定位根因與後續方案，不假裝 dashboard 已完成。

#### 實際執行內容與結果

- 在 rollout 後觀察窗已相對乾淨的條件下，進行了一輪受控測試：使用 rich menu 固定觸發 `6` 次 `postback`，約每 `10` 秒操作一次。
- 第一張 raw counter 圖：`line_webhook_events_total{event_type="postback"}` 顯示兩條 per-pod 序列，最後都收斂到 `3`。這代表兩個 Pod 各自收到 `3` 次 `postback`，合計正好對應這次手動觸發的 `6` 次操作。
- 更重要的是，這兩條 raw counter 序列在這一輪測試裡都呈現正常的累積行為，不再出現之前那種「沒有真實操作也自己上下亂跳」的情況。
- 第二張 `sum by (event_type) (increase(line_webhook_events_total[5m]))` 圖則顯示 `postback` 在最近 `5` 分鐘內有一段與手動操作對應的小規模上升，之後維持在約 `4` 到 `3` 左右。
- 這張圖沒有精準等於 `6`，但它已不再像 rollout 前那樣，在沒有操作時長時間維持 `20` 到 `40+` 的高值假流量。

#### AI 判讀與收斂

- 這一輪 Step 4 最有力的證據是 raw counter，而不是 `increase()` 的精確數字。
- raw counter 現在能清楚對應到人工測試結果：兩個 Pod 各累積到 `3`，總和為 `6`。這代表在 `workers=1` 的條件下，序列已恢復成可被正常解讀的 per-pod counter。
- 第二張 `increase()[5m]` 圖不應被讀成「精確逐次對帳器」。它比較適合回答「最近 5 分鐘是否有一段與手動操作對應的增加趨勢」，而不是要求在低流量、fresh series、離散 scrape 的條件下每一個點都精準等於手動次數。
- 對這次 W7 demo MVP 而言，原本真正要解的問題是 ghost traffic / 假流量。現在這個問題已經消失，raw counter 也恢復正常，因此可以合理收斂成：`workers=2` 加上 in-process registry 造成序列失真；改成 `workers=1` 後，序列恢復可解讀。
- 更完整地說，這代表這題對 demo 收尾已經解掉，但不是長期架構的最終解。若未來需要回到多 worker，正式解法仍然會是 multiprocess aggregation，而不是假設目前這版可直接外推到所有部署條件。

#### 目前狀態

- 已完成

### Step 5

#### 這一步要驗證什麼

- 先把 W7 dashboard 的最小資訊架構定下來，避免一邊做 panel 一邊改主題，讓後面 query 與畫面設計反覆重來。

#### 預計採取的動作

- 決定 dashboard 是否拆成 `Node Dashboard` 與 `App Dashboard` 兩份。
- 定義每個 dashboard 的角色、最小 panel 數，以及它們各自回答什麼問題。
- 若同一個 metric family 需要兩種展示語意，例如總量與近窗活動，這一步就先明講，不等到畫 panel 時才臨時決定。

#### 實際執行內容與結果

- 這一步先不急著做 panel，而是先把 dashboard 的資訊架構定稿。
- 決定不把所有內容硬塞進單一 dashboard，而是拆成兩份：`Node Dashboard` 與 `App Dashboard`。
- `Node Dashboard` 的角色很單純：只承接 W7 minimum spec 的 Node 3，也就是 CPU usage、memory usage、filesystem usage。
- `App Dashboard` 的角色則是承接 WeaMind app metrics，重點不只是把 4 個 metric family 貼上去，而是替每個指標決定合適的展示語意與 query。
- 這也代表 App dashboard 的 panel 數量不必等於 4 個 raw metrics；若同一個 metric family 需要兩種展示語意，例如總量與近窗活動，就可以拆成多個 panel。
- 目前先定的最小方向是：Node dashboard 先做 3 個 panels；App dashboard 則至少覆蓋 received / success / error / latency，必要時再把 total 與近窗活動拆成不同 panel。

#### AI 判讀與收斂

- 這個拆分決策是合理的，因為 Node 與 App 其實在 dashboard 設計上回答的是兩種不同層次的問題。
- Node 這一側比較像資源背景盤，重點是快速完成並對齊 W7 minimum spec，不需要重新發明 query。
- App 這一側則需要更多 query 與 panel 語意設計，尤其這次剛好又學到 raw counter、`increase()[5m]`、`increase()[1m]` 各自回答什麼問題，所以把它獨立成一份 dashboard 會比較好收斂。
- 這一步做完之後，後面就不需要再討論「要一份還是兩份 dashboard」；下一步只要先把 Node 3 的現成 panel 找出來即可。

#### 目前狀態

- 已完成

### Step 6

#### 這一步要驗證什麼

- Node dashboard 是否能直接重用現成 stack 內建 panel / query，而不需要重新發明 Node 3 的查詢。

#### 預計採取的動作

- 從現成 `node-exporter` / mixin dashboard 裡，鎖定對應 W7 minimum spec 的 3 個 panel：CPU usage、memory usage、filesystem usage。
- 記下這 3 個 panel 的來源與要搬到新 dashboard 的對應 query / panel 類型。

#### 實際執行內容與結果

- 重新檢視內建 `Node Exporter / Nodes` dashboard 後，可以確認原本把 Node 3 想成「3 個 metric = 3 個 panel」其實太粗。
- 目前畫面更合理的拆法是「3 個 metric family，但每個 family 用 2 個 panel 從不同角度看」，總共 6 個 panels：
  - CPU：`CPU Usage`、`Load Average`
  - Memory：`Memory Usage` 時序圖、`Memory Usage` gauge
  - Disk：`Disk I/O`、`Disk Space Usage`
- 這個拆法合理，因為 panel 不是對應 metric 名稱，而是對應觀察角度。
- `CPU Usage` 看的是 CPU 使用率趨勢；`Load Average` 則補的是排程壓力與核心數對照，兩者不是重複資訊。
- `Memory Usage` 時序圖看的是記憶體組成與時間變化；旁邊的 gauge 則提供當下使用率的一眼判讀。
- `Disk I/O` 看的是讀寫活動與 io time；`Disk Space Usage` 則回答容量剩多少、掛載點是否逼近滿載，這也不是同一件事。
- 另外也確認了這組內建 panel 是透過 dashboard variables 在切 node，而不是每個 panel 各自寫死節點。
- 從畫面上看，目前至少有兩個關鍵變數：`datasource` 與 `instance`；`instance` 下拉可切 `10.0.0.3:9100`、`10.0.0.4:9100`、`10.0.0.5:9100`。
- 這代表若要把這些 panel 搬到新的 dashboard，有兩條可行路線：
  - 路線 A：保留 variable-driven 設計，把 `datasource` 與 `instance` 變數也一起帶進新 dashboard，讓同一份 dashboard 可切不同 node。
  - 路線 B：若 W7 demo 只要求固定展示 Node 3，則直接把查詢裡的 `instance` 鎖定成 Node 3，做成不帶下拉選單的定版 dashboard。
- 以這次 W7 收尾目標來看，路線 B 更乾淨，因為需求不是做通用 node explorer，而是交付能穩定展示 Node 3 的 dashboard。
- 也就是說，這一步的真正結論不是「只挑 3 個 panel」，而是「接受 6 個 panel 才是合理最小展示面，並決定後續搬運時以 Node 3 固定版為優先」。

#### AI 判讀與收斂

- 這一步把一個很重要的 dashboard 設計原則釐清了：panel 對應的是問題，不是 metric family 的數量。
- 所以後面做 App dashboard 時，也不應把思路卡死在「4 個 metrics 就只能有 4 個 panels」；如果同一個 metrics family 需要總量與近窗活動兩種語意，拆成 2 個 panels 才是正確做法。
- 對 Node dashboard 而言，最小可交付面其實不是 3 格，而是這 6 格。這樣既保住 W7 minimum spec，又保住可讀性。
- 搬運方式上，Grafana 並不是用「引用既有 panel」的概念來重用；比較實際的作法是複製 panel 設定或 panel JSON 到新 dashboard。
- 如果保留原本的 variable-driven 查詢，新 dashboard 也必須有相同名稱的 variables，至少包含 `datasource` 與 `instance`，否則 panel 會失效。
- 如果直接做 Node 3 固定版，反而更適合這次 lesson：把 `instance` 變數拿掉，將查詢直接鎖到 Node 3，會比保留下拉選單更容易解釋、也更像交付物而不是工具盤。

#### 目前狀態

- 已完成

### Step 7

#### 這一步要驗證什麼

- Node dashboard 是否能在最小成本下完成，並直接成為 W7 Node 3 的展示面。

#### 預計採取的動作

- 優先採用低成本搬運法，而不是從零重建 6 個 panel。
- 第一選項是直接從內建 `Node Exporter / Nodes` dashboard 另存新檔或複製一份，再刪掉不需要的 panels，只保留 Step 6 選定的 6 個 panel。
- 若內建 dashboard 因 provisioned / read-only 限制無法直接另存，第二選項才是匯出 dashboard JSON 再 import 成可編輯副本。
- 只有在前兩條都卡住時，才退回逐個 panel 複製設定或重貼 query。
- 建立或整理 `Node Dashboard` 後，確認標題、單位、時間範圍與變數策略看起來合理。

#### 實際執行內容與結果

- 已實際驗證 `Node Exporter / Nodes` 可以直接用 `Save As` 複製成新的 dashboard。
- 複製後的新 dashboard 會出現在 dashboard 清單中，與先前建立的其他 dashboard 並列存在，代表這條路可作為 W7 Node dashboard 的主路線，不需要先走 export/import，也不需要逐個 panel 重建。
- 重新檢視內建 `Nodes` dashboard 後，也確認它原本其實就是 4 個 metric family：CPU、Memory、Disk、Network。
- 若以 W7 minimum spec 來看，真正必需的是 Node 3，也就是 CPU usage、memory usage、filesystem usage；network 並不是硬需求。
- 但從實作成本與可讀性來看，network panels 本身並沒有造成明顯干擾，而且保留整份現成 dashboard 幾乎是零額外成本。
- 因此目前收斂出的較佳做法是：先保留原本 `Nodes` dashboard 的整體結構，不急著刪 network，只做輕量客製，例如改成自己的 dashboard 名稱，必要時再調整變數或預設 node。
- 也就是說，對這次 W7 收尾而言，「複製一份內建 Nodes dashboard，保留大部分既有 panel 結構，只做最小命名與展示客製」已經足夠合理。

#### AI 判讀與收斂

- 這一步的關鍵不是技術上能不能重建，而是有沒有必要重建。
- 現在既然 `Save As` 已驗證可行，就代表最省力且最穩的路線已經成立：直接複製內建 dashboard，再做最小幅度客製。
- 對目前 lesson 目標來說，我傾向同意先不要刪 network。原因不是 network 很重要，而是它不構成主要成本，也不會破壞 dashboard 的正當性；相反地，若現在為了追求「只剩必要 panel」而做一堆裁切，反而增加無謂編修。
- 更精準地說，現在的客製重點可以從「大量刪 panel」改成「定義這份 dashboard 在清單與展示中的身份」：
  - 用自己的命名方式把它和內建 dashboard 區分開。
  - 視需要把它放到合適 folder。
  - 視需要調整預設 node 或變數可見性。
- 若之後真的發現 demo 畫面太雜，再回頭做 slim 版 dashboard 也來得及；但這不應該阻塞目前的 W7 推進。

#### 目前狀態

- 已完成

### Step 8

#### 這一步要驗證什麼

- App dashboard 的 panel 結構應該怎麼設計，才能同時保住 W7 minimum spec 和這次學到的 counter / query 邊界。

#### 預計採取的動作

- 先列出 App dashboard 的 panel inventory。
- 至少決定這些 panel 是否存在：
  - received total 或 total by event type
  - recent events / activity window
  - success events
  - error events
  - average duration
  - p95 duration
- 若同一個 metric family 要拆成兩個 panel，例如 total 與近 5 分鐘活動，這一步就先寫清楚理由。

#### 實際執行內容與結果

- 在完成 `WatchMind Nodes` 的複製、命名、folder 與 starred 整理後，開始回到 App dashboard 的真正交付內容，也就是先定 `WatchMind Apps` 的 panel inventory。
- 這一步先不急著寫每個 panel 的 PromQL，而是先決定 App dashboard 到底要回答哪些問題。
- 目前已確認的原始 metric family 仍是 4 類：
  - `line_webhook_events_total`
  - `line_webhook_events_success_total`
  - `line_webhook_events_error_total`
  - `line_webhook_event_duration_seconds`
- 但 panel inventory 不應硬等於 4，因為同一個 metric family 可能需要不同觀察角度。
- 綜合前面對 counter 語意、`increase()[5m]` vs `increase()[1m]`、以及 raw total / trend 用途差異的整理後，第一版 App dashboard panel inventory 先收斂成 6 格：
  - `Webhook Events Total by Event Type`
  - `Webhook Events Recent Activity (5m)`
  - `Webhook Success Events (5m)`
  - `Webhook Error Events (5m)`
  - `Webhook Average Duration`
  - `Webhook P95 Duration`
- 這 6 格對應的意圖如下：
  - 第一格看累積總量與 event type 分布，回答「目前系統總共接了哪些 webhook event」。
  - 第二格看近 5 分鐘活動量，回答「最近是否有一波 webhook 活動」。
  - 第三、四格把 success / error 拆開，回答「最近成功與失敗的處理量如何」。
  - 第五、六格把 latency 拆成平均值與高分位，回答「一般延遲」與「尾延遲」是否健康。
- 這也代表這次不採用「只有 4 格、每個 metric family 對一格」的簡化版本；因為那會把 total 與 recent activity 混在一起，也會把 latency 的平均與尾部風險混在一起。
- 另外，這一步也維持前面的收斂：近期活動主 panel 先以 `5m` 為主，不把 `1m` 當成預設主 panel；若後面覺得需要更即時脈衝視角，再考慮補一張額外 panel。

#### AI 判讀與收斂

- Step 8 的核心收斂已經成立：App dashboard 應該用「問題導向」來定 panel，而不是用「metric family 數量」來定 panel。
- 這個結論和 Node dashboard 那邊學到的是同一件事：同一個 metrics family 完全可能需要兩個以上 panel，因為它們回答的是不同問題。
- 目前這 6 格版本已經足夠支撐 W7 minimum spec，而且也能把這次 counter semantics lesson 真正學到的邊界保留下來。
- 最重要的兩個設計決策是：
  - total 與 recent activity 分開，不讓單一 panel 同時承擔「總量」和「近窗活動」兩種語意。
  - latency 拆成 average 與 p95，不讓單一平均值掩蓋尾端慢請求。
- 因此下一步就不再是討論 App dashboard 要幾格，而是直接進 Step 9：逐一替這 6 個 panels 定 PromQL。

#### 目前狀態

- 已完成

### Step 9

#### 這一步要驗證什麼

- App dashboard 每一個 panel 的 PromQL 是否與它想回答的問題一致，而不是只把 raw metrics 名稱直接貼上去。

#### 預計採取的動作

- 逐一替 App dashboard 的 panel 定 query。
- 對每一個 panel 明確寫下它是回答「總量」、「近窗活動」、「成功 / 錯誤」、「平均延遲」還是「高分位延遲」。
- 若某個 panel 使用 `increase()`，也同步記下它是看趨勢，不是逐次精準對帳。

#### 實際執行內容

- 核心原則先固定三條：
  - total panel 用 raw counter，回答累積總量，不混入近窗估算。
  - activity / success / error panels 用 `increase(...[5m])`，回答最近 5 分鐘是否有一波事件量變化。
  - duration panels 用 histogram 慣用寫法，分別回答平均延遲與 p95 尾延遲。
- 第一版 panel-to-query 對應如下。

`Webhook Events Total by Event Type`

- 建議 visualization type：`Time series`
- 理由：這格雖然是看累積總量，但在 Grafana 的一般 dashboard 編輯流程裡，Prometheus 預設通常會先以 range query 呈現；若直接套 `Bar chart`，X 軸很容易被時間點塞滿，畫面反而變成視覺噪音。

```promql
sum by (event_type) (line_webhook_events_total)
```

- 這格回答的是累積總量與 event type 分布，所以直接用 raw counter 聚合，不用 `increase()`。
- 第一版先用 `Time series` 會更穩，因為它能自然呈現各 event type 的累積曲線，也較符合目前 dashboard 其他 panels 的閱讀方式。
- 若未來真的想把這格改成「只看當下總量比較」而不是看時間上的累積過程，較合理的替代方向會是 `Bar gauge` 或 `Table` 搭配 instant query，而不是直接用目前這種 `Bar chart` + range query 組合。

`Webhook Events Recent Activity (5m)`

- 建議 visualization type：`Time series`
- 理由：這格是看最近 5 分鐘活動量的變化，核心是時間趨勢，不是單點比較。

```promql
sum by (event_type) (increase(line_webhook_events_total[5m]))
```

- 這格回答的是最近 5 分鐘活動量，延續前面 lesson 的收斂，主 panel 先用 `5m` 而不是 `1m`。

`Webhook Success Events (5m)`

- 建議 visualization type：`Time series`
- 理由：這格要和 recent activity 對齊時間語意，方便觀察最近一段時間成功處理量是否跟著活動量上升。

```promql
sum by (event_type) (increase(line_webhook_events_success_total[5m]))
```

- 這格回答最近成功處理量，維持和 recent activity 相同的時間語意，方便橫向比對。

`Webhook Error Events (5m)`

- 建議 visualization type：`Time series`
- 理由：錯誤量本身也是時間上的事件量變化，先用 time series 才看得出是否在某段時間突然冒出錯誤尖峰。

```promql
sum by (event_type, error_type) (increase(line_webhook_events_error_total[5m]))
```

- error counter 額外帶有 `error_type` label，所以這格保留 `error_type` 維度，讓 panel 同時看得到是哪一類 event、哪一類錯誤。
- 若後面發現 legend 太亂，再考慮把這格拆成 table 或只保留 `error_type` 維度；但第一版先保持 time series，優先保留時間脈絡。

`Webhook Average Duration`

- 建議 visualization type：`Time series`
- 理由：平均延遲不是只看一個瞬間數字，而是看某段時間內有沒有變慢，所以先用 time series 最合適。

```promql
1000 * (
  sum by (event_type) (rate(line_webhook_event_duration_seconds_sum[5m]))
  /
  sum by (event_type) (rate(line_webhook_event_duration_seconds_count[5m]))
)
```

- 這格用 histogram 的 `_sum / _count` rate 算平均延遲，並在 query 端直接乘上 `1000` 轉成毫秒，回答一般情況下每種 event 的平均處理時間。
- 單位建議設成 `milliseconds (ms)`，但前提是 query 本身也已轉成毫秒；不能只改面板單位而不改 query，否則會變成把秒值錯標成毫秒。

`Webhook P95 Duration`

- 建議 visualization type：`Time series`
- 理由：p95 的價值就在觀察尾延遲是否在某個時間段惡化，所以同樣應保留時間軸。

```promql
1000 * histogram_quantile(
  0.95,
  sum by (le, event_type) (rate(line_webhook_event_duration_seconds_bucket[5m]))
)
```

- 這格用 histogram bucket 做 p95，並在 query 端直接乘上 `1000` 轉成毫秒，回答尾端慢請求是否有惡化。
- 單位同樣建議設成 `milliseconds (ms)`，並和 average duration 保持一致；同樣不能只改顯示單位而不改 query。

#### 結果

- 這一步目前完成的是設計稿收斂，不是 Grafana 內的實際落地。
- 也就是說，現在已經把 Step 8 確認的 6 個 App panels，逐一對應到第一版 PromQL 與 visualization type；但這些查詢尚未逐一放進 `WatchMind Apps` 驗證畫面表現。
- 到這一步為止，6 格 panel 都已有第一版 query 與對應的 visualization type，而且每一格都能對應到一個明確問題，不再只是把 metric 名稱原樣貼上去。
- 真正的 panel 建立、畫面檢查與 query 實跑，留到 Step 10。

#### AI 判讀與收斂

- Step 9 目前能成立的判讀，只是「設計層已可進入實作」，還不是「dashboard 已驗證完成」。
- 第一版設計已經足夠進入實作階段，因為每一格 panel 的語意與 query 類型都已對齊。
- 最重要的設計一致性有三個：
  - 所有事件量 panel 都清楚區分「累積總量」與「近窗活動」，避免一張圖混兩種語意。
  - success / error 都採 `5m` 視窗，讓它們可以和 recent activity panel 用同一個時間語意互相比較。
  - duration 明確拆成 average 與 p95，避免平均值掩蓋尾端風險。
- 另外也有兩個實務上的提醒：
  - `Webhook Error Events (5m)`` 在低流量情境下可能常常是空的，這是正常現象，不代表 panel 壞掉。
  - duration 相關 panel 若某些 event type 在觀察窗內沒有樣本，也可能短暫不出線，這同樣是 histogram rate 查詢在低流量條件下的正常表現。
- 因此 Step 9 應收斂成「設計稿已完成」，下一步直接進 Step 10，把這 6 個 panels 實際放進 `WatchMind Apps` 並做畫面驗收。

#### 目前狀態

- 已完成（設計稿，待實作驗證）

### Step 10

#### 這一步要驗證什麼

- App dashboard 是否已經具備最小可 demo 能力，並能和 Node dashboard 一起構成 W7 observability MVP。

#### 預計採取的動作

- 把 Step 9 已確認的 app panels 實際放進 dashboard。
- 檢查 panel 標題、legend、單位、時間範圍與整體閱讀順序。
- 確認 `Node Dashboard` 與 `App Dashboard` 加起來，已能覆蓋 W7 的 Node 3 + App 4 + dashboard 交付線。

#### 實際執行內容

- 把 Step 9 已確認的 app panels 實際放進 dashboard。
- 檢查 panel 標題、legend、單位、時間範圍與整體閱讀順序。
- 確認 `Node Dashboard` 與 `App Dashboard` 加起來，已能覆蓋 W7 的 Node 3 + App 4 + dashboard 交付線。

#### 結果

- 已將 Step 9 設計的 6 個 App panels 實際放進 `WatchMind Apps`，並用一輪受控測試做首輪驗證：再次以 rich menu 觸發 `6` 次 `postback`。
- `Webhook Events Total by Event Type`：`postback` 累積值由 `6` 上升到 `12`，這表示 raw total panel 的語意正確，能清楚反映這一輪新增的 6 次事件。
- `Webhook Events Recent Activity (5m)`：`postback` 在最近 5 分鐘內出現約 `6.31` 的上升，這次已非常接近人工觸發的 6 次操作，明顯比前面那輪約 `4` 的情況更貼近人工測試結果。
- `Webhook Success Events (5m)`：同樣出現約 `6.31` 的上升，且和 recent activity 幾乎同步，代表這 6 次 `postback` 在這一輪測試裡都被成功處理。
- `Webhook Average Duration`：在 query 端正確乘上 `1000` 之後，最新圖面顯示 `postback` 平均延遲大約落在 `450ms` 到 `600ms` 區間，而不是先前誤讀的 `12ms`。
- `Webhook P95 Duration`：`postback` 約落在 `950ms` 附近，表示在這一輪少量樣本下，尾延遲接近 `1s` 等級。
- `Webhook Error Events (5m)`：維持 `No data`，在這次沒有錯誤事件的情況下是合理結果，不代表 panel 設定失敗。
- 畫面層面上，6 個 panels 都已有明確回應或合理的空狀態，代表 `WatchMind Apps` 已具備可 demo 的基本可讀性。

#### AI 判讀與收斂

- 這一輪最重要的訊號有三個。
- 第一，事件量相關的三張圖已經彼此對齊：
  - total 從 `6 -> 12`
  - recent activity 約 `6.31`
  - success 約 `6.31`
- 這代表 App dashboard 的核心事件流是通的，而且這次 `increase()[5m]` 的估算已經相當貼近人工測試值；至少從 demo 與教學角度來說，這組 panel 已可被信任。
- 第二，`Webhook Error Events (5m)` 為空是合理現象，不是壞掉。因為這輪測試本來就沒有失敗事件，所以沒有 error series 很正常。
- 第三，duration 兩張圖是有訊號的，但解讀要比事件量更保守：
  - average duration 在 query 正確轉成毫秒後，最新圖面約落在 `450ms` 到 `600ms`，這代表這一輪測試的平均處理時間其實是數百毫秒級，而不是先前誤以為的十幾毫秒。
  - p95 在 query 正確轉成毫秒後，約 `950ms`；在只有 6 筆樣本、且 histogram bucket 有固定粒度的情況下，容易被單一較慢樣本或 bucket 邊界放大，因此目前比較適合讀成「這輪曾出現接近 1 秒的尾延遲」，而不是直接下結論說整體系統常態上有 1 秒延遲。
- 也就是說，事件量 panels 現在已經足夠穩，可以當作 W7 主展示面；duration panels 也可保留，但更適合當補充觀察，而不是拿來做過度精細的效能結論。
- 綜合來看，`WatchMind Apps` 已達到 W7 demo 所需的最小可用狀態：
  - 有 total
  - 有 recent activity
  - 有 success
  - 有 error
  - 有 average duration
  - 有 p95 duration
- 因此 Step 10 可以收斂成首輪驗證已完成；若後面還要再調整，優先順序會是「把 duration queries 明確轉成 `ms`，並同步設定 panel 單位」，而不是重改整體 panel 結構。

#### 目前狀態

- 已完成（首輪驗證）
