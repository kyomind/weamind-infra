# 2026-03-12 Pod To VM And Endpoints Notes
複習：2026-04-14
## Notes

### Pod IP 是怎麼來的？在 cluster 裡是不是唯一？

使用者在 command drill 看到 `10.42.1.14` 與 `10.42.2.13` 之後，追問這些 Pod IP 是否是在啟動時自動分配，以及它們是否在 cluster 內唯一。

這題的較準確答案是：

- 是，Pod IP 通常是在 Pod 被建立並成功接入 cluster 網路時，**由 CNI 網路層自動分配**，不是手動寫死在 Deployment 裡。
- ⭐️在 Pod 存活的當下，這個 IP 會是整個 cluster Pod network 裡的唯一位址，**否則路由無法正確運作**。
- 但這個 IP 不是永久身分證；只要 Pod 被刪掉、重建、重新調度，**新的 Pod 很可能拿到不同的 IP**。
- ⭐️這也正是為什麼前面的元件不應直接依賴 Pod IP，而是**應該依賴 Service**。Service 提供穩定入口，Endpoints 則反映**目前這一刻**實際對到哪些 Pod IP。

一句話收斂：Pod IP 是執行期由 cluster 網路動態分配的、當下唯一但不保證永久不變，因此流量應依賴 Service，而不是直接綁定 Pod IP。

### Pod 可以怎麼被「特定」？

使用者在 command drill 中追問：Service 看起來很容易指定到某個特定資源，但 Pod 是否也能被特定，還是只能透過 label 來抓。

這題可以拆成兩層：

- Pod 當然可以被「特定」，最直接的方式是用 Pod 名稱，例如 `kubectl describe pod <pod-name>`。所以 Pod 不是不能特定，只是不是像 Service 那樣天然就有一個穩定入口角色。
- ⭐️但在 Kubernetes 的日常操作與設計裡，**通常不應太依賴某個 Pod 名稱，因為 Pod 是可替換、可重建的執行個體**；今天這個 Pod 被刪掉或重建後，**名稱與 IP 都可能改變**。
- 因此，若問題是「某一群 app Pods 是哪些」、「Service 會選到誰」、「Deployment 管的是哪批 Pods」，**更常用也更穩定的方式會是透過 labels 去篩選與對應**。
- Service 尤其明顯就是依賴 selector 去選符合 labels 的 Pods，而不是寫死某個 Pod 名稱。

一句話收斂：Pod 可以用名稱被特定，但在 Kubernetes 的穩定操作模型裡，真正可持續依賴的通常是 labels，而不是某個單一 Pod 名稱或 Pod IP。

## Flashcards

- 在 WeaMind 裡，line-bot Pod 連 PostgreSQL / Redis 時，實際連到哪裡？ #DevOps #card
	- 不是連 cluster 內的 Service，也不是連某個 Pod IP
	- 是透過 `ConfigMap` 注入的環境變數，直接連原 VM 的內網 IP
	- PostgreSQL 是 `10.0.0.2:5433`
	- Redis 是 `redis://10.0.0.2:6379/0`

- 為什麼回答「Pod 連哪裡」時，要同時提 `ConfigMap` 和 `Deployment`？ #DevOps #card
	- `ConfigMap` 提供的是連線位址與設定值
	- `Deployment` 用 `envFrom` 把這些值注入容器
	- 只講 `ConfigMap` 只回答了值在哪裡，沒有回答它怎麼進 Pod

- 為什麼 WeaMind 沒把 PostgreSQL / Redis 一起搬進 K8s？ #DevOps #card
	- 這個專案是刻意的 K8s + VM 混合架構
	- 遷移範圍先只收在應用層，把資料層留在原 VM
	- 這樣能降低 stateful workload 的維運複雜度，優先維持資料層穩定性

- 為什麼 WeaMind 不把 PostgreSQL / Redis 包成 cluster 內的 Service 名稱？ #DevOps #card
	- 因為 PostgreSQL / Redis 根本不在 cluster 裡
	- app 是直接透過 private network 連外部 VM
	- 所以 `ConfigMap` 直接寫 VM 內網 IP，比硬包一層 cluster 內 Service 更符合現況

- 在這個專案裡，Pod、Service、Endpoints 三者各自代表什麼？ #DevOps #card
	- Pod 是實際跑 line-bot 容器的執行單位
	- Service 是 cluster 內的穩定入口，會把流量轉給符合 selector 的 Pod
	- Endpoints 是 Service 在執行期實際對到的後端 Pod IP/port 清單

- 為什麼確認 Service 後面有沒有健康 Pod 時，第一眼該看 Endpoints？ #DevOps #card
	- 因為 Endpoints 比 YAML 更接近執行期真相
	- 它能直接告訴你 Service 目前到底有沒有選到可導流的後端
	- `kubectl get svc` 只能證明資源存在，不能證明後端真的接起來

- `kubectl get endpoints -n weamind` 的輸出，該怎麼理解？ #DevOps #card
	- 它顯示的是該 namespace 內的 Endpoints 資源清單
	- 每一列通常對應某個 Service 目前的後端清單
	- `ENDPOINTS` 欄位列出的就是後端 Pod IP 與 port

- 如果 `kubectl get endpoints weamind-line-bot` 是空的，第一輪該查哪裡？ #DevOps #card
	- 先查 `Service → selector → Pods` 這條 cluster 內路徑
	- 看 Service selector 是否對得到 Pod labels
	- 看 Pod 是否 Running / Ready，而不是先跳去查 PostgreSQL / Redis

- 如果 Endpoints 正常，但 app 還是連不到 PostgreSQL / Redis，代表什麼？ #DevOps #card
	- 代表 `Service → Pod` 這段大致成立
	- 問題應切到 `Pod → VM` 路徑
	- 接下來查 `ConfigMap`、`Deployment` 注入與 app logs，而不是繼續卡在 Service / Endpoints

- 為什麼「Pod 是 Running」仍然不代表流量一定會通？ #DevOps #card
	- Running 只代表 Pod 進程活著
	- 它不保證 Service 一定有選到它
	- 也不保證 Pod 已經 Ready 或有進入 Endpoints

- `kubectl get pods -o wide` 在這次練習中的價值是什麼？ #DevOps #card
	- 預設 `kubectl get pods` 看不到 Pod IP
	- 加上 `-o wide` 才能把 Endpoints 裡的 IP 對回真實 Pods
	- 它特別適合回答「Pod IP 是多少、跑在哪個 node」這種問題

- `kubectl describe svc weamind-line-bot -n weamind` 主要補了哪三個關鍵欄位？ #DevOps #card
	- `Selector`：Service 用什麼 label 去選 Pod
	- `TargetPort`：流量最後打到容器的哪個 port
	- `Endpoints`：目前實際對到哪些 Pod IP/port

- `kubectl get pods --show-labels` 在這次練習中的意義是什麼？ #DevOps #card
	- 它把 Pod 身上的 labels 顯示出來
	- 可以直接驗證 Service 的 selector 是否真的對得上
	- 在這次案例裡，兩個 Pods 都有 `app=weamind`

- 在這個專案裡，`Service → Endpoints → Pods` 的最小觀察順序是什麼？ #DevOps #card
	- 先用 `kubectl get endpoints` 看 Service 目前實際對到誰
	- 再用 `kubectl get pods -o wide` 與 `--show-labels` 對回 Pod IP 與 labels
	- 最後用 `kubectl describe svc` 補齊 selector 與 port mapping

- Service IP 和 Endpoints IP 有什麼差別？ #DevOps #card
	- Service IP 是 cluster 內穩定入口，例如 `ClusterIP`
	- Endpoints IP 是這個入口背後當下實際接到的 Pod IP
	- 前者應被前面元件依賴，後者是執行期觀察結果

- Pod IP 是怎麼來的？它在 cluster 裡是固定的嗎？ #DevOps #card
	- Pod IP 通常由 CNI 在 Pod 建立並接上網路時動態分配
	- 在 Pod 存活當下，它在 cluster Pod network 裡是唯一的
	- 但它不是永久固定；Pod 重建後很可能拿到新 IP

- 為什麼前面的元件不應直接依賴 Pod IP？ #DevOps #card
	- 因為 Pod IP 是動態的，不保證重建後不變
	- 真正穩定的依賴目標應該是 Service
	- Endpoints 只用來觀察目前這一刻 Service 對到哪些 Pod

- Pod 可以被「特定」嗎？為什麼還是常用 labels？ #DevOps #card
	- 可以，最直接是用 Pod 名稱
	- 但 Pod 名稱與 Pod IP 都可能隨重建改變
	- 在穩定操作模型裡，更可持續依賴的是 labels，而不是單一 Pod 名稱

- 如果 `kubectl` 突然出現 `127.0.0.1:6443 connection refused`，第一輪該先懷疑什麼？ #DevOps #card
	- 先懷疑 SSH proxy / 管理通道是否逾時
	- 這通常是管理通道問題，不一定是 cluster 內資源壞掉
	- 不要第一時間就誤判成 Service 或 Pod 異常

- `kubectl get svc` 有輸出，能證明什麼？不能證明什麼？ #DevOps #card
	- 它能證明 Service 資源存在
	- 它不能證明 Service 後面一定有正常 Pod
	- 真正要確認後端是否接起來，還是要看 Endpoints

- 為什麼 `kubectl describe svc` 比 `kubectl get svc` 更適合第一輪深查？ #DevOps #card
	- 因為它會同時顯示 `Selector`、`TargetPort`、`Endpoints`
	- 可以一次看出 Service 怎麼選 Pod、流量打到哪個 port、目前後端是誰
	- 它更適合拿來對照 YAML 與執行期狀態

- 在這次案例裡，`TargetPort: 8000` 代表什麼？ #DevOps #card
	- 代表 Service 收到流量後，最後會把流量轉到容器的 8000 port
	- 這要和 Endpoints 裡的 `:8000` 一起看才有意義
	- 它回答的是「流量最後打到容器哪個 port」

- 在這次案例裡，`Port: 80` 和 `TargetPort: 8000` 要怎麼一起理解？ #DevOps #card
	- `Port: 80` 是 Service 對內提供的入口 port
	- `TargetPort: 8000` 是容器實際監聽的 port
	- 兩者不同很正常，代表 Service 做了一層 port mapping

- 為什麼 Endpoints 是切問題的高價值觀察點？ #DevOps #card
	- 因為它不能保證一切都正常，但能快速排除一大段問題
	- Endpoints 空，代表問題多半還在 `Service → Pod`
	- Endpoints 正常，則可把注意力切到 `Pod → VM` 或應用內部

- 在 WeaMind 的排查裡，為什麼要把問題切成 `Service → Pod` 和 `Pod → VM` 兩段？ #DevOps #card
	- 因為這兩段是不同層級的問題
	- 前者是 cluster 內流量與資源對接，後者是 app 對外部依賴的連線
	- 不先切開，排查很容易在 Service、Pod、DB 設定之間亂跳

- 在這次 lesson 裡，`ConfigMap` 最關鍵的觀察值有哪些？ #DevOps #card
	- `POSTGRES_HOST`
	- `POSTGRES_PORT`
	- `REDIS_URL`
	- 這三個值直接決定 Pod 對外連 VM 的目標位址

- 在這次 lesson 裡，`envFrom` 為什麼是關鍵字？ #DevOps #card
	- 因為它證明 `ConfigMap` 和 `Secret` 的值會被整批注入容器
	- 沒看到 `envFrom`，就還沒把「設定值在哪裡」和「它怎麼進 Pod」接起來
	- 它是回答 Q1 時必須補上的另一半

- `pod-template-hash` 在這次練習裡可以順手幫你看出什麼？ #DevOps #card
	- 它顯示這些 Pods 來自同一個 Deployment / ReplicaSet 模板
	- 但 Service 真正依賴的不是這個 hash，而是 `app=weamind`
	- 所以它是補充線索，不是 Service selector 的核心

- 看到兩個 Endpoints IP 都對得回 Pods，最小可以得出什麼結論？ #DevOps #card
	- `weamind-line-bot` 目前至少對到了 2 個後端 Pods
	- Service selector 和 Pod labels 在這一刻是對得上的
	- cluster 內 `Service → Pod` 這段至少已接起來

- 為什麼這次 lesson 的 command drill 有長期價值？ #DevOps #card
	- 因為它不是背單一指令，而是建立一條可重用的觀察順序
	- 之後看到任何 Web app Service，都能先看 Endpoints、再對 Pods、最後看 describe
	- 這比只背名詞或只背 YAML 更接近真實排查能力
