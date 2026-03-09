# WeaMind Infrastructure - AI Coding Instructions

## Project Context

這是 [WeaMind LINE Bot](https://github.com/kyomind/weamind) 的 Kubernetes 基礎設施配置。採用 **K8s + VM 混合架構**：僅 line-bot 運行於 K8s，資料庫保留在保壘機。

目前專案已完成實作，**當前階段是學習深化與面試準備**，不是重新規劃實作。AI 協作的首要任務是把既有成果轉化成可以講清楚、可以追問、可以 debug 的材料。

## Architecture Overview

```
LINE → k8s.kyomind.tw → Hetzner LB (SSL終止) → K3s(Traefik) → line-bot Pods → 保壘機(PostgreSQL/Redis)
```

**關鍵設計決策**：
- 使用 K3s（非 kubeadm）內建 Traefik
- 資料庫保留在保壘機，僅應用層遷移至 K8s
- PostgreSQL/Redis 透過保壘機內網 IP 連接
- 獨立端點切換：透過 LINE webhook URL 切換流量（`k8s.kyomind.tw` vs `api.kyomind.tw`）

**面試材料重點**：
- 為什麼選 K3s，而不是 kubeadm / EKS / GKE
- 為什麼資料庫仍放 VM，而不是一起搬進 K8s
- 流量路徑如何從 LINE 走到 Pods，再連到 VM 上的 PostgreSQL/Redis
- 遇到故障時，如何從 DNS / LB / Ingress / Service / Pod 逐層排查
- 每個設計的 trade-off，而不是只描述它是什麼

## Critical Configuration

### 環境變數規範

**ConfigMap（非敏感）**：
```yaml
POSTGRES_HOST: "<保壘機內網IP>"  # 使用內網 IP
REDIS_URL: "redis://<保壘機內網IP>:6379/0"
BASE_URL: "https://k8s.kyomind.tw"  # K8s 版專用端點
ENV: "production"
```

**Secret（敏感資料）**：
- `LINE_CHANNEL_SECRET`, `LINE_CHANNEL_ACCESS_TOKEN`
- `POSTGRES_PASSWORD`, `WEA_DATA_PASSWORD`

### line-bot Deployment 規格

- **Image**: `ghcr.io/kyomind/weamind:latest`
- **Port**: 8000
- **Health Check**: `/health` endpoint
- **Replicas**: 2

**啟動指令**：
```yaml
command: [uvicorn, app.main:app, --host, "0.0.0.0", --port, "8000",
          --workers, "2", --proxy-headers, --loop, uvloop, --http, httptools]
```

## File Structure

```
weamind-infra/
├── manifests/          # 已完成的 K8s YAML
├── reference/          # 來自 WeaMind 的參考配置
├── docs/               # 公開文件與架構說明
├── .env.example        # 環境變數範本
└── .privatedocs/       # 私密文檔、學習計畫、個人背景、歷史資料
```

## Current Working Mode

- 預設以「學習教練 / 面試官」模式協作，而非「綠地建置顧問」。
- 優先使用現有 manifests、架構文件、踩坑紀錄來出題、追問、整理答案。
- 若使用者要求精簡上下文，保留架構、關鍵決策、流量路徑、debug 故事即可；過時的時程規劃與執行清單可視為歷史資料。
- 回答重點應放在 Why、How、trade-off、debug sequence，而不是重複列出所有實作步驟。

## Development Workflow

1. **編輯 manifests** → `kubectl apply -f manifests/`
2. **驗證部署** → `kubectl get pods -n weamind`
3. **查看日誌** → `kubectl logs <pod-name> -n weamind -f`
4. **切換流量** → 修改 LINE Developers webhook URL

## Reference

- 完整架構規格：`docs/WeaMind V2核心架構.md`
- 實作進度追蹤：`docs/PROGRESS.md`(已完成)
- 學習背景與定位：`.privatedocs/about-me.md`
- 深化學習計畫：`.privatedocs/三月詳細學習計畫.md`
- 環境變數範本：`.env.example`
- 參考配置：`reference/` 目錄
