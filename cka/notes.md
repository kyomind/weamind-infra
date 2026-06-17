# CKA Practice Notes

## DaemonSet 問題診斷方向

DaemonSet 考題幾乎都是排程問題，重點永遠在 node 端（taint/label），不在 DaemonSet 本身。

## grep YAML 多行結構要帶 -A

`grep -i tai` 只抓到 `taints:` 那行，value 在下一行會漏掉。標準做法：

```bash
grep -iA5 taint
```

## 查 taint 標準指令

```bash
k describe node <name> | grep -iA5 Taint
```

## Taint vs Label 定位

| 機制 | 用途 | 粒度 |
|------|------|------|
| Taint | 禁令、排除 | 粗，數量少 |
| Label | 標籤、選擇 | 細，數量多 |

排程精細控制靠 label + nodeAffinity，不靠 taint。

## toleration 沒有 imperative 指令

只能 `k edit` 或改 YAML apply。nodeAffinity、volumeMounts 也一樣沒有對應的 kubectl 指令。

## toleration 層級記法

`spec.template.spec.tolerations`，和 containers 同層。

Controller 類資源（Deployment / DaemonSet / StatefulSet）的 Pod 設定都在 `spec.template.spec` 下。

## Taint 沒 value 時用 Exists

Taint 格式 `key=value:effect`，value 可選。沒有 `=` 代表沒 value，toleration 用 `operator: Exists` 最乾淨：

```yaml
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
```

## Vim 多行縮排

`V` 選行 → `j`/`k` 或方向鍵擴選 → `>` 縮排 → `.` 重複。

按 `>` 後 Vim 會退出 Visual 模式回到 Normal 模式，此時再按單個 `>` 沒反應（在等 motion）。`.` 的好處是不用重選，直接對同一範圍再縮一層。

## node 加 / 移除 taint 語法

```bash
# 加 taint
kubectl taint nodes node1 key1=value1:NoSchedule

# 移除 taint（結尾加 -）
kubectl taint nodes node1 key1=value1:NoSchedule-
```

## etcdctl 輸出走 stderr

要用 `&>` 才能捕捉完整輸出，單用 `>` 只抓 stdout 會是空的。

```bash
etcdctl snapshot save /opt/backup.db &> backup.txt
```

## Node NotReady + NodeStatusUnknown = kubelet

`describe node`，Conditions 全顯示 `Kubelet stopped posting node status` 時，直接：

```bash
systemctl restart kubelet
```

## Conditions vs Events 使用時機

| 面向 | Conditions | Events |
|------|------------|--------|
| 本質 | 持續性的狀態快照 | 一次性的事件紀錄 |
| 回答問題 | 「現在怎麼了？」 | 「剛才發生什麼？」 |
| 適用層級 | Node | Pod |
| 典型內容 | Ready、MemoryPressure | Scheduled、Pulling、FailedMount |

Node 問題看 Conditions（心跳消失會自動變 Unknown）；Pod 問題看 Events（動作失敗才有紀錄）。

## etcd 沒帶 TLS 會 hang 不報錯

超過 2 秒沒回應就是缺證書參數，直接 `Ctrl+C` 檢查 `--cacert`、`--cert`、`--key` 有沒有帶齊。

## &> 是覆寫模式

忘記導向不用刪檔，重跑加 `&>` 就會覆蓋。`&>>` 才是追加。

## etcd backup 流程口訣

1. 修 kubelet（如果 Node NotReady）
2. 確認 etcd pod 活著
3. `grep -- "--"` 從 etcd pod yaml 拿 TLS 路徑
4. `snapshot save` + `&>` 一次搞定備份和輸出存檔

## 每題做完要自己驗證

KillerCoda 有 checker 但真考試沒有。養成習慣：做完 → 驗證 → 下一題。沒驗證的答案不算完成。

## NetworkPolicy ingress.from 是 OR 關係

每一條 `- podSelector` 都是獨立放行規則，彼此是 OR。要縮減存取就砍條目，不是改條件。

## PVC Pending 診斷與 immutable 限制

診斷三要素：`storageClassName` 對不對、`accessModes` 符不符、capacity 夠不夠。

PVC spec 幾乎全部 immutable：

| 欄位 | 能否 edit | 備註 |
|------|-----------|------|
| `accessModes` | ✗ | immutable |
| `resources.requests.storage` | ⚠️ 只能擴 | 唯一可變欄位，但只能往上不能縮 |

改 accessModes 或縮容 → delete 重建。

## RBAC 排查順序

Role 內容 → RoleBinding 接線 → Namespace 一致。

SA 驗證包含在 RoleBinding 的 subjects 裡，不用獨立查。

## 為什麼先查 Role

Role 出錯面最大：`apiGroups`、`resources`、`verbs` 三個欄位都可能寫錯或漏寫。RoleBinding 只是接線，SA 更簡單。

## Role 可以直接 k edit

Role 是 mutable 的，`k edit role <name>` 改完即生效，不用 delete 重建。跟 PVC 不一樣。

## YAML 多值要一行一個 - item

逗號分隔是字串不是陣列，Kubernetes 會找不到資源。

```yaml
# ✓ 正確
resources:
- pods
- services

# ✗ 錯誤（這是一個字串 "pods, services"）
resources:
- pods, services
```

## RBAC 驗證指令

```bash
# 單一權限檢查
k auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<name>

# 範例
k auth can-i create pods --as=system:serviceaccount:default:dev-sa

# 列出全部權限
k auth can-i --list --as=system:serviceaccount:default:dev-sa
```

