# WeaMind Infrastructure - AI Coding Instructions

## Project Context

這是 [WeaMind LINE Bot](https://github.com/kyomind/weamind) 的 Kubernetes 基礎設施配置。採用 **K8s + VM 混合架構**：僅 line-bot 運行於 K8s，資料庫保留在原 VM。

## Architecture Overview

```
LINE → 原VM(NGINX) → K3s(Traefik) → line-bot Pods → 原VM(PostgreSQL/Redis)
```

**關鍵設計決策**：
- 使用 K3s（非 kubeadm）因內建 Traefik 和快速部署
- 資料庫維持在 VM，僅應用層遷移至 K8s
- PostgreSQL/Redis 透過內網 IP 連接（非 K8s Service）

## Critical Configuration Patterns

### 環境變數規範

**Secrets（敏感資料）**：
- `LINE_CHANNEL_SECRET`, `LINE_CHANNEL_ACCESS_TOKEN`
- `POSTGRES_PASSWORD`

**ConfigMap（非敏感配置）**：
```yaml
POSTGRES_HOST: "<原VM內網IP>"  # 重要：使用內網 IP，非 K8s service name
REDIS_URL: "redis://<原VM內網IP>:6379/0"
BASE_URL: "https://api.kyomind.tw"
ENV: "production"
```

### line-bot Deployment 規格

**Container Image**: `ghcr.io/astral-sh/uv:python3.12-bookworm-slim`
**Port**: 8000
**Health Check**: `/health` endpoint

**啟動指令**（精確版本）：
```yaml
command:
  - uvicorn
  - app.main:app
  - --host
  - "0.0.0.0"
  - --port
  - "8000"
  - --workers
  - "2"
  - --proxy-headers
  - --loop
  - uvloop
  - --http
  - httptools
```

## Infrastructure Topology

| 服務 | 部署位置 | 管理方式 |
|------|---------|---------|
| line-bot | K8s Cluster | 本 repo |
| PostgreSQL | 原 VM (Docker) | 手動管理 |
| Redis | 原 VM (Docker) | 手動管理 |
| NGINX | 原 VM | 反向代理 |

## Development Workflow

1. **編輯 K8s manifests** → 使用 kubectl apply
2. **驗證部署** → `kubectl get pods -n <namespace>`
3. **查看日誌** → `kubectl logs <pod-name>`

## Reference Documents

**完整架構細節**：參考目錄`.privatedocs/`底下相關文件
