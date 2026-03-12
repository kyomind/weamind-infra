# 2026-03-12 Pod To VM And Endpoints QA

> 原則：每題都先回到 repo 檔案或既有 SOP，不直接背 Kubernetes 名詞。
> 這份 QA 的重點是把「Pod 連 VM」和「Service / Endpoints / Pod 對照」分成兩條可觀察路徑。

## Q1

### 題目

在 WeaMind 這個專案裡，line-bot Pod 如果要連 PostgreSQL 和 Redis，它實際上會連到哪裡？這個答案你可以從哪些 repo 檔案直接看出來？

### 拆題

- `POSTGRES_HOST` 與 `REDIS_URL` 在哪個檔案裡？
- 這些值是 Service 名稱、Pod IP，還是 VM 的內網 IP？
- 這些設定是怎麼進到容器裡的？

### 對照檔案

- `manifests/configmap.yaml`
- `manifests/deployment.yaml`
- `docs/WeaMind Infra核心架構.md`

### 使用者回答摘要

- 待回答

### AI 修正與補充

- 待補

### 狀態

- 進行中

---

## Q2

### 題目

為什麼這個專案沒有把 PostgreSQL / Redis 也搬進 K8s，或至少包成 cluster 內的 Service 名稱給 app 連？

### 對照檔案

- `docs/WeaMind Infra核心架構.md`
- `README.md`
- `manifests/configmap.yaml`

### 使用者回答摘要

- 待回答

### AI 修正與補充

- 待補

### 狀態

- 未開始

---

## Q3

### 題目

`weamind-line-bot` Service、Endpoints、Pods 三者在這個專案裡各自代表什麼？如果我想最快確認 Service 後面到底有沒有健康 Pod，最該看哪個？

### 對照檔案

- `manifests/service.yaml`
- `manifests/deployment.yaml`
- `docs/LINE-Webhook-切換流程.md`

### 使用者回答摘要

- 待回答

### AI 修正與補充

- 待補

### 狀態

- 未開始

---

## Q4

### 題目

如果今天 `kubectl get endpoints weamind-line-bot` 是空的，你第一輪會先查哪幾件事？如果 Endpoints 正常，但 app 還是連不到 PostgreSQL / Redis，又該切到哪條排查路徑？

### 對照檔案

- `manifests/service.yaml`
- `manifests/deployment.yaml`
- `manifests/configmap.yaml`
- `docs/LINE-Webhook-切換流程.md`

### 使用者回答摘要

- 待回答

### AI 修正與補充

- 待補

### 狀態

- 未開始