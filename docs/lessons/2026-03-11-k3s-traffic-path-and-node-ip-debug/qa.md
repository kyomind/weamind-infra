# 2026-03-11 K3s Traffic Path And Node IP Debug QA

> 原則：每題都先回到 repo 檔案或既有架構文件，不直接背名詞。
> 這份 QA 的重點是流量路徑、責任邊界與 debug sequence，不是一般 Kubernetes 教科書。

## Q1

### 題目

在 WeaMind 這個專案裡，一個來自 LINE 的 webhook 請求，從外部進來到進入 line-bot Pod 為止，完整會經過哪些層？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`
- `manifests/ingress.yaml`
- `manifests/service.yaml`

### 使用者回答摘要

- 待填

### AI 修正與補充

- 待填

### 狀態

- 未開始

---

## Q2

### 題目

在這條流量路徑裡，Hetzner Load Balancer、Traefik、`weamind-line-bot` Service 三者的責任邊界分別是什麼？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`
- `manifests/ingress.yaml`
- `manifests/service.yaml`

### 使用者回答摘要

- 待填

### AI 修正與補充

- 待填

### 狀態

- 未開始

---

## Q3

### 題目

為什麼這個專案會特別強調 K3s 節點要綁定私有網路介面？如果節點抓錯成公網 IP，最可能先影響哪一段路徑？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`

### 使用者回答摘要

- 待填

### AI 修正與補充

- 待填

### 狀態

- 未開始

---

## Q4

### 題目

`--node-ip` 和 `--flannel-iface` 在這個專案裡各自是要修什麼問題？為什麼常常需要一起講？

### 對照檔案

- `README.md`
- `docs/WeaMind Infra核心架構.md`

### 使用者回答摘要

- 待填

### AI 修正與補充

- 待填

### 狀態

- 未開始

---

## Q5

### 題目

如果今天外部 webhook 打到 `k8s.kyomind.tw` 沒有進到 line-bot，第一輪排查順序在這個專案裡應該怎麼排？

### 對照檔案

- `README.md`
- `manifests/ingress.yaml`
- `manifests/service.yaml`
- `manifests/deployment.yaml`

### 使用者回答摘要

- 待填

### AI 修正與補充

- 待填

### 狀態

- 未開始