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

- 在 WeaMind 的 Deployment 題裡，Deployment、ReplicaSet、Pod 的最小管理鏈是什麼？ #DevOps #card
	- `Deployment → ReplicaSet → Pod`
	- Deployment 宣告期望狀態並管理 ReplicaSet
	- ReplicaSet 再維持符合條件的 Pods 數量

- 在 `manifests/deployment.yaml` 裡，Deployment 是靠什麼知道自己要管哪些 Pods？ #DevOps #card
	- 靠 `spec.selector.matchLabels` 對應 `spec.template.metadata.labels`
	- 在 WeaMind 裡關鍵 label 是 `app=weamind`
	- 它管理的是符合 selector、且由 Pod template 建出的那批 Pods

- `replicas: 2` 在 WeaMind 裡不只是「高可用」，還實際解了哪些問題？ #DevOps #card
	- 單一 Pod 故障時，不會整個沒有後端
	- Service 可以同時對多個後端 Pods 導流
	- 部署更新時，不需要把舊版本 Pods 一次全部停掉

- 為什麼 WeaMind 的 line-bot 應該掛在 Deployment，而不是直接手寫一個 Pod？ #DevOps #card
	- line-bot 是長期常駐、持續提供 webhook 的服務
	- Pod 是可替換的執行個體，不適合當主要管理單位
	- Deployment 才能提供副本管理、自動修復與滾動更新

- 今天先怎麼理解 workload？ #DevOps #card
	- workload 是 Kubernetes 裡要被執行與管理的應用工作負載
	- line-bot 這種長期常駐的 Web 服務就是一種 workload
	- Deployment 是用來管理這類 workload 的控制器之一

- `manifests/deployment.yaml` 直接宣告的是哪一層的期望狀態？ #DevOps #card
	- 直接宣告的是 Deployment 這一層的期望狀態
	- 它定義想要幾個副本、用什麼 Pod template、如何更新
	- 不是直接手寫某個固定 ReplicaSet 或某個固定 Pod 的身分

- 為什麼 repo 沒手寫 ReplicaSet YAML，執行期還是會有 ReplicaSet？ #DevOps #card
	- 因為 Deployment controller 會根據 Deployment 宣告自動建立並管理 ReplicaSet
	- 所以 ReplicaSet 不是不存在，而是不用手動直接維護
	- repo 宣告的是高層控制目標，不需要把每一層都手寫出來

- 為什麼 `manifests/deployment.yaml` 沒寫 ReplicaSet，仍然能支援自動修復？ #DevOps #card
	- Deployment 會自動建立並管理 ReplicaSet
	- ReplicaSet 會持續把 Pod 數量維持在目標值
	- 當 Pod 掛掉時，ReplicaSet 會補新的 Pod 回來

- 當 Pod template 變更時，Deployment 怎麼做到滾動更新？ #DevOps #card
	- Deployment 會建立新的 ReplicaSet
	- 舊的 ReplicaSet 不會立刻消失，而是和新的一起參與 rollout
	- 新的逐步增加、舊的逐步減少，最後完成版本交接

- 在 WeaMind 目前 `replicas: 2` 的情境下，為什麼可以把 rolling update 想成「可能先到 3 再回到 2」？ #DevOps #card
	- 因為更新時常見做法是先增加新版本 Pod，再逐步減少舊版本 Pod
	- 這比「先砍掉舊的再補新的」更接近預設 rolling update 的方向
	- 核心目標是避免可用副本一次掉太多

- 在 Deployment YAML 裡，為什麼要講 Pod template，而不是 Pod 名稱？ #DevOps #card
	- Deployment 寫的是未來要建立出什麼樣的 Pod 模板
	- 模板包含 image、labels、command、probes 等設定
	- Pod 名稱通常是執行期產生的，不是 Deployment 先寫死的

- Pod crash 後，Service 是怎麼知道後端變了？ #DevOps #card
	- 不是 Service 自己定時輪詢某個 Pod
	- 控制面會根據 Pod 狀態與 readiness 變化，更新 Endpoints / EndpointSlice
	- Service 之後依更新後的後端清單導流
