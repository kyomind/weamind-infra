# README 重構與 Badge 調整 Handoff

整理日期：2026-05-15

## 任務摘要

本次任務的主軸，是重構 `README.md` / `README.en.md`，讓這個 repo 更適合作為 DevOps 轉職作品展示，同時避免 README 變成學習日誌或過長的操作手冊。

這次工作不是全面重寫，而是在保留原本核心架構敘事的前提下，逐步做小幅但高價值的調整。

## 已完成變更

### 1. 新增並調整 badges

已在 `README.md` 與 `README.en.md` 的 H1 下方加入靜態技術 badges，採灰底 flat 風格，與使用者偏好的 `kyomind` repo 風格接近。

目前 badges 為：

- Kubernetes
- K3s
- Terraform
- Helm
- Prometheus
- Grafana
- GitHub Actions

決策理由：

- 這些 badges 是靜態 identity badges，不是 CI / Codecov / CodeQL 之類的狀態 badges。
- 之所以不做狀態 badge，是因為本 repo 目前沒有對應的 GitHub Actions workflow 可作為真實訊號來源。
- Helm 後來補上，原因是 README 的 Tech Stack 已明確寫出 `Helm + kube-prometheus-stack`，badge 若缺 Helm 會出現輕微不對稱。

### 2. 調整 badges 位置

badges 最初加在 H1 上方，後來改到 H1 下方。

決策理由：

- H1 在上、badges 在下，是較主流、較穩的 README 排法。
- 這份 README 偏文件與作品集展示，不需要讓 badges 壓過標題本身。

### 3. 擴充 Tech Stack

`Tech Stack` 從原本偏 runtime infra 的 5 條，擴充為 7 條，並加入一行範圍說明。

目前方向為：

- `K3s` 叢集（1 控制平面 + 2 工作節點）於 Hetzner Cloud
- `Traefik` Ingress Controller（K3s 內建）
- `Hetzner Load Balancer` 負載平衡器
- `cert-manager` + Let's Encrypt（Cloudflare DNS-01 驗證）
- `PostgreSQL` 與 `Redis` 於堡壘機（不在 K8s 內）
- `Helm` + `kube-prometheus-stack`（Prometheus / Grafana observability）
- `Terraform` 於 GCP Free Tier 的 IaC 實作

範圍說明：

- 中文版：本 repo 目前涵蓋執行中基礎設施、可觀測性，以及以 Terraform 為主的 IaC 實作。
- 英文版：This repository currently covers the runtime infrastructure stack, observability tooling, and Terraform-based IaC work.

決策理由：

- 使用者認為 `Tech Stack` 不必為了精簡而硬縮，因為原本就不長。
- `Prometheus` 與 `Grafana` 最終合併成一條，並明確寫出實際使用的是 `Helm + kube-prometheus-stack`。
- `Terraform` 可以納入 `Tech Stack`，前提是該區塊被定義為「這個 repo 目前涵蓋的技術範圍」，而不是純 production runtime stack。

### 4. 壓縮 Deployment Overview

中文版 `README.md` 的 `Deployment Overview` 已從 8 點壓縮為 6 點；英文版後來也同步調整為 6 點。

目前 6 點為：

1. K3s 叢集建立
2. Traefik 設定
3. cert-manager 安裝
4. 應用部署
5. 公開入口配置
6. 流量切換

決策理由：

- 使用者認為 `Deployment Overview` 必須保留，因為它不只是部署教學，而是「implementation map」，能證明這個 infra 不是純靠 AI 從頭做完，而是有實際參與、自己的思路與順序理解。
- 第 2 點原本獨立的網路配置，後來併入 K3s 叢集建立，因為那比較像關鍵實作細節，而不是獨立階段。
- Hetzner Load Balancer 與 Cloudflare DNS 也被合併成「公開入口配置」，降低 checklist 感。

### 5. 重新整理架構摘要

`Architecture` 區塊下方原本的「架構特點 / Architecture highlights」後來被改寫成較摘要式的版本。

目前目的：

- 快速說明「混合式執行環境」與「入口 / 切換模型」
- 避免和後面的 `Why This Architecture` / `Design Decisions` 重複講同樣的判斷

這是一次「壓縮重複敘述」的重構，而不是新增新內容。

### 6. 對齊中英文 README

最終已完成：

- badges 一致
- `Tech Stack` 一致
- `Deployment Overview` 一致
- Related Resources 一致
- 中文版與英文版整體結構一致

英文版額外補上 `Project article`，與中文版的「專案介紹文章」對齊。

## 核心決策與思路

這次 README 調整最重要的判斷，不是「補多少內容」，而是先界定 README 的展示任務。

本次對 README 的定位是：

- 展示結果
- 展示架構判斷
- 展示 repo 目前能證明的能力面
- 不把 README 寫成學習過程或 lesson 紀錄

幾個關鍵共識如下：

### 1. README 不應該追求完整記錄

使用者明確提出：README 若過長，雖然完整，但可能降低閱讀意願。

因此這次採取的原則是：

- `README.md` 展示高訊號資訊
- 更細的實作過程、踩坑、驗證與日誌，外移到 `PROGRESS.md`、`docs/` 或其他記錄檔

### 2. Deployment Overview 要保留

曾討論過是否縮短甚至移除，但後來結論是：應保留。

原因不是它像教學流程，而是它能證明：

- 這個 repo 的 infra work 有清楚的實作順序
- 使用者對系統建構過程有自己的理解
- 這不是單純叫 AI 做完的結果

因此後來的最佳定位是：

- `Deployment Overview` 不是操作手冊
- 它是 implementation overview / implementation map

### 3. Tech Stack 可以吸收 W7-W9 的 repo scope

一開始曾討論是否應新增 `Repository Scope` 區塊來承接 W7-W9。

後來在 `Tech Stack` 議題上收斂為：

- 現階段不一定需要獨立 `Repository Scope`
- 只要在 `Tech Stack` 前加入一句範圍說明，就能自然吸收 observability 與 Terraform 這兩條新能力線

這是目前最省篇幅、又能講清楚邊界的做法。

## 仍在思考中的事項

### GitHub Repository Description

README 改完後，使用者開始重新思考 GitHub repo 的 Description 是否太短。

原本畫面上的 Description 為：

- `Infrastructure for WeaMind – K3s Kubernetes on Hetzner Cloud`

討論結論：

- 目前這句不算錯，但稍微太薄，只講了「跑在哪裡」，沒有反映 observability / Terraform / migration story。
- 使用者尚未決定是否要修改 Description，目前只是進入思考階段。

曾提出的方向包括：

- `Infrastructure for WeaMind — migration from single-server Docker to K3s on Hetzner Cloud`
- `Infrastructure for WeaMind — K3s on Hetzner Cloud, with observability and Terraform`
- `Infrastructure for WeaMind — K3s, observability, and Terraform for the WeaMind project`

這一題尚未定案，也尚未實作。

## 目前檔案狀態

本次實際修改的核心檔案：

- `README.md`
- `README.en.md`

本次新增的 handoff 檔案：

- `docs/HANDOFF-readme-refactor-and-badges-2026-05-15.md`

## 待處理事項

目前沒有必須立刻處理的 issue。

可選後續事項：

1. 決定 GitHub repo Description 是否要改寫
2. 若改寫 Description，需選擇要偏「遷移故事」還是偏「技術範圍」
3. 若後續 README 再擴寫，應先檢查是否會破壞目前已建立的高訊號結構

## MEMOS

- 這次 README 重構的成功關鍵，不是大量新增內容，而是先界定 README 的角色：作品集門面，不是學習日誌。
- `Deployment Overview` 一度被懷疑過長，但最後保留，因為它能證明使用者有自己的 infra implementation map。
- `Tech Stack` 不要再往回縮；目前 7 條是可接受平衡。
- `Prometheus` / `Grafana` 要維持合併成 `Helm + kube-prometheus-stack` 這一條，這是經過討論後的刻意收斂。
- badges 目前採灰底 flat 風格，位置在 H1 下方，這是使用者認可的版本。
- badges 目前已包含 Helm；再新增 badge 應非常保守，否則容易變成 badge 牆。
- 中英文 README 已同步；未來若再調整 README，應預設兩份一起改，不要只改單邊。
- GitHub repo Description 還沒定案；下次新 AI 若要接手，這會是最自然的下一題。
