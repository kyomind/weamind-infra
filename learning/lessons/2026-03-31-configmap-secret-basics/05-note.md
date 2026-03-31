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

<!-- 初始化時保持空白；等 lesson 過程中真的出現延伸問答或暫時結論後再填。 -->

## Flashcards

<!-- 初始化時保持空白；等 lesson 過程中真的整理出卡片素材後再填。 -->
