# 2026-04-06 CI Image Pipeline Skeleton Note
複習：2026-05-18
## 學習注意事項

### 今日 lesson 邊界

- 今天主題是 WeaMind 的 CI workflow、publish 到 GHCR、Deployment image 引用方式，以及目前為什麼還不算完整 CD。
- 今天不展開 GitHub Actions 的所有語法細節，也不展開完整 GitOps 或 Argo CD / Flux 實作。
- 今天也不把焦點放在 app repo 內部程式碼，而是只收斂從 workflow 到 Deployment 的最小鏈路。

### 今天要特別觀察的 repo 事實

- CI workflow 同時包含程式品質檢查與 Docker build validation。
- publish workflow 是由 CI 的 workflow_run 觸發，且只在成功條件成立時才會 push image。
- Deployment 目前引用 ghcr.io/kyomind/weamind:latest。
- imagePullPolicy: Always 只影響 Pod 重新建立時的拉 image 行為，不會主動觸發 rollout。

### 今天不展開的項目

- 未來若要補成真正 CD，該選 GitHub Actions 直推 K8s 還是 GitOps 工具，今天只點到為止。
- image tag strategy 的更完整版本管理設計，今天只收斂到 latest 與 sha-short tag。

## Notes

### Production 常見的 image 更新方式，不一定等於手動 apply 加 rollout restart

- 你今天問的延伸題很重要，但它已經超出「WeaMind 目前現況是怎麼接 image」這個主問題，所以放在 note 比較合適。
- 若是比較傳統、非 GitOps 的流程，常見做法是 **把 manifest 裡的 image tag 從舊版改成新版**，再重新 `kubectl apply`；因為 Pod template 已改變，Deployment controller 會自動觸發新的 rollout，**通常不需要再額外手動 `rollout restart`**。
- `rollout restart` 比較常見在另一種情境：**manifest 沒改、tag 名稱也沒改，但你仍想強制把現有 Pods 重建一次**。WeaMind 目前用 `latest` 時，這種做法就特別合理，因為 image reference 表面上沒變，但 registry 裡的實際內容可能已更新。
- 若進入較成熟的 production 流程，常見做法會往 **immutable tag + GitOps** 靠攏，也就是更新 Git 中的 image tag，讓 Argo CD / Flux 這類 controller 發現 declarative state 改了，再自動同步到叢集。
- 所以更精準地說，不是所有 production 都是「改 YAML 再 apply，再 rollout restart」三步一起做；**若 tag 有變，通常改 manifest 並 apply 就足以觸發 rollout；若 tag 沒變而想強制吃到新 image，才更可能用 rollout restart。**

### WeaMind 目前有沒有必要補 CD

- 以這個專案目前的規模與用途來看，**不是立即必做**，但它是一個合理的下一階段優化題，不是多餘工作。
- 若目前部署頻率不高、操作者就是你自己，而且你也能接受 publish 後手動 `rollout restart`，那現況其實是可控的；這時候 **手動 deploy 反而比較透明、風險也比較低**。
- 但如果你想降低「忘記重啟所以實際服務還在跑舊版」這種人為落差，或未來部署頻率提高、流程想更穩定，那補上最小 CD 就開始有價值。
- 所以更務實的判斷不是「要不要追求完整自動化」，而是：**你目前最想消掉的是不是最後那個手動步驟造成的認知落差。** 若答案是是，那就值得做。

### 為什麼很多 production 不會讓 CI 一路直衝到 production CD

- 你的理解是對的。很多 production 流程確實不是「CI 成功就直接部署到正式環境」，而是會在 CI 與 production deploy 之間加入一層 **promotion / approval gate**。
- 這層 gate 的作用不是拖慢速度，而是把兩件事分開：**CI 負責證明 artifact 可用；人工審核或 promotion 負責決定這個 artifact 現在要不要進正式環境。**
- 在真實團隊裡，dev 或 staging 可能會自動 deploy，但 production 常保留人工核准、變更窗口、release manager，或至少要經過 PR / approval 才前進。
- 所以「app repo release 成功後，自動開 PR 到 infra repo，再由人審核後合併」這條路，不是反自動化，而是很典型的 **受控式 CD**。

### 為什麼直接更新 infra 或直接 rollout 容易讓邊界變怪

- 你這個直覺也是對的。若 app repo 直接去「改正式環境」卻沒有同步更新 infra repo 的宣告狀態，就會出現 **runtime state 和 Git state 脫鉤** 的問題。
- 如果它有直接修改 infra repo 檔案，但沒有經過 PR / review，那問題就變成：**雖然 state 有被改，但 change management 邊界很弱，infra repo 容易變成被動接受 app repo 直接寫入的地方。**
- 如果它完全不改 infra 檔案，只是直接 rollout 或直接改叢集，那問題更典型：**叢集真的跑了新版，但 infra repo 還停在舊版，這就是 configuration drift。**
- 也因此，對宣告式基礎設施來說，比較穩的順序通常是：**先更新 Git 中的 infra state，再讓叢集去收斂到這個 state**，而不是反過來先改 runtime 再希望 Git 之後補記錄。
- 所以你前面偏向「用 PR 去修改 infra repo 裡的內容，再由人審核」的直覺，正是比較不容易越界、也比較符合宣告式維運邏輯的做法。

### CD 討論主文件

- 從這裡往後延伸出的 CD 設計、release tag 選型、app repo 與 infra repo 分工、以及落地方案，已整理到 [docs/WeaMind實作CD討論與實踐.md](docs/WeaMind實作CD討論與實踐.md)。
- 後續若要繼續推進這個主題，原則上直接修改那份文件，不再把長篇設計稿持續堆在 lesson note。

## Flashcards

- WeaMind 的 CI 在做什麼，和 publish 有什麼關係？ #DevOps #card
	- CI 分成 code quality/tests 與 Docker build validation 兩個 job
	- 它先證明程式碼品質與 Docker build 路徑可成立
	- 它是 publish 到 GHCR 前的品質閘門，不是部署本身

- 為什麼 WeaMind 的 publish workflow 要綁 `workflow_run`，而不是直接綁 `push`？ #DevOps #card
	- 它要等前一份 `CI` workflow 先跑完
	- 只有 main 上的成功 push 才真的 build and push image
	- 這是在把 PR 檢查和正式 image 發佈分層

- `on.workflow_run` 已有限制，為什麼還要再寫 job-level `if`？ #DevOps #card
	- `on` 決定 workflow 什麼時候被喚起
	- `if` 決定被喚起後這個 job 要不要真的執行
	- 它是第二道保護，用來排除 PR 檢查或失敗 CI 也誤發佈 image

- `imagePullPolicy: Always` 在 WeaMind 這題裡真正保證什麼？ #DevOps #card
	- 只保證 Pod 在建立或重建時會重新嘗試拉 image
	- 不保證背景自動偵測 registry 新版本
	- 不保證現有 Pods 會因 `latest` 更新而自動 rollout

- 為什麼 WeaMind 現在只能說有 CI 與 image publishing，還不能說有完整 CD？ #DevOps #card
	- app repo 已會做 CI 與 push image 到 GHCR
	- 但從 registry 到 cluster 的最後一跳沒有自動化
	- 沒有 `kubectl set image`、`rollout restart` 或 GitOps controller 證據

- 為什麼 production 常保留 CI 和正式 deploy 之間的人工審核層？ #DevOps #card
	- CI 證明 artifact 可用，不等於它現在就該進 production
	- approval gate 是在控制 promotion，不是反自動化
	- 自動開 PR 到 infra repo 再審核，是典型的受控式 CD

- 為什麼 app repo 直接改叢集或直接 rollout，容易讓 infra 邊界變怪？ #DevOps #card
	- 若不更新 infra Git state，就會出現 configuration drift
	- 若直接寫 infra repo 但無 review，change management 邊界會變弱
	- 較穩的順序是先更新 infra state，再讓叢集收斂到它
