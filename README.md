# weamind-infra

Kubernetes manifests for [WeaMind](https://github.com/kyomind/weamind) LINE Bot.

## Stack

- **K3s** (1 control-plane + 2 workers) on Hetzner Cloud
- **Traefik** Ingress Controller (K3s built-in)
- **Hetzner Load Balancer** for traffic distribution
- **cert-manager** + Let's Encrypt (Cloudflare DNS-01) for TLS
- **PostgreSQL** & **Redis** on bastion VM (not in K8s)

## Architecture

```mermaid
flowchart TD
    LINE[LINE Platform] -->|Webhook HTTPS| LB

    subgraph Hetzner["Hetzner Private Network"]
        LB[Hetzner LB<br/>TCP 443 Passthrough]

        subgraph K3s["K3s Cluster (3 Nodes)"]
            subgraph CP["Control Plane"]
                API[API Server]
            end

            subgraph Workers["Worker Nodes × 2"]
                Ingress[Traefik Ingress<br/>TLS Termination]
                Pod1[line-bot Pod]
                Pod2[line-bot Pod]
            end

            API -.->|manages| Workers
        end

        subgraph Bastion["Bastion VM - Data Layer"]
            PG[(PostgreSQL)]
            Redis[(Redis)]
        end
    end

    LB --> Ingress
    Ingress --> Pod1
    Ingress --> Pod2
    Pod1 --> PG
    Pod1 --> Redis
    Pod2 --> PG
    Pod2 --> Redis
```

- **混合架構**：僅應用層在 K8s，資料庫保留在保壘機（內網連接）
- **獨立端點**：`k8s.kyomind.tw` (K8s) vs `api.kyomind.tw` (單機)
- **流量切換**：透過 LINE webhook URL 切換

## Related Repositories

- [WeaMind](https://github.com/kyomind/weamind) - LINE Bot FastAPI application
