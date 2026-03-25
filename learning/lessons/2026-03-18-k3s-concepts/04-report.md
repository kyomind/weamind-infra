# 2026-03-18 K3s Concepts Report

## 今日主題

從 WeaMind 的架構文件、實作紀錄與 Deployment 補強題，收斂 K3s 的選型理由、control-plane / worker 分工、kubeconfig / 本機連線骨架，以及 rollout 細節的最小對照。

## 狀態

已完成。

## QA 收斂了什麼

- 今天把 K3s 的選型理由正式對回 WeaMind 的專案情境，而不是停在「比較輕量」這種抽象口號。
- 也把 control-plane / worker 與 Scheduler / kubelet 的責任邊界拆開，並對回 `nodeSelector.nodepool=worker` 為什麼是這個 repo 裡真正可控的排程依據。
- kubeconfig 題目也收斂到最小可講版：`cluster` 回答 API server 與 CA、`user` 回答登入身分、`context` 回答目前用哪組連線組合，而 `server: https://127.0.0.1:6443` 代表的是 SSH tunnel 後的本機入口。
- 最後補上 rollout 邊界：`kubectl rollout status` 看交接是否完成，Deployment conditions 看物件狀態訊號，rolling update strategy 看新舊 Pod 如何交接，三者不能混成同一層。

## 使用者原本卡住什麼

- 原本比較容易把 worker 身分和 `ROLES` 欄位綁在一起，還沒完全收斂到「真正可控的是 node labels，不是顯示欄位」。
- 對 kubeconfig 的 `cluster`、`user`、`context` 雖然有直覺，但還沒整理成可穩定講出的最小骨架。
- 對 rollout、conditions、strategy 三者的分層也還不夠穩，容易把它們都當成 Deployment 狀態的不同寫法。

## 今日 command 練習收斂

- 透過 `kubectl get nodes -L nodepool`，把 control-plane / worker 的實際輸出與 `nodepool=worker` label 對上，確認這才是 WeaMind 內真正可控的排程依據。
- 透過 `kubectl config view --minify`，把當前 active context 的最小 kubeconfig 骨架直接攤開，對回 `server: https://127.0.0.1:6443` 與 SSH tunnel 的關係。
- 透過 `kubectl rollout status deployment/weamind -n weamind`，把「rollout 是否完成」和 strategy / conditions 這些更細的 Deployment 問題切開。

## 今日真正留下來的核心收穫

- WeaMind 選 K3s 的理由，應該連同小型叢集、單人維運、成本控制與作品展示價值一起講，而不是只說它比較輕。
- 在這個專案裡，worker 的可控辨識與排程限制，是靠 `nodepool=worker` 這種明確 label，不是靠 `ROLES` 顯示欄位。
- kubeconfig 的價值不是背欄位名，而是能把「本機 kubectl 怎麼透過 SSH tunnel 連到遠端 control-plane API」講成一條完整路徑。
- rollout status、conditions、strategy 各自回答不同層次的問題，不能混講。

## 學完後已能講清楚什麼

- 已能用 WeaMind 的實際情境講清楚為什麼選 K3s，而不是 kubeadm、EKS 或 GKE。
- 已能分開講清楚 control-plane、worker、Scheduler、kubelet 分別站在哪一側，以及 `nodeSelector.nodepool=worker` 為什麼能對回這個角色分工。
- 已能白話講出 kubeconfig 裡 `cluster`、`user`、`context` 各自回答什麼問題，並解釋為什麼 `server` 會是 `https://127.0.0.1:6443`。
- 已能區分 `kubectl rollout status`、Deployment conditions 與 rolling update strategy 各自在回答什麼問題。

## 仍待補強什麼

- 之後可再補一次 Deployment conditions 的實際輸出與常見 reason，讓 `Available`、`Progressing`、`ReplicaFailure` 的判讀更穩。
- 若要再往下延伸，可以在彈性日補 `maxSurge`、`maxUnavailable` 和 rolling update 節奏之間的更細緻對照。

## 下一步

- W2 Day 3 lesson 已完成；下一步可進入 3/19 彈性日，視狀況補強 rollout 細節，或開始整理本週 Deployment / K3s 的收斂稿。
