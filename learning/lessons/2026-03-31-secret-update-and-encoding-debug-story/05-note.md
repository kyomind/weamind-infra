# 2026-03-31 Secret Update And Encoding Debug Story Note

## 學習注意事項

### 今日 lesson 邊界

- 今天主題是 WeaMind 內的 Secret 引用方式、更新影響與 `invalid UTF-8` debug story。
- 今天不展開 Secret at-rest 保護機制，例如 etcd encryption、RBAC 細節與外部 secret manager。
- 今天也不展開 volume mount 型 Secret 更新行為的完整比較，只先收斂 WeaMind 目前 `envFrom` 情境。

### 今天要特別觀察的 repo 事實

- `manifests/deployment.yaml` 目前用 `envFrom` 搭配 `secretRef`，不是逐 key `valueFrom`。
- `PROGRESS.md` 已正式記錄：人工撰寫 Secret 一律用 `stringData`，且曾發生 `CreateContainerError (invalid UTF-8)`。
- `.privatedocs/weamind/踩坑清單.md` 有保留更短版的問題、解法、根因，可用來壓成面試可講的 debug story。

### 今天不展開的項目

- Secret 不是加密，這題保留到後續補強或面試延伸。
- Ingress `tls` 與 Secret 的關係，不納入今天主線。

## Notes

<!-- lesson 進行中再補充延伸問答與暫時結論 -->

## Flashcards

<!-- lesson 收尾後再整理卡片 -->
