# 2026-04-08 TLS Operations and Debug Skeleton Report

## 今日主題

把 WeaMind 目前的 TLS 接法、cert-manager 資源鏈，以及最小排查順序收斂成可口述也可操作的 debug 骨架，並補出一份課後 homework 去理解 Kubernetes resource object / CRD pattern。

## 狀態

已完成 QA、command drill 與課後補強 homework 建立；homework 學習報告也已帶回。

## QA 收斂了什麼

- 已把 WeaMind 的 TLS 分工拆清楚：Hetzner LB 只做 `443` TCP passthrough，Traefik 在叢集內做 TLS termination，cert-manager 負責憑證生命週期，Ingress `tls` 區塊則負責把 host 與對應 TLS Secret 綁起來。
- 已把 cert-manager 資源鏈講成一條有順序的模型：`Certificate` 宣告想要什麼與輸出到哪個 Secret，`CertificateRequest` / `Order` / `Challenge` 是後續 workflow 狀態資源，最後結果才寫進 TLS Secret。
- 已建立 TLS 問題的最小排查順序：先判斷是不是握手前的 TLS 問題，再看 Ingress `tls.secretName`、`Certificate READY`、必要時往下追 `CertificateRequest` / `Order` / `Challenge`，而不是一開始就跳去看 Pod log。

## 使用者原本卡住什麼

- 原本對 `Ingress.spec.tls.secretName`、`Certificate` 與 TLS Secret 之間的關係還沒有完全切乾淨，特別是不確定 Secret 的名字到底是誰先宣告、誰負責建立。
- 原本也不夠確定 `Certificate`、`CertificateRequest`、`Order`、`Challenge` 這些資源究竟是在存什麼，以及它們和真正憑證內容之間的距離。
- 對 `80` / `443` 正式流量、health check `443`、redirect middleware 與 TLS Secret 之間的邊界也曾一度混在一起。

## 今日 command 練習收斂

- 已用 `kubectl get ingress weamind -n weamind -o yaml` 直接確認目前入口實際引用的 TLS Secret 是 `k8s-kyomind-tw-tls`。
- 已用 `kubectl get certificate -n weamind` 確認對應 `Certificate` 是 `READY=True`，並用 `kubectl get secret ... -o yaml` 補看 Secret annotation，確認它確實是 cert-manager 管理的產物。
- 已用 `kubectl get certificaterequest,order,challenge -n weamind` 驗證 cert-manager workflow 後續各層沒有卡在 request / order 這一段，並建立「若 `Certificate` 不 ready，就沿著這條資源鏈往下查」的操作順序。

## 今日真正留下來的核心收穫

- TLS debug 不該直接被理解成「憑證過期沒」，而應該先把它看成一條入口 TLS 鏈：症狀判讀、Ingress、TLS Secret、`Certificate`、再到 cert-manager workflow。
- cert-manager 相關資源不是隨機長出來的名詞堆，而是一組有明確分工的 Kubernetes resource objects；`Secret` 比較像最終輸出物，`Certificate` 比較像主資源，`CertificateRequest` / `Order` / `Challenge` 則是流程中間狀態資源。
- 課後 homework 也把今天背後更大的 pattern 補出來：core resource 與 CRD resource 在 Kubernetes 裡本質上共用同一套 resource object + controller 模型。

## 學完後已能講清楚什麼

- 已能用 3 到 5 句話講清楚 WeaMind 目前的 TLS 路徑、TLS termination 落點、cert-manager 的角色，以及 Ingress `tls` 區塊的責任。
- 已能講清楚為什麼 `Certificate` 和 TLS Secret 是兩個不同資源，以及它們如何透過 `spec.secretName` 連起來。
- 已能說出若 TLS 出問題時，為什麼第一步該看 `Certificate READY` 與 workflow 資源，而不是先看 app。
- 已能初步把 `Deployment`、`Secret`、`Certificate` 這些看似不同的東西，放回同一套 Kubernetes resource object / controller pattern 下理解。

## 仍待補強什麼

- 對 resource object / controller / CRD 的通用模型雖然已補到最小骨架，但還需要把 homework 再帶回 repo 對照一次，才能真正穩定內化。
- 對 controller 內部更細的實作方式、不同 controllers 之間如何協作，目前仍只需要停在概念層，不必提前展開到原始碼層。

## 下一步

- 先完成這份 homework 的外部補強吸收，再把報告帶回 repo，和 WeaMind 的 `Deployment`、`Certificate`、`Secret` 等實際資源對照一次。
- 正式主線上，W5 Day 3 已完成，下一步可進入 W5 的彈性補強 / 收斂階段，再決定是否直接銜接總演練或先整理短版答題稿。
