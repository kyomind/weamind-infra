# 2026-04-07 cert-manager DNS-01 Basics Outline

## 今日主題

把 WeaMind 的 cert-manager、ACME challenge 選型與目前 TLS 架構，收斂成可以口頭講清楚的最小概念骨架。

## 這次要解的專案問題

1. cert-manager 在 WeaMind 架構裡到底自動化了什麼。
2. DNS-01 和 HTTP-01 的差異是什麼。
3. WeaMind 為什麼偏向 DNS-01，而不是 HTTP-01。
4. 為什麼這個專案不需要為了 ACME 驗證而保留公開 HTTP 入口，這又如何影響後續 HTTP→HTTPS redirect 的設計。

## 這份 lesson 是否需要外部預習

- 需要
- 原因：雖然 repo 內已有足夠證據可做專案對照，但使用者目前對 DNS-01 vs HTTP-01、cert-manager 的角色、以及它如何和 DNS provider 互動仍缺最小概念骨架。這些屬於適合先交給外部 AI 補的純知識內容，因此今天應先完成 prework，再進入 repo-backed lesson。

## 要對照的 repo 檔案

1. README.md
2. PROGRESS.md
3. manifests/ingress.yaml
4. docs/LINE-Webhook-切換流程.md

## 建議學習順序

1. 先讀 README.md，確認 cert-manager 在架構圖中的位置與 DNS-01 決策。
2. 再讀 PROGRESS.md，確認實際做過哪些 TLS / cert-manager 操作，避免把概念講成抽象名詞。
3. 接著讀 manifests/ingress.yaml，確認目前 TLS secret 與 Ingress 的接法。
4. 最後回到 docs/LINE-Webhook-切換流程.md，把 TLS 方案、驗證方式與流量現況接起來。

## 今日 command 練習

- 今天不建立 command drill。
- 原因：今天主題以概念邊界、選型理由與 repo-backed 判讀為主。實際 cert-manager 資源鏈與排查留到明天的 TLS 操作與排查骨架 lesson 再做。

## 文件分工

1. 01-outline.md：規劃今天主題、順序與邊界。
2. 02-qa.md：記錄今天的 repo-backed 問題、使用者回答摘要與 AI 修正。
3. 04-report.md：收斂今天真正學到的 cert-manager / DNS-01 骨架。
4. 05-note.md：記錄延伸補充、暫時結論與之後可接到 TLS 排查 lesson 的邊界。

## 這次要追問的 Why / How 題

1. cert-manager 為什麼不是單純的「憑證下載工具」，而是憑證生命週期管理元件。
2. 為什麼 DNS-01 比 HTTP-01 更符合 WeaMind 目前的 DNS、LB 與 TLS 架構。
3. 為什麼不需要為了 ACME 驗證而刻意保留公開 80，也不能把這件事簡化成「所以 HTTPS redirect 不能做」。

## 這份 lesson 的完成標準

1. 能用自己的話解釋 cert-manager 想自動化解決什麼問題。
2. 能比較 DNS-01 與 HTTP-01 的差異，並指出各自依賴的驗證面。
3. 能說出 WeaMind 為什麼偏向 DNS-01。
4. 能結合 WeaMind 現況說出：為什麼這個專案不需要為了 HTTP-01 驗證而保留外部 80，以及這件事如何影響後續 HTTP→HTTPS redirect 的設計。
