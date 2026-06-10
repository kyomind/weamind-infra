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

## ImagePullBackOff 先查 image 拼寫

Events 看到 `Failed to pull image "xxx": not found` 時，第一反應檢查 image 名稱和 tag 有沒有 typo。

常見：`nginx:ltest`（少打 a）、`nginx:latst`（少打 e）。

## Pod image 是少數可變欄位

`spec.containers[*].image` 可以直接改，不需要 delete-recreate：

```bash
k set image pod/nginx-pod nginx-container=nginx:latest
```

或用 `k edit pod/nginx-pod` 改 image 欄位，存檔後立即生效。

## Pod 可變欄位清單

| 可變欄位 | 說明 |
|----------|------|
| `spec.containers[*].image` | 最常用 |
| `spec.activeDeadlineSeconds` | 少見 |
| `metadata.labels` / `annotations` | metadata 層，不影響 spec |
| `spec.tolerations` | 只能加，不能改已有的 |

其他 spec（`command`、`args`、`resources`、`ports`、`volumeMounts`、`env`）全部不可變，改了 API server 會拒絕。

## 修改 Pod 的三種方式

| 方式 | 速度 | 適用場景 |
|------|------|----------|
| `k set image` | ⚡ 最快 | 只改 image |
| `k edit` | 🔧 快 | 改 image 或其他可變欄位 |
| export → delete → recreate | 🐢 慢 | 改不可變欄位，沒得選 |

能 `set image` 就不 `edit`，能 `edit` 就不 delete-recreate——考試省秒數。

## Pod spec 預設不可變，image 是例外

心智模型：把 Pod spec 當「幾乎凍結」，只有 `image` 是那個重要的例外。

遇到要改 Pod 時，先判斷欄位可不可變，再決定用哪種方式。

## Troubleshooting 起手式

| 資源 | 起手指令 |
|------|----------|
| Pod | `get pod` → `describe pod` → `logs` |
| Deployment | `get deploy` → `describe deploy` → `get rs -l app=xxx` |
| Service | `get svc` → `get ep`（看有沒有抓到 Pod IP）|
| Node | `get node` → `describe node` |
| 通用 | `k get events --sort-by='.lastTimestamp'` |

Deployment 問題通常是底層 Pod 或 RS 的問題，往下追。Service 不通先看 endpoints。

## apply 報 NotFound 先看缺什麼資源

`namespaces "xxx" not found` → 建 namespace，不要改 YAML 去配合環境。

```bash
k create ns nginx-ns
```

同理適用於 SA、ConfigMap、Secret 等依賴資源——缺什麼補什麼，別改 YAML 去遷就現有環境。

## Troubleshooting 題考的是診斷速度

題目本身可能很簡單（缺個 namespace 而已），重點是快速定位問題，不是解題難度。

## Pending Pod + Pending PVC = 兩層問題

看到 Pod Pending 且引用的 PVC 也 Pending，代表問題在更底層。

修復順序：先解決 PVC（讓它 Bound），再回頭修 Pod。

## PVC 正常 vs 異常狀態對照

| 欄位 | Pending（異常） | Bound（正常） |
|------|-----------------|---------------|
| STATUS | Pending | Bound |
| VOLUME | （空） | 綁定的 PV 名稱 |
| CAPACITY | （空） | PV 提供的容量 |
| ACCESS MODES | （空） | RWO / RWX / ROX |

這些欄位全空 = PVC 找不到任何符合條件的 PV 可以綁。

## PVC Pending + PV Available = 匹配條件對不上

PV 明明 Available 但 PVC 綁不上，逐一比對這三項：

1. `storageClassName` — 最常見的坑
2. `accessModes` — 必須完全一致
3. `capacity` — PV 容量必須 >= PVC 請求

找到不一致的就是問題所在。

## storageClassName 的兩種角色

| 場景 | SC 物件需要存在？ | storageClassName 的作用 |
|------|-------------------|-------------------------|
| Static provisioning（手動建 PV） | ❌ | 純字串標籤，寫 `banana` 都行，只要 PV 和 PVC 一致 |
| Dynamic provisioning（自動建 PV） | ✅ | 必須指向真實的 SC，靠 provisioner 動態建立 PV |

手動建 PV 時，storageClassName 只是「暗號」，不需要真的有那個 SC 物件。

## Troubleshooting 傾向改消費端

Troubleshooting 題的常見設計：基礎設施沒問題，使用端寫錯了。

- PV vs PVC 對不上 → 通常改 PVC（消費端）
- ConfigMap/Secret 名稱不符 → 通常改 Pod/Deployment 的引用

不是絕對，但機率很高。題目有提示如 "a PV has been created for you" 就更確定了。

## Troubleshooting 缺資源時哪些能直接建

**可以直接建（空殼）：** Namespace、ServiceAccount

**有內容，不能憑空建：** ConfigMap、Secret、PV

ConfigMap、Secret、PV 有複雜內容，Troubleshooting 題如果缺這些，題目會給線索（告訴你內容，或有個名字打錯的版本可以參考），不會讓你憑空生。

## Troubleshooting = 追因果鏈

每一層的 "why" 都用 `describe` 或 `get` 來回答：

```
Pod Pending
 └─ why? → PVC not found
     └─ why? → 名稱不符 + PVC 本身也 Pending
         └─ why? → storageClassName 對不上 PV
             └─ 修 PVC → Bound → 修 Pod → Running
```

一直問 why 直到找到可以動手修的根因。
