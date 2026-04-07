# 2026-04-07 cert-manager DNS-01 Basics Note

## 學習注意事項

### 今日 lesson 邊界

- 今天主題是 cert-manager 的角色、DNS-01 vs HTTP-01、WeaMind 的選型理由，以及 ACME 驗證與正式流量策略的邊界。
- 今天不展開完整 PKI、CA 信任鏈、openssl 細節，也不提前展開明天的 Certificate / CertificateRequest / Order / Challenge 排查鏈。
- 今天也不把焦點放成 cert-manager 安裝步驟清單，而是聚焦在為什麼這個專案這樣選。

### 今天要特別觀察的 repo 事實

- README 已明確寫出 WeaMind 採用 cert-manager + Cloudflare DNS-01。
- PROGRESS 已記錄 Hetzner Managed Certificate 因 Cloudflare DNS 架構而不可行，改採 cert-manager + Cloudflare DNS-01。
- Ingress 目前直接引用 TLS secret，代表憑證最終是提供給 K8s 內的 Traefik 使用。
- ACME 驗證方法與正式 HTTP→HTTPS redirect 策略不是同一層決策。

## Notes

<!-- 待互動後補充延伸問題與暫時結論 -->

## Flashcards

<!-- 待互動後補卡片 -->
