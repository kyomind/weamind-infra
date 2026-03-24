# 2026-03-12 Pod To VM And Endpoints Report

## 今日主題

把 WeaMind Day 3 的主題正式收斂成 repo 內 lesson：Pod 如何連到原 VM 上的 PostgreSQL / Redis，以及 Service、Endpoints、Pod 在執行期怎麼對應。

## 狀態

這份 lesson 已完成第一輪 QA 與互動式 command drill 收斂。

## QA 收斂了什麼

- WeaMind 的 line-bot Pod 不是連 cluster 內的 PostgreSQL / Redis Service，而是透過 `ConfigMap` 與 `Deployment` 注入的環境變數，直接連原 VM 的內網 IP。
- 這個 repo 採用的是刻意的 K8s + VM 混合架構：只遷移應用層，不遷移資料層，重點是控制遷移範圍並維持 PostgreSQL / Redis 的穩定性。
- 在 cluster 內流量觀察上，`Endpoints` 是第一輪高價值觀察點，因為它能最快回答「Service 後面現在到底有沒有實際後端」。
- 排查時要先把問題切層：若 Endpoints 是空的，先查 `Service → selector → Pods`；若 Endpoints 正常但 app 連不到 PostgreSQL / Redis，再切去查 `Pod → VM` 路徑。

## 使用者原本卡住什麼

- 一開始對 Q1 的回答較偏向只看 `ConfigMap`，還沒把 `Deployment` 的 env 注入角色一起講完整。
- 對 Q3 的 Endpoints 概念不夠穩，知道它存在，但不確定它代表什麼。
- 對 Q4 的後半段有一個合理疑問：Endpoints 正常與 app 連不到 PostgreSQL / Redis 是否屬於同一層問題。

## 今日 command 練習收斂

- 這一輪 command drill 的主要價值，不是多看了幾個 kubectl 指令，而是把 `Service → Endpoints → Pods` 這條執行期觀察鏈正式對起來。
- 現在已能用一條固定骨架去看 cluster 內流量是否真的接到 app，而不是只停在 YAML 或抽象名詞。
- 也順手確認了一個操作面訊號：若 SSH proxy 斷掉，`kubectl` 看到的 `127.0.0.1:6443 connection refused` 屬於管理通道問題，不是 cluster 內資源本身異常。

## 今日真正留下來的核心收穫

- 今天真正留下來的，不是四個零散知識點，而是兩條可以分開講、也可以分開查的路徑：`Service → Endpoints → Pods` 與 `Pod → VM`。
- 這讓 WeaMind 這份 lesson 不只是在記 Kubernetes 名詞，而是建立一套之後能拿去面試、複習與排查的說法。

## 學完後已能講清楚什麼

- 我已能講清楚 line-bot Pod 如何透過 `ConfigMap` 與 `Deployment` 拿到 PostgreSQL / Redis 的連線資訊，並直接連原 VM 的內網 IP。
- 我已能講清楚為什麼 WeaMind 不把 PostgreSQL / Redis 一起搬進 K8s，也不另外包成 cluster 內的 Service 名稱。
- 我已能講清楚 Pod、Service、Endpoints 三者的關係，以及為什麼 `kubectl get endpoints weamind-line-bot` 是第一輪高價值觀察點。
- 我已能講出 Q4 的基本排查骨架：先切 `Service → Pod`，再切 `Pod → VM`，不要把兩條路混在一起。

## 仍待補強什麼

- `Service`、`Endpoints`、`Pods` 三者的對照已經清楚很多，但之後仍要多做幾輪，才能把這條觀察鏈變成反射動作。
- command drill 的節奏也已校正完成，後續應繼續維持「使用者親手操作、AI 協助判讀」這個模式。
- 之後仍可補一輪從 Pod 內實測 PostgreSQL / Redis 連線的 command drill，讓今天的 `Pod → VM` 路徑不只停在 YAML 與 logs 層。
- 之後可把今天的排查切法再濃縮成更短的面試版答案，提升臨場表達穩定度。

## 下一步

- 可選擇補一輪從 Pod 內測 PostgreSQL / Redis 的 command drill，或進入彈性日收斂。