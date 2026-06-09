# 2026-06-05 CKA Cluster Upgrade Basics

## Prework 內容

### 今日焦點

- 主題：CKA 題目中的 kubeadm cluster upgrade
- 範圍：control plane 與 worker node 升級順序、kubeadm / kubelet / kubectl 的角色、drain / uncordon、升級前後驗證
- 目標：建立能看懂 Cluster Upgrade 題的最小維護心智模型，之後再回到題庫練精確指令
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的背景是：我正在刷 KillerCoda CKA 題庫，Architecture / Installation / Maintenance 類別裡有 Cluster Upgrade 題。請先教維護順序與每一步的目的，不要直接變成一長串指令背誦。

### 今天一定要學會的最小骨架

1. kubeadm upgrade 題要分清楚 control plane node 與 worker node，它們的升級節奏不同。
2. `kubeadm` 負責協助升級 cluster components；`kubelet` 是每台 node 上管理 Pod 的 agent；`kubectl` 是 client CLI。
3. 常見流程是先 `kubeadm upgrade plan` 理解可升級版本，再升級 control plane，之後處理 worker nodes。
4. `drain` 是在維護前把一般 workload 從 node 上移走；`uncordon` 是維護完成後讓 node 重新可排程。
5. 升級時要注意版本 skew，不是所有元件都能任意跨版本。
6. 維護題要養成操作後驗證：nodes version、node Ready 狀態、system pods、workload pods。

### 建議教學順序

1. 先用白話說明 kubeadm-managed cluster 裡 control plane、worker、kubeadm、kubelet、kubectl 的角色。
2. 再講為什麼升級要有順序，尤其是先 control plane、再 worker 的原因。
3. 拆解 `kubeadm upgrade plan`、`kubeadm upgrade apply`、`kubeadm upgrade node` 各自在做什麼。
4. 講 `drain` / `cordon` / `uncordon` 的差別，以及為什麼 worker 維護前常需要 drain。
5. 說明 kubelet / kubectl package 升級與 restart kubelet 的位置。
6. 最後整理一條 CKA cluster upgrade 節奏：確認版本、升級 control plane、升級 kubelet/kubectl、處理 worker、uncordon、驗證。

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

- 今天最大的收穫不是背 `kubeadm upgrade` 指令，而是建立「cluster upgrade 到底在維護什麼」的心智模型。
- Cluster upgrade 的本質不是升級 Pod，而是在維護 Kubernetes 平台本身，也就是 API server、scheduler、controller-manager、etcd、kubelet 這些讓 cluster 能運作的元件。
- Deployment 壞掉通常是應用程式問題；cluster upgrade 是平台維運問題，層次不同。
- Control plane 負責管理整個 cluster，核心元件包含 API server、scheduler、controller-manager、etcd。它接收 `kubectl` 指令、保存 cluster state、決定 Pod 排程位置，並維持 desired state。
- Worker node 負責執行 workload，例如 line-bot Pod、Traefik Pod、CoreDNS Pod。真正提供服務的是 worker 上的 workloads。
- `kubeadm`、`kubelet`、`kubectl` 是三個不同層級的工具：`kubeadm` 管理 cluster lifecycle，`kubelet` 是每台 node 上的 agent，`kubectl` 是人類操作 Kubernetes resource 的 client。
- Cluster upgrade 通常先升級 control plane，再升級 worker。原因是 API server 是 cluster 規則與協調中心；先升級「大腦」，再升級「手腳」，可以避免 worker 理解新行為但 control plane 還不支援的狀況。
- `kubeadm upgrade plan` 是看升級計畫，類似先確認目前版本、目標版本與升級條件，不會真正升級。
- `kubeadm upgrade apply` 是真正升級 control plane 元件，但不會自動升級 kubelet 或 kubectl。
- `kubeadm upgrade node` 通常出現在 worker 升級流程中，用來更新該 node 的 kubeadm 管理資訊。
- Drain 的目的不是保護 node，而是保護 workload。維護 worker 前先 drain，讓 Kubernetes evict pods 並重新排程到其他 node，降低直接升級造成的服務中斷。
- `cordon` 是禁止新的 Pod 排進來，但既有 Pod 繼續跑；`drain` 大致可以理解成 `cordon + evict pods`；`uncordon` 是維護完成後恢復 node 的可排程能力。
- Version skew 的核心是 Kubernetes 允許不同元件短時間版本不一致，因為真實 cluster 不可能所有元件同時升級，但這種不一致必須落在官方允許範圍內。
- 升級後不能只看指令成功，還要驗證系統正常。至少要看 nodes 是否 Ready 與版本正確、`kube-system` 裡 control plane / system pods 是否正常、workload pods 是否正常，以及 node 是否不再是 `SchedulingDisabled`。

### 已能白話講清楚什麼

- Cluster upgrade 是平台維運，不是單純升級某個 Pod 或 Deployment。
- Control plane 是 cluster 的管理中心，worker 是執行 workload 的地方，所以升級通常先 control plane、後 worker。
- `kubeadm` 管 cluster lifecycle，`kubelet` 管 node 上的 Pod，`kubectl` 是操作 Kubernetes resource 的 CLI。
- `kubeadm upgrade plan` 是看計畫，`kubeadm upgrade apply` 是升級 control plane，`kubeadm upgrade node` 是 worker 升級流程中的一部分。
- Drain 的白話意思是「搬家」，不是「關機」。它先把一般 workload 從要維護的 node 上移走，再讓 node 進入維護。
- `cordon` 是不讓新的 Pod 進來，`drain` 是不讓新的 Pod 進來並把既有 Pod 搬走，`uncordon` 是讓 node 維護後重新接收 Pod。
- 升級完成後要驗證 cluster 狀態，不是只看 upgrade command 是否成功。

### 目前還卡住什麼

- Version skew 的細節還需要補強，例如 API server 可以領先 kubelet 幾個 minor version、不同 Kubernetes 版本政策的精確限制是什麼。
- `kubeadm upgrade node` 的內部機制還不夠清楚，目前知道它在 worker 升級流程中使用，但還不知道它實際修改哪些設定或檔案。
- HA cluster 的升級流程還沒有展開。這份 prework 先以單一 control plane 的 CKA 題型為主，之後可以補多 control plane 情境。

### 今日最重要的觀念

- Control plane 先升級，worker 後升級。
- `kubeadm`、`kubelet`、`kubectl` 是三個不同層級的元件。
- Drain 的核心是遷移 workload，不是關機。
- `kubeadm upgrade apply` 完成後不代表整個升級結束，還有 kubelet / kubectl 與 worker nodes 要處理。
- 升級完成一定要驗證，不要只看指令成功。

### 帶回 repo 內對照的問題

1. WeaMind 是 K3s、1 control plane、2 worker 的架構。如果今天升級其中一台 worker，Traefik Pod、line-bot Pod、CoreDNS Pod 會如何重新排程？哪些服務可能短暫受影響？
2. K3s 的升級流程和 kubeadm upgrade 流程相比，哪些維運觀念相同？哪些步驟被 K3s 封裝掉了？
