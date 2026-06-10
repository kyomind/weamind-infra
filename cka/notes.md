# CKA Practice Notes

## resourceVersion 衝突

`apply` 報 "the object has been modified; please apply your changes to the latest version and try again" = 版本號不符。

原因：導出後 apply 成功，server 端 `resourceVersion` 就從 100 變 101；你手上的 YAML 還是 100，再 apply 就衝突。

解法：
- 每次 apply 成功後重新導出
- 或直接用 `k edit`（不會有版本衝突）
- 或刪掉 `resourceVersion` 欄位再 apply

## resourceVersion vs Revision

| 概念 | 層級 | 用途 |
|------|------|------|
| `resourceVersion` | **所有** K8s 資源 | API server 的樂觀鎖，每次修改就遞增 |
| Revision (`rollout history`) | Deployment 專屬 | 記錄 Pod template 變更歷史，用於 rollback |

兩者無關。任何資源都可能遇到 `resourceVersion` 衝突，不是 Deployment 特有的。

## 導出 YAML 後要刪的欄位

```yaml
metadata:
  resourceVersion: "12345"  # 必刪，版本衝突的元兇
  uid: "xxx"                # 選刪，留著會被忽略
  creationTimestamp: "..."  # 選刪，留著會被忽略
  generation: 1             # 選刪，留著會被覆蓋
status:                     # 選刪，read-only
  ...
```

考試時間緊迫，只刪 `resourceVersion` 就能 apply 成功。

## ConfigMap/Secret not found 先 get 確認

Events 看到 `FailedMount: configmap "nginx-configuration" not found` 時，先確認實際存在的名稱：

```bash
k get cm
```

比對實際名稱和 Deployment 裡引用的名稱，確認是誰寫錯再改。

## 一份導出只能成功 apply 一次

導出 → 改 → apply 成功後，YAML 裡的 `resourceVersion` 就過時了。

要再改就兩條路：
1. 重新 `k get -o yaml > file.yaml` 導出
2. 直接 `k edit`（改 live 資源，不經過本地檔案）

## 刪掉 resourceVersion 再 apply

沒有 `resourceVersion` 欄位時，API server 不比對版本，直接以你的 YAML 為準覆蓋。

這招可以讓一份 YAML 重複 apply 不衝突，但要注意可能蓋掉別人的修改。

## Troubleshooting 是迴圈

```
get → describe → fix → get → ...
```

一個資源可能有多個問題，修完一個要重新 `get` 確認狀態，沒變 Running 就繼續 `describe` 找下一個錯誤，直到 `1/1 Running`。

## Init container 狀態速查

| STATUS | 意思 |
|--------|------|
| `Init:0/1` | 卡在 init container 階段（還沒跑完或跑不起來）|
| `Init:RunContainerError` | init container 執行失敗 |
| `Init:CrashLoopBackOff` | init container 反覆 crash |
| `PodInitializing` | init 跑完了，主容器正在啟動 |

Init 階段的問題一樣用 `describe` 看 Events 找原因。
