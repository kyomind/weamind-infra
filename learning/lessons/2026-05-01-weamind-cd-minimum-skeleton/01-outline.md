# 2026-05-01 WeaMind CD Minimum Skeleton Outline

## 今日主題

- 以 WeaMind 現有 release 與 infra 邊界為基礎，做出第一版可驗收的 CD 最小 skeleton。

## 今日套用的 lesson mode

- implement-heavy mode

## 為什麼今天要套用 implement-heavy mode

1. 今天的驗收重點不是只講清楚概念，而是要把昨天收斂的方案邊界落成可對 repo 的 skeleton。
2. 今天需要留下實際變更、驗證訊號與回退點，因此主體應放在 implementation-first 的流程。

## 這次要解的專案問題

1. WeaMind 第一版 CD 應該把哪一段自動化先接起來，才不會破壞 app repo 與 infra repo 的責任邊界。
2. infra repo 要如何從固定追 `latest`，改成能記錄正式 deploy version 的 deployment state。
3. 今天做出的 skeleton 到底解了什麼，還有哪些部署與 rollback 邊界刻意沒做。

## 這份 lesson 是否需要外部預習

- 不需要
- 原因：W8 D3 已完成 deploy source、repo 邊界與最小自動化鏈路的設計收斂，今天主要是把既有決策落成 repo-backed skeleton。

## 要對照的 repo 檔案

1. `references/phase2/w8-cd-minimum-spec.md`
2. `references/weamind-ci-to-k8s-flow.md`
3. `docs/WeaMind實作CD討論與實踐.md`
4. `manifests/deployment.yaml`

## 今日實作邊界

1. 第一優先是讓 infra repo 的 deployment state 能明確追固定 release version，不再停在 `latest`。
2. 今天只做到 repo-backed skeleton 或最小可落地實作，不把 app repo 直接拿 cluster credentials 去改叢集。
3. deploy-to-cluster 的 infra-side automation、GitHub token 細節、PR merge 後自動 apply 與完整 rollback 流程，只收斂邊界，不在今天一次做完。

## 驗收訊號與回退點

### 驗收訊號

1. repo 內能看到一版清楚的最小 CD skeleton，且它明確以完整 release version 作為 deploy source。
2. 能指出這版 skeleton 目前停在哪一跳，以及它和完整 CD 之間還差什麼。

### 回退點

1. 若今天無法穩定做到真正可執行的 automation，至少保留清楚的 skeleton 與 implementation note，不假裝已完成 deploy automation。
2. 若某個變更會把 repo 邊界拉壞或引入需要額外秘密管理的耦合，回退到只保留 version state 與流程骨架。

## 建議學習順序

1. 先用 `06-implementation.md` 做主要實作與每個 step 的閉環記錄。
2. 若 `06` 過程中出現 implementation-specific 補充觀察或設計取捨，同步整理到 `05-note.md`。
3. 只有在實作主體完成後，再回 `02-qa.md` 做 post-implementation QA 與定位收斂。
4. 若需要最小操作驗證，直接把證據留在 `06-implementation.md` 的對應 step。
5. 過程中的一般 lesson 延伸問答與實作補充都整理進 `05-note.md`。
6. 最後回 `04-report.md` 做整體收斂。

## 文件分工

1. `01-outline.md`：宣告今天套用 implement-heavy mode，並寫清楚流程、邊界、驗收與回退點。
2. `02-qa.md`：記錄 post-implementation QA 的短版定位題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的內容。
4. `05-note.md`：記錄一般 lesson 延伸問答、實作補充、暫時結論與卡片整理。
5. `06-implementation.md`：記錄今天的主要實作 step，包含必要的驗證證據。

## 這份 lesson 的完成標準

1. 完成一版可對 repo、可口述的 WeaMind CD 最小 skeleton，並明確指出 deploy source 與 repo 邊界。
2. 至少留下一段可驗收的 implementation 證據，能說明今天實際改了什麼、驗了什麼、結果如何。
3. 能用自己的話講清楚這版做法解了什麼、沒解什麼，以及 rollback / release 邊界。
