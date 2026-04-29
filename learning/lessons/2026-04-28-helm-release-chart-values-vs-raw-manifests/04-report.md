# 2026-04-28 Helm Release Chart Values vs Raw Manifests Report

## 今日收斂

- 今天真正完成的，不是再做一次 Helm 安裝，而是把 W7 已經用過的 Helm 經驗，收斂成一版能對回 repo、也能拿去面試回答的口頭模型。
- 我已經能把 Helm 和 raw manifests 的差別壓成三層：Helm 多了 template、values 與 release state；raw manifests 則比較直接、透明，但不自帶這些抽象與版本管理能力。
- 我也已經把幾個最容易混的詞切開：chart 不等於 chart repo，release 不等於 chart，values 也不等於任意 yaml merge。

## Helm 在 W7 到底做了什麼

- W7 那次不是直接拿 repo 裡的 raw YAML 去套，而是從遠端 chart repo 取用 `kube-prometheus-stack` chart，讓 Helm 以預設 values 或少量設定 render 成 Kubernetes manifests，再送進 cluster。
- 那次經驗最重要的收穫，不只是「會下 `helm install`」，而是確認 Helm 真正多做了一層：先 render templates、再建立資源、再把結果記成 release revision。
- 這也解釋了為什麼當時 infra repo 沒有多出任何新的 YAML 檔案：render 後的結果不是回寫 Git，而是送進 cluster；release 對應的 manifest 與 revision 則由 Helm 存在 cluster 內。

## WeaMind 哪些欄位適合 values

- 對回目前 repo，最典型的 values 候選是 `image tag`、`replicaCount`、以及 `ingress.host` / `BASE_URL` 這類環境差異明顯的欄位。
- `PROCESSING_LOCK_TTL_SECONDS` 這種應用程式行為參數也可以做成 values，但比較像次高價值候選；若只選最常見、最典型的前三個，通常還是版本、容量與 domain / URL 會更前面。
- 反過來說，不應輕易暴露成 values 的，主要是兩類：Secret 內的敏感值，以及 selector / labels / 固定命名這類結構性邊界欄位。這也剛好證明 values 不是任意 yaml merge，而是只能填進 chart template 預先留好的入口。

## Helm rollback 和 rollout undo 的差異

- `kubectl rollout undo` 回退的是 Deployment 這類 rollout controller 的歷史，核心是在把 Pod template 對回前一版，然後由 Deployment / ReplicaSet 控制鏈重新長出對應 Pods。
- Helm rollback 則是回退整個 release revision；若某個資源屬於這個 release，而且存在於該 revision 的 manifest 裡，它就屬於 Helm 的回退範圍。
- 若某次 revision 實際只改了 Deployment，那 Helm rollback 的體感可能很像 `rollout undo`；但概念上 Helm 仍是在把整個 release 對回某個 revision 的完整 manifest snapshot，而不是只反向操作最近那次 diff。

## 接到 W8 Day 2 的銜接點

- W8 Day 1 已把 Helm 的核心模型講穩，下一步可以直接進 W8 Day 2：把 Helm 放回 WeaMind repo 的實際部署脈絡，回答「哪些欄位值得參數化、哪些成本不值得現在引進」。
- W8 Day 2 的重點不再是補 Helm 基本名詞，而是把今天建立的模型對回 raw manifests / Helm / Kustomize 的實際邊界。
- 若後面要談 CD，今天這份 lesson 最重要的前置價值是：先把 release、values、rollback 這些 Helm 語彙講準，避免 Day 3 / Day 4 把 CD 與 Helm 混成同一層抽象口號。
