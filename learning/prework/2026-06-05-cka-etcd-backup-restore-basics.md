# 2026-06-05 CKA Etcd Backup Restore Basics

## Prework 內容

### 今日焦點

- 主題：CKA 題目中的 etcd backup / restore
- 範圍：etcd 在 control plane 中的角色、snapshot save / restore、endpoint / CA / cert / key / data-dir 的語意、restore 後的驗證
- 目標：建立能看懂 ETCD Backup / ETCD Restore 題的最小概念骨架，之後再回到題庫練精確指令
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的背景是：我正在刷 KillerCoda CKA 題庫，Architecture / Installation / Maintenance 類別裡有 ETCD Backup、ETCD Restore 題。請先教概念骨架與操作順序背後的原因，不要直接變成一長串指令背誦。

### 今天一定要學會的最小骨架

1. etcd 是 Kubernetes control plane 的狀態資料庫，保存 API server 看到的 cluster state。
2. etcd snapshot 是把當下 cluster state 備份下來；restore 是用 snapshot 建立一份新的 etcd data directory。
3. etcd backup / restore 題的核心不是只背 `etcdctl`，而是知道 endpoint、CA、cert、key、snapshot 檔案與 data-dir 分別在做什麼。
4. snapshot 能備份 Kubernetes API state，但不等於備份 node OS、container image 或外部資料庫資料。
5. restore 之後通常需要讓 control plane static Pod 或 etcd process 指向新的 data directory。
6. 維護題要養成「操作前確認狀態、操作後驗證 API server / nodes / pods」的節奏。

### 建議教學順序

1. 先用 control plane 架構說明 etcd、API server、scheduler、controller-manager 的責任分工。
2. 再說明為什麼 etcd snapshot 能代表 cluster state，以及它不能代表什麼。
3. 拆解 `etcdctl snapshot save` 背後每個參數的意義，重點是語意，不要求一次背熟完整指令。
4. 拆解 `etcdctl snapshot restore`、data-dir、static Pod manifest 之間的關係。
5. 用 CKA restore 題型講清楚為什麼 restore 後要驗證 API server 是否恢復可用。
6. 最後整理一條 etcd 維護題安全節奏：先查、備份、restore、切換 data-dir、重啟/等待 control plane、驗證。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 repo 內後，應該拿去做專案對照的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

- 今天的重點不是背誦 `etcdctl` 指令，而是建立 etcd backup / restore 的最小理解骨架：etcd 是 Kubernetes control plane 的 state database，保存 Kubernetes 對整個 cluster 的「記憶」。
- Kubernetes 重要的不只是 Pod process 本身，而是 API server / controller 看到的 cluster state。`kubectl -> API server -> etcd` 這條鏈代表 Kubernetes object 最終會透過 API server 寫入 etcd。
- etcd 保存的是 Kubernetes desired state 與 API objects，例如 Deployment、Pod、Service、ConfigMap、Secret、Namespace、Node、RBAC 等。Controller 能做 self-healing，是因為它可以比較 desired state 和 actual state。
- Snapshot 的本質是某個時間點的 cluster state backup。它備份 Kubernetes state，不是整個系統備份。
- etcd snapshot 不會備份 node OS、container image，也不會備份外部 application data。以 WeaMind 來說，Kubernetes 內的 Deployment、Service、Ingress 等 state 會進 etcd，但 Bastion VM 裡的 PostgreSQL / Redis data 不會因為 etcd snapshot 而被備份。
- `endpoint`、CA、cert、key 不是只需要死背的參數。`endpoint` 代表 etcd 在哪裡；CA 用來驗證對方真的是合法 etcd；cert 用來告訴 etcd 我是誰；key 用來證明我是 cert 持有人。
- `etcdctl snapshot save` 可以理解成透過 TLS 保護的連線，向 etcd 發出 snapshot 請求。
- Restore 不會直接讓正在運行的 etcd 自動恢復。`snapshot restore` 的核心是用 snapshot 建立一份新的 data directory。
- Snapshot 是備份檔，例如 `backup.db`；data directory 是 etcd runtime 實際使用的資料目錄，例如 `/var/lib/etcd` 或 restore 後的新路徑。Restore 是從 snapshot 產生新的 data directory，不是直接覆蓋舊 etcd。
- kubeadm control plane 元件通常以 Static Pod 形式存在，例如 etcd、kube-apiserver、kube-scheduler、kube-controller-manager。它們的 manifests 通常位於 `/etc/kubernetes/manifests`，由 kubelet 直接監看與啟動。
- Control plane 上也有 kubelet。它不只存在於 worker node，也負責 control plane node 上的 static pods。
- Restore 後需要修改 etcd static Pod manifest 裡的 `--data-dir`，讓 etcd 指向新的資料目錄。kubelet 偵測 manifest 改變後會重建 etcd Pod，新的 data-dir 才會真正生效。
- Static Pod 的行為要分清楚：刪除 Pod 但 manifest 還在，kubelet 會重建；刪除 manifest，kubelet 會停止對應 Pod 且不再重建。
- Restore 後不要只驗證 restore command 成功，而要驗證 cluster recover 成功。像 `kubectl get nodes` 能成功，代表 API server 可服務、API server 能讀 etcd、Node objects 存在，worker kubelet 也還能回報狀態。

### 已能白話講清楚什麼

- etcd 是 Kubernetes 的狀態資料庫，保存 API server 看到的 cluster state。
- Snapshot 是某個時間點的 cluster state 備份。
- Snapshot 不等於系統備份，因為它只保存 Kubernetes state，不保存外部資料庫、VM 檔案系統或 application data。
- Restore 是用 snapshot 建立新的 data directory，不是直接修改正在運行的 etcd。
- Restore 後還要改 `--data-dir`，因為 etcd 不會自動切換到新的資料目錄。必須透過修改 static Pod manifest，讓 kubelet 重建 etcd Pod 並使用新的 data-dir。
- Static Pod 是 kubelet 根據本機 manifest 直接管理的 Pod，不需要先經過 API server、Deployment 或 ReplicaSet。這可以避免 control plane bootstrap 時出現循環依賴。
- Restore 後要驗證的是 API server、etcd 與 cluster state 是否恢復，不只是 `etcdctl` 指令是否成功。

### 目前還卡住什麼

- Static Pod 的實際觀察經驗還不足。概念上已理解 `/etc/kubernetes/manifests` 與 kubelet 的關係，但還需要親手觀察 manifest 改變後 kubelet 如何重建 static Pod。
- kubeadm 與 K3s 的差異需要後續對照。這份 prework 主要以 kubeadm CKA 題型為主，之後要確認 WeaMind 的 K3s control plane 中 etcd 是否同樣使用這種模式、data-dir 在哪裡、static Pod 或 runtime 管理方式有什麼不同。
- 實際 backup / restore 手感還需要回 KillerCoda 補上。下一步要真的做一次 backup、restore、修改 data-dir、驗證 cluster，把概念對上操作。

### 今日最重要的觀念

- etcd 是 Kubernetes 的 state database。
- Snapshot 保存的是 cluster state，不是整個系統。
- Restore 只會建立新的 data directory。
- 修改 `--data-dir` 才是真正讓 restore 後的資料被 etcd 使用。
- 永遠驗證 cluster 是否恢復，而不是只驗證 restore 指令是否成功。

### 帶回 repo 內對照的問題

1. 在 WeaMind 的 K3s control plane 裡，etcd 的 data directory 實際位於哪裡？它和 kubeadm 教學中常見的 `/var/lib/etcd` 有什麼不同？
2. 如果 WeaMind 的 etcd 遺失，但 PostgreSQL 與 Redis VM 完全正常，restore 後哪些 Kubernetes state 會恢復？哪些 application data 不會恢復？哪些東西需要另外處理？請從 cluster state vs application data 的角度回答。
