# k9s 第一天練習單

## 文件目的

這份練習單的目標不是背快捷鍵大全，而是用最小範圍建立 k9s 的日常手感。

今天只做三件事：

1. 學會用 k9s 快速看 Pod、Deployment、Node
2. 學會從資源列表跳到 logs / describe / yaml 等高頻資訊
3. 建立 k9s 與 Headlamp、kubectl 的分工感

這份練習單預設你已經能在本機執行：

```bash
k9s
```

並且 kubeconfig 已經能連到目前的 WeaMind K3s cluster。

## 使用原則

今天不要做下面幾件事：

1. 不要急著背全部快捷鍵
2. 不要一開始就試大量編輯或刪資源
3. 不要把注意力放在 theme 或畫面設定

今天先把它當成快速觀察工具，而不是萬能操作台。

## 今日任務總覽

| 任務   | 目標               | 產出                                              |
| ------ | ------------------ | ------------------------------------------------- |
| 任務 1 | 熟悉基本移動與切換 | 知道怎麼進不同資源頁面                            |
| 任務 2 | 看 Pod             | 能快速找到狀態、logs、events                      |
| 任務 3 | 看 Deployment      | 能快速看到 replicas 與底下 Pod                    |
| 任務 4 | 看 Node            | 能快速掌握節點與資源使用                          |
| 任務 5 | 建立工具分工感     | 知道哪些事情交給 k9s、哪些交給 Headlamp / kubectl |

## 先建立最小操作感

打開 k9s 後，今天先只記下面幾個最基本的操作：

| 操作    | 作用                            |
| ------- | ------------------------------- |
| `:`     | 進入 command mode，切換資源視圖 |
| `/`     | 搜尋或過濾                      |
| `Enter` | 進入選中的資源細節              |
| `Esc`   | 返回上一層                      |
| `l`     | 看 logs                         |
| `d`     | describe                        |
| `y`     | yaml                            |
| `0`     | 顯示所有 namespace              |
| `q`     | 離開                            |

今天不要求全部牢記，但要至少用過一次。

## 任務 1：熟悉切換

### 操作

依序輸入下面幾個 command：

1. `:pod`
2. `:deploy`
3. `:node`
4. `:ns`

### 你要觀察什麼

1. k9s 的畫面切換速度如何
2. 每個列表頁面大概會顯示哪些欄位
3. namespace 切換是否直觀

### 你要回答的問題

1. 你能不能很快在 Pod、Deployment、Node 間切換？
2. 你能不能看懂目前自己在哪個 namespace？
3. 你知不知道怎麼切到所有 namespace？

### 完成標準

你能不查文件就完成一次 Pod -> Deployment -> Node 的切換。

## 任務 2：看 Pod

先切到 Pod 視圖：

```text
:pod
```

然後找到一個熟悉的 Pod，例如：

1. `weamind` namespace 的 line-bot Pod
2. `kube-system` namespace 的 coredns 或 traefik Pod

### 你要做的事

1. 看 Pod 狀態
2. 看 restart 次數
3. 看它跑在哪個 Node
4. 按 `l` 看 logs
5. 按 `d` 看 describe
6. 按 `y` 看 yaml

### 你要回答的問題

1. 你能不能一眼看出 Pod 是否健康？
2. 你能不能快速找到 logs？
3. 你能不能找到 events / describe 類資訊？
4. 你能不能找到完整 yaml？

### 完成標準

你能在 30 秒內從 Pod 列表進到 logs，再退回列表。

## 任務 3：看 Deployment

切到 Deployment 視圖：

```text
:deploy
```

找到 line-bot 對應的 Deployment。

### 你要做的事

1. 看 desired / ready replicas
2. 進入 Deployment 細節
3. 觀察底下的 Pod 或相關資源
4. 用 describe 或 yaml 看設定

### 你要回答的問題

1. Deployment 目前目標 replicas 是多少？
2. 實際 ready 的 replicas 是多少？
3. 你能不能快速找到它底下對應的 Pod？
4. 和 Headlamp 相比，k9s 在 Deployment 上給你的感覺是什麼？

### 完成標準

你能說出：

1. 在 k9s 裡看 Deployment 很快
2. 但資源關係仍需要你自己腦中補圖

## 任務 4：看 Node

切到 Node 視圖：

```text
:node
```

### 你要做的事

1. 看每個 Node 是否 Ready
2. 看 CPU / memory 使用情況
3. 進去一個 Node 細節頁
4. 看該 Node 上的工作負載分布

### 你要回答的問題

1. 三個節點都正常嗎？
2. 哪個節點目前最忙？
3. 你能不能快速從 Node 視角感受到整個 cluster 狀態？

### 完成標準

你能快速指出哪個 Node 資源相對高、哪個相對低。

## 任務 5：建立工具分工感

這一步最重要。

請你用今天的操作感，回答下面問題：

1. 哪些事用 k9s 你覺得比 GUI 更快？
2. 哪些事你仍然會想打開 Headlamp？
3. 哪些場景最後還是得回到 kubectl？

### 參考方向

| 需求                              | 比較適合的工具 |
| --------------------------------- | -------------- |
| 快速巡檢、快速跳資源、快速看 logs | k9s            |
| 視覺化理解資源關係、舒服看 YAML   | Headlamp       |
| 精準命令、腳本化、正式排查與驗證  | kubectl        |

## 建議紀錄格式

做完今天的練習後，至少記下：

1. 我今天用 k9s 看了哪一個 Pod
2. 我今天用 k9s 看了哪一個 Deployment
3. 我覺得 k9s 最快的 2 個地方
4. 我覺得 Headlamp 比 k9s 更好的 2 個地方
5. 我覺得 kubectl 仍然不可取代的 2 個場景

## 今天的收斂結論

如果今天練完，你能清楚講出下面三句話，就算達標：

1. 我知道怎麼用 k9s 快速切 Pod、Deployment、Node
2. 我知道怎麼從 k9s 直接看 logs、describe、yaml
3. 我知道 k9s 是快速反應工具，不是拿來取代所有 GUI 與 kubectl

## 下一步

完成這份練習單之後，下一個合理步驟是：

1. 把同一個 Pod、Deployment、Node 再用 Headlamp 看一次
2. 比較 Headlamp 與 k9s 的手感差異
3. 最後用 kubectl 重做一次核心查詢，建立三者分工
