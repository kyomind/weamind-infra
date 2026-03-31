# 2026-03-31 ConfigMap Secret Basics Outline

## 今日主題

把 WeaMind 目前的環境變數配置拆清楚：哪些值屬於 ConfigMap，哪些值屬於 Secret，Deployment 又是怎麼把兩者一起注入 Pod。

## 啟用條件

這份 lesson 以同日 prework 已完成為前提。

W3 已正式結束，但在今天重新確認後，W4 Day 1 先改走 prework，等外部預習完成後再正式進入這份 lesson。

## 這次要解的專案問題

1. 為什麼 WeaMind 要把環境變數拆成 ConfigMap 與 Secret，而不是全部塞進同一個檔案。
2. `envFrom` 與 `valueFrom` 在語意上差在哪裡，為什麼這個 repo 目前先使用 `envFrom`。
3. Secret 的 `data` 與 `stringData` 差在哪裡，為什麼這個專案的人手維護做法以 `stringData` 為主。
4. 看到 `POSTGRES_HOST`、`REDIS_URL`、`LINE_CHANNEL_SECRET` 這些 key 時，能不能說出它們在 WeaMind 架構裡應該放哪裡，以及理由是什麼。

## 這份 lesson 是否需要外部預習

- 需要。
- 原因：使用者已明確表示目前對 ConfigMap / Secret 還不熟，今天先補通用骨架會更穩。這份 lesson 保留給 prework 完成後的 repo 對照與驗收使用。

## 要對照的 repo 檔案

1. `manifests/configmap.yaml`
2. `manifests/deployment.yaml`
3. `.env.example`
4. `.privatedocs/secrets/secret.yaml`
5. `PROGRESS.md`

## 建議學習順序

1. 先完成同日 prework，補齊 ConfigMap / Secret、`data` / `stringData`、`envFrom` / `valueFrom` 的通用骨架。
2. 回到 `02-qa.md`，把 ConfigMap / Secret 的責任分工與 key 分類講清楚。
3. 接著對照 `deployment.yaml` 裡的 `envFrom`，釐清 Pod 是怎麼同時拿到兩種設定。
4. 再回到 Secret 的 `stringData` 與 `data`，把目前 repo 採用的寫法與原因收斂乾淨。
5. 需要補充的邊界先記進 `05-note.md`，特別是「今天不展開 Secret 更新後 Pod 是否自動吃到新值」與「今天不展開 UTF-8 Secret 踩坑」。
6. 最後回 `04-report.md`，收斂今天已經能講清楚的短版答題骨架。

## 今日 command 練習

今天先不建立 `03-command.md`。

原因：Day 1 的重點是把設定責任、欄位差異與注入方式講清楚；若後面需要補 `kubectl get configmap`、`kubectl describe pod` 或 `printenv` 類型的最小觀察，再視實際進度補 command drill。

## 文件分工

1. `01-outline.md`：規劃今天學習順序與邊界。
2. `02-qa.md`：記錄今天的專案問題、使用者回答摘要與 AI 修正。
3. `04-report.md`：收斂今天真正學到的內容。
4. `05-note.md`：記錄延伸邊界、暫時結論與之後可接到 W4 Day 2 的提醒。

## 這次要追問的 Why / How 題

1. 為什麼 `POSTGRES_HOST` 雖然和資料庫有關，但在這個 repo 裡仍然放 ConfigMap 而不是 Secret。
2. 為什麼 `envFrom` 在這個案例下比逐個 `valueFrom` 更簡潔，但也意味著什麼邊界。
3. 為什麼人手維護 Secret 時，`stringData` 通常比直接寫 `data` 更安全。
4. 為什麼同樣都是環境變數，是否敏感、是否常需要逐 key 控制、是否要避免 Git 曝露，會影響它最後該落在哪一層。

## 這份 lesson 的完成標準

1. 能用 WeaMind 的實際 key 解釋 ConfigMap 與 Secret 的責任差異。
2. 能指出 `deployment.yaml` 是怎麼把 ConfigMap 與 Secret 注入 Pod，並解釋為什麼這裡先用 `envFrom`。
3. 能說出 Secret 的 `data` 與 `stringData` 差異，並說明這個 repo 目前採用 `stringData` 的原因。
4. 能用 3 到 5 句話講出今天的最小答題稿，不把 Day 2 的 Secret 踩坑故事混進來。
