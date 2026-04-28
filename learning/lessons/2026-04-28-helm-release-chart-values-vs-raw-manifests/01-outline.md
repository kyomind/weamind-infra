# 2026-04-28 Helm Release Chart Values vs Raw Manifests Outline

## 今日主題

- 把已完成的 Helm prework 骨架，對回 WeaMind repo 現有的 `manifests/`、W7 的 `kube-prometheus-stack` 經驗，以及 Helm 與 raw manifests 的實際邊界。

## 這次要解的專案問題

1. W7 安裝 `kube-prometheus-stack` 時，我們到底用了 Helm 的哪一層，而不只是「照著下了一串指令」。
2. 若把 WeaMind 現有 `manifests/` 帶進 Helm 思維，哪些欄位最可能成為 values，哪些則不該輕易暴露成參數。
3. `kubectl rollout undo` 和 Helm rollback 的恢復邊界有什麼差異，為什麼這件事和 release 的概念直接相關。

## 這份 lesson 是否需要外部預習

- 已完成
- 原因：今天原本需要先補 Helm 的通用概念骨架；prework 已完成，現在可以正式進入 repo-backed 對照與驗收。

## 要對照的 repo 檔案

1. .privatedocs/Phase2三週計畫.md
2. learning/prework/2026-04-28-helm-core-model-basics.md
3. learning/lessons/2026-04-21-helm-kube-prometheus-stack-basics/01-outline.md
4. manifests/deployment.yaml
5. manifests/service.yaml
6. manifests/configmap.yaml
7. manifests/ingress.yaml
8. references/weamind-ci-to-k8s-flow.md

## 建議學習順序

1. 先用 prework 收斂出的 Helm 模型，回看 W7 的 `kube-prometheus-stack` 安裝到底做了什麼。
2. 再對照 WeaMind 現有 `manifests/`，判斷哪些欄位值得參數化、哪些欄位不宜暴露。
3. 接著比較 Helm release 與 `kubectl rollout undo` 各自管理的是哪一層狀態。
4. 今天不做 command drill，先把 repo-backed 口頭模型講穩。
5. 最後回 `04-report.md` 收斂成一版可接到 W8 Day 2 的結論。

## 今日 command 練習

- 今天不建立 `03-command.md`。
- 原因：W8 Day 1 的主體是把 Helm 模型對回 repo 邊界，不是新增 CLI 操作肌肉記憶。

## 文件分工

1. `01-outline.md`：規劃今天主題、範圍與順序。
2. `02-qa.md`：記錄今天的 repo-backed 問題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的 Helm 與 raw manifests 邊界。
4. `05-note.md`：記錄延伸問答、暫時結論與後續要帶去 W8 Day 2 的補充。

## 這次要追問的 Why / How 題

1. 為什麼 Helm 真正多出來的不是「比較方便」，而是 template、values 與 release state 這三層。
2. 為什麼不是所有 manifest 欄位都應該暴露成 values，而是要看變動頻率、環境差異與安全邊界。
3. 為什麼 Helm rollback 和 `Deployment` 自己的 rollout undo 不是同一層能力。

## 這份 lesson 的完成標準

1. 能用 WeaMind repo 脈絡講清楚 Helm 在 W7 到底扮演什麼角色。
2. 能說出至少 3 個 WeaMind 現有欄位適合做成 values，以及至少 2 類不應輕易暴露的東西。
3. 能說出 Helm rollback 和 `kubectl rollout undo` 各自能救回什麼、救不回什麼。
