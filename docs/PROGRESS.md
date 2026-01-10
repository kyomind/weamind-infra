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

- [x] 啟用內建 Traefik Ingress Controller：透過移除 `--disable traefik` 並重啟服務實現
- [x] **關鍵修正：強制綁定私有網路**：解決 Hetzner 預設抓取公網 IP 導致隧道不通的問題，明確指定 `--node-ip` 與 `--flannel-iface`。
- [x] 驗證 Traefik 相關 Pod 正常運行：`traefik` Pod 狀態為 Running，`svclb-traefik` 於各節點就位。
- [x] 驗證內部 Service 通訊：確認 Worker 節點可透過 Service IP (10.43.0.1) 存取 API Server。
- [ ] 部署測試用 nginx（最小 Deployment + Service + Ingress）：驗證 K8s 調度與 Ingress 路由機制
- [ ] 驗證 CoreDNS：Pod 內執行 `nslookup kubernetes.default` 確認內部 DNS 解析正常

---