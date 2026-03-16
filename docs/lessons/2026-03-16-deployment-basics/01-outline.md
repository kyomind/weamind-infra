# 2026-03-16 Deployment Basics Outline

## 今日主題

把 WeaMind 第二週的第一個主題正式落到 repo 內：從 `manifests/deployment.yaml` 看懂 Deployment、ReplicaSet、Pod 的層級關係，以及 `replicas`、自動修復、滾動更新在這個專案裡分別解什麼問題。

## 啟用條件

這份 lesson 預設在外部預習完成後才正式啟用。

若外部預習尚未做完，這份文件只作為內部 lesson 的預備骨架，不直接開始 QA 或 command。

## 這次要解的專案問題

1. 在 WeaMind 裡，Deployment、ReplicaSet、Pod 三者要怎麼用 repo 內現成 YAML 講成一條管理鏈。
2. `replicas: 2` 在這個專案裡到底解了什麼問題，不能只講成「高可用」。
3. 為什麼這個 app 應該掛在 Deployment，而不是直接手寫一個裸 Pod。
4. 為什麼 Deployment 能支援自動修復與滾動更新，即使 YAML 沒明寫 ReplicaSet。

## 這份 lesson 是否需要外部預習

- 需要，而且只做最小限度預習。
- 原因：雖然今天最終要回到 repo 對照 `manifests/deployment.yaml`，但若一開始就假設 Deployment、ReplicaSet、滾動更新的管理概念已經穩，後面的 QA 與 command 會變成硬背輸出。比較穩的做法是先用外部 AI 補一輪純知識骨架，再回 VS Code 做專案對照。

## 要對照的 repo 檔案

1. `manifests/deployment.yaml`
2. `README.md`
3. `docs/WeaMind Infra核心架構.md`
4. `manifests/service.yaml`

## 建議學習順序

1. 先使用外部預習大綱 `docs/outlines/2026-03-16-deployment-basics.md`，把今天會用到的最小管理骨架補齊。
2. 回到 repo 後先看 `manifests/deployment.yaml`，只回答一件事：這份 YAML 想維持什麼東西一直存在。
3. 先完整做完 `02-qa.md`，把 Deployment、ReplicaSet、Pod 的關係、`replicas: 2` 的價值，以及 Deployment 為什麼不是裸 Pod 這幾個主問題先講清楚。
4. 接著進入 `03-command.md`，用 `kubectl get deploy/rs/pods` 與 rollout 相關指令，把剛剛的管理層級對回實際資源名稱與叢集狀態。
5. command drill 完成後，再回頭把操作觀察補進 QA 與 `05-note.md`，最後一起收斂到 `04-report.md`。
6. 最後把穩定結論收斂進 `04-report.md`，中途若已出現可重用說法，也可先補到 `05-note.md`。

## 今日 command 練習

今天會建立 `03-command.md`，但放在 Q1、Q2 之後。

原因是 Deployment 這題不只要會說，也要能從叢集輸出看出 Deployment、ReplicaSet、Pods 的層級關係；不做 command drill，這堂課會缺少執行期對照。不過若一開始就直接看指令，也容易只記名字不懂管理邏輯，所以仍先用最小 QA 打底，再進操作觀察。

## 文件分工

1. `01-outline.md`：規劃今天學習順序，以及今天為什麼採用外部預習 → QA → command 的流程。
2. `02-qa.md`：記錄今天的專案問題、回答摘要與修正。
3. `03-command.md`：記錄今天的指令、觀察目標、輸出判讀與操作手感。
4. `04-report.md`：在 lesson 結束後收斂今天真正學到的內容。
5. `05-note.md`：記錄延伸問答、暫時結論與卡片整理。

## 這次要追問的 Why / How 題

1. 為什麼 Deployment 不直接等於 Pod，而是中間還會經過 ReplicaSet。
2. 為什麼 `replicas: 2` 在這個專案裡不只是「多一份備援」，而是和 Service 導流、rolling update、單 Pod 故障時不中斷有關。
3. 為什麼 Deployment 能做到自動修復與滾動更新，背後到底是哪一層在持續比對期望狀態。
4. 為什麼在 WeaMind 這種 line-bot workload，使用 Deployment 比直接管理裸 Pod 更合理。

## 這份 lesson 的完成標準

1. 能用自己的話講出 Deployment、ReplicaSet、Pod 三者的關係，而且說法能對回 `manifests/deployment.yaml`。
2. 能指出 WeaMind 的 `replicas` 設定在哪裡，並說清楚它在這個專案裡實際解的問題。
3. 能解釋為什麼 Deployment 能支援自動修復與滾動更新，不把原因講成 Kubernetes 會「自動幫你處理」而已。
4. `02-qa.md` 至少完成 3 題，且每題都有 repo 對照與修正紀錄。