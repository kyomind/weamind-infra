# 2026-03-10 WeaMind Traffic Path Report

## 今日主題

把 Day 1 與 Day 2 的 networking 概念，正式對到 WeaMind 專案裡的實際流量路徑。

## 為什麼這份 lesson 存在

外部預習已經建立了 Pod、Service、Ingress、Ingress Controller、LoadBalancer 的概念骨架。

但如果沒有回到 repo 對照，就還停留在一般 Kubernetes 知識，還不能穩定回答 WeaMind 的流量到底怎麼走、為什麼 line-bot Service 是 ClusterIP、Traefik 在這個專案裡到底站在哪一層。

這份 report 的目的，就是把抽象概念收斂成 WeaMind 專案內的真實說法。

## repo 對照重點

### 1. line-bot Service 是 ClusterIP

在 `manifests/service.yaml` 中：

- Service 名稱是 `weamind-line-bot`
- `type` 是 `ClusterIP`
- Service port 是 `80`
- `targetPort` 是 `8000`

這代表它不是直接對 Internet 暴露，而是作為 cluster 內的穩定入口，讓 Ingress Controller 可以把流量送進來，再由 Service 分配到後面的 Pods。

### 2. Ingress 使用 Traefik

在 `manifests/ingress.yaml` 中：

- `ingressClassName` 是 `traefik`
- host 是 `k8s.kyomind.tw`
- backend service 指向 `weamind-line-bot:80`

這代表 WeaMind 的 HTTP/HTTPS routing 是交給 Traefik 處理，不是直接從外部進到 line-bot Service。

### 3. Traefik 不是規則，而是執行者

Ingress YAML 只是宣告規則：

- 哪個 host 要接哪個 service
- 哪個 path 要送去哪裡

真正會監聽流量、讀取 Ingress 規則並轉送到 `weamind-line-bot` 的，是 K3s 內建的 Traefik Ingress Controller。

## WeaMind 的實際流量路徑

目前應以這條路徑理解：

`LINE / Client → Cloudflare DNS → Hetzner Load Balancer → Traefik → weamind-line-bot Service → line-bot Pods`

如果再把資料層補上，完整說法是：

`LINE / Client → Cloudflare DNS → Hetzner Load Balancer → Traefik → weamind-line-bot Service → line-bot Pods → Bastion VM 上的 PostgreSQL / Redis`

## 為什麼這樣設計

### 為什麼不是直接把 line-bot Service 做成 LoadBalancer

因為 production 常見做法是先由一個 external load balancer 把流量送進 Ingress Controller，再由 Ingress Controller 做 HTTP routing。

這樣比較容易集中管理入口、TLS 與路由規則，也避免每個 app service 都各自對外暴露。

### 為什麼 Service 用 ClusterIP 反而合理

因為在這個架構裡，line-bot Service 的責任不是直接對外，而是：

1. 提供 cluster 內穩定入口。
2. 把流量導向符合 selector 的 Pods。
3. 讓 Ingress Controller 有固定目標可以轉送。

換句話說，外部入口由 Hetzner LB 與 Traefik 負責；Service 只需要做好 cluster 內的轉送角色。

## 目前已能講清楚什麼

1. WeaMind 的 line-bot Service 為什麼是 ClusterIP。
2. Traefik 在這個專案裡是 Ingress Controller，不只是名詞。
3. 這個專案的流量骨架不是 Client → Service → Pod，而是先經過 external LB 與 Traefik。

## 目前還沒完全補齊什麼

1. K3s 內 Traefik 的 Service type 與實際暴露方式還需要用 `kubectl` 再確認。
2. Hetzner Load Balancer 是怎麼接到 K3s 節點與 Traefik 的，還要再補實際部署細節。
3. 外部請求進不來時，還需要整理成一份固定的 debug sequence。

## 下一步

下一個 internal lesson 應接著補其中一個：

1. Traefik Service 與 Hetzner LB 的實際接法。
2. Pod 連 VM 上 PostgreSQL / Redis 的內網路徑。
3. DNS → LB → Ingress → Service → Pod 的逐層排查順序。