# 2026-03-16 Deployment Basics Notes

## Notes

### 1. Deployment 題裡，管理鏈和執行鏈要怎麼分？

使用者在進入 Q1 前先追問：Deployment、ReplicaSet、Pod 這條管理鏈，是否要一路延伸講到 Scheduler、Node、Container；如果現在不講，後面是否還會學到。

這題要先切成兩段：

- 今天 Q1 要先收斂的是管理鏈，也就是 `Deployment → ReplicaSet → Pod`。
- 這條鏈回答的是：誰在宣告期望狀態、誰在維持副本數、誰是實際被建立出來的執行單位。
- `Scheduler → Node / kubelet → container runtime` 則屬於 Pod 被建立之後的最小執行鏈，回答的是：這個 Pod 最後怎麼被放到某個節點上並啟動。
- 兩條鏈都重要，但如果在 Deployment 基礎題一開始就混在一起，很容易把「控制關係」和「執行流程」說成同一件事。

一句話收斂：今天先把 Deployment 的管理鏈講穩，執行鏈保留到 Pod 管理、K3s 分工與後面的 debug 情境再補。

### 2. 這週要不要把執行鏈拉成獨立主題？

使用者進一步追問：既然執行鏈也重要，本週是否要改計畫，另外抽一段專門學。

目前的較佳做法是不獨立拉成一整天，而是在本週做局部補強：

- 3/16 仍先完成 Deployment 基礎，主線不改。
- 3/17 在 Pod 管理與 probe 那天，額外補一段最小執行鏈骨架：Pod 建立後，由 Scheduler 決定節點，再由 node 上的 kubelet 交給 container runtime 啟動 container。
- 3/18 講 K3s 概念時，再把 Scheduler 與 kubelet 放回 control-plane / worker 的分工位置。
- 若到 3/19 仍覺得管理鏈與執行鏈容易混，再用彈性日補一份短筆記或小 outline，不另外重排整週主題。

一句話收斂：本週只做最小執行鏈補強，不把它升級成新的獨立 lesson。

### 3. Pod crash 後，Service 會「立刻感知」嗎？

使用者在 Q2 後追問：如果 Service 不是自己定時輪詢 Pod，那是不是代表 Pod crash 時，後端清單會像事件一樣即時變動，所以 Service 會立刻知道。

這個理解方向接近，但要再修得更精準：

- 不要把它講成 Service 自己在感知 Pod 狀態。
- 比較準確的說法是：控制面會根據 Pod 狀態與 readiness 變化，更新對應的 Endpoints / EndpointSlice；Service 導流時依賴的是這份後端清單。
- 所以整體行為比較接近事件驅動或狀態變更後的快速收斂，而不是固定頻率輪詢某兩個 Pod。
- 但也不要把它講成絕對零延遲的「瞬間」；從 Pod 異常、狀態更新、到後端清單改變，中間仍有一個很短的控制面收斂過程。
- 在實務上，對 Deployment / Service 這種題目，只要先記住「不是手動刷新，也不是寫死 Pod 名單，而是後端清單會隨 Pod 狀態改變而更新」就夠了。

一句話收斂：Pod crash 後，不是 Service 本身去即時偵測某個 Pod，而是控制面會很快把可導流後端清單更新掉，Service 之後就依新的清單導流。

### 4. 今天先怎麼理解 workload？

使用者在回答 Q3 時提到：目前還沒正式學過 `workload` 這個詞，所以不太確定它在 Kubernetes 裡到底指什麼。

今天先用最小版本理解即可：

- `workload` 指的是 Kubernetes 裡要被執行、維持、管理的應用工作負載。
- 它不是某一個特定資源種類，而是一個較上位的統稱。
- 像 WeaMind 的 line-bot 這種長期常駐、需要持續提供 webhook 服務的 app，就可以被稱為一個 workload。
- Deployment、StatefulSet、DaemonSet 這些物件，都是拿來管理不同類型 workload 的控制器；只是今天先聚焦在 Deployment，不需要把其他種類一起展開。

一句話收斂：在今天的語境裡，workload 可以先簡單理解成「這個要被 Kubernetes 持續跑著並管理的服務或應用」。

## Flashcards

- 在 Deployment 基礎題裡，今天先要講清楚的是哪一條鏈？ #DevOps #card
	- 先講管理鏈，不先展開執行鏈
	- 管理鏈是 `Deployment → ReplicaSet → Pod`
	- 它回答的是誰在宣告與維持期望狀態

- 最小執行鏈是什麼？ #DevOps #card
	- Pod 建立後，由 Scheduler 決定要去哪個 node
	- 該 node 上的 kubelet 再把 Pod 交給 container runtime 啟動 container
	- 這條鏈屬於執行面，不是 Deployment Q1 的主回答

- 為什麼今天不把管理鏈和執行鏈混在一起講？ #DevOps #card
	- 因為兩者回答的是不同層次的問題
	- 管理鏈講的是控制與期望狀態
	- 執行鏈講的是 Pod 建立後怎麼被排程與啟動

- 這週對執行鏈的安排是什麼？ #DevOps #card
	- 不獨立拉成一整天
	- 3/17 補最小執行鏈骨架
	- 3/18 再補 Scheduler / kubelet 在 control-plane / worker 的位置

- Pod crash 後，Service 是怎麼知道後端變了？ #DevOps #card
	- 不是 Service 自己定時輪詢某個 Pod
	- 而是控制面根據 Pod 狀態與 readiness 變化，更新 Endpoints / EndpointSlice
	- Service 之後依更新後的後端清單導流

- 今天先怎麼理解 workload？ #DevOps #card
	- workload 是 Kubernetes 裡要被執行與管理的應用工作負載
	- line-bot 這種長期常駐的 Web 服務就是一種 workload
	- Deployment 是用來管理這類 workload 的控制器之一