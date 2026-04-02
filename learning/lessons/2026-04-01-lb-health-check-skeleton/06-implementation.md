# 2026-04-01 LB Health Check Skeleton Implementation

## 這份文件的角色

- 這不是一般 `03-command.md` 的 command drill。
- 這份檔案只用在今天這種比較少見的情況：**lesson 進行中需要真的改動 cluster 設定**。
- 記錄重點不是完整逐字稿，而是每一輪都留下最小閉環：**這一輪想改什麼、實際做了什麼、看到什麼結果、目前怎麼判讀。**
- 最終 lesson 收斂仍以 `04-report.md` 為主；延伸補充與卡片素材仍放 `05-note.md`。

## 今日實作主題

- 目標：把 WeaMind 目前「HTTP 與 HTTPS 都可直接命中」的狀態，朝 **HTTPS health check + HTTP→HTTPS redirect** 的方向安全調整。
- 原則：先保住 Hetzner LB health check 的穩定，再做 redirect，避免入口先變 unhealthy。

## 今日實作順序

1. 先確認 Hetzner LB 目前 health check 設定與預計要改的欄位。
2. 先把 health check 改成走 HTTPS 的 `/health`。
3. 驗證 LB target 是否維持 healthy。
4. 再決定 Traefik / Ingress 要用哪種方式加上 HTTP→HTTPS redirect。
5. 驗證外部 `http://` 是否真的跳到 `https://`，且 `https://` 正常可用。
6. 若中途出現 unhealthy 或行為異常，先記錄現象與回退點，不硬往下做。

## 記錄格式

### Round 1

#### 這一輪要驗證什麼

- 先確認目前 Hetzner LB health check 還是不是走 HTTP，以及它的 `Domain` / path / port 設定是否與 lesson 裡的理解一致。

#### 預計操作

```bash
# 使用者待執行
```

#### 實際輸出 / 操作結果

```bash
# 待回填
```

#### AI 判讀與收斂

- 待回填。

#### 目前狀態

- 進行中
