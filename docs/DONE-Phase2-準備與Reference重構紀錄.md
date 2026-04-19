# DONE-Phase2 準備與 Reference 重構紀錄

## 文件目的

這份文件用來整理本次 Phase 2 開始前的準備過程。

重點不是逐字重播對話，而是把最後真正留下來的決策、文件結構、命名調整與目前可直接使用的入口收斂成一份可回看的紀錄。

## 這次整理想解的問題

在這次收斂之前，Phase 2 雖然已有主題方向，但還缺幾個會直接影響後續 lesson 與實作的東西：

- Phase 2 缺少一份足夠正式的三週細部計畫
- W7 / W8 / W9 的穩定規格和週計畫混在一起，讀起來太厚
- W8 的「現況證據」與「實作方案邊界」容易混在一起
- W9 的 Terraform 目標原本還偏抽象，沒有明確對齊要做出哪一台 VM
- 週次 reference 的命名還不夠一眼辨識

這次整理的核心，就是把這些邊界切清楚，讓 Phase 2 進場時不再需要一邊上課一邊補文件結構。

## 最終留下的文件結構

### 1. Phase 2 主入口

- `.privatedocs/Phase2三週計畫.md`

這份文件的角色已經收斂成：

- 管節奏
- 管每週 / 每日目標
- 管是否包含 implement
- 管短版驗收標準
- 指向對應週次的 reference

它不再承擔所有穩定細節。

### 2. 週次 reference

Phase 2 三週各自有一份對應的穩定規格 reference：

- `references/w7-observability-minimum-spec.md`
- `references/w8-cd-minimum-spec.md`
- `references/w9-iac-minimum-spec.md`

這三份文件現在的命名邏輯是故意以 `w7`、`w8`、`w9` 開頭，避免 `weamind-...` 連續重複造成辨識成本。

### 3. 現況證據檔

- `references/weamind-ci-to-k8s-flow.md`

這份文件沒有改成 W8 前綴，因為它的角色不是單純某一週的 minimum spec，而是 WeaMind 目前 CI / image publishing / Deployment 引用方式的證據檔。

它目前被保留作為：

- 現況證據
- 流程邊界確認
- W8 設計對照時的依據

而不是施工藍圖本身。

## 本次最重要的幾個決策

### 決策 1：Phase 2 計畫要做成入口檔，不再做成超厚總規格檔

最後採用的做法是：

- 週計畫只保留日程、主題、implement 與驗收
- 穩定規格與可重複引用內容移到 `references/`

這樣做的原因很簡單：

- 如果當週主題和其他週沒有直接關聯，就不應每次都把其他週的細節一起讀進來

這也是後來把 W7 / W8 / W9 各自拆成獨立 reference 的主要原因。

### 決策 2：W8 要把「現況證據」和「施工邊界」切開

W8 目前有兩份相關文件，但角色不同：

- `references/weamind-ci-to-k8s-flow.md`：現況證據檔
- `references/w8-cd-minimum-spec.md`：W8 的最小 CD 規格檔

前者回答「現在已經有什麼、沒有什麼」，後者回答「如果 W8 要開始做，第一版應該怎麼收斂」。

這個切法是為了避免後續實作時把證據檔誤當施工規格。

### 決策 3：W9 不再只是抽象 IaC 練習，而是明確對齊 GCP Free Tier VM

W9 最後被收斂成：

- 以 `https://kucw.io/blog/gcp-free-tier/` 那篇教學中的 Free Tier VM 條件為目標
- 在前置帳號、billing、project 都已就緒的前提下
- 用 Terraform 建出一台等價的 GCE VM

這個決策非常重要，因為它把 W9 從「泛泛做一次 Terraform 練習」收斂成一個有明確目標物的題目。

### 決策 4：W9 reference 要內化文章規格，不只是叫人回去看文章

最後 `references/w9-iac-minimum-spec.md` 裡已補上：

- 教學規格內化版
- 手動教學到 Terraform 的對照方式
- 驗收 checklist
- Terraform 參數對照草稿
- 第一版資源輪廓
- implementation sketch

也就是說，文章現在是來源背景，而不是主操作文件。

## 各週目前的準備狀態

### W7：Observability

`references/w7-observability-minimum-spec.md` 已整理出：

- Node 3
- App 4
- 最小 dashboard 目標
- metric naming
- labels
- hook points
- `event_type` 最小分類規則

所以 W7 現在已經不只是「要學 Prometheus / Grafana」，而是有明確最低交付物。

### W8：CD

`references/w8-cd-minimum-spec.md` 已整理出：

- 為什麼現況還不算完整 CD
- 正式 deploy source 為什麼不應追 `latest`
- app repo / infra repo 的責任邊界
- 最小自動化鏈路
- 第一版最推薦方案

而 `references/weamind-ci-to-k8s-flow.md` 則保留現況證據。

### W9：IaC / Terraform

`references/w9-iac-minimum-spec.md` 已整理出：

- W9 的最小目標
- Free Tier VM 目標規格
- 手動設定到 Terraform 意圖的對照
- 驗收 checklist
- Terraform 參數對照草稿
- 第一版實作應長出的結構

這代表 W9 已經從「概念導向」進一步收斂到「準 implementation 狀態」。

## 命名重構結果

這次明確做了週次前綴命名調整：

- `references/weamind-observability-minimum-spec.md` -> `references/w7-observability-minimum-spec.md`
- `references/weamind-cd-minimum-spec.md` -> `references/w8-cd-minimum-spec.md`
- `references/weamind-iac-minimum-spec.md` -> `references/w9-iac-minimum-spec.md`

調整原因：

- `weamind-...` 作為前綴雖然正確，但在 `references/` 場景下資訊密度偏低
- `w7`、`w8`、`w9` 更能直接對應 Phase 2 的閱讀入口

相關引用也已同步更新到 `.privatedocs/Phase2三週計畫.md` 與其他需要的文件中。

## 目前可以怎麼使用這套結構

若現在正式開始 Phase 2，最自然的入口順序是：

1. 先看 `.privatedocs/12週計畫.md`
2. 再看 `.privatedocs/Phase2三週計畫.md`
3. 依當週主題進對應 reference：
   - W7 -> `references/w7-observability-minimum-spec.md`
   - W8 -> `references/w8-cd-minimum-spec.md`
   - W9 -> `references/w9-iac-minimum-spec.md`
4. 若 W8 需要理解現況證據，再讀 `references/weamind-ci-to-k8s-flow.md`

## 這次整理後的判斷

以「正式開始 Phase 2」來說，文件準備目前已經足夠。

也就是說，現在缺的已經不是結構整理，而是：

- 真的進入 W7 prework / lesson
- 到 W8 / W9 implementation day 時，再依 reference 開始落地

若未來還要補文件，應以「implementation 當天是否真的需要」為標準，而不是先把所有可能東西都寫滿。

## 一句話總結

這次整理的成果，不是多寫了幾份文件，而是把 Phase 2 從「主題列表」收斂成一套可進場、可按週讀取、可按需展開的學習與實作骨架。
