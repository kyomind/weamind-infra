# 2026-03-12 Pod To VM And Endpoints Report

## 今日主題

把 WeaMind Day 3 的主題正式收斂成 repo 內 lesson：Pod 如何連到原 VM 上的 PostgreSQL / Redis，以及 Service、Endpoints、Pod 在執行期怎麼對應。

## 狀態

這份 lesson 已完成第一輪 QA 與互動式 command drill 收斂。

## 今日 command 練習

### 練了哪些指令

- 詳見 `03-command.md`

### 從輸出確認了什麼

- 使用者已親手完成一輪 `Service → Endpoints → Pods` 的 command drill。
- 目前已確認 `weamind-line-bot` 後面有 2 個 Running Pods，Endpoints 對到 `10.42.1.14:8000` 與 `10.42.2.13:8000`。
- 也已確認 `kubectl describe svc weamind-line-bot -n weamind` 中的 selector 是 `app=weamind`，而 `kubectl get pods --show-labels` 顯示兩個 Pods 的 labels 確實包含 `app=weamind`。
- 另外確認到一個操作面事實：若 SSH proxy 斷掉，`kubectl` 會出現 `127.0.0.1:6443 connection refused`，這屬於管理通道問題，不是 cluster 內資源本身異常。

### 哪裡還不順手

- Endpoints 與 Pod / Service 的關係原本不夠穩，但已透過親手操作補起來。
- 這次也修正了 command drill 的流程，後續要維持由使用者親手操作、AI 協助判讀的節奏。

## 這次對話實際學了什麼

- 補清楚了 line-bot Pod 並不是連 cluster 內的 PostgreSQL / Redis Service，而是透過 `ConfigMap` 注入的環境變數，直接連原 VM 的內網 IP。
- 補清楚了為什麼這個專案只把 line-bot 搬進 K8s，而把 PostgreSQL / Redis 保留在原 VM：這是刻意的混合架構決策，重點是控制遷移範圍與維持資料層穩定性。
- 透過拆題與互動式 command drill，建立了 Service、Endpoints、Pods 三者在執行期的對應關係。
- 也建立了 Q4 的排查切法：若 Endpoints 是空的，先查 `Service → selector → Pods`；若 Endpoints 正常但 app 連不到資料庫，則切去查 `Pod → VM` 路徑。

## 使用者原本卡住什麼

- 一開始對 Q1 的回答較偏向只看 `ConfigMap`，還沒把 `Deployment` 的 env 注入角色一起講完整。
- 對 Q3 的 Endpoints 概念不夠穩，知道它存在，但不確定它代表什麼。
- 對 Q4 的後半段有一個合理疑問：Endpoints 正常與 app 連不到 PostgreSQL / Redis 是否屬於同一層問題。

## 對話中釐清的關鍵點

- `ConfigMap` 負責提供連線位址，`Deployment` 負責把設定注入 Pod，兩者要一起講才完整。
- 這個 repo 的重點不是「Kubernetes 能不能跑資料庫」，而是「WeaMind 為什麼刻意只遷移應用層」。
- Endpoints 的價值不在於抽象定義，而在於它能快速告訴你 Service 後面現在實際有沒有可導流的後端 Pod。
- Endpoints 正常只能證明 `Service → Pod` 這段大致成立，不能證明 `Pod → VM PostgreSQL/Redis` 一定沒問題；它主要用來幫你切分排查路徑。
- 若 `kubectl` 突然連不到 `127.0.0.1:6443`，第一輪要先懷疑 SSH proxy / 管理通道是否逾時。

## 學完後已能講清楚什麼

- 我已能講清楚 line-bot Pod 如何透過 `ConfigMap` 與 `Deployment` 拿到 PostgreSQL / Redis 的連線資訊，並直接連原 VM 的內網 IP。
- 我已能講清楚為什麼 WeaMind 不把 PostgreSQL / Redis 一起搬進 K8s，也不另外包成 cluster 內的 Service 名稱。
- 我已能講清楚 Pod、Service、Endpoints 三者的關係，以及為什麼 `kubectl get endpoints weamind-line-bot` 是第一輪高價值觀察點。
- 我已能講出 Q4 的基本排查骨架：先切 `Service → Pod`，再切 `Pod → VM`，不要把兩條路混在一起。

## 仍待補強什麼

- 之後仍可補一輪從 Pod 內實測 PostgreSQL / Redis 連線的 command drill，讓今天的 `Pod → VM` 路徑不只停在 YAML 與 logs 層。
- 之後可把今天的排查切法再濃縮成更短的面試版答案，提升臨場表達穩定度。

## 下一步

- 可選擇補一輪從 Pod 內測 PostgreSQL / Redis 的 command drill，或進入彈性日收斂。