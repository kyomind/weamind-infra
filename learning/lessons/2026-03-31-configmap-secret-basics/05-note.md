# 2026-03-31 ConfigMap Secret Basics Notes

## 學習注意事項

### 外部預習回帶重點

- 待補

### 今天進 lesson 前先記住的邊界

- 今天的 lesson 要等同日 prework 完成後再正式開始。
- Day 1 先專注在 ConfigMap / Secret 的責任分工、`envFrom` / `valueFrom`、`data` / `stringData`。
- 今天先不把 W4 Day 2 的 Secret 更新影響與 UTF-8 / base64 踩坑提前展開。

### 待驗證的 repo 對照點

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

<!-- 初始化時保持空白；等 lesson 過程中真的整理出卡片素材後再填。 -->
