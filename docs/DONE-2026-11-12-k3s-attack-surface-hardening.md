# 2026-11-12 K3s 攻擊面強化：NetworkPolicy、grafana RBAC 與 SA token

整理日期：2026-11-12

## MEMOS

給沒有上下文的下一個 AI：先讀這一節。本文是**公開版**，只記錄適合公開的設計、推理與驗證方法。節點連線方式、叢集版本、剩餘風險清單等細節放在 Kyo 的私有維運 repo（fleet-ops），本 repo 不寫。

- **起點：** Kyo 讀到一篇資安文章，重點是 AI 讓自動化攻擊的成本降到接近零，所以「規模小、不值得被打」的假設不再成立。私有維運 repo 據此做了攻擊面盤點，其中一層的問題是：「假設 WeaMind 應用 Pod 已經被 RCE，攻擊者下一步能走到哪？」盤點結論寫成一份 `TODO.md` 交給本 repo 處理。那份檔案是 Kyo 自己的工作清單，不進 git。
- **已完成（全部套用到正式叢集並驗證）：**
  1. `manifests/networkpolicy-ingress.yaml`：WeaMind Pod 只接受 traefik 與 Prometheus 的連線。
  2. `manifests/networkpolicy-egress.yaml`：WeaMind Pod 出站只能連 DNS、bastion 上的 Postgres 和 Redis，以及公網 443；封鎖 cloud metadata 和叢集內網段。
  3. `helm/watchmind-values.yaml`：watchmind（kube-prometheus-stack）的 values 首次納入版控，grafana 改用 namespaced RBAC，不再能讀全叢集 secrets。
  4. `manifests/deployment.yaml`：`automountServiceAccountToken: false`。
  5. 三台節點的 Hetzner user-data 確認為空，不含 K3s join token。
- **PR：** #11（`harden-k3s-attack-surface`），以 merge commit 合併到 `main`。
- **待處理事項：** 本 repo 沒有待處理事項。Kyo 想把這次經過寫成文章，本文因此保留較多推理細節（見「寫文章可用的素材」）。
- **注意：** 之後改 watchmind 時，一律用 `-f helm/watchmind-values.yaml` 執行 `helm upgrade`。不帶這個檔會把 grafana 的 RBAC 打回 ClusterRole。

## 1. 背景：從「API 權限」轉向「網路上碰得到什麼」

盤點先查 RBAC，結論是 API 這條路已經乾淨：

- `weamind:default` SA 沒有任何 API 權限，Pod 被攻破後，掛載的 token 也做不了事。
- 對外入口只有 traefik LB → Ingress `k8s.kyomind.tw` → `weamind-line-bot`。argocd、grafana 等權限大的元件都沒有對外。

剩下的風險在網路層：

1. **叢集內橫向移動**：weamind namespace 沒有 NetworkPolicy，被攻破的 Pod 可以連到叢集內所有 Service，例如 grafana、prometheus、alertmanager，甚至 K8s API。
2. **跳板讀 secrets**：grafana 的 sidecar 預設以 ClusterRole 讀全叢集 secrets。grafana 是 web 應用，只要攻擊者從叢集內打下它（路徑就是第 1 點），就能讀到 weamind 的 secrets。
3. **cloud metadata**：Pod 預設連得到 `169.254.169.254`。如果節點的 user-data（cloud-init）裡放了 K3s join token，攻擊者就能用它加入一台惡意節點，之後排到該節點的 Pod 和 secrets 都歸它。

這三點串起來是一條完整的攻擊鏈：RCE → 叢集內網 → 高權限元件 → secrets 或節點身分。這次的處置就是逐段切斷這條鏈。

## 2. NetworkPolicy 設計

### 前置確認：policy 會不會生效

NetworkPolicy 只是 API 物件，要有 CNI 或 controller 執行才有效。K3s 預設使用 flannel，並內建 kube-router 的 network policy controller，除非 server 啟動時加了 `--disable-network-policy`。所以先看 control plane 的 `k3s.service` 啟動參數，確認沒有這個 flag，才開始寫 policy。

這一步很重要。如果 controller 被停用，policy 照樣 apply 得上去，也不會有任何錯誤，但完全不生效，會帶來一種最危險的虛假安全感。

### Ingress（`manifests/networkpolicy-ingress.yaml`）

- `podSelector: app=weamind`：只選應用 Pod，不選整個 namespace。原因是 cert-manager 用 HTTP-01 更新憑證時，會在 Certificate 所在的 namespace（這裡是 `weamind`）建立暫時的 solver Pod，由 traefik 轉 `/.well-known/acme-challenge/` 給它。選整個 namespace，solver 的流量也會被限制，結果要等到憑證續期時才會壞，而且壞得很隱蔽。
- 放行兩個來源，都用 `namespaceSelector` 搭配 `podSelector`，並寫在同一個 `from` 項目裡，表示兩者要同時成立（AND）：
  - `kube-system` 裡 `app.kubernetes.io/name=traefik` 的 Pod：對外入口。
  - `watchmind` 裡 `app.kubernetes.io/name=prometheus` 的 Pod：抓 `/metrics`，對照 `manifests/service-monitor.yaml`。
- namespace 用 `kubernetes.io/metadata.name` 這個 label 來選。K8s 1.21 起，每個 namespace 都會自動帶這個 label，不必自己補。
- port 寫 `8000`：NetworkPolicy 看的是 Pod 的 port（containerPort），不是 Service 的 port 80。
- kubelet probe 從 Pod 所在節點本機發出。kube-router 預設放行節點本機到 Pod 的流量，所以不用另外開規則。這一點寫 policy 時只是推論，套用後以新 Pod 變成 Ready 實際確認。

### Egress（`manifests/networkpolicy-egress.yaml`）

出站的目的地從應用實際行為推出來：ConfigMap 裡的資料層位址，加上在應用 repo 搜尋對外 HTTP 呼叫的結果。

| 規則 | 目的地 | 為什麼 |
| --- | --- | --- |
| DNS | `kube-system` 裡 `k8s-app=kube-dns` 的 Pod，UDP/TCP 53 | 沒有 DNS 什麼都連不上。TCP 53 給大型回應用 |
| 資料層 | `10.0.0.2/32` 的 TCP 5433、6379 | bastion 上的 Postgres 與 Redis，對照 `manifests/configmap.yaml` |
| 公網 HTTPS | `0.0.0.0/0` 排除 `10/8`、`172.16/12`、`192.168/16`、`169.254/16`，只開 TCP 443 | LINE API 走 CDN，IP 不固定，沒辦法列白名單，只能用 port 限制 |

這張表的關鍵是第三條的 `except`：

- `10.0.0.0/8` 同時涵蓋 Hetzner 私網、Pod CIDR `10.42/16` 和 Service CIDR `10.43/16`。被攻破的 Pod 因此連不到叢集內任何服務，包括 K8s API 的 `10.43.0.1:443`。這比逐一封鎖 grafana、prometheus 更簡單，也不會因為之後新增服務而漏掉。
- `169.254.0.0/16` 擋掉 metadata。不論 user-data 有沒有 token，都多一層防護。
- 資料層 `10.0.0.2` 雖然落在被排除的 `10/8` 裡，但 NetworkPolicy 的規則是聯集：只要有任何一條規則允許就放行，所以第二條精確規則仍然有效。

### 為什麼分兩階段

Ingress 寫錯，頂多是外面連不進來，馬上看得到。Egress 寫錯，Pod 看起來一切正常（Running、Ready、`/health` 回 200），但回覆 LINE 或查 DB 時才失敗。所以先套 Ingress、驗證完再套 Egress，兩者分成兩個檔，方便各自套用和回滾（`kubectl delete netpol <name> -n weamind`）。

TODO 原本建議 Egress 在離峰時段套。實際上這個服務用戶極少，任何時候都算離峰，所以接著直接套用。

## 3. grafana RBAC

### 找出實際生效的值

- `helm get values watchmind -n watchmind` 的結果是 `null`：這個 release 從安裝以來沒有任何自訂 values，全部是 chart 預設。這也代表過去沒有任何版控的 values。
- `helm get values --all` 查到的實際生效值是 `grafana.rbac.namespaced: false`、`grafana.sidecar.dashboards.searchNamespace: ALL`，也就是 sidecar 會到全叢集找 dashboard ConfigMap，所以需要 ClusterRole。
- 有了這個資訊，才能判斷限縮範圍會不會讓 dashboard 消失。查帶有 `grafana_dashboard` label 的 ConfigMap，28 個全部在 `watchmind`，所以可以安全限縮。

### 改法（`helm/watchmind-values.yaml`）

```yaml
grafana:
  rbac:
    namespaced: true          # Role 取代 ClusterRole
  sidecar:
    dashboards:
      searchNamespace: null   # 不再是 ALL，回到 release 所在的 namespace
```

只改 `namespaced` 不夠：sidecar 還是會照 `ALL` 去 list 全叢集資源，但這時已經沒有權限，結果是不斷出現 403，dashboard 也不會更新。兩個值要一起改。

套用前用 `helm template` 渲染確認：grafana 只剩 Role 和 RoleBinding，sidecar container 也不再帶 `NAMESPACE=ALL` 環境變數。之後用同一個 chart 版本升級，只套用這份 values：

```sh
helm upgrade watchmind prometheus-community/kube-prometheus-stack \
  -n watchmind --version 83.6.0 -f helm/watchmind-values.yaml
```

固定 `--version` 是為了這次只改 RBAC，不要順便升級 chart。

## 4. SA token 與 metadata

- `automountServiceAccountToken: false`：WeaMind 不呼叫 K8s API。token 雖然沒有權限，但只要掛著，就是一張攻擊者可以拿去試的憑證。少一個憑證，就少一個需要推理「它真的沒用嗎」的地方。
- user-data：在三台節點上 curl Hetzner 的 user-data 端點，**只印長度與關鍵字命中數，不印內容**。三台都是 0 bytes、命中 0。
  - **陷阱**：curl 失敗時也會得到 0 bytes。所以另外確認 user-data 端點回的是 HTTP 204（No Content），也查了 metadata 的 hostname，回的是正確的節點名稱，證明 metadata 服務正常運作、user-data 真的是空的。
  - 結果符合 README 的記載：worker 是手動用 node-token 加入，沒有經過 cloud-init。

## 5. 驗證紀錄

每一步套用後都看「正向」（該通的有通）和「反向」（該擋的有擋）兩面，只看單面不算驗證。

| 階段 | 正向 | 反向 |
| --- | --- | --- |
| 套用前 | `kubectl apply --dry-run=server` 通過；`helm template` 渲染結果符合預期 | — |
| Ingress | 新 Pod 1/1 Ready（probe 沒被擋）；對外 `/health` 回 200；Prometheus 的 `up{namespace="weamind"}` 為 1；LINE 實測正常 | 從 `default` namespace 開臨時 busybox Pod 連 WeaMind Pod 的 8000 埠，被擋 |
| SA token | — | Pod 內 `/var/run/secrets/kubernetes.io/serviceaccount` 不存在 |
| grafana | Pod 3/3 Running；Grafana API 查得到 28 個 dashboard | grafana SA 對 `list secrets -A`、`get secrets -n weamind` 的 `auth can-i` 都是 `no`；原本的 ClusterRole 已不存在 |
| Egress | Pod 內用 Python socket 測 `api.line.me:443`、Postgres、Redis 都連得上；LINE 實測正常 | metadata、叢集內 grafana Service、K8s API 都被擋 |

### 驗證時的觀察

- **被擋時回 `ConnectionRefused`，不是 timeout**：kube-router 對不符合 policy 的連線直接 REJECT，不是 DROP。好處是應用連錯目的地時會立刻失敗，不會卡住等 timeout；debug 時看到 refused 也不能直接判斷「對方沒開 port」，也可能是被 policy 擋掉。
- **Prometheus 查詢結果裡還有舊 Pod**：rollout 後幾分鐘內，`up` 還會出現已刪除的 Pod，這是 time series 尚未過期，不是抓取異常。判斷 policy 有沒有影響抓取，只看新 Pod 的 series。
- **grafana sidecar 的錯誤 log 要分辨**：升級後的 log 裡有 `Connection refused`（sidecar 在等 Grafana 啟動完成的重試），也有一筆 `OSError: Address in use`（sidecar 自己的 health server 綁 port 衝突）。縮權造成的問題會是 `403 Forbidden`。兩者都不是，加上 Pod 沒有重啟、dashboard 數量正確，判定與縮權無關。
- **公網 HTTPS 實測要連真實的域名**：用 `api.line.me` 測試，一次就同時驗證了 DNS 規則和 443 規則。

## 6. 取捨與刻意沒做的事

- **Egress 用 port 而不是用域名限制公網**：原生 NetworkPolicy 只認 IP 和 port，沒有 FQDN 規則。要做到「只能連 `api.line.me`」，需要 Cilium 之類支援 FQDN policy 的 CNI，或是加一層 egress proxy。對這個規模的服務來說成本太高。目前的做法是「公網只能用 443」：攻擊者還是能把資料往外送，但叢集內網和 metadata 都碰不到。
- **只保護 weamind，沒有給每個 namespace 都加 policy**：這次的威脅模型是「對外的應用 Pod 被攻破」。weamind 的 Egress 已經切斷它往叢集內走的路，其他 namespace 沒有對外入口。
- **沒有 default-deny**：policy 只選 `app=weamind` 的 Pod，沒有寫 namespace 層級的 default-deny，以免影響 cert-manager solver 這類暫時的 Pod。之後在 weamind namespace 新增其他工作負載時，要記得替它另寫 policy。

## 7. 如法炮製：通用流程

1. 先確認執行 policy 的 controller 存在且啟用（K3s 看 `--disable-network-policy`）。
2. Ingress 從「誰需要連我」推：入口 controller、監控抓取。用 `kubectl get pods --show-labels` 看真實 label，不要憑印象寫。
3. Egress 從「我需要連誰」推：ConfigMap 裡的位址，加上在應用程式碼裡搜尋對外呼叫的結果。
4. 公網規則用 `except` 排除私有網段和 `169.254/16`。
5. 用 `--dry-run=server` 驗證語法，讓 API server 做完整檢查。
6. 先 Ingress、後 Egress。每次套用都要驗證正向和反向，最後用真實使用者流程（這裡是 LINE）收尾。
7. Helm release 要縮權時，先用 `get values` 和 `get values --all` 看實際生效的值，再用 `helm template` 確認渲染結果，固定 chart 版本後升級，最後用 `auth can-i --as=system:serviceaccount:...` 驗證。

## 8. 寫文章可用的素材

- **主軸**：「Pod 被打下之後」比「Pod 會不會被打下」更值得花時間。RBAC 乾淨不代表安全，網路可達性才是下一關。
- **攻擊鏈與切斷點**：RCE → 叢集內網（Egress 的 `except 10/8` 切斷）→ grafana（namespaced RBAC 切斷）→ secrets；RCE → metadata（`except 169.254/16` 切斷）→ join token（user-data 本來就是空的）。
- **隱藏陷阱**：
  - controller 被停用時，policy 照樣能 apply，但完全不生效。
  - 選整個 namespace 會擋到 cert-manager solver，而且要等到憑證續期才會壞。
  - Helm values 是 `null` 代表沒有版控，下次 upgrade 就會打回預設值。
  - grafana 只改 `namespaced` 不改 `searchNamespace`，會造成 403。
  - curl 讀到 0 bytes 不等於內容是空的，要看 HTTP 狀態碼。
  - REJECT 和 DROP 的差別，會影響 debug 時怎麼判讀錯誤。
- **取捨**：原生 NetworkPolicy 沒有 FQDN 規則，所以公網只能用 port 限制，這是規模與成本之間的取捨。
- **流程**：每個變更都是先改 repo、PR、dry-run，再套用，並驗證正向和反向。全程用滾動更新，對外 `/health` 一直回 200。
