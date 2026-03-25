# 2026-03-12 Pod To VM And Endpoints Outline

## 今日主題

把 WeaMind Day 3 的重點正式收斂成 repo 內 lesson：Pod 如何從 K8s 叢集內連到原 VM 上的 PostgreSQL / Redis，以及 Service、Endpoints、Pod 三者在執行期怎麼對應。

## 這次要解的專案問題

1. 為什麼這個專案的 PostgreSQL / Redis 沒有做成 K8s Service，而是直接用 VM 內網 IP。
2. Pod 內的 app 會透過哪些設定拿到 PostgreSQL / Redis 的連線資訊。
3. `weamind-line-bot` Service、Endpoints、Pods 在執行期的對應關係是什麼。
4. 如果 webhook 進得來 Traefik，但最後沒有成功打到 app，第一輪應先怎麼切開查。

## 這份 lesson 是否需要外部預習

這份 lesson 預設不需要外部純知識預習。

原因是這次核心不是新的 Kubernetes 抽象名詞，而是把 repo 內已存在的 ConfigMap、Deployment、Service 與既有 SOP 對成一條可操作的路徑。

## 要對照的 repo 檔案

1. `manifests/configmap.yaml`
2. `manifests/deployment.yaml`
3. `manifests/service.yaml`
4. `docs/LINE-Webhook-切換流程.md`
5. `docs/WeaMind Infra核心架構.md`

## 建議學習順序

1. 先看 `manifests/configmap.yaml`，確認 app 連 PostgreSQL / Redis 時實際用的是什麼 host。
2. 先做 `02-qa.md` 的 Q1，但第一輪先聚焦在「Pod 到底連哪裡」，不急著一次講完整個注入過程。
3. 再看 `manifests/deployment.yaml`，補上這些環境變數是怎麼被注入 Pod 的，然後把 Q1 補完整。
4. 接著進入 `03-command.md`，做今天第一輪指令練習，實際看 Pods、Service、Endpoints 的輸出。
5. 再回到 `02-qa.md` 的 Q2 到 Q4，把設計理由、故障症狀與排查順序講清楚。
6. 最後把穩定結論收斂進 `04-report.md`；若中途已有穩定結論，也可先局部回填。

## 今日 command 練習

這部分獨立記錄在 `03-command.md`，不再混在 `02-qa.md` 裡。

command 練習的目的不是背大全，而是把今天學到的資源、指令與輸出判讀綁在一起。

在今天這份 lesson 裡，command 不放在最前面，而是放在最小 QA 之後。原因是今天要先知道自己正在驗證哪條流程，指令輸出才會有意義。

本次 lesson 對應檔案：`03-command.md`

1. 記今天要看的資源
2. 記今天實際敲了哪些指令
3. 記每個輸出回答了什麼問題
4. 記還不順手的地方，留給後續補強

## 文件分工

1. `01-outline.md`：規劃今天學習順序，以及 QA / command 如何穿插。
2. `02-qa.md`：記錄今天的專案問題、回答摘要與修正。
3. `03-command.md`：記錄今天的指令、觀察目標、輸出判讀與操作手感。
4. `04-report.md`：在 lesson 結束後收斂今天真正學到的內容，必要時也可中途先回填穩定結論。

## 這次要追問的 Why / How 題

1. 為什麼在 WeaMind 裡，Pod 連 PostgreSQL / Redis 是直接連 `10.0.0.2` 這類 VM 內網 IP，而不是連一個 cluster 內的 Service 名稱。
2. 為什麼 Service selector 對到了 Pod，還需要再看 Endpoints，不能只看 YAML 就當作流量一定會通。
3. 如果 `kubectl get endpoints weamind-line-bot` 是空的，第一輪最該先懷疑哪幾件事。
4. 如果 Endpoints 正常，但 app 還是連不到 PostgreSQL / Redis，排查路徑應該往哪裡走。

## 這份 lesson 的完成標準

1. 能用自己的話講出 line-bot Pod 如何拿到 PostgreSQL / Redis 的連線設定，並透過 VM 內網 IP 連線。
2. 能說出 Service、Endpoints、Pods 的對應關係，以及為什麼 Endpoints 是第一輪高價值觀察點。
3. 能講出 webhook 進不來或 app 不通時，應如何把問題切成 cluster 內流量與 Pod 對外連 VM 兩段。
4. 至少完成一輪 `03-command.md` 內的指令練習，並能用輸出回答今天的觀察問題。
5. `02-qa.md` 至少完成 3 題，且每題都有 repo 對照與修正紀錄。