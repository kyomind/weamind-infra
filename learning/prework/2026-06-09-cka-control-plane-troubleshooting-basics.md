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

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 CKA 題庫或 repo 內對照的問題

1.
2.
