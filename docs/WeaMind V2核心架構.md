# WeaMind Infrastructure Agent Guide

描述 WeaMind V2(K8s 部署) 的架構與關鍵配置。

## Project Purpose

管理 WeaMind 系統的 Kubernetes 基礎設施。這是一個 **K8s + VM 混合架構**，只有 line-bot 運行於 K8s，資料庫保留在原 VM。

## 架構重點（必讀）

```
LINE → k8s.kyomind.tw → Hetzner LB (SSL終止) → K3s(Traefik) → line-bot Pods → 原VM(PostgreSQL/Redis)
```

**流量架構設計（獨立端點）**：
- **K8s 環境**：LINE → k8s.kyomind.tw → Hetzner LB → K3s Traefik → line-bot Pods → PostgreSQL/Redis (原VM)
- **單機環境**：LINE → api.kyomind.tw → 原 VM NGINX → line-bot Docker → PostgreSQL/Redis (原VM)
- **切換機制**：透過 **LINE webhook URL 切換**（秒級生效，無 DNS 傳播延遲）

| 服務         | 部署位置                    |
| ------------ | --------------------------- |
| line-bot     | **K8s 集群** ← 本 repo 管理 |
| PostgreSQL   | 原 VM (Docker)              |
| Redis        | 原 VM (Docker)              |
| weamind-data | 原 VM (Docker)              |
| Hetzner LB   | Hetzner Cloud 服務          |

## Key Facts

- **Cloud Provider**: Hetzner Cloud (德國)
- **K8s Distribution**: K3s
- **Ingress**: Traefik (K3s 內建)
- **Domain**: `k8s.kyomind.tw` (K8s 版專用端點)
- **切換機制**: LINE webhook URL 切換（與單機版 `api.kyomind.tw` 獨立運行）

## VM 節點配置

| 節點            | 規格   | 月費         | 服務                                                   |
| --------------- | ------ | ------------ | ------------------------------------------------------ |
| 原 VM           | 4C/8GB | €6.5         | PostgreSQL + Redis + weamind-data + 堡壘機（SSH 跳板） |
| K8s 控制平面    | 2C/4GB | €3.5         | API Server + etcd（僅內網）                            |
| K8s 工作節點 x2 | 2C/4GB | €7           | line-bot Pods + Traefik（僅內網）                      |
| Hetzner LB      | -      | €5           | 健康檢查 + SSL termination（按需開啟）                 |
| **K8s 總成本**  | -      | **€15.5/月** | 平時可關閉 LB 省至 €10.5/月                            |

**網路安全設計**：K8s 三台機器不暴露公網，僅透過原 VM 堡壘機 SSH 管理

**成本優化說明**：K3s 輕量級設計，控制平面 2C/4GB 對於單一 line-bot workload 綽綽有餘。省下的成本用於 Hetzner LB，實現生產級流量管理。

## K8s 需部署的服務

僅 **line-bot**，不包含 PostgreSQL 和 Redis。

| Service  | Image                                           | Port | Type       |
| -------- | ----------------------------------------------- | ---- | ---------- |
| line-bot | `ghcr.io/astral-sh/uv:python3.12-bookworm-slim` | 8000 | Deployment |

## Critical Environment Variables

```yaml
# 必填 - Secrets
POSTGRES_PASSWORD: ""
LINE_CHANNEL_SECRET: ""
LINE_CHANNEL_ACCESS_TOKEN: ""

# 必填 - ConfigMap
POSTGRES_USER: "<your_db_user>"
POSTGRES_DB: "<your_db_name>"
POSTGRES_HOST: "<原VM內網IP>"  # 重要：不是 K8s service name
POSTGRES_PORT: "5432"
REDIS_URL: "redis://<原VM內網IP>:6379/0"  # 重要：不是 K8s service
ENV: "production"
BASE_URL: "https://k8s.kyomind.tw"  # K8s 版專用端點
```

## line-bot Container Command

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

## Health Checks

- **Endpoint**: `/health`
- **Port**: 8000

## 成功標準

**最小目標**：line-bot 能接收 LINE webhook 並正常回應。

## Related Repos

- `weamind` - LINE Bot FastAPI 應用 → K8s
- `weamind-data` - 天氣資料 ETL → 原 VM
