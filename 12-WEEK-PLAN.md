# 12-Week Plan

> WeaMind 基礎設施與 Kubernetes 能力深化的 12 週學習輪廓。

---

## Overview

| Phase   | Weeks   | Focus                                                     | Outcome                                       |
| ------- | ------- | --------------------------------------------------------- | --------------------------------------------- |
| Phase 1 | W1-W6   | WeaMind K8s 架構深化與排查能力                            | 建立對部署、網路、設定、TLS、debug 的完整理解 |
| Phase 2 | W7-W9   | Observability（Prometheus、Grafana）、WeaMind CD、Helm、Terraform | 補齊可觀測性、交付流程與 IaC 基礎能力         |
| Phase 3 | W10-W12 | CKA 衝刺與整體收斂                                        | 把前期能力格式化成更穩定的實戰與考試表現      |

---

## Weekly Outline

| Week | Topic                        | Focus                                                | Deliverable              |
| ---- | ---------------------------- | ---------------------------------------------------- | ------------------------ |
| W1   | Network and Traffic Path     | Ingress、Service、流量路徑、Pod 連 VM                | WeaMind 架構整理         |
| W2   | Deployment and K3s Basics    | Deployment、Pod 管理、K3s 核心概念                   | Deployment / K3s 心得    |
| W3   | Kubernetes Debugging         | 常見異常狀態、排查框架、核心工具                     | K8s Debug 實戰整理       |
| W4   | Config, LB, and Image Flow   | ConfigMap / Secret、LB、health check、image pipeline | 配置與交付流程整理       |
| W5   | TLS and Cluster Operations   | cert-manager、TLS、自動化與補強                      | TLS / 基礎設施操作整理   |
| W6   | kubectl Drill with Darkmind  | 指令排查特訓、壞 Pod 情境演練                        | 完整排查演示             |
| W7   | Observability Foundations    | Prometheus、Grafana、Metrics 分工                    | 可觀測性筆記與 dashboard |
| W8   | Helm and Continuous Delivery | Helm 模型、WeaMind CD 設計與最小實作                 | CD 設計稿或實作骨架      |
| W9   | Terraform and IaC Basics     | Terraform workflow、state、GCP 練習                  | IaC 練習紀錄             |
| W10  | CKA Scope Review             | 考試範圍掃描、盤點弱點                               | CKA 重點地圖             |
| W11  | CKA Reinforcement            | 弱點補強、模擬操作                                   | 模擬考與修正紀錄         |
| W12  | Final CKA Prep               | 手速、節奏、整體收斂                                 | 最後衝刺與驗收           |

---

## Summary

這 12 週的主線不是只學單一工具，而是把 WeaMind 的真實基礎設施經驗整理成一條完整能力線：先打穩 Kubernetes 架構與排查，再補 observability、delivery、IaC，最後收斂成可驗證的實戰能力。
