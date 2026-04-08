# 2026-04-08 TLS Operations and Debug Skeleton Outline

## 今日主題

把 WeaMind 目前的 TLS 接法、cert-manager 資源鏈，以及最小排查順序，收斂成可口述也可操作的 debug 骨架。

## 這次要解的專案問題

1. Ingress 的 `tls.secretName` 在這個專案裡代表什麼，和 Traefik / cert-manager 的分工怎麼接起來。
2. `Certificate`、`CertificateRequest`、`Order`、`Challenge` 這條資源鏈各自在 TLS 流程裡負責什麼。
3. 如果 HTTPS 出問題，應該先看哪一層，怎麼避免一開始就陷進錯誤層級。
4. 為什麼 WeaMind 的 TLS termination 要講成「LB passthrough，Traefik terminate，cert-manager 維護憑證」。

## 這份 lesson 是否需要外部預習

- 不需要
- 原因：昨天已完成 cert-manager / DNS-01 的概念骨架，今天重點改成 repo-backed 的資源關係、操作觀察與排查順序，適合直接在 lesson 內完成。

## 要對照的 repo 檔案

1. README.md
2. PROGRESS.md
3. manifests/ingress.yaml
4. docs/WeaMind Infra核心架構.md

## 建議學習順序

1. 先從 `manifests/ingress.yaml` 確認 `tls.secretName` 與 Traefik 的接點。
2. 再回到 `README.md` 與 `PROGRESS.md`，把 TLS termination、DNS-01 與實際操作紀錄接起來。
3. 先做 QA，把資源鏈與排查順序講清楚。
4. 再做 command drill，練習用 `kubectl` 觀察 `Certificate`、Secret 與 challenge 鏈。
5. 最後在 report 收斂成可複述的最小 debug 答題稿。

## 今日 command 練習

- 今天建立 command drill。
- 原因：今天主題不只要能口頭說明，還要能把 TLS 問題拆成可觀察的 Kubernetes 資源鏈，因此需要最小操作閉環。

## 文件分工

1. 01-outline.md：規劃今天主題、範圍與順序。
2. 02-qa.md：記錄 TLS 資源關係、分工與排查問題的回答摘要與修正。
3. 03-command.md：記錄今天用哪些指令驗證 Ingress、Secret 與 cert-manager 資源鏈。
4. 04-report.md：收斂今天真正學到的 TLS debug 骨架。
5. 05-note.md：記錄延伸問答、暫時結論與卡片整理。

## 這次要追問的 Why / How 題

1. 為什麼 `tls.secretName` 不能被講成「Ingress 自己產生的憑證」。
2. 為什麼 `Certificate` ready 不等於所有 TLS 問題都排除，但通常是很關鍵的一層。
3. 為什麼 `Challenge` / `Order` 出問題時，要把它和正式流量路徑問題分開看。

## 這份 lesson 的完成標準

1. 能說出 Ingress、Traefik、TLS Secret、cert-manager 的最小分工。
2. 能用自己的話解釋 `Certificate`、`CertificateRequest`、`Order`、`Challenge` 的關係。
3. 能說出 HTTPS 出問題時的最小排查順序。
4. 能用 3 到 5 句話講清楚 WeaMind 目前的 TLS termination 與憑證維護方式。
