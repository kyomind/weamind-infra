# 2026-03-17 Pod Management And Probe Outline

## 今日主題

把 WeaMind 第二週的第二個主題正式落到 repo 內：從 `manifests/deployment.yaml` 看懂 readiness probe、liveness probe、nodeSelector，以及 rollout 相關指令在這個專案裡分別扮演什麼角色，並把管理鏈與最小執行鏈分開講清楚。

## 啟用條件

這份 lesson 以外部預習完成為前提。

目前外部預習已完成，因此今天可以直接進入 repo 內 QA 與 command drill。

## 這次要解的專案問題

1. `manifests/deployment.yaml` 裡的 readiness probe 與 liveness probe 雖然都打 `/health`，但在行為與判讀上有什麼不同。
2. `nodeSelector.nodepool=worker` 在 WeaMind 這個架構裡到底解了什麼問題，為什麼不讓 line-bot 跑去 control-plane。
3. `kubectl rollout status`、`kubectl logs`、`kubectl describe pod` 這幾類觀察指令，各自適合回答什麼問題。
4. 為什麼要把 `Deployment → ReplicaSet → Pod` 這條管理鏈，和 `Scheduler → kubelet → container runtime` 這條最小執行鏈分開理解。

## 這份 lesson 是否需要外部預習

- 需要，而且已完成。
- 原因：probe、排程、kubelet 與 runtime 的分工如果沒有先補最小骨架，回到 repo 後很容易把 Deployment 管理責任與節點執行責任混在一起，導致後面的 QA 與 command 只剩片段名詞。

## 要對照的 repo 檔案

1. `manifests/deployment.yaml`
2. `README.md`
3. `docs/WeaMind Infra核心架構.md`
4. `manifests/service.yaml`

## 建議學習順序

1. 先做 `02-qa.md`，把 probe 差異、nodeSelector 角色、rollout 觀察點與兩條鏈的邊界先講清楚。
2. 接著進入 `03-command.md`，用 `kubectl` 觀察 Deployment、Pod、Node 與 rollout 狀態，確認這些概念能對回實際資源。
3. command drill 完成後，把新的觀察補回 QA 與 `05-note.md`。
4. 最後一起收斂到 `04-report.md`。

## 今日 command 練習

今天會建立 `03-command.md`，而且仍放在 QA 之後。

原因是 probe、nodeSelector 與 rollout 這題如果直接從指令開始看，容易只記住輸出片段，卻說不清楚每個欄位在驗證什麼。先用 QA 對齊概念邊界，再進 command drill，較容易把觀察收斂成可複習的結論。

補充：`rollout restart` 屬於會改動執行期狀態的操作，今天預設先做觀察型指令；若之後要實做 restart，應確認環境安全再進行。

## 文件分工

1. `01-outline.md`：規劃今天學習順序，以及今天為什麼先做外部預習。
2. `02-qa.md`：記錄今天的專案問題、回答摘要與修正。
3. `03-command.md`：記錄今天的指令、觀察目標、輸出判讀與操作手感。
4. `04-report.md`：在 lesson 結束後收斂今天真正學到的內容。
5. `05-note.md`：記錄外部預習摘要、延伸問答、暫時結論與卡片整理。

## 這次要追問的 Why / How 題

1. 為什麼 readiness probe 失敗時是先停止接流量，而不是直接重啟 container。
2. 為什麼 WeaMind 要用 `nodeSelector` 把 line-bot 固定在 worker，而不是讓 scheduler 自由選任何 node。
3. 為什麼 `rollout status` 看到的是 Deployment 更新進度，而不是應用程式邏輯是否正常。
4. 為什麼 Scheduler、kubelet、container runtime 應該被歸到最小執行鏈，而不是 Deployment 的管理鏈。

## 這份 lesson 的完成標準

1. 能把 `manifests/deployment.yaml` 中的 readiness probe、liveness probe 與 `nodeSelector` 對回實際目的與行為差異。
2. 能說出 `kubectl rollout status`、`kubectl logs`、`kubectl describe pod` 在今天主題下分別最適合回答什麼問題。
3. 能把管理鏈與最小執行鏈分開講清楚，不把 Deployment controller、Scheduler、kubelet、runtime 混成同一層。
4. `02-qa.md` 至少完成 4 題，且 `03-command.md` 至少完成 1 輪由使用者親手操作的最小閉環。
