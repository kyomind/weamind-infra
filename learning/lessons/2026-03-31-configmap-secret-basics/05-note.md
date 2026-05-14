# 2026-03-31 ConfigMap Secret Basics Notes
複習：2026-05-14
## 學習注意事項

### 今天進 lesson 前先記住的邊界

- 今天的 lesson 要等同日 prework 完成後再正式開始。
- Day 1 先專注在 ConfigMap / Secret 的責任分工、`envFrom` / `valueFrom`、`data` / `stringData`。
- 今天先不把 W4 Day 2 的 Secret 更新影響與 UTF-8 / base64 踩坑提前展開。

### Repo 對照文件與觀察點

- `manifests/configmap.yaml` 目前哪些 key 屬於非敏感部署設定。
- `.privatedocs/secrets/secret.yaml` 為什麼採用 `stringData`。
- `manifests/deployment.yaml` 裡的 `envFrom` 在這個 repo 扮演什麼角色。

### 暫時不在今天展開的點

- ConfigMap / Secret 更新後，既有 Pod 為什麼不一定自動拿到新值。
- Secret 的 UTF-8 / base64 踩坑故事。
- `kubectl` 指令觀察與 container 內 `printenv` 驗證。

## Notes

### 什麼情況比較適合用 `env + valueFrom`

- 不同 stage 本身不一定會逼你放棄 `envFrom`；若每個環境下 app 都仍需要整組設定，拆不同環境的 `ConfigMap` / `Secret` 再搭配 `envFrom` 依然合理。
- 真正較常需要 `env + valueFrom` 的情境，是某個 Pod 只需要同一份設定中的部分 key，不想整包注入。
- 另一個常見理由是要避免 key 撞名，或想把外部 key 映射成 container 內另一個環境變數名稱。
- 若團隊想讓 manifest 更明確表達「這個 container 真正依賴哪些值」，逐個列 `env` 也會比 `envFrom` 更清楚。
- 若只想從 `Secret` 取極少數敏感值，不想把整份 `Secret` 都 expose 給某個 Pod，`env + valueFrom` 也更合適。

### 為什麼還要有 `data`，而不是全部只用 `stringData`

- `stringData` 主要是給人手寫入時的便利欄位，它是 write-only 的輸入形式；送進 API server 後，最終仍會被轉成 `data`。
- `data` 的角色比較像 Secret 物件真正持有內容的標準表示法，底層是用 `base64` 來承載 bytes，不是為了加密，而是為了讓二進位或非純文字內容可以穩定放進 YAML / JSON / API 傳輸格式。
- 所以 `base64` 的意義不是安全，而是表示與傳輸格式一致性：Secret 底層可以承載任意 bytes，不只人眼可讀的明文字串。
- 對人來說，`stringData` 比較好寫；對 API 與儲存格式來說，`data` 才是統一落地的形式。兩者不是競爭關係，而是人類輸入介面與系統最終表示法的分工。
- 實務規則可以收斂成：人手維護優先用 `stringData`，機器穩定產生的值或系統輸出結果才直接看 `data`。

## Flashcards

- WeaMind 這個 repo 怎麼分 `ConfigMap` 和 `Secret`？ #DevOps #card
	- 關鍵不是看它像不像資料庫設定
	- 關鍵是值洩漏後會不會直接形成授權、控制或冒用風險
	- 一般部署設定放 `ConfigMap`，高風險憑證放 `Secret`

- 為什麼 `POSTGRES_HOST`、`POSTGRES_PORT`、`POSTGRES_USER` 可以在 `ConfigMap`？ #DevOps #card
	- 它們和資料庫連線有關，但通常不是最核心的授權憑證
	- 它們比較偏位置資訊、識別資訊或一般連線設定
	- 真正高風險的那段通常是密碼或 token

- `REDIS_URL` 什麼情況下可以放 `ConfigMap`，什麼情況下該改放 `Secret`？ #DevOps #card
	- 要看 URL 裡實際包了什麼，不是看名字像不像敏感值
	- 像 `redis://host:6379/0` 這種沒有密碼的 URL，仍可視為一般設定
	- 若 URL 內含密碼，例如 `redis://:password@host:6379/0`，就應改進 `Secret`

- 為什麼 WeaMind 目前用 `envFrom` 是合理的？ #DevOps #card
	- 因為這個 app 啟動時本來就需要整份 `ConfigMap` 與 `Secret` 裡的大部分 key
	- 這種情境下整包匯入比較簡潔，也比較不容易漏設定
	- 關鍵不是 `envFrom` 比較高級，而是這個 Pod 剛好真的需要整組設定

- 什麼情況比較適合改用 `env + valueFrom`？ #DevOps #card
	- 當 Pod 只需要部分 key，不想整包注入
	- 當你要避免 key 撞名，或想把外部 key 映射成另一個變數名稱
	- 當你想降低暴露面，或更明確表達某個 container 真正依賴哪些值

- 新增環境變數時，應先判斷什麼？ #DevOps #card
	- 先判斷它該進 `ConfigMap` 還是 `Secret`
	- 再判斷它該跟現有設定一起用 `envFrom`，還是改用 `env + valueFrom`
	- 資源分類和注入方式是兩層判斷，不應混成同一題

- `stringData` 和 `data` 的實務差別是什麼？ #DevOps #card
	- `stringData` 是給人手寫入的便利欄位，接受明文字串
	- `data` 是 Secret 最終落地的標準表示法，內容要用 `base64` 表示
	- 對人手維護來說，優先用 `stringData` 會更穩

- 為什麼 WeaMind 會收斂出「人工撰寫一律使用 `stringData`」？ #DevOps #card
	- 因為這個專案曾錯用 `data` 與格式，導致 `CreateContainerError (invalid UTF-8)`
	- `stringData` 讓 Kubernetes 自動處理轉換，能減少手動 `base64`、換行與編碼錯誤
	- 它不是比較安全，而是更適合人手維護

- 為什麼 Kubernetes 還要有 `data`，不能全部只用 `stringData`？ #DevOps #card
	- `stringData` 比較像人類友善的輸入介面，送進 API server 後仍會轉成 `data`
	- `data` 用 `base64` 承載 bytes，不是為了加密，而是為了穩定表示與傳輸任意內容
	- 兩者是分工關係：`stringData` 解決怎麼寫，`data` 解決怎麼存
