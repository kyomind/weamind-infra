# Headlamp 第一天練習單

## 文件目的

這份練習單的目標不是把 Headlamp 所有功能都學完，而是用最小範圍建立三件事：

1. 看懂 cluster 的全局畫面
2. 看懂主要資源之間的關係
3. 建立之後與 k9s / kubectl 的分工感

這份練習單預設你已經可以在本機打開 Headlamp，並且已經連到目前的 WeaMind K3s cluster。

## 使用原則

今天不要做下面幾件事：

1. 不要花時間調整介面或 theme
2. 不要深挖不相干的進階功能
3. 不要一開始就想用 GUI 做所有事

今天只做觀察與理解。

## 今日任務總覽

| 任務   | 目標              | 產出                                        |
| ------ | ----------------- | ------------------------------------------- |
| 任務 1 | 看懂 cluster 概覽 | 能用自己的話描述目前 cluster 整體狀態       |
| 任務 2 | 看懂 Pod          | 能指出某個 Pod 的狀態、事件、logs 位置      |
| 任務 3 | 看懂 Deployment   | 能說明 Deployment、ReplicaSet、Pod 的關係   |
| 任務 4 | 看懂 Node         | 能說明節點資源與 Pod 分布                   |
| 任務 5 | 建立工具分工感    | 能說出哪些事用 Headlamp，哪些事之後改用 k9s |

## 任務 1：看概覽頁

先停在 Headlamp 的概覽頁，不要急著點進細節。

### 你要看什麼

1. CPU 使用
2. 記憶體使用
3. Pods 數量與是否 ready
4. 節點數量與是否 ready
5. 事件區塊目前顯示了什麼

### 你要回答的問題

1. 目前 cluster 有幾個節點？
2. 目前 Pod 大致健康嗎？
3. 有沒有持續出現的 warning event？
4. 目前是資源緊張的狀態，還是相對輕鬆？

### 完成標準

你可以用 3 到 5 句話描述目前 cluster 的整體狀態。

## 任務 2：看 Pod

接著進到某個 namespace，選一個你熟悉的 Pod。

優先建議：

1. `weamind` namespace 內的 line-bot Pod
2. `kube-system` 內的 coredns 或 traefik Pod

### 你要找什麼

1. Pod 的狀態
2. Pod 跑在哪個 Node
3. Pod 的容器資訊
4. Events
5. Logs
6. YAML

### 你要回答的問題

1. 這個 Pod 現在是 Running 還是有異常？
2. 它在哪個 Node 上？
3. 最近有沒有 warning event？
4. 你在哪裡看 logs？
5. 你在哪裡看完整 YAML？

### 完成標準

你能快速指出：

1. Pod 狀態在哪裡看
2. Events 在哪裡看
3. Logs 在哪裡看
4. YAML 在哪裡看

## 任務 3：看 Deployment

接著找 line-bot 對應的 Deployment。

### 你要找什麼

1. replicas 設定
2. 目前 ready replicas
3. Deployment 底下對應的 ReplicaSet
4. ReplicaSet 底下對應的 Pods
5. rollout / history 相關資訊是否容易看懂

### 你要回答的問題

1. Deployment 想維持幾個 replicas？
2. 現在實際有幾個 Pod ready？
3. Deployment 與 Pod 中間隔了哪一層？
4. Headlamp 有沒有幫你更容易看出這個關係？

### 完成標準

你可以順著這條鏈講出來：

Deployment -> ReplicaSet -> Pods

並能指出畫面上各自在哪裡看到。

## 任務 4：看 Node

進到節點頁面，查看 cluster 內三個節點的狀態。

### 你要找什麼

1. 每個 Node 是否 Ready
2. CPU / memory 資源使用情況
3. 每個 Node 上大致跑了哪些 Pod
4. 有沒有異常 event 或壓力跡象

### 你要回答的問題

1. 三個節點都 healthy 嗎？
2. 哪個節點目前資源使用最高？
3. line-bot Pod 是不是分散在不同節點？
4. 你能不能從 GUI 大致看出 cluster 的負載分布？

### 完成標準

你能指出：

1. Node readiness 在哪裡看
2. Node 資源使用在何處看
3. Node 與 Pod 分布關係是否容易追蹤

## 任務 5：建立工具分工感

這一步最重要。

今天不要只停在「Headlamp 好清楚」，而是要開始做工具分工。

### 請回答下面問題

1. 哪些操作你覺得用 Headlamp 看最舒服？
2. 哪些操作你已經可以想像之後用 k9s 會更快？
3. 哪些問題最後還是得回到 kubectl？

### 參考方向

| 需求                         | 比較適合的工具 |
| ---------------------------- | -------------- |
| 先看全局、找畫面感           | Headlamp       |
| 看資源關係、YAML、視覺化巡檢 | Headlamp       |
| 快速跳轉、快速反應、日常巡檢 | k9s            |
| 精準查詢、腳本化、正式排查   | kubectl        |

## 建議紀錄格式

做完今天的練習後，請至少記下下面內容：

1. 我今天看了哪一個 Pod
2. 我今天看了哪一個 Deployment
3. 我在 Node 頁看到什麼分布現象
4. 我認為 Headlamp 最有價值的 2 個地方
5. 我預計之後交給 k9s 的 2 個場景

## 今天的收斂結論

如果今天練完，你能明確說出下面三句話，就算達標：

1. 我知道怎麼用 Headlamp 快速掌握 cluster 現況
2. 我知道怎麼用 Headlamp 看 Pod、Deployment、Node 的關係
3. 我知道 Headlamp 不是取代 kubectl，而是幫我先建立畫面感

## 下一步

完成這份練習單之後，下一個合理步驟是：

1. 安裝並打開 k9s
2. 用 k9s 重做一次 Pod、Deployment、Node 的查看
3. 比較 Headlamp 與 k9s 在同一件事上的手感差異
