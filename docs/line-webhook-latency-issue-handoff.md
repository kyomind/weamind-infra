# LINE Webhook Latency Issue Research / Handoff

## 文件目的

這份文件記錄 W7 observability 收尾後發現的一個後續問題：

`line_webhook_event_duration_seconds` 顯示 `postback` 平均處理時間約落在 `450ms` 到 `600ms`，p95 在少量樣本下曾接近 `950ms`。

這不是 W7 必須立刻處理的 blocker。W7 的目標是完成 demo-grade observability baseline，而不是做 production-grade latency attribution。但這個現象值得保留下來，之後若要繼續優化 webhook latency，可以從這份 handoff 接手。

## 目前已知事實

- `line_webhook_event_duration_seconds` 量到的是 app 端處理單一 webhook event 的時間。
- 它不是使用者端到端體感延遲。
- 它不包含使用者手機到 LINE 平台、LINE 平台內部處理、或 LINE 平台把 webhook 送到 WeaMind 服務之前的時間。
- 正常 event 路徑中，計時邊界大致是：event 進入 app 內部 dispatch handler 前開始，到 handler 執行完成或拋出例外後結束。
- 目前 `postback` 平均約 `450ms` 到 `600ms`，這表示 server-side webhook handling 是數百毫秒級。
- 這個數字比直覺上「只是查 DB」來得長，因此值得拆解。

相關既有記錄：

- `docs/line-webhook-metrics-implementation-report.md`
- `learning/lessons/2026-04-26-observability-counter-semantics-and-closeout/04-report.md`
- `learning/lessons/2026-04-26-observability-counter-semantics-and-closeout/05-note.md`
- `learning/lessons/2026-04-26-observability-counter-semantics-and-closeout/06-implementation.md`

## 重要釐清：這不是 Fast ACK 延遲

WeaMind 的 webhook router 仍採用 Fast ACK 架構：

1. router 收到 LINE webhook
2. 檢查 content type
3. 讀 body
4. 驗 LINE signature
5. 記錄 received metric
6. 把實際 event handling 丟進 `BackgroundTasks`
7. 回傳 `{"message": "OK"}`

因此這次討論的 `450ms` 到 `600ms` 不是 LINE 平台等待 ACK 的時間，而是 background task 裡 handler 把 event 實際處理完的時間。

這點很重要，因為優化方向不同：

- 如果是 ACK 慢，會影響 LINE 是否重送 webhook。
- 如果是 background handler 慢，主要影響使用者多久看到 Bot 回覆，也影響 app 端資源占用與 tail latency。

## 為什麼 `0.5s` 仍然值得追

如果這條路徑真的只是在同機器本地查 DB，`0.5s` 會明顯偏慢。

但 WeaMind 的實際架構不是本地 DB：

```text
LINE -> k8s.kyomind.tw -> Hetzner LB -> K3s / Traefik -> line-bot Pod -> bastion VM PostgreSQL / Redis
```

Pod 會透過內網連到 bastion VM 上的 PostgreSQL / Redis。這不應該慢到數百毫秒，但它已經不是 localhost 查詢。

更重要的是，`postback` handler 可能不只做 DB 查詢。它可能包含：

- parse postback data
- Redis processing lock
- 查 user
- 必要時建立或恢復 user
- 查 home / work location
- 寫入 user query history
- 查 weather records
- format 回覆文字
- 呼叫 LINE Messaging API 回覆使用者

其中最可疑的一段是同步呼叫 LINE Messaging API。若目前 duration 包含 `reply_message()` 的外部 round trip，`450ms` 到 `600ms` 就不一定主要是 DB 慢。

## 初步假設

### 假設 A：LINE reply API round trip 是主要來源

這是目前最值得優先驗證的假設。

理由：

- handler 最後通常會呼叫 LINE Messaging API 回覆使用者。
- 這是外部網路 I/O。
- 如果計時邊界包到 `reply_message()` 完成，duration 就會包含 WeaMind 到 LINE API 的 round trip。
- 在這種情況下，`0.5s` 比較像「DB / Redis / format + LINE reply API」的總和，而不是單純 DB 查詢時間。

### 假設 B：DB / Redis 存取有非預期延遲

仍然需要保留這個可能。

可能來源：

- 每次 handler 都建立或取得 DB session
- user / location / weather query 次數比想像多
- `record_user_query()` 造成同步 write + commit
- PostgreSQL 在 bastion VM，並非 Pod 本地
- Redis lock 第一次建立連線或偶發 latency

但在沒有分段 timing 前，不能直接把 `0.5s` 歸因給 DB。

### 假設 C：少量樣本與 histogram bucket 讓 p95 看起來偏高

目前 p95 接近 `950ms` 的觀察來自低樣本測試。

這可以說明「這輪曾出現接近 1 秒的尾延遲」，但還不能說明系統常態 p95 就是 1 秒。

## 為什麼不建議立刻上完整 tracing

完整 tracing，例如 OpenTelemetry，可以最完整地回答 latency attribution 問題。

但以目前狀態來說，直接導入完整 tracing 可能過重：

- W7 已經 delay，不適合再擴大 scope。
- 目前只是要回答一個具體問題：`postback` 的 `0.5s` 花在哪裡。
- 真實 webhook latency 需要 production 路徑才能觀察，不能只靠本地測試。
- 每次 production 驗證都需要走 commit、build image、rollout、觸發 LINE webhook、查 logs / metrics 的流程。

因此下一步比較適合先做最小 instrumentation，而不是立刻建立完整 tracing stack。

## 建議的最小實驗：structured timing log

下一次若要接手，建議先只針對 `postback` path 加 structured timing log。

目標不是永久建立新監控，而是短期回答 latency attribution。

建議拆成：

```text
postback_total_ms
parse_postback_ms
redis_lock_ms
user_db_ms
record_query_ms
weather_query_ms
format_response_ms
line_reply_api_ms
```

可接受的第一版也可以更粗：

```text
postback_total_ms
redis_lock_ms
db_and_weather_ms
line_reply_api_ms
```

如果第一版已經看出 `line_reply_api_ms` 佔大頭，就不需要立刻把 DB 再拆得很細。

## 建議 log 格式

用一行 structured log，方便 `kubectl logs` 或後續 log system 搜尋。

範例：

```json
{
  "event": "webhook_timing",
  "event_type": "postback",
  "action": "weather",
  "postback_type": "home",
  "total_ms": 538,
  "redis_lock_ms": 18,
  "db_and_weather_ms": 112,
  "line_reply_api_ms": 386
}
```

注意事項：

- 不要記錄 LINE user id。
- 不要記錄 reply token。
- 不要記錄完整 request body。
- `action` / `postback_type` 這類低敏感度分類可以保留，方便分辨 home / office / current / recent_queries。
- log 應該可由 feature flag 開關控制。

## 建議 feature flag

建議在 app repo 加類似設定：

```text
WEBHOOK_TIMING_LOG_ENABLED=false
WEBHOOK_TIMING_SAMPLE_RATE=1.0
```

第一輪 production 測試可以短時間設成：

```text
WEBHOOK_TIMING_LOG_ENABLED=true
WEBHOOK_TIMING_SAMPLE_RATE=1.0
```

若未來流量變大，再把 sample rate 降低。

## Production 驗證流程草案

這件事無法只靠本地測試完成，因為真實 LINE webhook 與 LINE reply API round trip 需要 production-like 路徑。

下一次執行可用這個流程：

1. 在 WeaMind app repo 加最小 timing log 與 feature flag。
2. 本地只跑單元測試，確認 timing helper 不破壞 handler 行為。
3. commit app change。
4. build / push image。
5. rollout 到 K8s。
6. 開啟 `WEBHOOK_TIMING_LOG_ENABLED`。
7. 用 LINE rich menu 固定觸發 `postback` 10 到 20 次。
8. 用 `kubectl logs` 搜尋 `webhook_timing`。
9. 彙整 `line_reply_api_ms`、`db_and_weather_ms`、`redis_lock_ms` 的大致分布。
10. 測完關閉 feature flag。

## 驗收問題

這個 issue 不需要一開始就追求完整監控。下一次接手時，只要能回答以下問題，就算完成第一輪：

1. `postback` 的 `450ms` 到 `600ms` 主要花在哪一段？
2. `line_reply_api_ms` 是否佔總時間的大頭？
3. DB / weather query 是否真的慢到需要優化？
4. Redis lock 是否有明顯 latency？
5. `current` / `home` / `office` / `recent_queries` 不同 postback path 是否差異很大？

## 後續可能方向

如果 `line_reply_api_ms` 是主要來源：

- 目前不一定需要優化。
- 可把結論寫成「server-side handler duration 包含 LINE reply API round trip」。
- dashboard 解讀時避免把 `line_webhook_event_duration_seconds` 說成純 app compute / DB time。

如果 DB / weather query 是主要來源：

- 再補更細的 DB query timing。
- 檢查 user / location / weather 查詢次數。
- 檢查 `record_user_query()` 的 write + commit 是否可以調整。
- 評估是否需要 index / query rewrite / session 使用方式調整。

如果 Redis lock 是主要來源：

- 檢查 Redis 連線建立是否發生在 hot path。
- 檢查 Redis 到 Pod 的網路與連線 reuse。

如果沒有單一大頭：

- 代表 `0.5s` 可能是多段小 I/O 加總。
- 可再評估是否導入 OpenTelemetry tracing，而不是繼續加手工 log。

## 暫時結論

目前看到的 `postback` `0.5s` 不應直接解讀成「DB 查詢需要 0.5 秒」。

比較準確的暫時說法是：

`line_webhook_event_duration_seconds` 顯示 WeaMind 在 production webhook path 中，單次 `postback` server-side handler 完成時間約為數百毫秒。這段時間可能包含 Redis、PostgreSQL、weather query formatting，以及對 LINE Messaging API 的同步回覆呼叫。若要知道主要來源，需要下一輪加最小 structured timing log 或 tracing。

這個問題保留為 W7 之後的 latency attribution / tracing 候選題，不併入 W7 demo MVP 收尾。
