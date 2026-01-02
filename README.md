# weamind-infra

Kubernetes manifests for [WeaMind](https://github.com/kyomind/weamind) LINE Bot.

## Stack

- K3s on Hetzner Cloud
- Traefik Ingress (K3s built-in)

## Architecture

```
LINE Platform → NGINX (Reverse Proxy) → K3s Cluster → line-bot Pods
```

## Related Repositories

- [WeaMind](https://github.com/kyomind/weamind) - LINE Bot FastAPI application
