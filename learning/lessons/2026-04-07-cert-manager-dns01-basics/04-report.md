# 2026-04-07 cert-manager DNS-01 Basics Report

## 今日主題

把 WeaMind 的 cert-manager、DNS-01 / HTTP-01 選型理由，以及 ACME 驗證和正式流量策略的邊界，收斂成可口述的專案答案。

## 狀態

已完成 QA 收斂，本次 lesson 不做 command drill。

## 今日最小收斂

1. cert-manager 在 WeaMind 裡自動化的不只是拿到憑證，而是整個 TLS 憑證生命週期，包括申請、DNS-01 驗證、儲存與續期。
2. DNS-01 驗證的是 DNS 控制權，HTTP-01 驗證的是公開 HTTP 路徑控制權；在 WeaMind 這種 LB + Ingress 架構下，HTTP-01 更容易和流量路徑、redirect 例外與 solver 路徑糾纏在一起。
3. WeaMind 的 DNS 在 Cloudflare，不在 Hetzner，因此無法直接走 Hetzner Managed Certificate；TLS 便改由 K3s 內的 Traefik 終止，再由 cert-manager 搭配 Cloudflare DNS-01 管理憑證。
4. 因為憑證驗證已改走 DNS-01，WeaMind 不需要為 ACME 驗證特地保留外部 HTTP challenge 路徑，後續 HTTP→HTTPS redirect 可以更乾淨地套在一般流量上。

## 最短答題稿

WeaMind 的 DNS 託管在 Cloudflare，不在 Hetzner，因此無法直接使用 Hetzner Managed Certificate；TLS 改由 K3s 內的 Traefik 終止，再由 cert-manager 搭配 Cloudflare DNS-01 管理憑證。DNS-01 驗證的是 DNS 控制權，不必讓 ACME challenge 一直依賴公開 HTTP 路徑，所以比 HTTP-01 更不會和 Hetzner LB、Ingress 規則與 HTTP→HTTPS redirect 糾纏在一起。

## 今日延伸結論

- HTTP→HTTPS redirect 和 HTTP-01 並非絕對衝突；真正關鍵是 challenge 路徑有沒有被正確保留例外。
- TLS Secret 和一般業務 Secret 本質上都是 Kubernetes Secret，但在 type、內容格式、建立方式與消費者上有明顯差異。
