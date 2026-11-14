# TODO：Traefik 與 CoreDNS 改成兩個副本

整理日期：2026-11-14

## MEMOS

給沒有上下文的下一個 AI：先讀這一節。

- **目前狀態：** 尚未開始。2026-11-14 Kyo 決定明天（2026-11-15）處理，這份只記錄起點，沒有改動叢集。
- **要做的兩件事：** `kube-system` 的 `traefik` 與 `coredns` 都是單副本，改成兩個。
- **來源：** `docs/DONE-2026-11-14-node-maintenance-availability.md` 的待決事項第 2 項（當時只討論過、沒有決定）。2026-11-14 Kyo 決定要做。
- **範圍：** 只處理這兩個 Deployment 的副本數與其分散。不動 WeaMind 的 `nodeSelector`、GitOps 或其他元件。
- **流程：** 依 `AGENTS.md` 的 Learning Workflow 從第 2 步開始：先對照目前叢集討論設計與可觀察的驗證標準，Kyo 同意範圍後再實作。這是 Kyo 已理解主題內的變更。

## 2026-11-14 觀測到的現況

唯讀查詢 `kube-system`：

| 項目 | 類型 | 狀態 |
| --- | --- | --- |
| `traefik` | Deployment | 1/1，image `traefik:3.5.1` |
| `coredns` | Deployment | 1/1，image `coredns:1.13.1` |
| `svclb-traefik-*` | DaemonSet | 3/3，K3s 內建 ServiceLB，每台節點一個 |
| `service/traefik` | LoadBalancer | EXTERNAL-IP 為三台節點，80 與 443 |

- 節點層的入口有三份（每台一個 svclb），單點在 Traefik Pod 本身。node 重開時，svclb 仍會接進請求，但沒有可用的 Traefik Pod，請求失敗到它在別台起來為止。
- 兩個 Deployment 目前都在 `weamind-002`（取自 `DONE-2026-11-14-node-maintenance-availability.md` 的觀測）。
- 叢集裡沒有任何 `HelmChartConfig`。

## 還沒確認的事

- **Traefik：** K3s 的 Traefik 由 HelmChart 管理，直接改 Deployment 的 `replicas` 可能被覆寫。預期用 `HelmChartConfig` 設定，需對照 K3s 與 Traefik chart 的文件確認欄位。
- **CoreDNS：** 沒有確認 K3s 如何管理它，也沒有確認改副本數的正確方式。直接改 Deployment 可能被 K3s 的內建 manifest 覆寫，要先查。
- **分散：** 兩個副本也會遇到今天 WeaMind 的問題：不保證分到兩台。要不要加 topology spread 與 PDB，是設計討論的一部分。
- **兩個 Traefik 副本的影響：** 記憶體與 CPU 的餘裕、`weamind-001` 已用 59% 的限制，都要先看再決定可排到哪些節點。

## 建議驗證標準（待 Kyo 同意）

1. 兩個 Traefik 副本與兩個 CoreDNS 副本都 Ready，且分在不同節點。
2. 設定能在叢集重啟或 K3s 重新套用後保留，不會被改回 1 個。
3. LINE 實測正常。
4. 新設定放進 repo（`manifests/` 或對應位置），`kubectl diff` 無差異。
5. drain 一台節點時，入口路徑仍有可用的副本。這項沒測過，要等一次真實的節點維護或刻意演練。

## 不中斷的缺口清單

2026-11-14 Kyo 表示：雖然是小服務，仍希望不中斷。Traefik 與 CoreDNS 各兩個副本只是入口路徑的一環，以下是目前看到的其他缺口。這份清單只列缺口，不代表都要做，順序與取捨要另外討論。

| 缺口 | 現況 | 證據 | 狀態 |
| --- | --- | --- | --- |
| PostgreSQL 與 Redis 的主機 | 都在 `bastion`（`10.0.0.2`），Pod 經私網連過去 | `manifests/configmap.yaml` 的 `POSTGRES_HOST`、`REDIS_URL`，以及 `manifests/networkpolicy-egress.yaml` 的註解 | 已確認是單一主機；它重開時 WeaMind 的副本再多也無法服務，**很可能是最大的單點** |
| Hetzner LB | 託管服務，前置在入口 | `docs/TODO-cloudflare-tunnel-entry-evaluation.md`（2026-05-04） | 舊文件的描述，沒有重新驗證 |
| K3s 唯一的 server | `weamind-001` 掛掉時，已在跑的服務通常還能處理請求，但不能排程、rollout 或 drain | 見 `DONE-2026-11-14-node-maintenance-availability.md` | 影響維運能力，不是流量；未實測 |
| 滾動更新期間是否掉請求 | `readinessProbe` 已設定，沒有明確設 `strategy`，用預設值 | `manifests/deployment.yaml` | rollout 約 40 秒完成且沒卡住，但沒測過期間是否有失敗請求 |

### 明天開工前先做

1. 確認 `bastion` 上 PostgreSQL 與 Redis 的現況：是否仍是單一主機、有沒有備份與還原演練（fleet-ops 有 `docs/backup.md`），以及重開時的實際影響。這件事決定「做完 Traefik 與 CoreDNS 之後，離不中斷還差多少」。
2. 把答案補回這一節，再決定要不要為資料層另開 TODO。

## 後續

- 完成後在 `CHANGELOG.md` 記錄叢集狀態變更，並把這份改寫成 `DONE-` 文件，或補進 `DONE-2026-11-14-node-maintenance-availability.md` 的待決事項第 2 項。
- 這是部署行為改變，版號依 `references/release-management.md` 的規則，由 Kyo 選定。
