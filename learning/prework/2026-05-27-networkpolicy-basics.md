# 2026-05-27 NetworkPolicy Basics Prework

## Prework 內容

### 今日焦點

- 主題：Kubernetes NetworkPolicy 的最小概念骨架與 CKA 題型判讀
- 範圍：`podSelector`、`policyTypes`、`ingress` / `egress`、`from` / `to`、`ipBlock`、`namespaceSelector`、`podSelector`、default deny、allow list、selector 的 OR / AND 語意
- 目標：讓我能看懂與手寫一個基本 `NetworkPolicy`，並能在 CKA 題目中快速判斷「保護誰、允許誰、允許哪個方向、允許哪個 port」
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補 WeaMind repo 細節。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 這是 Phase 3 / CKA 衝刺期間的補強 prework，不是前九週正式主線的新進度。
- 請優先建立 CKA 會用到的操作與 YAML 判讀骨架，不要展開成完整 Kubernetes networking 或 CNI 產品比較。

### 今天一定要學會的最小骨架

1. `NetworkPolicy` 是 namespace-scoped 的 Pod 流量 allow list，用來限制被選到的 Pods 的 ingress、egress，或兩者。
2. `spec.podSelector` 回答的是「這條 policy 保護哪些 Pods」，不是「哪些 Pods 可以進來」。
3. `policyTypes` 回答的是「這條 policy 管哪個方向」；沒被 policy 管到的方向，不會因為這條 policy 自動被擋。
4. `ingress.from` 與 `egress.to` 裡的多個 peer entry 是 OR；同一個 peer entry 裡同時放 `namespaceSelector` 與 `podSelector` 時是 AND。
5. `ipBlock.cidr` 是允許範圍，`except` 是從已允許的範圍中再排除，不是額外允許。
6. 一旦某個 Pod 被某個方向的 NetworkPolicy 選到，該方向就進入 default deny，只允許 policy 明確放行的流量。
7. NetworkPolicy 通常是 stateful 的：只要允許連線發起方向，回應流量不需要另外寫一條反向 policy。
8. NetworkPolicy 是否真的生效取決於 CNI 是否支援；考 CKA 時重點放在物件語意與 YAML 寫法。

### 建議教學順序

1. 先用白話說明 NetworkPolicy 在 Kubernetes 裡解什麼問題，以及它和 Service、Ingress、CNI 的邊界。
2. 接著拆一份最小 YAML：`apiVersion`、`kind`、`metadata.namespace`、`spec.podSelector`、`policyTypes`、`ingress`、`egress`。
3. 用「保護誰、允許誰、方向、port」四個問題來教我讀題與寫 YAML。
4. 逐一解釋 `ipBlock`、`namespaceSelector`、`podSelector` 的用途與常見陷阱。
5. 特別練 OR / AND：
   - `from` 底下兩個 list item 代表任一來源符合即可。
   - 同一個 list item 同時有 `namespaceSelector` 和 `podSelector`，代表要同時符合 namespace 與 pod 條件。
6. 說明 default deny、allow list、空 selector、空 rules 的常見考題語意。
7. 最後用 2 到 3 題 CKA 風格小練習收斂，題目要包含 namespace label、pod label、port、ingress / egress 至少各一題。

### 額外要求

- 請特別回答下面這幾個我目前最在意的問題：
  1. `spec.podSelector` 和 `ingress.from[].podSelector` 到底差在哪裡？
  2. `namespaceSelector` 和 `podSelector` 分開寫成兩個 list item，與寫在同一個 list item，語意差在哪裡？
  3. `policyTypes: [Ingress]` 時，egress 會不會被擋？
  4. 一個 empty `podSelector: {}` 在 `spec`、`from`、`to` 裡分別可能代表什麼？
  5. default deny ingress 與 default deny egress 最小 YAML 各長什麼樣子？
  6. 為什麼 response traffic 通常不用另外放行？
- 請避免展開 Calico、Cilium、kube-proxy、iptables、eBPF 的產品或底層實作細節；只在需要提醒「CNI 要支援才會生效」時簡短帶過。
- 請用考試視角整理常見 YAML 片段，例如：
  - 只允許某 namespace 的某些 Pods 連進來。
  - 只允許某 app 對 DNS 或某外部 CIDR 做 egress。
  - 對 namespace 內所有 Pods 做 default deny。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 repo 內後，應該拿去做 CKA 練習或專案對照的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

#### 1. NetworkPolicy 在解什麼問題

Kubernetes 預設 Pod 之間大多可互相通訊。

NetworkPolicy 的作用是控制哪些 Pod 可以跟哪些 Pod 通訊。

它本質上是：

- allow list
- Pod 網路存取控制規則

它不是：

- Service discovery
- Load balancing
- Ingress routing

一句白話：

> Service 解決「怎麼找到 Pod」，NetworkPolicy 解決「找到後能不能連」。

#### 2. NetworkPolicy 的核心模型

今天最重要的骨架：

```text
NetworkPolicy =
  選出被保護 Pods
  +
  定義允許流量
```

以及：

```text
沒被允許的流量 = 被拒絕
```

它是 allow list 模型，不是 deny list。

#### 3. `spec.podSelector` 的真正意思

這是今天最重要觀念之一。

```yaml
spec:
  podSelector:
```

回答的問題永遠是：

```text
哪些 Pods 被保護？
```

不是：

```text
哪些 Pods 可以進來？
```

這是 NetworkPolicy 最容易混淆的地方。

#### 4. ingress 與 egress 的真正意思

ingress：

```text
誰可以進來找我
```

egress：

```text
我可以出去找誰
```

不管 ingress / egress：

```yaml
spec:
  podSelector:
```

永遠都是：

```text
被保護的 Pod
```

#### 5. `policyTypes` 的真正語意

`policyTypes` 是：

```text
這條 policy 管哪個方向
```

例如：

```yaml
policyTypes:
  - Ingress
```

代表：

- ingress 進入 allow list 模式
- egress 不受影響

今天建立的重要觀念：

```text
被某方向的 policy 選到
=
該方向進入 default deny
```

#### 6. default deny 的真正意思

例如：

```yaml
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

代表：

- namespace 內所有 Pods
- ingress 全部拒絕

因為已開始管理 ingress，但沒有任何 allow rules，所以形成：

```text
default deny ingress
```

同理：

```yaml
policyTypes:
  - Egress
```

可形成：

```text
default deny egress
```

#### 7. selector 的作用範圍

`spec.podSelector`：

```text
保護誰
```

`from[].podSelector`：

```text
誰被允許
```

單獨 `podSelector` 只匹配：

```text
同 namespace Pods
```

不是整個 cluster。

`namespaceSelector + podSelector` 代表：

```text
指定 namespace 裡的指定 Pods
```

例如：

```yaml
namespaceSelector:
  matchLabels:
    env: prod
podSelector:
  matchLabels:
    app: api
```

意思是：

```text
prod namespace 裡的 api Pods
```

#### 8. OR / AND 的真正語意

這是今天最容易卡的部分。

不同 list item，也就是不同 `-`，通常是 OR。

例如：

```yaml
from:
  - podSelector: ...
  - namespaceSelector: ...
```

代表：

```text
符合任一即可
```

同一個 item 裡多個 field，通常是 AND。

例如：

```yaml
- namespaceSelector: ...
  podSelector: ...
```

代表：

```text
兩者都要符合
```

`from` + `ports` 也是 AND。

例如：

```yaml
- from:
    ...
  ports:
    ...
```

意思是：

```text
符合來源 AND 符合 port
```

#### 9. YAML list/object 的結構感

今天一個重要突破不是單純學 NetworkPolicy，而是開始建立 YAML 的結構感。

尤其是：

- `-` = list item
- field = object 欄位
- 縮排決定語意

重要觀念：

```text
不同 list item 通常是 OR
同 object fields 通常是 AND
```

這其實是 Kubernetes YAML 的核心閱讀能力。

#### 10. `ipBlock` 的語意

例如：

```yaml
ipBlock:
  cidr: 10.0.0.0/16
  except:
    - 10.0.1.0/24
```

意思是：

```text
允許：
10.0.0.0/16

但排除：
10.0.1.0/24
```

重要觀念：

```text
except 不是額外允許
而是從允許範圍中扣掉
```

#### 11. empty selector `{}` 的語意

今天建立了非常重要的觀念：

```text
{} 的意思
取決於它在回答哪個問題
```

`spec.podSelector: {}`：

```text
namespace 內所有 Pods
```

`from.podSelector: {}`：

```text
namespace 內所有 Pods 都允許
```

`namespaceSelector: {}`：

```text
所有 namespace
```

#### 12. NetworkPolicy 是 stateful

NetworkPolicy 通常是 stateful。

意思是：

```text
允許連線發起
=
response traffic 自動允許
```

因此通常不用另外寫 response policy。

這點很像：

- AWS Security Group
- GCP Firewall

### 已能白話講清楚什麼

- NetworkPolicy 在 Kubernetes 裡解什麼問題。
- Service 與 NetworkPolicy 的差別。
- ingress / egress 的白話意義。
- `spec.podSelector` 是「保護誰」。
- `from` / `to` 是「允許誰」。
- `policyTypes` 的作用。
- default deny 的形成條件。
- OR / AND 的 YAML 語意。
- `namespaceSelector` 與 `podSelector` 的差異。
- `ipBlock` 與 `except` 的作用。
- 為什麼 response traffic 不需要另外放行。
- 為什麼 YAML 的縮排與 `-` 會直接影響語意。

### 目前還卡住什麼

#### 1. YAML list/object 的結構感仍不夠穩

目前已開始建立：

- `-` 是 list item
- field 是 object 欄位

但還需要更多實戰閱讀與手寫。

尤其：

```yaml
- from:
- ports:
```

與：

```yaml
- from:
    ...
  ports:
    ...
```

這種縮排差異仍需多看。

#### 2. selector scope 容易一時混亂

容易短暫混淆：

- 被保護的人
- 被允許的人

特別是：

```yaml
spec.podSelector
```

vs

```yaml
from.podSelector
```

但目前已能在提醒後快速修正。

#### 3. namespace scope 的腦內模型仍在建立中

已理解：

```text
NetworkPolicy namespace-scoped
=
只能保護自己 namespace 的 Pods
```

但 selector 的作用範圍與跨 namespace allow rule 仍需要更多題目強化。

### 今日最重要的觀念

1. `spec.podSelector` = 被保護的 Pods，永遠不是允許進來的人。
2. 被某方向 policy 管到 = 該方向進入 default deny。
3. 不同 list item = OR；同 object fields = AND。這是整個 NetworkPolicy YAML 的核心。
4. 單獨 `podSelector` = 同 namespace，不是全 cluster。
5. NetworkPolicy 是 allow list，不是 deny list。沒有被允許，就是拒絕。

### CKA 解題流程

之後看到任何 NetworkPolicy，先問四件事：

| 問題 | 看哪裡 |
| --- | --- |
| 保護誰？ | `spec.podSelector` |
| 哪個方向？ | `policyTypes` |
| 誰被允許？ | `from` / `to` |
| 哪些 port？ | `ports` |

這是今天建立的最重要解題框架。

### 帶回 repo 內對照的問題

1. 如果未來要保護 WeaMind 的 `line-bot` Pod，只能連 PostgreSQL、只能查 kube-dns、禁止亂連 Internet，那 egress policy 應該怎麼設計？
2. 如果未來有 monitoring namespace 與 app namespace，並且只允許 Prometheus 抓 metrics，那 `namespaceSelector + podSelector` 應該怎麼組合？

### 最後總結

今天最大的收穫其實不是背 NetworkPolicy YAML，而是開始建立 Kubernetes YAML 的語意結構感。

尤其是：

- list
- object
- selector scope
- OR / AND
- allow list 思維

這些能力未來會直接延伸到：

- RBAC
- Affinity
- Ingress
- Gateway API
- Helm values
- CRD

也就是說，今天學的不只是 NetworkPolicy，而是開始真正進入 Kubernetes YAML 的世界。
