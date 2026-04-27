# 2026-04-26 Observability Counter Semantics and Closeout Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 今天的主體是釐清 WeaMind app metrics 在目前 deployment 條件下的 counter 語意，並決定 W7 observability demo MVP 的收尾方式。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 用最小診斷實驗驗證 Grafana 上持續出現的 `postback` 數字，判斷它是來自真實流量、PromQL 解讀，還是多 worker 下的 Prometheus metrics runtime 問題。

## 今日實作順序

1. 先整理目前最可疑的根因假設，並確認要看的 raw counter / `increase()` / `resets()` / `changes()` 查詢。
2. 對照 WeaMind app metrics 實作與目前 deployment 命令，確認多 worker + 預設 registry 是否成立。
3. 做 `workers: 2 -> 1` 的最小 deployment 診斷實驗，並確認 rollout 已完成。
4. 重看 `/metrics`、Prometheus query 與 Grafana panel，判斷異常數值是否消失或明顯收斂。
5. 先把 dashboard 收尾策略定稿，決定是單一 dashboard 還是拆成 Node / App 兩個 dashboard。
6. 先完成 Node dashboard：從內建 node-exporter / mixin panels 裡挑出 W7 需要的 3 個指標。
7. 再完成 App dashboard：逐一決定 App 4 metrics 應該用哪些 panel 與查詢語法呈現。
8. 完成 App dashboard 後，再回收整體 W7 demo MVP 的完成線與後續收尾文件。

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

### Step 5

#### 這一步要驗證什麼

- 先把 W7 dashboard 的最小資訊架構定下來，避免一邊做 panel 一邊改主題，讓後面 query 與畫面設計反覆重來。

#### 預計採取的動作

- 決定 dashboard 是否拆成 `Node Dashboard` 與 `App Dashboard` 兩份。
- 定義每個 dashboard 的角色、最小 panel 數，以及它們各自回答什麼問題。
- 若同一個 metric family 需要兩種展示語意，例如總量與近窗活動，這一步就先明講，不等到畫 panel 時才臨時決定。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 6

#### 這一步要驗證什麼

- Node dashboard 是否能直接重用現成 stack 內建 panel / query，而不需要重新發明 Node 3 的查詢。

#### 預計採取的動作

- 從現成 `node-exporter` / mixin dashboard 裡，鎖定對應 W7 minimum spec 的 3 個 panel：CPU usage、memory usage、filesystem usage。
- 記下這 3 個 panel 的來源與要搬到新 dashboard 的對應 query / panel 類型。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 7

#### 這一步要驗證什麼

- Node dashboard 是否能在最小成本下完成，並直接成為 W7 Node 3 的展示面。

#### 預計採取的動作

- 建立或整理 `Node Dashboard`。
- 將 Step 6 選好的 3 個 node panels 放進 dashboard，確認標題、單位與時間範圍看起來合理。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

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

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 9

#### 這一步要驗證什麼

- App dashboard 每一個 panel 的 PromQL 是否與它想回答的問題一致，而不是只把 raw metrics 名稱直接貼上去。

#### 預計採取的動作

- 逐一替 App dashboard 的 panel 定 query。
- 對每一個 panel 明確寫下它是回答「總量」、「近窗活動」、「成功 / 錯誤」、「平均延遲」還是「高分位延遲」。
- 若某個 panel 使用 `increase()`，也同步記下它是看趨勢，不是逐次精準對帳。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 10

#### 這一步要驗證什麼

- App dashboard 是否已經具備最小可 demo 能力，並能和 Node dashboard 一起構成 W7 observability MVP。

#### 預計採取的動作

- 把 Step 9 已確認的 app panels 實際放進 dashboard。
- 檢查 panel 標題、legend、單位、時間範圍與整體閱讀順序。
- 確認 `Node Dashboard` 與 `App Dashboard` 加起來，已能覆蓋 W7 的 Node 3 + App 4 + dashboard 交付線。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

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
- 再對照 `manifests/deployment.yaml`，目前 `weamind` deployment 仍明確以 `uvicorn --workers 2` 啟動，而且 `replicas` 也仍是 `2`。
- 換句話說，現在的 runtime 組合是：每個 Pod 內有 2 個彼此獨立的 Python worker process，而每個 process 又各自持有自己的 in-memory Prometheus registry。

#### AI 判讀與收斂

- Step 2 基本上已經把 Step 1 的推測坐實了。
- Step 1 從 PromQL 端看到的是：某條 `postback` raw counter 序列本身就不穩、`resets()` 與 `changes()` 異常偏高。Step 2 則從 runtime 端補上了解釋：目前 metrics 實作確實是 in-process registry，而 deployment 也確實還在多 worker 模式下運作。
- 這兩組證據拼起來後，最合理的診斷就是：現在 Prometheus 抓到的 `line_webhook_events_total`，不是來自單一穩定的 counter source，而是來自多個彼此不共享 registry 的 process 狀態；因此 `increase()` 算出的長時間流量不可信。
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
