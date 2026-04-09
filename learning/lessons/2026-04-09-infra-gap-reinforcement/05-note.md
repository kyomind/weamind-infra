# 2026-04-09 Infra Gap Reinforcement Note

## 學習注意事項

- 今天聚焦在 CoreDNS、Flannel 與少量觀念校正，不回頭重跑已完整演練過的 CI / TLS / debug lesson。
- 今天不做 command drill；若中途冒出值得延伸的操作題，先記在這裡，留給下週 workshop 或後續補強。
- 若討論中出現和今天主線無關的大範圍 networking 延伸，先記錄，不讓 QA 膨脹成另一堂課。

## Notes

### `--node-ip` / `--flannel-iface` 當時實際是怎麼下的？效果是什麼？

- 這題值得記錄，因為若只背參數作用，很容易忘記它在真實環境裡到底是怎麼被改進去的。
- 目前在 repo 歷史材料裡，最具體的版本出現在 `.privatedocs/weamind/4-2.md` 與 `.privatedocs/weamind/架構講稿.md`。它們顯示這次修復不是改 app YAML，而是直接改 `systemd override`，覆蓋 `k3s` 與 `k3s-agent` 的 `ExecStart`。
- Control-plane 當時的寫法可收斂成：先建立 `/etc/systemd/system/k3s.service.d/override.conf`，再把 `ExecStart` 清空後重寫成 `k3s server --write-kubeconfig-mode 644 --node-ip=10.0.0.3 --flannel-iface=enp7s0`，最後 `systemctl daemon-reload` 與 `systemctl restart k3s`。

```bash
cat > /etc/systemd/system/k3s.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/local/bin/k3s server \
	--write-kubeconfig-mode 644 \
	--node-ip=10.0.0.3 \
	--flannel-iface=enp7s0
EOF

systemctl daemon-reload
systemctl restart k3s
```

- 兩台 worker 當時也是同一套邏輯，只是改成 `k3s agent` 與各自私網 IP。歷史材料裡明確出現的是 `10.0.0.4` 與 `10.0.0.5`，介面都是 `enp7s0`。

```bash
mkdir -p /etc/systemd/system/k3s-agent.service.d/

cat > /etc/systemd/system/k3s-agent.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/local/bin/k3s agent \
	--node-ip=10.0.0.4 \
	--flannel-iface=enp7s0
EOF

systemctl daemon-reload && systemctl restart k3s-agent
```

```bash
mkdir -p /etc/systemd/system/k3s-agent.service.d/

cat > /etc/systemd/system/k3s-agent.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/local/bin/k3s agent \
	--node-ip=10.0.0.5 \
	--flannel-iface=enp7s0
EOF

systemctl daemon-reload && systemctl restart k3s-agent
```

- 這些指令的效果，不只是「參數變對」而已，而是三層一起被修正：
- 第一，`kubectl get nodes -o wide` 的 `INTERNAL-IP` 會回到 `10.0.0.x` 私網位址。
- 第二，`Flannel` 的 `VXLAN` / overlay 封包會改走 `enp7s0` 這張私網介面，而不是誤走公網。
- 第三，原本壞掉的 `Service` 網路會恢復，歷史記錄裡甚至明確收斂成「`Service IP` 立刻恢復、Traefik 不再卡死」。
- 這段故事的最穩講法是：**`--node-ip` 修的是 node 身分與宣告位址，`--flannel-iface` 修的是 overlay 隧道要走哪張底層私網介面；兩者一起下，K3s 才真正回到私網通道。**

### 若 Flannel 壞掉，Ingress path 會不會受影響？

- 會有可能，但要分清楚「直接原因」和「表面症狀」。
- `Flannel` 不處理 `Ingress` 的 host / path 規則；它處理的是更底層的 Pod 網路與跨 node 連通性。
- 因此若 `Flannel` / overlay network 出問題，先壞掉的通常是 cluster 內 `Pod <-> Pod`、node-to-node 或 `Service -> Pod` 這段後半鏈路。
- 只是因為 `Ingress` 最後也要把流量送到後端 `Service` / `Pod`，所以底層連通性一壞，外部看起來仍可能表現成入口異常。
- 最穩的講法是：**這不是 Ingress path 規則先壞掉，而是底層 Pod 網路失敗，導致上層流量轉送也跟著失敗。**

### Overlay 壞掉時，具體是哪一段開始出問題？

- 這題要講清楚，就要把外部流量路徑拆成兩段，而不是只說「入口也會壞」。
- 在 WeaMind 目前架構下，外部請求的大路徑可以壓成：`Client -> Hetzner LB -> Traefik -> Ingress routing -> app Service -> Pod`。
- `Flannel` 不負責前半段的 `LB -> Traefik -> Ingress host/path` 判斷；它真正影響的是後半段，尤其是 **當入口層已經決定要把流量送進某個 `Service` 或某個後端 Pod 時，這個 Pod 網路到底通不通。**
- 因此若 overlay 壞掉，最典型先出問題的位置是這些段落：
- `Pod -> Pod`：不同 node 上的 Pods 彼此連不上。
- `Service -> Pod`：`Service` 雖然 selector / endpoints 都對，但流量送不進實際後端 Pod。
- `Traefik -> app Service -> Pod`：入口層規則命中之後，轉送到後端時卡在 cluster 內網路。
- 這也是為什麼歷史故事裡會出現「Pod 能拿到 `10.42.x.x`，但 `Service IP (10.43.0.1)` 完全不通」這種症狀。它不是 DNS 先壞，也不是 Ingress path 規則先壞，而是底層 `VXLAN` / overlay 通道建錯地方，導致 `Service routing` 的後半鏈路斷掉。
- 若把這題壓成最短版，可以講成：**overlay 壞掉時，最先壞的是 cluster 內 `Service -> Pod` 與跨 node Pod 網路；外部入口之所以也可能失敗，是因為 `Traefik` 最後還是要靠這段後半鏈路把流量送到 app。**
- 這個分層很重要，因為它讓你知道：當外部請求失敗時，不能一看到入口異常就只查 `Ingress`。有時候前半段規則都對，但後半段 cluster network 已經斷了。

### 單機版 `Nginx reverse proxy` 和 K8s `Ingress Controller` 到底差在哪裡？

- 這題值得單獨記，因為很容易把「底下都用 Nginx」誤解成「它們是同一個東西」。
- 單機版 `Nginx reverse proxy` 比較像你直接手寫一份固定代理設定，決定某個 domain / path 要轉到哪個後端，例如某個 container port、某個 upstream，或 `localhost` 上的服務。
- Kubernetes 裡的 `Nginx Ingress Controller` 則不是單純一份靜態代理設定，而是一個 **controller**。它會 watch Kubernetes API 裡的 `Ingress`、`Service`、`Endpoints` 等資源，再動態生成 / 更新真正的代理規則。
- 所以兩者的核心差別不是只有「有沒有對 port」，而是：**單機版 reverse proxy 是你自己直接維護路由設定；K8s 裡的 Ingress Controller 是根據叢集資源狀態動態維護入口規則。**
- 在 K8s 裡，入口控制器後面通常依賴的是 `Service` 這個穩定抽象層，而不是你手動盯著每個 Pod IP 或本機 port。`Service` 再往後才會對到實際 `Pods`。
- 這也是為什麼在 WeaMind 裡可以把它講成兩條不同世界的入口路徑：舊單機版是 `Nginx -> Docker app`；K8s 版則是 `Traefik -> Ingress rules -> Service -> Pods`。

### `ingress-nginx` retirement 和 `Ingress` API 不是同一件事

- 這題也值得補一句術語校正，避免之後面試時講錯層級。
- 比較準確的說法不是「`Ingress` 被 Kubernetes 廢棄」，而是：**你想指的是 `ingress-nginx` 這個 controller 專案進入 retirement / 停止維護流程。**
- `Ingress` 是 Kubernetes 的 API 資源；`ingress-nginx` 則是一個實作這個 API 的 controller。兩者不是同一層。
- 這也剛好呼應今天 Q3 的主題：Traefik、Nginx Ingress Controller、Gateway API controller 這些東西，都是「入口控制實作」的選擇；不能把 controller 專案的生命週期，直接講成 API 資源本身被廢棄。

### `ConfigMap` 和 `Secret` 作為 resource，真正的本質差別是什麼？

- 這題很重要，因為很多人會把它誤講成「Secret = 加密版 ConfigMap」，這其實不準。
- 更準確地說，`ConfigMap` 和 `Secret` 在 Kubernetes API 模型裡都屬於配置型 key-value 資源，而且都常被 Pod 以 environment variables 或 volume 的方式消費。
- 它們不是像 `Deployment` 和 `Service` 那樣功能完全不同的控制物件；兩者在結構與使用方式上其實很接近。
- 真正的差別在於：**`Secret` 是 Kubernetes 專門用來承載敏感值的配置資源 kind，整個系統會對它套用不同的語意、型別、權限與工具鏈慣例。**
- 例如 `Secret` 有自己的 `type`，像 `Opaque`、`kubernetes.io/tls`、`dockerconfigjson`；安全工具、外部密鑰系統、GUI 顯示方式、權限控管與 etcd encryption 也通常是圍繞 `Secret` 這個 kind 展開。
- 所以最穩的講法不是「它們完全不同」，也不是「只差 base64」。而是：**兩者都屬於配置資源，但 `Secret` 是被明確標示成敏感資料的配置資源，因此更適合承載密碼、token、憑證這類值。**

### `Secret` 被系統以不同語意處理，具體包含哪些事？

- 這題是 Q4 的延伸，不適合塞回主答案，但很值得單獨記住。
- 第一，`Secret` 在 API / client / GUI / 生態工具裡，通常會被預設視為敏感資料；顯示、匯出、審視與分享時，慣例上會比 `ConfigMap` 更保守。
- 第二，`Secret` 有自己的 `type` 語意，例如 `Opaque`、`kubernetes.io/tls`、`kubernetes.io/dockerconfigjson`，這表示它不只是任意 key-value，而是可以承載特定類型的敏感資料。
- 第三，許多安全與維運實務是圍繞 `Secret` 這個 kind 展開的，例如 `External Secrets`、sealed secrets、secret scanning、etcd encryption、RBAC 權限控管；這些做法通常不是圍繞 `ConfigMap` 設計的。
- 第四，工作負載在消費 `Secret` 時，團隊的默契與流程也通常會更嚴格，例如不直接進 Git、避免任意匯出明文、在 GUI 裡較少直接展示原值、更新時更注意 rollout 與權限邊界。
- 所以更準確的說法是：`ConfigMap` 和 `Secret` 在資料結構上很接近，但 `Secret` 這個 kind 會觸發一整套「敏感資料處理慣例」，而不是只有 `base64` 或欄位名字不同。

## Flashcards

- `--node-ip` 和 `--flannel-iface` 在 WeaMind 裡各自修的是哪一層？ #DevOps #card
	- `--node-ip` 修 node 對叢集宣告的位址
	- `--flannel-iface` 修 overlay 網路要走哪張私網介面
	- 兩者常一起下，才能把 K3s 拉回私網通道

- 若 `Flannel` / overlay network 壞掉，最先壞的是哪一段？ #DevOps #card
	- 先壞的是 cluster 內 `Pod <-> Pod` 與 `Service -> Pod` 後半鏈路
	- 外部入口也可能失敗，但那是底層網路失敗往上層傳導
	- 不是 `Ingress` path 規則本身先壞

- `Ingress Controller` 最穩的最短定義是什麼？ #DevOps #card
	- 它把 Kubernetes `Ingress` 規則變成真正可用的 `L7 HTTP/HTTPS` 入口 routing
	- 會依 `host`、`path`、TLS 與相關規則把流量送到對應 `Service`

- 為什麼 WeaMind 目前以 `Traefik` 為主，而不是另外裝 `Nginx Ingress Controller`？ #DevOps #card
	- repo 使用 `K3s`，而 `Traefik` 是內建入口方案
	- 對單人維運的小型叢集來說更務實，整合成本也更低

- 單機版 `Nginx reverse proxy` 和 Kubernetes `Ingress Controller` 的核心差別是什麼？ #DevOps #card
	- 前者是手動維護固定代理設定
	- 後者是 controller，會 watch `Ingress`、`Service`、`Endpoints` 並動態更新入口規則
	- K8s 裡後端抽象層通常是 `Service`

- `ingress-nginx` retirement 和 `Ingress` API 是同一件事嗎？ #DevOps #card
	- 不是
	- `Ingress` 是 Kubernetes API 資源
	- `ingress-nginx` 是實作這個 API 的 controller 專案

- 為什麼說 `Secret` 不是加密？ #DevOps #card
	- `Secret.data` 的 `base64` 只是表示形式，不是安全機制
	- 沒有額外的 `etcd encryption`、`RBAC` 與權限控制，不能直接等於安全

- `ConfigMap` 和 `Secret` 在 Kubernetes 裡的本質差別是什麼？ #DevOps #card
	- 兩者都屬於配置型 key-value 資源
	- `Secret` 是被系統以敏感資料語意處理的配置資源 kind
	- 因此更適合承載密碼、token、憑證

- WeaMind 目前判斷某個值該放 `ConfigMap` 還是 `Secret` 的標準是什麼？ #DevOps #card
	- 看外洩後會不會直接形成授權、冒用或控制風險
	- `POSTGRES_HOST`、`REDIS_URL`、`BASE_URL` 放 `ConfigMap`
	- `POSTGRES_PASSWORD`、`LINE_CHANNEL_SECRET`、`LINE_CHANNEL_ACCESS_TOKEN` 放 `Secret`
