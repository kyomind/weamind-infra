# WeaMind K8s 實作進度

## Day 1 - 基礎設施準備（2026-01-04）✅

- [x] Hetzner Cloud 開設 3 台 VM（1 控制平面 + 2 工作節點）
- [x] 建立私有網路（Private Network）確保內網互通
- [x] 配置防火牆規則（允許 SSH 從原 VM 堡壘機連入，K8s 節點不暴露公網）
- [x] 設定 SSH 跳板（透過原 VM 訪問 K8s 節點）
- [x] 系統基礎準備（`apt update && upgrade`，安裝必要工具）
- [x] 架構決策：三台節點直接使用 root（網路層已封死，單人操作，符合狠人思維）

---

## Day 2-4 - 控制平面安裝（2026-01-05 至 2026-01-07）（3-5h）

- [x] 控制平面安裝 K3s server（使用 `--disable traefik`，以降低初期變數），並確認 `k3s` 服務為 active (running)
- [x] 取得 node-token（`/var/lib/rancher/k3s/server/node-token`），並保存於堡壘機個人帳號家目錄（僅作為 worker join 使用）
- [x] 複製 kubeconfig（`/etc/rancher/k3s/k3s.yaml`）到本機，並移至標準位置 `~/.kube/config`
- [x] 設定本機 kubectl 透過 SSH tunnel 存取 API server（`-L 6443:127.0.0.1:6443`），kubeconfig 的 server 指向 `https://127.0.0.1:6443`
- [x] 驗證控制平面健康：本機執行 `kubectl get nodes`，顯示 control-plane 節點為 Ready
- [ ] （備用方案）在堡壘機安裝 kubectl，驗證可從堡壘機直接執行 kubectl 指令

---
