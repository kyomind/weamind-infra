# 2026-03-18 K3s Concepts Outline

## 今日主題

把 W2 Day 3 正式落到 repo 內：從 WeaMind 的架構文件與實作紀錄，講清楚為什麼這個專案選 K3s、control-plane / worker 如何分工、kubeconfig 與本機連線骨架怎麼運作，並視時間補 Deployment rollout status、conditions、rolling update strategy 的最小對照。

## 啟用條件

這份 lesson 以外部預習完成為前提。

目前外部預習已完成，因此今天可以直接進入 repo 內 QA 與 command drill。

## 這次要解的專案問題

1. 為什麼 WeaMind 會選 K3s，而不是 kubeadm、EKS 或 GKE。
2. 在 WeaMind 這個三節點 K3s 叢集裡，control-plane、worker、Scheduler、kubelet 分別落在哪一側。
3. 這個專案的 kubeconfig、SSH tunnel 與 kubectl 之間到底怎麼接起來，為什麼 kubeconfig 的 server 會指向 `https://127.0.0.1:6443`。
4. `kubectl rollout status`、Deployment conditions 與 rolling update strategy 各自在回答什麼問題，彼此不能怎麼混講。

## 這份 lesson 是否需要外部預習

- 需要，而且已完成。
- 原因：K3s 選型、control-plane / worker、kubeconfig 這題如果沒有先補通用骨架，回到 repo 內很容易只剩零碎名詞，無法穩定對回 WeaMind 的實際設計決策。

## 要對照的 repo 檔案

1. `README.md`
2. `docs/WeaMind Infra核心架構.md`
3. `PROGRESS.md`
4. `manifests/deployment.yaml`

## 建議學習順序

1. 先做 `02-qa.md`，把 K3s 選型理由、node 角色分工、kubeconfig / SSH tunnel 路徑與 rollout 補強的邊界先講清楚。
2. 接著進入 `03-command.md`，用 `kubectl` 觀察 nodes、kubeconfig 與 Deployment rollout 的實際入口。
3. command drill 完成後，把新的觀察補回 QA 與 `05-note.md`。
4. 最後一起收斂到 `04-report.md`。

## 今日 command 練習

今天會建立 `03-command.md`，而且仍放在 QA 之後。

原因是今天主題雖然偏概念，但如果不先把 K3s、kubeconfig 與 rollout 邊界講清楚，直接看指令輸出很容易只記住片段結果，卻不知道它對回哪個設計決策。

## 文件分工

1. `01-outline.md`：規劃今天學習順序與補強邊界。
2. `02-qa.md`：記錄今天的專案問題、回答摘要與修正。
3. `03-command.md`：記錄今天的指令、觀察目標、輸出判讀與操作手感。
4. `04-report.md`：在 lesson 結束後收斂今天真正學到的內容。
5. `05-note.md`：記錄外部預習摘要、延伸問答、暫時結論與卡片整理。

## 這次要追問的 Why / How 題

1. 為什麼在 WeaMind 這種單人維運、小型叢集情境下，K3s 比 kubeadm 更務實。
2. 為什麼 `nodeSelector.nodepool=worker` 可以直接對回 control-plane / worker 的角色分工。
3. 為什麼這個專案的 kubeconfig 會改成 `https://127.0.0.1:6443`，而不是直接寫 control-plane 的內網 IP。
4. 為什麼 `rollout status` 已成功，不等於 Deployment strategy、Pod 狀態與 app 邏輯就都一定正常。

## 這份 lesson 的完成標準

1. 能用 WeaMind 的實際架構說出為什麼選 K3s，而不是只背輕量化口號。
2. 能把 control-plane / worker 與 Scheduler / kubelet 的位置與責任分開講清楚。
3. 能說出這個專案裡 kubeconfig、SSH tunnel 與 kubectl 的最小連線骨架。
4. 能把 `rollout status`、conditions、rolling update strategy 的關係至少補到最小可講版。
5. `02-qa.md` 至少完成 4 題，且 `03-command.md` 至少完成 1 輪由使用者親手操作的最小閉環。
