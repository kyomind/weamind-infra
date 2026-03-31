# 2026-03-31 ConfigMap Secret Basics Report

## 今日主題

用 WeaMind 的實際設定檔與 Deployment 注入方式，釐清 ConfigMap、Secret、`envFrom`、`data`、`stringData` 之間的責任分工。

## 狀態

本日 lesson 已完成第一輪 QA 收斂，尚未進入 command drill。

## QA 收斂了什麼

- 已用 WeaMind 的實際 key 釐清 `ConfigMap` 與 `Secret` 的責任差異：不是看值是否和資料庫有關，而是看洩漏後會不會直接形成授權或操作風險。
- 已對照 `deployment.yaml` 釐清 `envFrom` 的語意：WeaMind 目前用 `envFrom` 合理，因為 app 啟動時本來就需要整組設定；`env + valueFrom` 則適合在只需要部分 key、要避免 key 撞名或要降低暴露面時使用。
- 已把 Secret 的 `stringData` / `data` 差異對回真實踩坑：曾因錯用 `data` 與格式造成 `CreateContainerError (invalid UTF-8)`，因此收斂出「人工撰寫一律使用 `stringData`」的規則。
- 已把新增環境變數的判斷拆成兩層：先判斷該放 `ConfigMap` 還是 `Secret`，再判斷該用 `envFrom` 還是 `env + valueFrom` 注入。

## 使用者原本卡住什麼

- 一開始還不確定今天是否需要先做 prework，且對 `ConfigMap` / `Secret` 的通用概念骨架不夠穩。
- 對 `data` / `stringData` 的差別有實務印象，但對 `invalid UTF-8` 的底層原因與 `base64` 的角色還沒有完整語言化。
- 對 `envFrom` 與 `env + valueFrom` 的界線有直覺，但還沒完全拆清楚「資源分類」和「注入方式」其實是兩層判斷。

## 今日真正留下來的核心收穫

- `ConfigMap` / `Secret` 的分類關鍵不是名詞表面，而是風險等級與可被直接利用的程度。
- `stringData` 不是更安全，而是更適合人手維護；`data` 則是系統最終落地的標準表示法。
- `envFrom` 適合整組設定都需要的情境；`env + valueFrom` 適合部分依賴、命名控制與最小暴露面。

## 學完後已能講清楚什麼

- 能用 WeaMind 的實際 key 說出哪些值應放 `ConfigMap`、哪些應放 `Secret`，以及原因。
- 能解釋 WeaMind 為什麼目前先用 `envFrom`，以及什麼情況下會改考慮 `env + valueFrom`。
- 能把 Secret 的 `stringData` / `data` 差別和 WeaMind 當時的 `CreateContainerError (invalid UTF-8)` 連成一條完整敘述。

## 仍待補強什麼

- Secret 是否真的安全，例如 etcd encryption、RBAC 與 namespace 邊界。
- ConfigMap / Secret 更新後，既有 Pod 是否會自動拿到新值。
- 若未來 `REDIS_URL` 或其他連線字串內含密碼，分類規則要如何跟著調整。

## 下一步

- 進入 W4 Day 2，接 Secret 更新影響與 UTF-8 / 編碼踩坑的更完整 debug 故事。
