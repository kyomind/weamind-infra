# 2026-04-06 CI Image Pipeline Skeleton Outline

## 今日主題

把 WeaMind 從 app repo 的 git push、GitHub Actions workflow、GHCR image，到 infra repo Deployment 之間的最小鏈路，收斂成可以口頭講清楚的專案骨架。

## 這次要解的專案問題

1. app repo 的 CI workflow 在驗證什麼，和 publish workflow 的關係是什麼。
2. 新 image 是怎麼被 build 並 push 到 GHCR 的。
3. infra repo 的 Deployment 現在是怎麼引用這個 image 的。
4. 為什麼 WeaMind 目前不能準確地說成完整 CD。
5. 為什麼 imagePullPolicy: Always 不等於現有 Pods 會自動更新。

## 這份 lesson 是否需要外部預習

- 不需要
- 原因：今天主題已有足夠 repo 證據可直接對照，包括兩份 app repo workflow 參考檔、CI 到 K8s flow 說明，以及 infra repo 的 Deployment manifest。今天重點是把現況流程與邊界講清楚，不是補一整套抽象 CI/CD 通用概念。

## 要對照的 repo 檔案

1. references/weamind-app-ci.yml
2. references/weamind-app-publish-ghcr.yml
3. references/weamind-ci-to-k8s-flow.md
4. manifests/deployment.yaml
5. README.md

## 建議學習順序

1. 先讀 references/weamind-app-ci.yml，確認 push 後第一段自動化在驗證什麼。
2. 再讀 references/weamind-app-publish-ghcr.yml，確認 publish 是如何被觸發、何時會真的 push image。
3. 接著讀 references/weamind-ci-to-k8s-flow.md，把兩段 workflow 與 Deployment 引用方式接起來。
4. 然後回到 manifests/deployment.yaml，回答 K8s 端實際引用哪個 image/tag，以及 imagePullPolicy 在這裡的真正含義。
5. 最後回 04-report.md，收斂成可口述的最小答題稿。

## 今日 command 練習

- 今天不建立 command drill。
- 原因：這個主題更偏 workflow 判讀、image version、repo 邊界與 deploy 流程理解，不是以 Kubernetes 指令手感為主的 lesson。今天維持 QA -> report 即可。

## 文件分工

1. 01-outline.md：規劃今天主題、順序與邊界。
2. 02-qa.md：記錄今天的 repo-backed 問題、使用者回答摘要與 AI 修正。
3. 04-report.md：收斂今天真正學到的 CI / Image Pipeline 骨架。
4. 05-note.md：記錄延伸補充、暫時結論與之後可接到 TLS / deploy automation 的邊界。

## 這次要追問的 Why / How 題

1. 為什麼 publish workflow 不直接綁 push，而是綁 CI 的 workflow_run。
2. 為什麼 Deployment 使用 latest 且 imagePullPolicy: Always，仍不代表現有 Pod 會自動換到新版 image。
3. 為什麼 WeaMind 目前更準確的說法是有 CI 與 image publishing，但沒有完整 CD。

## 這份 lesson 的完成標準

1. 能用自己的話講出從 git push 到新 image 可被 K8s 使用的最小流程。
2. 能指出 WeaMind 目前 image registry 在哪裡，以及 Deployment 怎麼引用它。
3. 能分清楚目前哪些步驟已存在，哪些仍不是完整自動化 pipeline。
4. 能解釋為什麼 imagePullPolicy: Always 不等於現有 Pods 會自動更新。
