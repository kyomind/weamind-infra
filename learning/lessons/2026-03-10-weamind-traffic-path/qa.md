# 2026-03-10 WeaMind Traffic Path QA

> 原則：每題都要小，優先回到 repo 看 YAML 或文件再回答。
> 這份檔案不是標準答案集，而是這次 internal lesson 的互動紀錄。

## Q1

### 題目

在 WeaMind 這個專案裡，為什麼 `weamind-line-bot` Service 用 `ClusterIP` 反而是合理的？

### 對照檔案

- `manifests/service.yaml`
- `manifests/ingress.yaml`
- `README.md`

### 使用者回答摘要

- 使用者先回答：因為這個 Service 主要是給 Traefik 使用，所以用 ClusterIP 就足夠。

### AI 修正與補充

- 核心方向正確，但更準確的說法是：Service 不是只對 Traefik 暴露，而是作為 cluster 內的穩定入口。
- 在 WeaMind 這條外部流量路徑裡，外部入口已由 Hetzner Load Balancer 與 Traefik 承接，因此 **app Service 不需要直接對 Internet 暴露**。

### 狀態

- 已完成

---

## Q2

### 題目

既然已經有 Traefik，為什麼 Traefik 不直接把流量送到 Pods，而是先送到 Service？

### 對照檔案

- `manifests/service.yaml`
- `manifests/deployment.yaml`

### 使用者回答摘要

- 使用者指出 **Pod 是動態的**，會因為擴縮容、更新或重建而改變，因此不能把它當成穩定目標。

### AI 修正與補充

- 這個回答正確。
- 補充重點是：Service 提供**穩定抽象層**，讓前面的 Ingress Controller **不需要知道每個 Pod 的即時變動**，只要把流量送到 Service 即可。

### 狀態

- 已完成

---

## Q3

### 題目

如果 line-bot 有 2 個 Pods，Service 在這個架構裡除了提供穩定入口，還做了什麼重要的事？

### 對照檔案

- `manifests/service.yaml`
- `manifests/deployment.yaml`

### 使用者回答摘要

- 使用者回答：Service 會對後面的多個 Pods 做 load balancing。
- 也提出疑問：控制 Pod 數量應該不是 Service 的責任。

### AI 修正與補充

- 回答正確。
- 補充邊界：Deployment 負責維持 Pod 副本數；Service 負責**找到符合 selector 的 Pods** 並把流量分配過去。

### 狀態

- 已完成

---

## Q4

### 題目

如果今天 `weamind-line-bot` Service 的 **Endpoints 是空的**，在這個 repo 裡第一個要對照哪兩個地方？

### 對照檔案

- `manifests/service.yaml`
- `manifests/deployment.yaml`

### 使用者回答摘要

- 使用者先想到要看 Deployment 與 Service，並比對 Service selector 與 Deployment 內的 app 設定是否對得上。

### AI 修正與補充

- 方向正確。
- 更精準地說，第一個應檢查的是 Service selector，第二個應檢查 Deployment Pod template 的 labels，而不是 Deployment 的資源名稱。

### 狀態

- 已完成

---

## Q5

### 題目

在 WeaMind 這條流量路徑裡，Ingress、Service、Deployment 三者各自的責任邊界是什麼？

### 對照檔案

- `manifests/ingress.yaml`
- `manifests/service.yaml`
- `manifests/deployment.yaml`

### 使用者回答摘要

- 使用者回答：Deployment 先把 Pod 跑起來，否則後面的導流沒有 target。
- 使用者回答：Service 為它選到的 Pods 建立固定入口，像是把這些 Pods 包起來。
- 使用者回答：Ingress 則負責決定外部請求應該進到哪個 Service，規則由 Ingress YAML 宣告，再由 Ingress Controller 讀取並執行。

### AI 修正與補充

- 整體理解正確，而且角色邊界已經抓到了。
- 一個要修得更準的地方是：沒有 Service，不代表 Pod 在 cluster 內完全不可見，而是它不再有「穩定、固定、可抽象依賴」的入口。Pod 仍然存在，也有自己的 IP，但 Pod IP 不適合作為前面流量長期依賴的目標。
- Deployment 的責任是維持指定數量的 Pods 存在，並處理更新、自我修復等生命週期管理。
- Service 的責任是透過 selector 對到一組 Pods，提供穩定入口並把流量分配過去。
- Ingress 的責任是宣告 HTTP/HTTPS 規則，決定哪個 host/path 應轉到哪個 Service；真正執行這些規則的是 Ingress Controller。

### 狀態

- 已完成
