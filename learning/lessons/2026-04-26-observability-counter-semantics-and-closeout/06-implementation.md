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
5. 視結果決定今天是直接收尾 App 4 dashboard，還是把缺口正式留成已定位問題。

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

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 3

#### 這一步要驗證什麼

- 把 `workers` 降到 1 之後，異常的 `postback` 長時間數值是否明顯收斂。

#### 預計採取的動作

- 將 deployment 的 `--workers` 從 `2` 改為 `1`，rollout 並確認 Pods 已更新。
- 用固定次數的 rich menu / webhook 操作重測，並重新觀察 `/metrics`、Prometheus query 與 Grafana panel。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 4

#### 這一步要驗證什麼

- 在新的診斷結果之上，今天能否把 App 4 panel 與 W7 demo MVP 做到合理收尾。

#### 預計採取的動作

- 若數值已可信，完成最小 App 4 panel 收尾並確認 W7 完成線。
- 若數值仍不可信，將今天結論收斂成已定位根因與後續方案，不假裝 dashboard 已完成。

#### 實際執行內容與結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始
