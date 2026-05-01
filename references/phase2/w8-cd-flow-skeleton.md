# WeaMind W8 CD Flow Skeleton

這份文件不是現況證據，也不是已完成的 automation 規格。

它的角色是：在 W8 先留下第一版可驗收的 CD 最小流程骨架，明確說明 WeaMind 若要從現有 CI 與 image publishing 往前補 CD，第一版最合理的鏈路應先接到哪裡，並刻意停在哪裡。

## 這版 skeleton 要解的事

1. 讓正式 deploy source 從 `latest` 收斂到完整 release version。
2. 讓 infra repo 開始保存 deployment state，而不是只被動追 mutable tag。
3. 先把 app repo 與 infra repo 的責任邊界接起來，但不假裝 cluster apply 已自動化。

## 這版 skeleton 不做的事

1. 不直接讓 app repo 拿 cluster credentials 去改叢集。
2. 不在這一版就補 `kubectl apply`、`rollout restart` 或 cluster-side automation。
3. 不把 rollback、PR merge 後自動 deploy、或 GitOps controller 一次全部做完。

## 最小流程骨架

1. app repo 建立正式 release。
2. release workflow build 並 push 對應的 release image。
3. app repo 產出可對應的完整 release version，例如 `1.1.2`。
4. app repo 自動對 infra repo 發出一個 version update PR。
5. PR 內容只更新 Deployment image，將 `ghcr.io/kyomind/weamind:latest` 改成對應的完整 release version。
6. infra repo 保留這次 version update 的 Git 歷史與 review 軌跡。
7. 這版 skeleton 先停在 PR / merge decision，不把 deploy-to-cluster 視為已完成。

## 為什麼第一版要停在這裡

1. 這樣已經能把 deploy source、deployment state 與 repo 邊界講清楚。
2. 這樣已經比直接追 `latest` 更可追溯，也更容易回滾。
3. 這樣仍保留人工 review 與收斂空間，不會太早把風險藏進 automation。

## 這版 skeleton 驗收時至少要能回答

1. 正式 deploy source 為什麼是完整 release version，而不是 `latest`。
2. app repo 與 infra repo 在這條流程裡各自負責什麼。
3. 為什麼這一版先停在 infra repo version update / PR，而不是直接做 cluster deploy。

## 後續若要往下一版推進，第一個自然延伸

1. PR merge 後的 deploy 先保留為後續議題，屆時再決定要人工執行、半手動執行，還是補成 automation。
2. 若要補 deploy automation，先定義誰持有 cluster credentials，以及 deploy 行為要放在哪一層。
3. 若不要直接 deploy，也可以先把 infra repo 變成更明確的 deployment source of truth。
