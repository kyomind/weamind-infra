# 2026-04-29 Helm In WeaMind Boundaries and Costs Outline

## 今日主題

- 把 Helm 放回 WeaMind 目前的 `manifests/`、W7 的 `kube-prometheus-stack` 經驗與 W8 的 CD 脈絡，回答它在這個 repo 裡到底值不值得引入、該引到哪一層。

## 這次要解的專案問題

1. 若 WeaMind 改用 Helm，實際多出來的是哪一層能力，而不是抽象地說「比較好管理」。
2. 對回目前 repo，Helm、raw manifests、Kustomize 各自比較適合承擔哪一類變更與部署需求。
3. 為什麼 WeaMind 現階段不必急著把整個 infra repo 全部 Helm 化，以及若真的要引入，最合理的落點是什麼。

## 這份 lesson 是否需要外部預習

- 不需要
- 原因：W8 Day 1 已先把 Helm 的核心模型補齊。今天主體是 repo-backed 對照與設計邊界判斷，不是新的通用概念骨架。

## 要對照的 repo 檔案

1. .privatedocs/Phase2三週計畫.md
2. learning/lessons/2026-04-28-helm-release-chart-values-vs-raw-manifests/04-report.md
3. manifests/deployment.yaml
4. manifests/configmap.yaml
5. manifests/service.yaml
6. manifests/ingress.yaml
7. references/weamind-ci-to-k8s-flow.md
8. references/phase2/w8-cd-minimum-spec.md
9. docs/WeaMind實作CD討論與實踐.md

## 建議學習順序

1. 先把昨天建立好的 Helm 模型，重新對回 WeaMind 現有 raw manifests 到底缺哪一層。
2. 再比較 Helm、raw manifests、Kustomize 在這個 repo 裡各自較合理的適用情境。
3. 接著把 Helm 的價值與成本接到 W8 的 CD 脈絡，而不是獨立談工具喜好。
4. 今天不做 command drill，主體先放在 repo-backed QA 與設計收斂。
5. 最後回 `04-report.md` 收斂成一版可接到 W8 Day 3 CD lesson 的結論。

## 今日 command 練習

- 今天不建立 `03-command.md`。
- 原因：W8 Day 2 的驗收重點是邊界、成本與決策理由，不是 CLI 操作手感。

## 文件分工

1. `01-outline.md`：規劃今天主題、範圍與順序。
2. `02-qa.md`：記錄今天的 repo-backed 問題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的 Helm 引入邊界與成本判斷。
4. `05-note.md`：記錄延伸問答、暫時結論與 W8 Day 3 的銜接點。

## 這次要追問的 Why / How 題

1. 為什麼 Helm 對 WeaMind 的價值，不能只講成「把 YAML 包起來比較方便」。
2. 為什麼同樣是避免重複，Helm 與 Kustomize 在這個 repo 裡的引入成本與抽象層不一樣。
3. 為什麼 W8 要先把 Helm 的落點講清楚，才適合進入 CD 設計。

## 這份 lesson 的完成標準

1. 能說出 Helm、raw manifests、Kustomize 在 WeaMind 現況下各自較適合的情境。
2. 能用 repo 脈絡講出 Helm 真正可能帶來的價值與成本，而不是只列工具特色。
3. 能說出為什麼現階段不必急著把整個 repo 全部 Helm 化，並提出一個較合理的最小引入方向。
