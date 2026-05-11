# Review Notes 範例

這份檔案收錄簡潔風格的筆記範例，供 AI 寫入 `notes.md` 時參照。

---

## CPU 資源單位 `250m` 怎麼理解

`m` 是 millicores，千分之一個 CPU 核心。

- `1000m` = 1 個完整 CPU 核心
- `250m` = 0.25 核 = 1/4 核
- `100m` = 0.1 核 = 10% CPU

所以 `requests.cpu: 250m` 代表這個 container 至少要保證能用到 1/4 核的 CPU 時間。

一句話記法：`m` 是毫核，`1000m = 1 核`，`250m` 就是 1/4 核。

---

## CreateContainerError 和 CrashLoopBackOff 差在哪

兩者卡住的階段不同：

- `CreateContainerError`：container 還沒成功建立。優先查 ConfigMap / Secret 引用、volume 掛載、env 設定是否有誤。WeaMind 有過 `invalid UTF-8` 案例，根因是 Secret 使用方式錯誤
- `CrashLoopBackOff`：container 建立成功但 app 啟動後反覆 crash。優先查 app logs、啟動指令、健康檢查

一句話記法：CreateContainerError 是「還沒生出來」，CrashLoopBackOff 是「生出來但一直掛」。

---

## `maxSurge` 和 `maxUnavailable` 各自在限制什麼

這兩個值一個管「可以多多少」，另一個管「可以少多少」：

- `maxSurge`：rolling update 時，最多能超出目標副本數多少新 Pod。用資源換更平滑的交接
- `maxUnavailable`：更新過程中，最多可暫時少掉多少可用 Pod。用來限制服務可用性的下降幅度

一句話記法：`maxSurge` 是先多開幾個新的，`maxUnavailable` 是允許先少掉幾個舊的。

---

## Blue-Green 和 Canary 不是 Deployment 原生策略嗎？

不是。Deployment 的 `spec.strategy.type` 只有 `RollingUpdate` 和 `Recreate` 兩種。

Blue-Green 和 Canary 是更上層的部署模式，需要額外工具或手動編排，例如：

- 手動管理兩個 Deployment + Service 切換
- Argo Rollouts、Flagger 等 CD 工具
- Service Mesh 做流量分流

一句話記法：Deployment 原生只有兩種策略；Blue-Green / Canary 是更高層的模式，Kubernetes 不直接提供。

---

## 有 L7 Load Balancer 嗎？什麼時候用？

有，而且很常見，不是反模式。

L7 LB 的例子：AWS ALB、GCP HTTP(S) Load Balancer、Cloudflare、Nginx、HAProxy。

什麼時候用 L7 LB：

- 想在 LB 層就做 host-based 或 path-based routing
- 想在 LB 層終止 TLS（SSL offloading）
- 想在 LB 層做 WAF、rate limiting、認證
- 用雲端託管服務，不想自己管 Ingress Controller

兩種架構的取捨：

| 架構 | 優點 | 缺點 |
|------|------|------|
| L7 LB 一層做完 | 簡單、少一層元件 | 彈性較低、綁定協定 |
| L4 LB + Ingress Controller | 彈性高、職責清楚 | 複雜度較高 |

WeaMind 用的是 L4 + Ingress（Hetzner LB + Traefik）。這是一種選擇，不是唯一正解。

一句話記法：L7 LB 存在且常見，選哪種看你要簡單還是要彈性。
