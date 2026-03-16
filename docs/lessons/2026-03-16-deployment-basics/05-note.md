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