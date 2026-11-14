# 更新記錄

這份檔案記錄 WeaMind 基礎設施每個版本的變更，以及每筆變更背後的理由與取捨。格式依循 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)。

- **tag 的定義**：tag 代表「已同步到叢集並驗證過」的狀態，不是部署的觸發點。目前的流程是 merge → 手動 `kubectl apply` → 驗證 → 打 tag。
- **版號**：獨立的 [SemVer](https://semver.org/lang/zh-TW/)，不跟 WeaMind app 的版本連動。
  - major：重大改動才會動，不輕易升。
  - minor：大改動，例如部署行為改變（topology spread、PDB、NetworkPolicy）。
  - patch：小改動，例如 image 版本更新、數值微調。

## [Unreleased]

### 工作負載
- **以 `topologySpreadConstraints` 強制兩個副本分在不同的工作節點**：被驅逐的 Pod 由排程器逐個挑節點，不保證分散，節點回來後也不會搬回去；2026-11-14 節點維護後，兩個副本就都落在同一台，那一台一停服務會整個中斷。`whenUnsatisfiable` 選 `DoNotSchedule`：drain 一台時，被驅逐的副本會 Pending，等節點回來再排回去。代價是那台節點不在的期間只剩一個副本，換來節點回來後不必人工重新平衡。這個代價在節點故障時同樣成立：故障節點的副本不會到另一台補位，要等節點修好或從叢集移除。
- **spread 加上 `matchLabelKeys: pod-template-hash`，只計算同一個 ReplicaSet 的 Pod**：少了這一行，滾動更新時舊 ReplicaSet 的 Pod 也會算進去，第二個新 Pod 排到哪一台都合法，等舊 Pod 砍完，兩個新 Pod 可能又在同一台。spread 只在排程當下檢查，事後不會修正，所以要在規則裡排除舊 Pod。
- **新增 PodDisruptionBudget，`minAvailable: 1`**：spread 只管排程，擋不住連續 drain 兩台節點。有了 PDB，另一個副本還沒 Ready 之前，第二次驅逐會被拒絕。它只對自願性中斷（drain、驅逐）有效，節點故障這類非自願中斷不在保護範圍內。

## [1.0.0] - 2026-11-14

第一個版本，為版本管理開始當下的架構留下基準：`main` 的內容已用 `kubectl diff` 確認與叢集一致。以下是這個基準包含的設計，以及各自的理由。

### 架構
- **應用層上 K8s，資料層留在 VM**：只有 line-bot 跑在叢集裡，PostgreSQL 與 Redis 留在原本的 VM，經 Hetzner Private Network 以內網 IP 連線。資料層以穩定為先，不為了「全部上 K8s」而承擔 StatefulSet 的管理成本。
- **K3s 三節點（1 控制平面 + 2 工作節點）**：單一執行檔、內建 Traefik，適合單人維運的小叢集。節點明確綁定私有網路介面，避免在 Hetzner 上誤用公網 IP，造成 flannel 與 Service 路由異常。
- **節點不對公網開放**：三台節點只能經堡壘機 SSH 管理，kubectl 透過 SSH tunnel 連 API server。對外的入口只剩 Load Balancer 一個。

### 入口與流量
- **Hetzner Load Balancer 只做 TCP 443 passthrough，TLS 在 Traefik 終止**：Hetzner 的託管憑證只支援 Hetzner DNS，而網域的 DNS 在 Cloudflare，所以憑證改由 cert-manager 以 DNS-01 簽發。DNS-01 不需要占用 80/443，也不必更動單機環境既有的 nginx 與 certbot。
- **LB 後端只放工作節點**：流量不經過控制平面。LB 的健康檢查需帶 `Host` 標頭，因為 Ingress 以 host 路由，不帶標頭時 `/health` 會回 404。
- **HTTP 轉 HTTPS 由 Traefik Middleware 處理**：LB 在 443 只轉送 TCP，看不到 HTTP，轉址只能在叢集內做。
- **以 LINE webhook URL 切換環境**：K8s（`k8s.kyomind.tw`）與單機（`api.kyomind.tw`）是兩個獨立端點，可以同時運作。切換秒級生效，不必等 DNS 傳播，回滾也是改回同一個設定。

### 工作負載
- **2 個副本，以 `nodeSelector` 限定在工作節點**：控制平面沒有 taint，Pod 預設會被排上去；用節點標籤加 `nodeSelector` 是最簡單的修正，也對齊 LB 只把流量送到工作節點的設計。
- **image 釘在 app 的正式版號**：`latest` 是會變動的 tag，repo 無法回答「叢集現在該跑哪一版」。app 發版後會自動對本 repo 開 PR 更新版號，讓部署的版本可以追溯，也保留人工審核這一關。
- **設定與機密分開**：非敏感設定放 ConfigMap 並進版控，機密放 Secret 且不進 Git。

### 可觀測性
- **kube-prometheus-stack 加 ServiceMonitor**：Prometheus 與 Grafana 以 Helm 安裝，應用的 `/metrics` 由 ServiceMonitor 宣告抓取。Helm values 納入版控，升級時只套用這份檔案，自訂的設定有跡可循，不會在下次升級時遺失。

### 安全
- **NetworkPolicy 限制應用 Pod 的進出流量**：威脅模型是「對外的應用 Pod 已經被攻破」。入站只放行 Traefik 與 Prometheus；出站只放行 DNS、資料層，以及公網的 443，叢集內網段與 cloud metadata 都連不到。原生 NetworkPolicy 沒有 FQDN 規則，LINE API 的 IP 又不固定，所以公網只能用 port 限制，這是規模與成本之間的取捨。
- **policy 只選應用 Pod，不做 namespace 層級的 default-deny**：cert-manager 會在同一個 namespace 建立暫時的 solver Pod，選整個 namespace 會讓憑證續期時才出問題。代價是之後新增工作負載時，要另外替它寫 policy。
- **Grafana 改用 namespaced RBAC**：chart 預設讓 Grafana 讀得到全叢集的 Secret，改成只能讀自己所在的 namespace，切斷「先打下 Grafana 再讀 Secret」這條路。
- **應用 Pod 不掛載 ServiceAccount token**：應用不呼叫 K8s API，少掛一張憑證，就少一個需要評估的攻擊面。

### 部署與 IaC
- **目前以手動 `kubectl apply` 部署**：`manifests/` 是部署的唯一來源。Argo CD 已安裝，但尚未建立 Application；GitOps 的導入計畫見 `docs/gitops-implementation-checklist.md`。
- **Terraform 與叢集部署分開**：`terraform/` 目前是 GCP VM 的 IaC 實作，每個情境一個獨立目錄，不做多 VM 的抽象化，以可驗證、好說明為先；它不是叢集的部署來源。
