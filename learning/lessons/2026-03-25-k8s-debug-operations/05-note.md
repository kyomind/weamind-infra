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

### `ingressClassName` 與 `Ingress Class` 怎麼理解

- `spec.ingressClassName: traefik` 不是隨便寫了 `traefik` 這個字，controller 就靠字面猜到要接手；更精準地說，這個欄位是在指定「這份 `Ingress` 要交給哪一個 `IngressClass` 來處理」。
- 也就是說，`ingressClassName` 比較像一個「指派對象名稱」或「歸屬類別名稱」，不是 OOP 那種 `class`。
- 在實務上，cluster 內通常會有對應的 `IngressClass` 資源；`Ingress` 上寫的 `ingressClassName` 會去對這個名稱。對 WeaMind 這個專案來說，值寫成 `traefik`，代表這份規則要交給 `Traefik` 這條處理鏈。
- 所以這裡的 `class`，若要用更直觀中文理解，可以先把它想成「處理類別」、「歸屬類別」或更白話的「這份 `Ingress` 要交給哪一路 controller 處理」。
- 它不是動詞，也不是 Python / Java 那種 class；在這裡它比較接近名詞性的「分類 / 類別 / 歸屬」。
- 值也不是只有少數幾種固定關鍵字。**更準確地說，它取決於 cluster 裡實際有哪些 `IngressClass`，以及哪些 `Ingress Controller` 被安裝並設定成會接手哪個 class。** 在你的環境裡看到 `traefik`，是因為這個 cluster 用的就是 `Traefik`。
- 因此當你在 `kubectl describe ingress` 裡看到 `Ingress Class: traefik`，最穩的理解不是「這是某種抽象 class 名稱」，而是「這份 `Ingress` 規則目前是交給 `Traefik` 這條 controller 處理」。

### controller 自己判斷是否接手這份 `Ingress`

- 一個很好懂的直覺是：Kubernetes 本身不需要先理解 `traefik` 這個字串背後的品牌故事；它主要只是把這個值記在 `Ingress` 物件上。
- 後續比較像是各個 `Ingress Controller` 自己來看：這份 `Ingress` 上標的 `ingressClassName` 是不是我負責的那個 class。
- 若是 `Traefik` 看到 `ingressClassName=traefik`，它就知道這份規則屬於自己要處理的範圍；若是別的 controller 看到不是自己負責的 class，通常就不會接手。
- 所以你的理解方向是對的：**不是 Kubernetes 中央大腦先幫你做品牌辨識，而是 controller 根據這份物件上的 class 歸屬，自己判斷要不要接。**
- 只是再精準一點說，controller 通常不是單純只靠「看到這個字串像自己名字」就臨場猜測，而是它在叢集裡本來就有設定自己負責哪個 `IngressClass` / class 名稱，然後去比對是否匹配。

### `exec + printenv` 能證明什麼，不能證明什麼

- 今天的 `Command 3` 很值得另外記一條邊界：`kubectl exec -it` 搭配 `printenv`，能驗證的是 container 內部最終收到的設定值，而不是依賴連線本身。
- 當我們在 container 裡看到 `POSTGRES_HOST=10.0.0.2`、`POSTGRES_PORT=5433`、`REDIS_URL=redis://10.0.0.2:6379/0`，而且它們和 [manifests/configmap.yaml](manifests/configmap.yaml) 一致時，可以說「設定注入層」目前沒有明顯問題。
- 但這還不能直接推出 `PostgreSQL` 或 `Redis` 一定連得通，因為 `printenv` 沒有真的發起 TCP 連線，也沒有替 app 驗證認證、timeout 或 route 問題。
- 所以如果未來 app 仍報資料庫或快取連線錯誤，正確收斂不是回去懷疑「環境變數根本沒進來」，而是往 app `logs` 或更具體的連線驗證去查。

## Flashcards

- 當 `https://k8s.kyomind.tw/health` 回 `200`，但 webhook Verify 回 `404`，第一輪更該優先懷疑什麼？ #DevOps #card
	- 先優先懷疑外部 webhook `path` 和 app 真正存在的路由不一致
	- 這比直接懷疑整條 `LB -> Ingress -> Service -> Pod` 都壞掉更合理
	- 因為 `health=200` 已證明至少有一條請求成功走到 app

- `kubectl describe ingress` 最適合回答什麼問題？ #DevOps #card
	- 它最適合回答 cluster 端宣告的 `Host`、`Path`、backend `Service`、`Ingress Class` 長什麼樣
	- 也就是先確認 Kubernetes 這邊預期怎麼路由
	- 但它不能單獨證明外部呼叫端真的帶了正確的 `Host` 與 `path`

- 為什麼 `Pods Running/Ready` 不能直接推出 webhook 一定正常？ #DevOps #card
	- 因為它只能證明 `Pod` 目前活著、通過 readiness，不能保證外部 URL、`Ingress` 規則、app 路由全都正確
	- `Running/Ready` 是 `Pod` lifecycle 的訊號，不是整條請求路徑的總驗證

- 懷疑 `CrashLoopBackOff` 時，第一輪為什麼先看 `kubectl describe pod`？ #DevOps #card
	- 因為它先給 Kubernetes 視角的狀態證據
	- 可以先看 `State`、`Last State`、`Restart Count`、`Conditions`、`Events`
	- 先知道它怎麼壞，再決定要不要往 app `logs` 深挖為什麼壞

- `kubectl describe pod` 和 app `logs` 的差別是什麼？ #DevOps #card
	- `kubectl describe pod` 回答的是 Kubernetes 目前怎麼看這個 `Pod`
	- app `logs` 回答的是應用程式自己發生了什麼
	- 前者偏「怎麼壞」，後者偏「為什麼壞」

- `kubectl exec -it` 搭配 `printenv` 能證明什麼，不能證明什麼？ #DevOps #card
	- 能證明 container 內部最終看到的設定值，例如 `POSTGRES_HOST`、`POSTGRES_PORT`、`REDIS_URL`
	- 若這些值和 [manifests/configmap.yaml](manifests/configmap.yaml) 一致，就代表設定注入層大致正確
	- 但這不能單獨證明 `PostgreSQL` 或 `Redis` 連線一定成功

- 區分「外部流量路徑問題」和「Pod 到 VM 依賴問題」的真正分界點是什麼？ #DevOps #card
	- 不是看 `Pod` 有沒有 `Running/Ready`
	- 真正的分界點是：請求有沒有進到 app，以及 app `logs` 裡有沒有留下依賴錯誤證據
	- 若連請求紀錄都沒有，更像外層 routing；若請求已進 app 但處理失敗，更像 app 或依賴問題

- 當 `health=200`、`Pods Running/Ready`，但還不知道 webhook 有沒有進到 app 時，最小 debug sequence 是什麼？ #DevOps #card
	- 先檢查 webhook `path` 是否和 app 真正暴露的路由一致
	- 再看 app `logs`，確認請求有沒有進到應用，以及處理時有沒有錯誤
	- 只有在請求已進 app 但 `logs` 仍不足時，才用 `kubectl exec -it` 做內部驗證

- 一旦已確認請求進到 app，K8s 版排錯主線通常會怎麼收斂？ #DevOps #card
	- 會逐漸靠近單機版常見順序：先看 `path` / 路由，再看 app `logs`，最後查設定與依賴
	- K8s 真正多出來的，主要是外層 `DNS`、`LB`、`Ingress`、`Service`、`Pod lifecycle` 的縮圈成本

- `Ingress Class: traefik` 在 `kubectl describe ingress` 裡最穩的理解是什麼？ #DevOps #card
	- 它代表這份 `Ingress` 規則目前是交給 `Traefik` 這條 controller 處理
	- 重點是「歸誰處理」，不是 Kubernetes 中央大腦去理解 `traefik` 這個字的品牌意義
