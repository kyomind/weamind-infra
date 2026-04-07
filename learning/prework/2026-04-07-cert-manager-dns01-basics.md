# 2026-04-07 cert-manager DNS-01 Basics

## Prework 內容

### 今日焦點

- 主題：cert-manager 基礎、ACME 驗證方式、DNS-01 vs HTTP-01
- 範圍：cert-manager 想自動化解決什麼問題、它如何和 DNS provider 互動、DNS-01 與 HTTP-01 的本質差異、什麼情況下會偏向 DNS-01
- 目標：先把今天會用到的純知識骨架補齊，再回到 VS Code 對照 WeaMind 的 TLS / Ingress / Cloudflare / Hetzner LB 實際選型
- 時間：控制在 45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天先專注在通用知識，不進入 WeaMind repo 的具體 YAML、資源名稱或安裝步驟細節。

### 今天一定要學會的最小骨架

1. cert-manager 不是單純幫你把憑證抓下來的工具，而是 Kubernetes 裡管理憑證申請、簽發、儲存與續期的元件。
2. cert-manager 會透過 ACME 流程向憑證機構證明「我真的控制這個網域」，而 DNS-01 與 HTTP-01 只是兩種不同的驗證方法。
3. HTTP-01 的本質是讓 CA 從公開 HTTP 路徑驗證網域控制權；DNS-01 的本質是讓 CA 從 DNS TXT 記錄驗證網域控制權。
4. cert-manager 若使用 DNS-01，通常會透過 DNS provider 的 API 自動新增與刪除 TXT 記錄，所以它和 DNS provider 的互動重點是 API 權限與可自動修改 DNS 區域。
5. 選 DNS-01 或 HTTP-01，不只是語法選擇，而是取決於你的流量入口、DNS 控制權、是否方便暴露 HTTP 驗證路徑，以及你想不想讓憑證驗證和正式流量路徑綁在一起。

### 建議教學順序

1. 先用白話講清楚 cert-manager 在 Kubernetes 裡扮演什麼角色，和單機上的 certbot 有什麼定位差異。
2. 再講 ACME 驗證在解什麼問題，讓我知道憑證申請不是憑空成功，而是要先證明網域控制權。
3. 接著比較 HTTP-01 與 DNS-01：各自驗證的是什麼、依賴什麼、常見優缺點是什麼。
4. 再講 cert-manager 用 DNS-01 時，通常怎麼和 Cloudflare 這類 DNS provider 互動，尤其是 API Token、TXT 記錄、Propagation 這幾個重點。
5. 最後用 2 到 3 個小問題確認我是否真的理解：什麼情況會偏 DNS-01，什麼情況 HTTP-01 反而更直覺。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 VS Code 後，應該拿去和 GitHub Copilot 對照 repo 的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日主題與學習範圍

- 主題：cert-manager 基礎、ACME 驗證、DNS-01 vs HTTP-01
- 範圍：
  - cert-manager 在 Kubernetes 中的角色
  - ACME 為什麼需要驗證網域控制權
  - HTTP-01 與 DNS-01 的本質差異
  - cert-manager 如何透過 DNS provider 進行 DNS-01 驗證

### 今日學到什麼

- cert-manager 不是單純拿憑證的工具，而是 Kubernetes 中負責憑證生命週期的 controller，涵蓋申請、驗證、儲存與續期。
- ACME 驗證的目的，是確保申請憑證的人真的控制該網域，避免攻擊者偽裝成合法網站。
- HTTP-01 與 DNS-01 的差異，在於驗證控制權的位置不同：HTTP-01 驗證你是否控制 HTTP 流量入口，DNS-01 驗證你是否控制 DNS，也就是網域本身。
- 在 Kubernetes 中，HTTP-01 會依賴完整的流量路徑，例如 LB、Ingress、Service 到 Pod；DNS-01 可以避開這些層，直接透過 DNS provider API 處理。
- DNS-01 的實作本質，是新增 `_acme-challenge` 的 TXT 記錄，等待 propagation 完成後通過驗證。
- DNS record 本身通常是公開可查的，但安全性不在於內容保密，而在於誰擁有 DNS 修改權。

### 已能白話講清楚什麼

- cert-manager 是 Kubernetes 裡持續運作的憑證管理 controller，而不是像 certbot 一樣的一次性工具。
- ACME 在驗證的是你是否真的控制該網域，否則 TLS 的身份驗證會失去意義。
- HTTP-01 是走網站流量路徑驗證，DNS-01 是走 DNS 控制權驗證。
- DNS-01 不需要碰 Ingress 或 routing，因此在 Kubernetes 中通常更解耦。
- DNS 是公開的，但真正敏感的是能修改 DNS 的 API Token，而不是 TXT 記錄本身。

### 目前還卡住什麼

- DNS propagation 的實際延遲與 cert-manager retry 機制。
- 不同 DNS provider 的 API 權限細節。
- cert-manager CRD，例如 Issuer、ClusterIssuer、Certificate 之間的關係。

### 今日最重要的觀念

- cert-manager 是 Kubernetes 中的憑證生命週期 controller。
- TLS 不只有加密，也包含身份驗證。
- ACME 的本質是驗證網域控制權。
- HTTP-01 vs DNS-01 的核心差異，是驗證位置不同：流量入口 vs DNS。
- DNS record 是公開的，但 DNS 修改權才是安全核心。

### 帶回 VS Code 的問題

1. 在 WeaMind 這種 Cloudflare DNS + Hetzner LB + Traefik 的架構下，為什麼 DNS-01 比 HTTP-01 更不容易和正式流量路徑糾纏在一起？
2. cert-manager 在目前 repo 中，是如何取得 Cloudflare API 權限來新增 TXT record 的？這個權限範圍是否最小化？
