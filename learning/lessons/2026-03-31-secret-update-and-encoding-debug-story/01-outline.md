# 2026-03-31 Secret Update And Encoding Debug Story Outline

## 今日主題

把 WeaMind 的 Secret 引用方式、Secret 更新後對 Pod 的實際影響，以及 `invalid UTF-8` 這次踩坑的因果鏈收斂成可以口頭講清楚的 debug story。

## 這次要解的專案問題

1. WeaMind 的 Deployment 目前是怎麼把 Secret 注入 Pod 的，這種引用方式代表什麼行為邊界。
2. 為什麼更新 ConfigMap / Secret 後，既有 Pod 不一定會自動拿到新值。
3. WeaMind 這次 `CreateContainerError (invalid UTF-8)` 的症狀、根因、修法與後續規則是什麼。
4. 如果未來再發生 Secret 值更新但 app 行為沒變，第一輪應該怎麼判斷是「沒更新到資源」還是「Pod 沒重建」。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：W4 Day 1 已完成 ConfigMap / Secret 基礎骨架，今天主題主要是 WeaMind 專案內的引用方式、更新行為與真實 debug story，不是新的純概念主題。

## 要對照的 repo 檔案

1. `manifests/deployment.yaml`
2. `PROGRESS.md`
3. `.privatedocs/weamind/踩坑清單.md`
4. `.privatedocs/secrets/secret.yaml`
5. `docs/WeaMind Infra核心架構.md`

## 建議學習順序

1. 先從 `deployment.yaml` 看 WeaMind 目前用 `envFrom` 搭配 `secretRef` 的引用方式。
2. 再回答「為什麼 Secret 更新後，Pod 不一定自動吃到新值」，把資源更新與 Pod 重建拆成兩層。
3. 接著回到 `PROGRESS.md` 與踩坑清單，把 `invalid UTF-8` 的症狀、根因、修法收斂成一條完整故事。
4. 若需要，再用 `03-command.md` 補最小 command drill，驗證應該看 Secret、Deployment、Pod 還是 rollout。
5. 最後回 `04-report.md` 收斂成可口述的短版答題稿。

## 今日 command 練習

今天建立 `03-command.md`。

原因：這個主題很適合用最小 command drill 釐清「資源已更新」和「Pod 已吃到新值」不是同一件事，也適合順手把 `rollout restart` 放回正確位置。但流程仍維持 `QA -> command -> report`，先把概念骨架講清楚再進觀察。

## 文件分工

1. `01-outline.md`：規劃今天主題、邊界與順序。
2. `02-qa.md`：記錄今天的 repo-backed 問題、回答摘要與修正。
3. `03-command.md`：記錄 Secret 更新與 Pod 觀察的最小 command drill。
4. `04-report.md`：收斂今天真正學到的 debug story 與更新行為理解。
5. `05-note.md`：記錄延伸問題、暫時結論與之後可擴充的卡片。

## 這次要追問的 Why / How 題

1. 為什麼 `envFrom + secretRef` 這種引用方式，會讓 Secret 更新和既有 Pod 的環境變數值脫鉤。
2. 為什麼 `CreateContainerError (invalid UTF-8)` 這次幾乎看不到 app log，而要先回到 Pod / runtime 層。
3. 為什麼這個 repo 後來把規則收斂成「人工撰寫一律用 `stringData`」，而不是只說「下次小心 base64」。
4. 如果值更新了但 app 沒變，為什麼第一反應不該只是說 Kubernetes 壞掉，而要先拆成 Secret、Deployment、Pod 三層狀態。

## 這份 lesson 的完成標準

1. 能描述 WeaMind 目前引用 Secret 的主要方式，並說出這個方式的行為邊界。
2. 能用自己的話解釋為什麼 ConfigMap / Secret 更新後，既有 Pod 不一定自動拿到新值。
3. 能完整講出 `CreateContainerError (invalid UTF-8)` 的症狀、根因、修法與後續規則。
4. 能說出 Secret 更新後若 app 沒變，第一輪該如何排查與為何常會用到 `rollout restart`。
