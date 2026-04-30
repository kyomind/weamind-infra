# 2026-04-30 WeaMind CD Current State and Boundaries Outline

## 今日主題

- 把上午建立的 `CD` 骨架對回 WeaMind repo，收斂目前到底做到哪裡、正式 deploy source 應該怎麼講，以及 app repo / infra repo 的責任邊界。

## 這次要解的專案問題

1. WeaMind 目前的 workflow 與 Deployment 證據，為什麼只能算有 `CI` 與 image publishing，還不能叫完整 `CD`。
2. 若要把 deployment version 收斂清楚，為什麼不應繼續追 `latest`，而應改用更可追溯的正式 release version。
3. 在 WeaMind 的雙 repo 結構下，app repo 與 infra repo 各自應負責什麼，明天 implement 前最合理的最小方向是什麼。

## 這份 lesson 是否需要外部預習

- 不需要
- 原因：今天上午的 prework 已完成，現在要把 `CD` 概念對回 WeaMind 現有 workflow、reference 與 manifests。

## 要對照的 repo 檔案

1. learning/prework/2026-04-30-cd-core-model-and-two-repo-boundaries.md
2. references/weamind-ci-to-k8s-flow.md
3. references/phase2/w8-cd-minimum-spec.md
4. docs/WeaMind實作CD討論與實踐.md
5. references/weamind-app-publish-ghcr.yml
6. manifests/deployment.yaml
7. .privatedocs/Phase2三週計畫.md

## 建議學習順序

1. 先把上午的三層模型對回 WeaMind：artifact 在哪裡產出，deployment config 在哪裡宣告，deployment state 目前如何被隱含地決定。
2. 再看 app repo publish workflow 與 infra repo Deployment，回答為什麼現在還不算完整 `CD`。
3. 接著收斂正式 deploy source 應追哪種版本，並說清楚 `latest` 的邊界問題。
4. 最後切清 app repo / infra repo 的責任邊界，為明天 implement 留下一條最小可落地方向。

## 今日 command 練習

- 今天不建立 `03-command.md`。
- 原因：今天下午的任務是 repo-backed 邊界對照與設計收斂；指令操作留到明天 implement mode 再集中處理。

## 文件分工

1. `01-outline.md`：規劃今天的 repo-backed 對照順序。
2. `02-qa.md`：記錄今天的問題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天對 WeaMind 現況、版本策略與 repo 邊界的結論。
4. `05-note.md`：記錄延伸問答、實作前提與明天 implement 的銜接點。

## 這次要追問的 Why / How 題

1. 為什麼 WeaMind 目前不能只因為有 GHCR publish 就被叫做完整 `CD`。
2. 為什麼第一版正式 deploy source 應追完整 release version，而不是繼續依賴 `latest`。
3. 為什麼在雙 repo 結構下，更穩的方向是讓 infra repo 保存 deployment state，而不是讓 app repo 直接改 cluster。

## 這份 lesson 的完成標準

1. 能用 WeaMind 現有 workflow 與 Deployment 證據，說清楚目前已做到哪裡、缺哪一段。
2. 能說出正式 deploy version 的最小收斂方向，以及 `latest`、minor、major tag 的邊界差異。
3. 能描述 app repo / infra repo 的責任分工，並提出一條可接到明天 implement 的最小自動化方向。
