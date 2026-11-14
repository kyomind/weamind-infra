# 2026-11-14 節點維護時的可用性：topology spread、PDB 與相關待決事項

整理日期：2026-11-14

## MEMOS

給沒有上下文的下一個 AI：先讀這一節。

- **目前狀態：** 已完成。WeaMind 的 `topologySpreadConstraints` 與 PodDisruptionBudget 經 PR #14 合併（merge commit `b81d5fc`）並套用到叢集；rollout、副本分布、PDB 與 LINE 實測都通過。設計、推導與驗證結果見「待辦一」。
- **這份文件記什麼：** 2026-11-14 Kyo 與 AI 討論「worker 重開機時 Pod 怎麼搬」得到的結論、這次變更的推導過程，以及還沒決定的事項。同一天的 release 管理另記在 `docs/DONE-2026-11-14-release-management.md`。
- **還沒決定的三件事：** Traefik 與 CoreDNS 要不要改成兩個副本、單一 uvicorn worker 要不要定案、GitOps 的實作。見「待決事項」第 2 到 4 項。
- **已決定：** WeaMind 保留 `nodeSelector`，app 只排 worker。理由與重新考慮的時機見「待決事項」第 1 項。
- **目前叢集剩下的風險：** 唯一的 Traefik 與 CoreDNS 都在 `weamind-002`；那台一停，流量會中斷到它們在別處起來為止。
- **還沒驗證的一件事：** drain 時「副本 Pending、節點回來後排回」沒有實測過。下次節點維護時觀察，並補記在「還沒驗證的假設」。

## 背景

2026-11-14 上午，私有維運 repo 對 `weamind-002`、`weamind-003` 做 glibc 更新並逐台重開機。過程中發現：drain `weamind-002` 之後，兩個 WeaMind 副本都落在 `weamind-003`；如果接著直接 drain `weamind-003`，兩個副本會同時被驅逐。當時靠人工先遷走一個副本避開。

Kyo 因此提出：現在只有 WeaMind 一個服務，重開機時 Pod 搬到另一台沒問題；之後有第二、三個服務可能放不下，是否該讓 control plane 也接受 workload。

## 討論得到的結論

### control plane 本來就在接 workload

`weamind-001` 沒有任何 taint（K3s 預設）。把 WeaMind 擋在 worker 的只有 `manifests/deployment.yaml` 的 `nodeSelector: nodepool=worker`。其他沒寫 nodeSelector 的元件早就排在 `weamind-001` 上。

2026-11-14 的觀測：

| 節點 | 可配置 | 記憶體用量 | 上面跑的東西 |
| --- | --- | --- | --- |
| `weamind-001`（control plane） | 2 CPU／約 3.7 GiB | 2275 Mi（59%） | cert-manager、Prometheus、Alertmanager、Grafana、部分 Argo CD |
| `weamind-002` | 同上 | 1241 Mi（32%） | 兩個 WeaMind 副本、Traefik、CoreDNS、其餘 Argo CD |
| `weamind-003` | 同上 | 571 Mi（14%） | 只有 `svclb-traefik` 與 `node-exporter` 兩個 DaemonSet Pod |

所以「開放 control plane」實際上只是拿掉 WeaMind 的 `nodeSelector`，能多拿到的是 `weamind-001` 剩下約 1 GiB 的緩衝，不是第三台 worker。

### drain 不會因為放不下而失敗

drain 只負責驅逐，不等 Pod 在別處排上去。另一台放不下時，Pod 會 Pending，節點回來後自然排回去。真正要顧的是兩件事：

1. **多副本服務不能同時全倒。** 用 topology spread 加 PDB 解決，不需要多餘容量。
2. **單副本服務重開時本來就會中斷。** 不管另一台放不放得下，它都要先被砍再重建。

另外三個容易誤會的行為：

- 被驅逐的 Pod 由排程器逐個挑節點，不保證分散，可能全落在同一台。
- DaemonSet 的 Pod 不會搬。
- 節點回來後，已經搬走的 Pod **不會自動搬回去**。上表的不平衡就是這樣來的。

### topology spread 只需要針對 WeaMind

叢集裡有兩個副本的只有 WeaMind，其他元件全是單副本，一個 Pod 沒有分散可言。

## 待辦一：WeaMind 加 topology spread 與 PDB

**狀態：已完成，尚未發版。** 2026-11-14 下午由 PR #14 合併（merge commit `b81d5fc`）並套用。以下保留當時的設計與步驟作為紀錄。

### 變更內容

`manifests/deployment.yaml` 的 Pod spec，加在 `nodeSelector` 旁邊：

```yaml
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: weamind
          matchLabelKeys:
            - pod-template-hash
```

新增 `manifests/pdb.yaml`：

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: weamind
  namespace: weamind
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: weamind
```

label `app: weamind` 已對照過 Deployment 的 selector。叢集目前沒有任何 PDB。

2026-11-14 下午用這份內容跑過 `kubectl apply --dry-run=server -f manifests/`，API server 接受，包含 `matchLabelKeys`。

### 為什麼要加 `matchLabelKeys: pod-template-hash`

最初的設計沒有這一行，2026-11-14 下午重新推演 rollout 時發現有漏洞。

只寫 `labelSelector: app=weamind` 時，舊 ReplicaSet 的 Pod 也算在內。以目前「兩個舊 Pod 都在 `weamind-002`」為起點，rollout 會這樣走：

1. 第一個新 Pod 只能去 `weamind-003`（去 `weamind-002` 偏差會是 3）。
2. 一個舊 Pod 被砍，變成兩台各一個。
3. 第二個新 Pod 去哪一台偏差都是 1，兩台都合法。`weamind-003` 空得多，資源評分傾向選它。
4. 最後一個舊 Pod 被砍，兩個副本都在 `weamind-003`。

spread 只在排程當下檢查，事後不會修正，所以結果只是換一台擠。之後每次 image 更新的 rollout 也可能重演。

加上 `matchLabelKeys: pod-template-hash` 後，限制只計算同一個 ReplicaSet 的 Pod：第一個新 Pod 落在哪一台都可以，第二個一定被逼到另一台，結果必然一台一個。drain 時的行為不變。

### 為什麼選 `DoNotSchedule`

- `DoNotSchedule`：drain 一台 worker 時，被驅逐的副本會 Pending，節點回來後排回原節點。重開期間只剩一個副本，但維護後自動恢復成一台一個。
- `ScheduleAnyway`：副本會擠到另一台，之後不會搬回來，也就是現在的狀況。

取捨是「維護期間少一個副本」換「維護後不必人工重新平衡」。

### 動手時的步驟

1. 開分支改檔，並在 `CHANGELOG.md` 的 `## [Unreleased]` 寫一筆，寫出上面的取捨。
2. `kubectl apply --dry-run=server -f manifests/` 確認可以套用。
3. 開 PR，合併後套用。目前還沒有 GitOps，部署是手動 `kubectl apply -f manifests/`（`Makefile` 的 `deploy`）。
4. 驗證：
   - 套用會觸發一次 rollout。確認 rollout 完成，兩個副本分別在 `weamind-002` 與 `weamind-003`。
   - `kubectl get pdb -n weamind` 顯示允許的中斷數為 1。
   - 用 LINE 實測服務正常。
5. 依 `.github/prompts/release.prompt.md` 發版。這是部署行為改變，依版號規則應為 minor，也就是 `v1.1.0`；版號仍由 Kyo 選定。

### 還沒驗證的假設

- **套用後會自動分散：已實測成立（2026-11-14）。** 第一個新 Pod 排到 `weamind-003`，第二個排到 `weamind-002`，套用本身就修正了不平衡。
- **滾動更新不會卡住：已實測成立（2026-11-14）。** rollout 約 40 秒完成，沒有 Pod 卡在 Pending。套用後 `ALLOWED DISRUPTIONS` 為 1，`kubectl diff -f manifests/` 無差異，LINE 實測正常。
- **drain 的實際行為：仍未驗證。** 「被驅逐的副本 Pending、節點回來後排回」沒有在這個叢集實測過。下次節點維護時觀察並補記。節點故障時同樣不會補位，這一點已寫進 `CHANGELOG.md`。

回滾：還原 `deployment.yaml` 的那一段並 `kubectl delete pdb weamind -n weamind`。

## 待決事項

第 1 項已決定，其餘三項只討論過，沒有決定。

1. **要不要拿掉 WeaMind 的 `nodeSelector`，讓它也能排到 control plane。** **已決定（Kyo，2026-11-14）：不拿掉，app 只排 worker。** 這是個人 side project，為了省成本讓平台元件使用 control plane 的閒置容量，但 app 留在 worker。理由：
   - 眼前要解的「兩個副本同時倒」靠 spread 加 PDB 就夠，不需要多餘容量。拿掉 `nodeSelector` 只多換到「維護期間維持 2 個副本」。
   - 搭配 spread 時，它不是暫時借用：drain 一台 worker，被驅逐的副本會排到 `weamind-001`，節點回來後不會搬回去，等於常態性有一個副本跑在 control plane。
   - `weamind-001` 是唯一的 K3s server，datastore 在上面，記憶體已用 59%。它記憶體不足時壞的是整個叢集的控制面。

   重新考慮的時機：第二個服務進來、兩台 worker 放不下時。屆時每個 workload 都要寫 memory request 與 limit；另外現在的做法是 app 自己用 `nodeSelector` 避開，新服務忘了寫就會被排上 `weamind-001`。
2. **Traefik 與 CoreDNS 要不要改成兩個副本。** 它們才是入口路徑上的單點；WeaMind 分散之後，Traefik 所在的節點重開仍會讓流量中斷到它在別台起來。Traefik 在 K3s 要用 `HelmChartConfig` 覆寫。如果計畫內維護可以接受短暫中斷，就不必做。
3. **單一 uvicorn worker 要定案還是改回多 worker。** `manifests/deployment.yaml` 的註解寫「Step 3 診斷：先用單 worker 驗證」，是排查指標問題時留下的暫時設定。它因此沒有寫進 `CHANGELOG.md` 的 `1.0.0` 基準。
4. **實作 GitOps。** Argo CD 已安裝但沒有任何 Application，計畫在 `docs/gitops-implementation-checklist.md`。已確認的原則：Argo CD 追 `main`、實作後禁止手動 `kubectl apply`、tag 在 Synced 且 Healthy 之後才打。版號是 minor（Kyo 於 2026-11-14 確定）：它引進新機制，但不到 major。先前寫的「預期是 `v2.0.0`」是 AI 的推測，不是 Kyo 的決定。

想立刻解除目前「兩個副本同在一台」的狀態、又不想先做待辦一的話，可以 `kubectl -n weamind rollout restart deploy/weamind`。沒有 spread 規則時不保證分到兩台，而且下次維護後又會回到原狀。這個指令會更動叢集，要 Kyo 同意才執行。

## 現況怎麼查

都是唯讀指令：

```sh
# 各節點的容量與 taint
kubectl get nodes -o custom-columns='NAME:.metadata.name,CPU:.status.allocatable.cpu,MEM:.status.allocatable.memory,TAINTS:.spec.taints[*].key'

# 各節點的用量
kubectl top nodes

# 每個 Pod 在哪一台、由誰管理、有沒有 nodeSelector
kubectl get pods -A -o custom-columns='NODE:.spec.nodeName,NS:.metadata.namespace,NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].kind,SEL:.spec.nodeSelector' --no-headers | sort

# 叢集裡的 PDB
kubectl get pdb -A

# main 與叢集是否一致
kubectl diff -f manifests/
```

## 相關文件

- `docs/DONE-2026-11-14-release-management.md`：release 管理的主文件。
- `references/release-management.md`：tag 定義與版號規則。
- `.github/prompts/release.prompt.md`：發版流程。
- `docs/gitops-implementation-checklist.md`：GitOps 導入計畫。
- 當天節點維護的過程記在私有維運 repo，不在本 repo 追蹤。
