# 2026-06-09 CKA Control Plane Troubleshooting Basics

## Prework 內容

### 今日焦點

- 主題：CKA Troubleshooting 題中的 control plane、kubelet、static Pod 與 Node NotReady 排查骨架
- 範圍：API server、scheduler、controller-manager、etcd、kubelet、static Pod manifests、systemd / journalctl、kube-system 狀態觀察
- 目標：建立能面對 Controller Manager Issue、Kubelet Issue、Node NotReady 題型的最小排查心智模型，不先背完整題解
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做 CKA Troubleshooting 的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的背景是：我正在刷 KillerCoda CKA 題庫，已經做過 etcd backup / restore、cluster upgrade、RBAC、kubectl evidence 類 prework。這份請專注在 Troubleshooting 題裡 control plane component、kubelet、static Pod、Node NotReady 的排查心智模型，不要展開成完整 Kubernetes 架構總複習。

### 今天一定要學會的最小骨架

1. Control plane 元件各自負責不同事情：API server 接收請求，etcd 存狀態，scheduler 決定 Pod 去哪個 node，controller-manager 維持 desired state。
2. kubeadm 類 CKA 環境裡，control plane components 常以 static Pod 形式由 control plane node 上的 kubelet 管理。
3. static Pod 壞掉時，要同時會看 Kubernetes 層的 Pod 狀態，以及 node 本機上的 manifest、kubelet 狀態與 journal。
4. Node NotReady 不等於某個 app Pod 壞掉；它通常要從 kubelet、container runtime、node condition、network、disk / memory / PID pressure 等方向收斂。
5. `kubectl get/describe`、`systemctl status kubelet`、`journalctl -u kubelet`、檢查 `/etc/kubernetes/manifests/` 是不同層級的證據。
6. CKA troubleshooting 的核心是先判斷故障層級：API 連不上、control plane Pod 不健康、kubelet 不健康、node condition 異常，還是 workload YAML 錯。

### 建議教學順序

1. 先用一張最小責任圖說明 API server、etcd、scheduler、controller-manager、kubelet 之間的關係。
2. 說明 static Pod 是什麼，為什麼 kubeadm control plane 常用 static Pod 跑 control plane components。
3. 拆解 control plane component 壞掉時的觀察順序：`kubectl get pods -n kube-system`、`describe pod`、manifest、kubelet journal。
4. 拆解 kubelet 壞掉時會看到什麼症狀：node NotReady、static Pod 不重建、API server 仍有舊狀態但 node 無法正常回報。
5. 拆解 Node NotReady 的常見排查方向：node conditions、events、kubelet service、container runtime、網路與資源壓力。
6. 最後整理一條 CKA 可用的排查節奏：先判斷 API 是否可用，再看 node / kube-system，再切到本機 systemd / journal / manifest，最後修改最小錯誤並驗證。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 CKA 題庫或 repo 內後，應該拿去練習或對照的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

- 今天的重點不是背 KillerCoda 某一題的標準答案，而是建立 CKA Troubleshooting 題型的分層排查骨架：先判斷故障在哪一層，再收集對應層級的證據，最後才做最小修改。
- Control plane 元件不只是名詞，而是在故障時會留下不同現象：API server 是 Kubernetes API 入口，etcd 保存 cluster state，scheduler 決定 Pod 要去哪個 node，controller-manager 持續讓 actual state 追上 desired state。
- Scheduler 和 kubelet 的責任要分清楚：scheduler 負責「決定」Pod 放到哪個 node，kubelet 負責在該 node 上「執行」Pod 並回報 node / pod 狀態。
- Static Pod 的存在是為了解決 control plane bootstrap 的循環依賴。API server、scheduler、controller-manager、etcd 這類 control plane components 在 kubeadm 類環境中通常由 control plane node 上的 kubelet 直接監看 `/etc/kubernetes/manifests/` 來啟動。
- Control plane 故障時，可以先用 `kubectl get pods -n kube-system` 找異常元件，再用 `kubectl describe pod` 看 events、restart count、container state，接著檢查 `/etc/kubernetes/manifests/`，必要時切到 `systemctl status kubelet` 與 `journalctl -u kubelet`。
- Node NotReady 不一定代表主機已經掛掉；它常常代表 kubelet 無法正常回報狀態。根因可能在 kubelet、container runtime、node conditions、資源壓力或 kubelet 到 API server 的網路通訊。
- 今天建立了三層排查模型：Workload layer 看 Deployment / ReplicaSet / Pod；Control Plane layer 看 API server / scheduler / controller-manager / etcd；Node layer 看 kubelet / container runtime / OS / network / resource pressure。

### 已能白話講清楚什麼

- Static Pod 是讓 kubelet 直接從本機 manifest 啟動 control plane components 的機制，避免 API server 需要依賴 API server 才能啟動自己的循環問題。
- Controller Manager 的核心工作是持續比較 desired state 和 actual state，例如 Deployment 要 3 個 replicas、實際只有 2 個時，它會推動系統補回缺少的 Pod。
- Scheduler 是選 node 的角色，kubelet 是在 node 上真正啟動與管理 Pod 的角色；一個負責決定，一個負責執行。
- Node NotReady 不等於 Deployment、Service 或 Ingress 壞掉；它更常是 node layer 的訊號，尤其要先想到 kubelet 是否還能正常回報。
- Troubleshooting 的穩定節奏是：先判斷故障層級，再用該層的工具收集證據，最後才修改設定。

### 目前還卡住什麼

- `kubectl describe pod`、檢查 manifest、`journalctl -u kubelet` 之間的切換時機還需要靠題目建立手感。概念上知道順序，但還沒練到看到輸出就能快速決定下一步。
- Node NotReady 的根因收斂還需要更多案例。現在知道可能是 kubelet、container runtime、resource pressure 或 network，但實戰上仍需要練習如何從 `kubectl describe node`、kubelet status 與 journal 裡快速判斷主因。

### 今日最重要的觀念

- Scheduler 負責決定，kubelet 負責執行。
- Controller Manager 的本質是讓 desired state 和 actual state 對齊。
- kubeadm 類環境中的 control plane components 通常是 static Pods。
- Static Pod 的真正管理者是 node 上的 kubelet，不是 Deployment 或 ReplicaSet。
- Node NotReady 應先從 kubelet / node layer 收斂，不要一開始就當成 workload layer 問題。

### 帶回 CKA 題庫或 repo 內對照的問題

1. 在 CKA lab 中故意改壞 `/etc/kubernetes/manifests/kube-controller-manager.yaml` 的一個參數，觀察 `kubectl get pods -n kube-system`、`kubectl describe pod`、`journalctl -u kubelet` 分別提供什麼證據。
2. 在 CKA lab 中停止 kubelet，觀察 `kubectl get nodes`、`kubectl describe node`、`kubectl get pods -n kube-system` 的變化，確認 Node NotReady、static Pod、kubelet、control plane 之間的關係。
