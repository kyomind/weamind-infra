# 2026-04-29 Helm In WeaMind Boundaries and Costs Report

## 今日收斂

- 今天真正完成的，不是決定「WeaMind 一定要不要用 Helm」，而是把 Helm 放回 repo 現況與 W8 的 CD 主問題裡，講清楚它真正解什麼、不先解什麼。
- 我已經能把今天的主線壓成一句話：**WeaMind 目前不缺基本部署能力，真正缺的是 deployment version、repo boundary 與 CD state；Helm 是可能的加值工具，但不是今天的前提條件。**

## Helm 放回 WeaMind 後真正多了什麼

- 若 WeaMind 改用 Helm，`Deployment`、`Service`、`Ingress`、`ConfigMap`、`Secret` 這些 Kubernetes 資源本身不會消失；真正多出來的是 template、values 與 release state 這一層。
- 也就是說，Helm 並不是把 Kubernetes 換掉，而是在 raw manifests 上多包了一層 render 與 release 管理能力。
- 對 repo 使用者來說，差異會變成：原本直接看的靜態 YAML，未來可能變成 chart templates 加 values，部署後再由 Helm 維護 release history、revision 與 rollback 邊界。

## Helm、raw manifests、Kustomize 的邊界

- raw manifests 在 WeaMind 現況下已經足夠部署完整服務，而且 Git 本身也能追蹤各個 manifest 的變更；這一層目前沒有明顯缺口。
- Helm 會開始有明顯價值的時機，是當多個資源需要被當成同一個 release 單位管理，或同一套部署需要反覆用不同 values render，並且真的想使用 release history / rollback 這類能力時。
- Kustomize 則比較適合少量環境差異或 patch。若需求只是調整 host、replicas、annotations、image tag 這類既有 YAML 上的小幅差異，Kustomize 通常會比 Helm 更輕。

## 為什麼現在不必急著全 Helm 化

- 因為 W8 眼前真正的問題不是模板化，而是從 app repo release image 到 infra repo deployment state，再到 cluster update 的最後一跳還沒有正式接起來。
- Helm 可以提供 release-level 管理，但它不等於 CD 本身，也不能替代 deploy source、repo boundary 與 version state 這些決策。
- 若現在直接全 repo Helm 化，反而會先引入 template 抽象、review 複雜度、release state 管理與新操作路徑成本，卻還沒先解決 W8 最急的主問題。

## 接到 W8 Day 3 的銜接點

- Day 3 應優先收斂 WeaMind 的 deploy source、infra repo 要保存哪個版本狀態，以及 app repo 與 infra repo 各自負責什麼。
- 第一版最穩的方向仍是：app repo release 成功後，自動更新 infra repo 的 image version，再由 infra repo 決定是否自動 deploy。
- 若後面還要重新討論 Helm，應該把它放在「CD 做起來之後，是否還需要額外的 release-level 管理能力」這個脈絡，而不是先假設 Helm 是 CD 的必要條件。
