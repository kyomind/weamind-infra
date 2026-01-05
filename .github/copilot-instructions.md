# WeaMind Infrastructure - AI Coding Instructions

## Project Context

這是 [WeaMind LINE Bot](https://github.com/kyomind/weamind) 的 Kubernetes 基礎設施配置。採用 **K8s + VM 混合架構**：僅 line-bot 運行於 K8s，資料庫保留在保壘機。

## Architecture Overview

```
LINE → k8s.kyomind.tw → Hetzner LB (SSL終止) → K3s(Traefik) → line-bot Pods → 保壘機(PostgreSQL/Redis)
```

**關鍵設計決策**：
- 使用 K3s（非 kubeadm）內建 Traefik
- 資料庫保留在保壘機，僅應用層遷移至 K8s
- PostgreSQL/Redis 透過保壘機內網 IP 連接
- 獨立端點切換：透過 LINE webhook URL 切換流量（`k8s.kyomind.tw` vs `api.kyomind.tw`）

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
├── manifests/          # K8s YAML（待建立）
├── reference/          # 來自 WeaMind 的參考配置
├── docs/               # Markdown 文檔
├── .env.example        # 環境變數範本
└── .privatedocs/       # 私密文檔（含詳細計畫）
```

## Development Workflow

1. **編輯 manifests** → `kubectl apply -f manifests/`
2. **驗證部署** → `kubectl get pods -n weamind`
3. **查看日誌** → `kubectl logs <pod-name> -n weamind -f`
4. **切換流量** → 修改 LINE Developers webhook URL

## Reference

- 詳細實作計畫：`.privatedocs/K8s實作計畫.md`
- 環境變數範本：`.env.example`
- 參考配置：`reference/` 目錄
