# WeaMind實作CD討論與實踐

## 文件目的

這份文件用來收斂 WeaMind 從目前的 CI 與 image publishing 狀態，往較擬真的 CD 流程前進時，應該如何思考、怎麼拆步驟、以及哪些做法更符合這個專案的真實現況。

這不是一份立即實作指令稿，而是一份設計討論與實踐方向文件。

目前目標不是追求 100 分 production 平台化，而是做出一個 **70 分擬真、邊界清楚、版本可追溯** 的 CD 流程。

---

## 背景

WeaMind 目前已經有相當完整的 CI 與 image publishing 流程，但從 image registry 到 Kubernetes 叢集的最後一跳，還沒有被自動化接起來。

這代表目前的狀態比較準確的說法是：

- 有 CI
- 有 image publishing
- 但還沒有完整 CD

這份文件的核心問題是：

1. WeaMind 現在有沒有必要補 CD。
2. 如果要補，應該補成什麼樣子才合理。
3. 正式 deploy version 應該追哪一種 tag。
4. app repo 與 infra repo 的責任邊界應該怎麼切。

---

## 目前現況

### App repo 已有兩條 image publish 路徑

目前 app repo 有兩條不同用途的 image 發佈路徑。

第一條是 main 分支上的持續發佈：

- CI 成功後觸發 publish workflow
- 發佈到 GHCR
- 產出 `latest` 與 `sha-<short_sha>`

第二條是 release tag 發佈：

- 當 push `v*` tag 時觸發 release image workflow
- 會根據 Git tag 解析版本號
- 產出完整版本、minor、major 這幾層 version tags

因此，WeaMind 並不是只有 sha 類型的 immutable 識別，也不是只有 `latest`。

它其實已經有正式 release tag 流程。

### Infra repo 目前仍引用 latest

目前 infra repo 的 Deployment 仍直接引用：

```yaml
image: ghcr.io/kyomind/weamind:latest
imagePullPolicy: Always
```

這表示 infra repo 現在的 deployment state 並沒有明確記錄「目前叢集應該跑哪個正式版本」，而是把部署依據放在 mutable tag `latest` 上。

### Infra repo 目前沒有既有 deploy workflow

目前 infra repo 沒有 `.github/workflows/` 這類既有 deploy automation。

這代表：

- 現在還沒有自動 deploy pipeline
- 也還沒有現成的 infra-side automation 可直接接上
- 若要補 CD，基本上是從零開始定義 infra 端流程

這不是缺點，反而是一個好處，因為現在可以很清楚地設計責任邊界。

---

## 現在為什麼還不算完整 CD

目前 WeaMind 已經自動化的部分包括：

- 程式碼品質檢查
- 測試
- Docker build validation
- push 到 GHCR

但它還不能叫完整 CD，因為 **從 registry 到 cluster 的最後一跳還沒有自動化**。

目前沒有證據顯示系統會在 image push 完後自動做下面任何一件事：

- 自動更新 Deployment image
- 自動 `kubectl set image`
- 自動 `kubectl rollout restart`
- 自動由 GitOps controller 同步新版本

因此目前的行為仍是：

- GHCR 上的 image 可以更新
- 但現有 Pods 不會因此自動換版
- 只有在 Pod 被 recreate、rollout 或 restart 時，才有機會拉到新 image

---

## imagePullPolicy: Always 的邊界

`imagePullPolicy: Always` 很重要，但它容易被誤解。

它真正保證的是：

- 當 Pod 被建立或重新建立時，kubelet 會重新嘗試拉取該 image reference

它沒有保證的是：

- 不會背景自動監看 registry 的變化
- 不會因為 registry 裡的 image 內容更新就自動更新現有 Pod
- 不會主動幫你觸發 rollout

因此在 `latest` 策略下，它只是讓 **新建立的 Pod 比較有機會拿到新的 latest**，不是讓現有 Pod 自動升級。

---

## 是否值得補 CD

以 WeaMind 目前的狀態來看，CD 不是立即必做，但很合理值得做。

理由如下：

- 服務本身已經成熟
- 大更新不多
- 小更新與依賴更新 PR 偶爾出現
- 手動部署當然還可控，但已經開始值得把流程做正確

更務實地說，現在最值得補的不是「極致自動化」，而是：

- 減少人為忘記更新的落差
- 讓 deployment version 可追溯
- 讓 infra repo 真正成為 deployment source of truth

所以這不是為了追求炫技，而是為了讓這個專案更接近真實世界的版本與部署邏輯。

---

## 為什麼不建議直接以 latest 為基礎補 CD

如果只追求最快看到成果，最小做法當然是：

- publish 完 `latest` 後
- 自動對既有 Deployment 做 `rollout restart`

這條路的優點是：

- 簡單
- 快速
- 幾乎不用重做版本策略

但它的缺點也非常明確：

- `latest` 是 mutable tag
- 回滾不直觀
- Git 歷史不會清楚記錄目前部署的是哪個正式版本
- 版本語意偏弱

所以這條路可以是最小可用 CD，但不適合作為比較擬真的正式方案。

---

## 為什麼正式 deploy source 應該是 release tag

這次回到 app repo 實際檢查後，可以確定：

- WeaMind 已經有正式 Git release tags，例如 `v1.1.2`
- 也已經有對應的 release image publish workflow

因此，如果要問 infra repo 最終應該追哪種版本，答案更合理的是：

- 不應追 `latest`
- 也不必以 `sha-<short_sha>` 當作最終 deploy version
- 應追正式 release tag 對應的 image

原因是 release tag 比 sha 更適合作為正式 deploy version：

- 對人類更有版本語意
- 較容易溝通
- 較容易回滾
- 較容易寫 release notes 與部署紀錄
- 更接近 production 版本管理習慣

sha 仍然有價值，但它更適合：

- debug
- 追查 build 來源
- main 分支上的持續交付中間產物

---

## 但不是所有 release-like tags 都同樣 immutable

app repo 的 release workflow 目前會從 `v1.1.2` 這類 Git tag 解析出：

- 完整版本，例如 `1.1.2`
- minor，例如 `1.1`
- major，例如 `1`

這裡必須收緊一個觀念：

- 真正嚴格 immutable 的，只有完整版本 tag
- `1.1` 與 `1` 仍然會隨後續 release 前移

所以若 infra repo 要追求真正可回滾、可追溯的 deployment version，應該只追：

- 完整 release version

而不是：

- `latest`
- `1.1`
- `1`

---

## 建議的責任邊界

### App repo 的責任

app repo 應負責：

- 建出 image
- 發佈 image 到 GHCR
- 定義什麼是正式可部署版本

更精準地說：

- main push 產出的 `latest` 與 `sha-<short_sha>` 是持續交付中的快速版本
- release tag 產出的完整版本 image 才是正式 deploy artifact

### Infra repo 的責任

infra repo 應負責：

- 宣告叢集目前要跑哪個版本
- 保存 deployment state 的 Git 歷史
- 決定何時把這個版本套進叢集

這代表 infra repo 不應再只是「永遠寫一個 latest 的靜態檔案」，而是應能明確回答：

- 現在叢集宣告要跑哪個 app release

---

## 推薦方案與落地順序

最推薦的方向是：

1. 保留現有兩條 publish 路徑。
2. 把正式 deploy version 改成 release workflow 產出的完整版本 tag。
3. 讓 app repo 在 release 成功後，自動更新 infra repo 中的 image version。
4. 第一階段先採「自動開 PR 到 infra repo」，不直接動 cluster。
5. 等流程穩定後，再決定 infra repo 是否要補合併後自動 deploy。

這個方向的核心不是增加很多自動化，而是先把 deployment version 做正確，再逐步補 deploy convenience。

---

## app repo 與 infra repo 各自最小需要補什麼

### app repo

app repo 不一定需要重做 release 機制，因為它已經有 `v*` tag 觸發的 release image publish workflow。

真正值得補強的，是把 release path 升級成正式 deploy source：

1. 明確規範只有完整 release version 才是正式 deploy source。
2. 讓 release workflow 更容易被下游流程引用。
3. 讓跨 repo 更新流程能清楚拿到這次 release version。

### infra repo

infra repo 的核心改動只有一件事：把 Deployment image 從固定 `latest`，改成完整 release version。

例如從：

```yaml
image: ghcr.io/kyomind/weamind:latest
```

改成：

```yaml
image: ghcr.io/kyomind/weamind:1.1.2
```

一旦 image tag 改成 manifest 內可見、可提交的固定值，infra repo 就真正開始擁有 deployment state：版本可追溯、回滾有依據、apply 時也會自然 rollout。

---

## 最小自動化鏈路

若要維持 repo 邊界清楚，最推薦的鏈路是：

1. app repo 建立正式 release。
2. app repo 的 release workflow build 並 push 對應 image。
3. app repo 自動更新 infra repo 的 image version。
4. infra repo 再決定是否要自動 deploy 到叢集。

這條鏈比「app repo 直接拿 cluster credentials 改叢集」更合理，因為 app repo 負責產出 artifact，infra repo 負責宣告 deployment state。

---

## 兩種落地方式

### 方案 A：自動開 PR 到 infra repo

流程如下：

1. app repo release 成功。
2. 自動在 infra repo 建一個 PR。
3. PR 只修改 Deployment image version。
4. 使用者確認後合併。
5. 再由人工或後續 automation deploy。

這條路最推薦，因為邊界清楚、可審核、風險低，也更接近真實團隊流程。

### 方案 B：直接觸發 infra repo workflow

流程如下：

1. app repo release 成功。
2. 觸發 infra repo workflow。
3. 由 infra repo workflow 自己更新版本、commit，甚至直接 apply 到 cluster。

這條路更自動，但邊界設計難度與風險都更高，較適合第二階段，而不是第一步。

---

## 目前最推薦的實踐模式

若只考慮 WeaMind 當前規模、更新頻率與擬真需求，我目前最推薦的模式是：

- app repo release 成功後，自動開 PR 到 infra repo。
- PR 只更新 Deployment image 的完整 release version。

這樣同時滿足幾件事：deploy version 清楚、repo 邊界清楚、保留人工審核，而且未來仍可自然升級到更完整的自動 deploy。
