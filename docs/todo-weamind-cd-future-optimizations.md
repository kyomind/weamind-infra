# WeaMind CD TODO：未來優化方向

## 文件目的

這份文件用來記錄 WeaMind 第一版 CD 已經完成之後，下一步如果要繼續優化，可以往哪些方向走。

目前第一版已經完成的事情是：

1. app repo release 後會自動對 `weamind-infra` 開 version update PR。
2. infra repo 已經有第一版人工 deploy 入口。
3. deploy / rollback 指令已經收斂成 repo 內可重複執行的命令。

這份文件不是要把現在的流程重寫一遍，而是要保留一個清楚的優化清單，讓後續如果要加強自動化、治理或操作體驗時，有一個明確起點。

---

## 目前已定下來的三個指令

目前 infra repo 的最小人工操作面，先收成三個入口：

1. `make deploy`
2. `make rollback`
3. `make rollout`

### `make deploy`

用途：套用 manifests，並確認 rollout 是否成功。

目前等同於：

```bash
kubectl apply -f manifests/
kubectl rollout status deployment/weamind -n weamind
```

### `make rollback`

用途：在部署後發現有問題時，回退到上一版 rollout 狀態。

目前等同於：

```bash
kubectl rollout undo deployment/weamind -n weamind
```

### `make rollout`

用途：單獨觀察 rollout 狀態，適合已經 apply 完之後再追蹤狀態，或排查 rollout 卡住的情況。

目前等同於：

```bash
kubectl rollout status deployment/weamind -n weamind
```

---

## 未來可以優化的方向

### 1. 讓 merge 後 deploy 更自動化

目前流程是：

- release 後自動開 infra PR
- PR merge 後人工執行 `make deploy`

如果未來要再進一步，可以考慮：

- PR merge 後自動觸發 deploy workflow
- 由 GitHub Actions 或其他 orchestration 層負責 apply
- 將人工操作改成更低摩擦的半自動流程

但這一版先不急著做，因為目前的人工作業面已經夠清楚，而且保留人工確認點比較穩。

### 2. 強化 rollback / 回退故事

目前已經有 `make rollback`，但它仍然只是最小回退入口。

未來可以再補的方向包括：

- 記錄每次 deployment version 對應的 release tag
- 在 PR 或 release note 裡附上更完整的回退資訊
- 如果真的遇到頻繁回退需求，再考慮更完整的回滾流程

### 3. 增加更方便的觀察指令

目前最小命令已經足夠用，但如果想讓操作更順手，可以加一些只讀指令，例如：

- `make status`
- `make pods`
- `make logs`
- `make events`

這些指令不一定要現在做，但如果未來要提升 operator 可用性，會很自然。

### 4. 改善 target 命名與參數化

現在的 Makefile target 很小而直接，這對第一版很剛好。

如果之後 infra repo 開始出現：

- 多環境
- 多 namespace
- staging / production 區分
- 不同 deployment 入口

那就可以考慮把 target 進一步參數化，例如：

- `make deploy ENV=prod`
- `make rollback ENV=prod`
- `make rollout ENV=prod`

但目前不需要先做，因為 WeaMind 第一版的部署場景還很單純。

### 5. 讓認證治理更正式

目前 release-to-infra PR 這條路已經用 fine-grained token 跑通。

未來如果這條路變成更正式的長期基礎設施，可以再評估：

- 改用 GitHub App
- 把機器身份治理得更清楚
- 把權限邊界從 PAT 再往前收

這不是現在的必要項，但如果後續要擴大自動化範圍，這會是最自然的升級方向。

### 6. 若未來採用 GitOps，再重新調整責任邊界

現在的做法是：

- app repo release → infra repo PR → 人工 merge → 人工 deploy

如果未來想往更完整的 GitOps 方向走，可以再考慮：

- 由 Argo CD / Flux 類工具負責同步
- 讓 repo 只保存期望狀態
- 將 deploy 操作從手動 command 進一步轉成 controller 監控

但這會是下一階段的架構選擇，不是目前第一版需要立即做的事。

---

## 目前的判斷

目前這版 WeaMind CD 的狀態是：

- release 後自動開 infra PR，已完成
- PR merge 後人工 deploy，已收斂成 Makefile target
- 之後若要優化，可以優先從「更自動化」和「更好操作」兩個方向下手

所以這份 TODO 的核心不是補洞，而是保留下一步的方向感。

---

## 一句話總結

第一版已經夠用，後續若要優化，優先順序大致是：

1. 讓 merge 後 deploy 更自動化
2. 強化 rollback 與觀察指令
3. 視需要再升級認證治理與 GitOps 架構

---

## 2026-05-27 補充：實作路徑規劃

### 分兩步實作，而不是直接上 Argo CD

決定採用漸進式演進：

1. 先實作 GitHub Actions 版本：merge 後自動 `kubectl apply`
2. 之後再升級到 Argo CD 版本

### 為什麼分兩步更好

- 有演進故事：「先用最小方案解決問題，發現痛點後再升級」是真實世界的做法
- 能講 trade-off：為什麼 GitHub Actions 夠用、什麼情況下不夠用、為什麼升級到 Argo CD
- 不是 over-engineering：展示「什麼時候該用什麼工具」，而不是一開始就搬大砲

### 文章故事線

```
第一篇：用 GitHub Actions 實作 merge 後自動 deploy
    → 夠用，但只是「推一次」，沒有持續同步

第二篇：升級到 Argo CD
    → 解決 drift detection、可視化、多環境管理
    → 順便講為什麼這時候才引入
```

這種漸進式演進的敘事，面試時會比「我直接用 Argo CD」更有深度。
