# WeaMind K8s 實作進度

## Day 1 - 基礎設施準備（2026-01-04）

- [x] Hetzner Cloud 開設 3 台 VM（1 控制平面 + 2 工作節點）
- [x] 建立私有網路（Private Network）確保內網互通
- [x] 配置防火牆規則（允許 SSH 從原 VM 堡壘機連入，K8s 節點不暴露公網）
- [x] 設定 SSH 跳板（透過原 VM 訪問 K8s 節點）
- [x] 系統基礎準備（`apt update && upgrade`，安裝必要工具）
- [x] 架構決策：三台節點直接使用 root（網路層已封死，單人操作，符合狠人思維）

---

## Day 2-4 - 控制平面安裝（2026-01-05 至 2026-01-07）

- [x] 控制平面安裝 K3s server（使用 `--disable traefik`，以降低初期變數），並確認 `k3s` 服務為 active (running)
- [x] 取得 node-token（`/var/lib/rancher/k3s/server/node-token`），並保存於堡壘機個人帳號家目錄（僅作為 worker join 使用）
- [x] 複製 kubeconfig（`/etc/rancher/k3s/k3s.yaml`）到本機，並移至標準位置 `~/.kube/config`
- [x] 設定本機 kubectl 透過 SSH tunnel 存取 API server（`-L 6443:127.0.0.1:6443`），kubeconfig 的 server 指向 `https://127.0.0.1:6443`
- [x] 驗證控制平面健康：本機執行 `kubectl get nodes`，顯示 control-plane 節點為 Ready

---

## Day 5-6 - 工作節點加入（2026-01-08 至 2026-01-09）

- [x] 工作節點 1 安裝 K3s agent（使用控制平面內網 IP `10.0.0.3` 與 node-token 加入叢集），確認 `k3s-agent` 服務為 active (running)
- [x] 工作節點 2 安裝 K3s agent（使用相同的 K3S_URL 與 node-token），確認 `k3s-agent` 服務為 active (running)
- [x] 驗證三節點叢集健康：本機執行 `kubectl get nodes`，應顯示 1 個 control-plane + 2 個 worker，且全部為 Ready
- [x] 確認節點間內網通訊正常：於 worker 節點使用內網 IP ping control-plane 與另一台 worker，封包 0% loss
- [x] 檢查節點角色顯示：control-plane 節點顯示 `control-plane`，worker 節點 `ROLES` 為 `<none>`（K3s 預設行為，屬正常狀態）

---

## Day 7-8 - Traefik 與網路驗證（2026-01-10 至 2026-01-11）

- [x] 啟用內建 Traefik Ingress Controller：移除 `--disable traefik` 並重啟 K3s，確認 Ingress controller 正式接管叢集入口流量
- [x] 關鍵修正：強制綁定私有網路介面，明確指定 `--node-ip` 與 `--flannel-iface`，避免 Hetzner 環境誤抓公網 IP 導致 flannel / Service routing 異常
- [x] 驗證 Traefik 系統元件狀態：`traefik` Pod 為 Running，`svclb-traefik` 於各節點建立，確認 entrypoint 已在每個 node 開放
- [x] 驗證叢集內部 Service 通訊：Pod 可透過 Service DNS（如 `http://nginx`）成功存取後端，確認 kube-proxy / CoreDNS / Endpoint 正常
- [x] 部署測試用 nginx（最小 Deployment + Service + Ingress）：完整驗證 Pod 調度、Service 代理、Traefik Ingress Host routing 全鏈路
- [x] 驗證 CoreDNS 解析能力：Pod 內成功解析 `kubernetes.default.svc.cluster.local`，確認 cluster DNS search domain 與 API Service 正常

---

## Day 9 - 應用程式準備（2026-01-12）

- [x] WeaMind repo 新增 `/health` endpoint（FastAPI 簡單返回 `{"status": "ok"}`）
- [x] 複製配置文件到 `weamind-infra/reference/`（Dockerfile、docker-compose.yml、docker-compose.prod.yml、Makefile）
- [x] 從保壘機 `.env` 生成 `weamind-infra/.env.example`（僅保留 key，清空 value）
- [x] 配置 `.gitignore`：`.env`、`.privatedocs/secrets/`、`kubeconfig.yaml`
- [x] 在保壘機測試 Docker Compose 單機版服務的 `/health` endpoint（`curl https://api.kyomind.tw/health` 回應 `{"status":"ok"}`）

---

## Day 10-12 - 容器化與 GHCR 自動發布（2026-01-13 至 2026-01-15）

- [x] WeaMind 建立 `publish-ghcr.yml` workflow：CI 成功後自動發布 `latest` 和 `sha-xxx` tags（使用 `workflow_run` 機制`）
- [x] WeaMind 建立 `publish-release.yml` workflow：git tag 觸發，產出語義化版本號（如 `1.0.7`, `1.0`, `1`）
- [x] 兩個 workflows 皆添加多平台支援（`linux/amd64` 和 `linux/arm64`）
- [x] WeaMind 修改 `docker-compose.yml`：從本地 build 改為使用 `ghcr.io/kyomind/weamind:latest`
- [x] 設定 GHCR package 為 public（允許無認證 pull）
- [x] 驗證流程：本地成功 pull image（Apple Silicon）與 Bastion 部署成功

---

## Day 13-14 - 撰寫 line-bot Manifests（2026-01-16 至 2026-01-17）（2-3h）

- [x] 建立 `manifests/namespace.yaml`：定義 `weamind` namespace，作為所有 K8s 資源的隔離邊界
- [x] 撰寫 `manifests/configmap.yaml`：僅放非敏感配置，來源對齊 `.env.example`
- [x] 明確使用保壘機內網 IP（`10.0.0.2`）作為 `POSTGRES_HOST` 與 `REDIS_URL`，避免誤用 localhost 或 Service 名稱
- [x] 修正 PostgreSQL 對 K8s 實際可連通的 host port（`POSTGRES_PORT=5433`），依據 `nc` 內網連線驗證結果
- [x] 移除 K8s line-bot 不需要的帳號設定（`WEA_DATA_USER`），維持最小權限與最小設定集合
- [x] 驗證 ConfigMap 套用結果，確認 data key 數量與實際內容符合預期（`kubectl get cm -o yaml`）

- [x] 撰寫 `.privatedocs/secrets/secret.yaml`：改用 `stringData` 明文定義敏感資料，避免手動 base64 與 UTF-8 編碼錯誤，**不提交 Git**
- [x] 釐清 Secret 關鍵規則：人手撰寫一律使用 `stringData`，僅在確定為 base64 時才使用 `data`
- [x] 排查並修復 `CreateContainerError (invalid UTF-8)`：根因為錯誤使用 `data` + 非 base64 字串
- [x] 驗證 Secret 套用結果與 Deployment 行為，確認 Pod 能正確注入敏感環境變數

- [x] 撰寫 `manifests/deployment.yaml`：image `ghcr.io/kyomind/weamind:latest`，2 replicas，command 與 docker-compose 一致
- [x] 設定 readiness / liveness probes 指向 `/health`，確認 Pod 進入 Ready 狀態
- [x] 驗證 Deployment / ReplicaSet 行為，確認僅有單一 active RS，Pods `2/2 Running`

- [x] 建立 `manifests/service.yaml`：ClusterIP Service（port 80 -> targetPort 8000），並修正 selector 對齊 Pod label `app=weamind`，確認 Endpoints 產生
- [x] 建立 `manifests/ingress.yaml`：Traefik Ingress（Host `k8s.kyomind.tw`，path `/`），後端指向 `weamind-line-bot:80`，確認 Backends 綁定正確
- [x] 叢集內驗證 Service：用臨時 curl Pod 呼叫 `http://weamind-line-bot/health` 回 `200 {"status":"ok"}`
- [x] NodePort 驗證 Ingress 路由：在 node 上以 `Host: k8s.kyomind.tw` 打 `http://127.0.0.1:30417/health` 回 `200 {"status":"ok"}`
- [x] Dry-run 驗證 manifests：`kubectl apply --dry-run=client -f manifests/` 全數通過

---