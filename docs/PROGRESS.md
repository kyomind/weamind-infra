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

- [ ] 控制平面安裝 K3s server（使用 `--disable traefik` 參數），驗證服務為 active 狀態
- [ ] 取得 node-token 並保存於本地（位於控制平面的 `/var/lib/rancher/k3s/server/node-token`）
- [ ] 複製 kubeconfig（`/etc/rancher/k3s/k3s.yaml`）到本地，驗證檔案包含正確的 cluster 資訊
- [ ] 設定本地 kubectl 透過 SSH tunnel 訪問（`ssh -L 6443:localhost:6443 保壘機`），修改 kubeconfig 的 server 為 `https://localhost:6443`
- [ ] 驗證控制平面健康：`kubectl get nodes` 應顯示控制平面節點為 Ready
- [ ] （備用方案）在保壘機安裝 kubectl，驗證可從保壘機直接執行 kubectl 指令

---
