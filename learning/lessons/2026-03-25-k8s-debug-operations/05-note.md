# 2026-03-25 K8s Debug Operations Notes

## 學習注意事項

### 外部預習回帶重點

- 今天不需要新的外部預習，直接承接 W3 Day 1 與 Day 2 已建立的 debug 骨架與工具語意。
- W3 Day 1 建立的是分層判讀框架。
- W3 Day 2 建立的是工具語意與證據類型。
- W3 Day 3 要做的是把前兩天接起來，練習遇到具體故障時，怎麼排出第一步、第二步與下一步。

### 今天進 lesson 前先記住的邊界

- 今天不重教 Pending、ImagePullBackOff、CreateContainerError、CrashLoopBackOff 的基本定義。
- 今天只聚焦在 WeaMind 已經遇過或很合理的故障情境，練「先看哪裡、為什麼、下一步是什麼」。

### 待驗證的 repo 對照點

- 不要把 `Pod Running` 或 `Ready=True` 誤讀成整條外部流量路徑一定沒問題。
- 不要把 `exec` 成功誤讀成 PostgreSQL、Redis、Ingress、LB、LINE webhook 路徑都已被驗證。
- 不要把 `404`、`500`、timeout 全部當成同一種故障；第一輪較值得懷疑的層次常不同。

### 暫時不在今天展開的點

- 今天也不展開新的進階工具，例如 ephemeral container 或完整故障演練劇本。

## Notes

### Q1 限縮力道補充

- Q1 的一個重要收穫不是只有把問題先分到 routing 類，而是學會利用「已知成功的證據」把嫌疑範圍再往內壓。
- 若 `https://k8s.kyomind.tw/health` 已回 `200`，代表至少有一條請求已成功走過 LB、Ingress、Service，最後進到 Pod 並由 app 正常回應。
- 這本身還不能證明所有路徑都正確，但若再加上 [manifests/ingress.yaml](manifests/ingress.yaml) 的規則是 `host: k8s.kyomind.tw` 搭配 `path: /` Prefix，就能再把推論往前推一步：這個 host 底下的大部分路徑本來就會被轉到同一個 Service，而不是只有 `/health` 例外通過。
- 因此當同一個 host 的 webhook Verify 回 `404` 時，嫌疑範圍會比「LB 到 Ingress 中間某處 routing 壞掉」更小；第一輪更值得優先懷疑的是「外部填入的 webhook path 與 app 真正存在的路由不一致」。
- 也就是說，Q1 最有價值的限縮，不只是知道它在 Pod 外面，而是能進一步說：入口大致已通、host 規則大致已通，現在更像是特定 path 對錯了。
- 這條推論鏈的價值在於，它示範了 debug 時不要只看失敗訊號，也要把已知成功訊號一起納入，因為真正的縮圈常常來自「成功了哪些部分」。

### Q1 更精準的限縮說法

- 第一層限縮：`/health` 回 `200`，代表整條入口不是全壞，Pod 與 app 也不是一開始就完全不可用。
- 第二層限縮：Ingress 目前是 `host + path / Prefix`，所以同一個 host 的大部分路徑本來就會被轉給同一個 Service。
- 第三層限縮：在前兩個條件都成立時，Webhook Verify 回 `404` 更像請求已進到應用，但打到 app 裡不存在的 path。
- 所以這題第一輪最值得檢查的是外部 webhook URL 寫成什麼 path，以及它是否真的對到 app 的實際 webhook 路由。

### 單機版與 K8s 版排錯主線的共通點

- 今天一個重要體感是：對 app 本身的排錯主線，單機版和 K8s 版其實沒有差到完全不同世界。
- 如果在 K8s 裡已經有足夠證據顯示請求真的進到 app，那後續常見順序仍然很像單機版：先看 `path` / 路由是否正確，再看 app `logs`，最後才在需要時檢查設定與依賴。
- K8s 真正多出來的，是外層還多了 `DNS`、`LB`、`Ingress`、`Service`、`Pod` lifecycle 這幾層需要先分流；也就是說，它主要增加的是「外層縮圈成本」，不是把 app 排錯邏輯整個改寫。
- 因此一旦已知 `health=200`、`Pods Running/Ready`，而且請求也看起來有進到 app，後面的判斷就會愈來愈接近單機版常見的思路，而不是還要一直停留在 Kubernetes 外層元件。

## Flashcards

<!-- 等 lesson 過程中真的整理出卡片素材後再填。 -->
