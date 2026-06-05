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

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 repo 內對照的問題

1.
2.

