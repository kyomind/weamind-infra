# LINE Webhook 切換流程 SOP

## 目的

將 LINE Bot webhook 從原堡壘機單機版（`api.kyomind.tw`）切換至 K8s 版本（`k8s.kyomind.tw`），實現應用層的 Kubernetes 遷移。

## 架構對照

| 項目         | 堡壘機版（舊）           | K8s 版（新）                                  |
| ------------ | ------------------------ | --------------------------------------------- |
| **Endpoint** | `https://api.kyomind.tw` | `https://k8s.kyomind.tw`                      |
| **運行環境** | Docker Compose           | K3s (3-node cluster)                          |
| **資料庫**   | 本地 PostgreSQL (5433)   | 保壘機內網 PostgreSQL (`10.0.0.2:5433`)       |
| **Redis**    | 本地 Redis (6379)        | 保壘機內網 Redis (`10.0.0.2:6379`)            |
| **SSL/TLS**  | Nginx + certbot          | Hetzner LB + cert-manager (Cloudflare DNS-01) |
| **流量入口** | Nginx 反向代理           | Hetzner LB → Traefik Ingress                  |

---

## 前置檢查清單（切換前必做）

### 1. K8s 叢集健康度

```bash
# 節點狀態
kubectl get nodes
# 預期：3 個節點全為 Ready

# weamind Pods
kubectl -n weamind get pods
# 預期：2/2 Running

# Service Endpoints
kubectl -n weamind get endpoints weamind-line-bot
# 預期：兩個 Pod IP
```

### 2. 憑證有效性

```bash
# 檢查憑證狀態
kubectl -n weamind get certificate k8s-kyomind-tw
# 預期：READY=True

# 驗證 HTTPS
curl -I https://k8s.kyomind.tw/health
# 預期：HTTP/2 200 / {"status":"ok"}
```

### 3. 資料庫連線（從 K8s 視角）

```bash
# 用臨時 Pod 測試 PostgreSQL
kubectl run -it --rm psql-test \
  --image=postgres:17.5-bookworm \
  --restart=Never \
  --namespace=weamind \
  -- psql -h 10.0.0.2 -p 5433 -U wea_bot -d weamind -c '\dt'
# 預期：能列出資料表

# 用臨時 Pod 測試 Redis
kubectl run -it --rm redis-test \
  --image=redis:8.2.1-bookworm \
  --restart=Never \
  --namespace=weamind \
  -- redis-cli -h 10.0.0.2 -p 6379 ping
# 預期：PONG
```

### 4. Hetzner LB 健康檢查

進入 Hetzner Console → Load Balancer：
- 確認 Targets 全為 **Healthy**
- 確認 Service (HTTPS 443) 狀態正常

---

## 切換步驟

### Step 1：記錄舊設定（重要！）

進入 [LINE Developers Console](https://developers.line.biz/console/)：

1. 選擇你的 Bot channel
2. **Messaging API** tab
3. 找到 **Webhook URL** 欄位
4. **截圖或複製**目前的 URL（`https://api.kyomind.tw/callback`）

> ⚠️ 這是回滾時的依據

### Step 2：更新 Webhook URL

在同一頁面：

1. 將 Webhook URL 改為：
   ```
   https://k8s.kyomind.tw/callback
   ```

2. 點 **Update**

3. **立刻點 Verify 按鈕**（重要！）

### Step 3：Webhook 驗證

點擊 **Verify** 後：

- ✅ **Success**：顯示綠色勾勾 → 可進行下一步
- ❌ **Failed**：立即執行回滾流程（見下方）

---

## 功能驗證（切換後必做）

### 1. 基礎存活檢查

```bash
# /health endpoint
curl https://k8s.kyomind.tw/health
# 預期：{"status":"ok"}
```

### 2. LINE Bot 實測（最關鍵）

在 LINE 對話框傳送測試訊息：

| 測試項目       | 操作                                   | 預期結果       |
| -------------- | -------------------------------------- | -------------- |
| **基本回應**   | 傳送任意訊息                           | Bot 正常回覆   |
| **資料庫讀取** | 觸發需查詢資料的指令（如查詢歷史記錄） | 能正確返回資料 |
| **Redis 互動** | 觸發需快取的操作（如 session 相關）    | 功能正常       |

### 3. 檢查 K8s Logs

```bash
# 即時查看 Pod logs
kubectl -n weamind logs -l app=weamind --tail=50 -f

# 確認有收到 LINE webhook 請求
# 應看到 POST /callback 相關日誌
```

### 4. 確認無錯誤

```bash
# 檢查最近 5 分鐘的錯誤日誌
kubectl -n weamind logs -l app=weamind --tail=100 --since=5m | grep -i error
# 應無異常錯誤
```

---

## 回滾流程（若遇問題）

### 情境 A：Webhook 驗證失敗

**立刻回滾**（1 分鐘內完成）：

1. LINE Developers Console → Webhook URL
2. 改回：`https://api.kyomind.tw/callback`
3. 點 **Update**
4. 點 **Verify** 確認成功

### 情境 B：驗證成功但實測異常

**先排查**（不超過 3 分鐘）：

```bash
# 1. 看 Pod 狀態
kubectl -n weamind get pods

# 2. 看即時 logs
kubectl -n weamind logs -l app=weamind --tail=100 -f

# 3. 確認 Service Endpoints
kubectl -n weamind get endpoints weamind-line-bot
```

**若 3 分鐘內無法解決**：

1. **立即回滾 Webhook URL**（同情境 A）
2. 事後分析問題

### 情境 C：部分功能異常

**判斷影響範圍**：

- **僅影響新功能** → 可暫時保持 K8s 版，標記 known issue
- **影響核心流程** → 立即回滾

---

## 切換後監控（首 24 小時）

### 關鍵指標

```bash
# 1. Pod 穩定性（每小時檢查）
kubectl -n weamind get pods

# 2. Restart 次數（應為 0）
kubectl -n weamind get pods -o wide

# 3. 錯誤日誌（每 4 小時）
kubectl -n weamind logs -l app=weamind --tail=200 --since=4h | grep -i error
```

### LB 健康狀態

進入 Hetzner Console，確認：
- Targets 持續 Healthy
- Request rate 正常（視業務量而定）

### 資料庫連線

```bash
# 在堡壘機檢查 PostgreSQL 連線數
docker exec -it postgres psql -U wea_bot -d weamind -c \
  "SELECT count(*) FROM pg_stat_activity WHERE datname='weamind';"
# K8s 版應有 2–4 條連線（對應 2 個 Pod，每個 2 workers）
```

---

## 附錄：常見問題排查

### Q1：Webhook 驗證失敗（Invalid response）

**可能原因**：
- Pod 未 Ready（`kubectl -n weamind get pods` 確認）
- Ingress 未正確綁定 Service（`kubectl -n weamind describe ingress` 確認 Backends）
- 憑證異常（`kubectl -n weamind get certificate` 確認 READY=True）

**快速檢查**：
```bash
# 從叢集外測試
curl -v https://k8s.kyomind.tw/callback
# 應回應 405 Method Not Allowed（因為是 GET，不是 POST）
# 關鍵是「能通、有回應」
```

### Q2：Bot 回應延遲

**可能原因**：
- 資料庫查詢慢（保壘機內網 latency）
- Pod 資源不足

**檢查方式**：
```bash
# Pod 資源使用
kubectl -n weamind top pods

# 資料庫連線測試（從 K8s Pod）
kubectl run -it --rm psql-latency \
  --image=postgres:17.5-bookworm \
  --restart=Never \
  --namespace=weamind \
  -- bash -c "time psql -h 10.0.0.2 -p 5433 -U wea_bot -d weamind -c 'SELECT 1;'"
# 預期 < 10ms（內網）
```

### Q3：部分請求失敗（間歇性）

**可能原因**：
- Pod 其中一個異常（ReplicaSet = 2）
- LB health check 延遲

**檢查方式**：
```bash
# 逐一檢查兩個 Pod 的 logs
kubectl -n weamind logs <pod-name-1> --tail=100
kubectl -n weamind logs <pod-name-2> --tail=100

# 找出哪個 Pod 有問題
kubectl -n weamind describe pod <pod-name>
```

---

## 參考資訊

- **架構文檔**：[WeaMind V2核心架構.md](./WeaMind%20V2核心架構.md)
- **實作進度**：[PROGRESS.md](../PROGRESS.md)
- **LINE Developers Console**：https://developers.line.biz/console/
- **Hetzner Load Balancer Console**：https://console.hetzner.cloud/

---

**最後更新**：2026-01-20
**文檔版本**：v1.0
