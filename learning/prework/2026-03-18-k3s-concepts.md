# 2026-03-18 K3s Concepts

## 今日焦點

- 主題：K3s 概念篇
- 範圍：K3s 的選型理由、control-plane 與 worker 的基本分工、kubeconfig 的最小結構，以及 Scheduler / kubelet 各自落在什麼位置
- 目標：先把今天會用到的通用骨架建立起來，再回到 WeaMind repo 對照為什麼這個專案會選 K3s
- 時間：控制在 45 到 60 分鐘

## 這份 outline 要怎麼用

這份文件是給外部 ChatGPT 類服務做今天的純知識預習。

把這份 outline 直接貼給外部 AI 即可，不需要另外補一大段提示詞。

它今天的任務是：

1. 先用白話講清楚 K3s 是什麼，以及它和標準 Kubernetes 發行方式的關係。
2. 幫我理解為什麼有人會選 K3s，而不是 kubeadm、EKS 或 GKE。
3. 講清楚 control-plane 與 worker 各自負責什麼，不要把它們混成同一層。
4. 補上 Scheduler 與 kubelet 各自站在哪一側，讓我能把昨天的最小執行鏈放到正確位置。
5. 用最小骨架說明 kubeconfig 至少包含哪些核心資訊，以及它為什麼能讓 kubectl 連到叢集。
6. 用少量問題確認我是否真的有聽懂。
7. 最後產出一份可以帶回 VS Code 的學習報告。

今天先專注在通用知識，不進入 WeaMind repo 的實際 YAML、安裝指令或 kubectl 操作細節，也不先展開面試式追問。

## 今天一定要學會的 5 件事

1. K3s 不是另一套完全不同的 Kubernetes，而是偏輕量、整合度更高的一種發行方式。
2. 選 K3s 通常和環境規模、維運成本、安裝複雜度與內建元件整合有關，不只是因為它比較小。
3. control-plane 主要負責叢集控制與決策，worker 主要負責實際執行工作負載，兩者責任不能混講。
4. Scheduler 屬於 control-plane 這一側，負責決定 Pod 去哪個 node；kubelet 在各個 worker node 上，負責把 Pod 實際啟動起來。
5. kubeconfig 至少要能讓我回答三件事：我要連哪個 cluster、我要用哪個使用者身分、目前預設用哪個 context。

## 建議教學順序

1. 先講 Kubernetes 發行方式的大圖，再定位 K3s 在哪裡。
2. 再講為什麼有人會選 K3s，不只列優點，也要補它的取捨。
3. 接著講 control-plane 與 worker 的基本分工。
4. 然後把 Scheduler 與 kubelet 分別放回 control-plane / worker 的位置。
5. 最後用最小結構講 kubeconfig，確認我知道它怎麼幫 kubectl 連線。
6. 用 2 到 3 個小問題做理解確認。

如果我卡住，請先換更白話的例子，再讓我用自己的話重述一次。

## 學完後請產出學習報告

請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。

這份報告請至少包含以下內容：

1. 今日主題與學習範圍。
2. 我今天學到什麼。
3. 我已經能用白話講清楚什麼。
4. 我還卡住什麼。
5. 今天最重要的 3 到 5 個觀念整理。
6. 我回到 VS Code 後，應該拿去和 GitHub Copilot 對照 repo 的 2 個問題。

如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。
