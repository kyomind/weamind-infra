# 2026-03-31 Secret Update And Encoding Debug Story Report

## 今日主題

- 把 WeaMind 目前 Secret 的引用方式、Secret 更新後對既有 Pod 的影響，以及 `CreateContainerError (invalid UTF-8)` 這次踩坑的因果鏈，收斂成可重講的 debug story。

## 狀態

- 已完成第一版收斂。

## QA 收斂了什麼

- WeaMind 目前不是逐個 key 用 `env + valueFrom` 注入 Secret，而是在 Deployment 的 Pod template 裡，用 `envFrom + secretRef` 把 `weamind-secret` 整包轉成環境變數。
- 這個注入位置很重要，因為它代表設定是在新 Pod / 新 container 建立時才套用，不是 Secret 物件更新後就會即時回寫到既有 Pod。
- Secret 更新和 Pod 內環境變數更新不是同一件事。前者是 Kubernetes 資源物件狀態的改變，後者則要等新的 Pod 建立流程發生，app 才會重新吃到新值。
- `CreateContainerError (invalid UTF-8)` 這次不是 app 業務邏輯錯，而是 Secret 寫法錯在更底層：把不符合 `data` 預期格式的內容塞進 Secret，解碼後產生不合法的 bytes，最後 container runtime 在建立容器時失敗。
- 這次事件後 repo 已收斂出明確規則：人工撰寫 Secret 一律用 `stringData`；只有在非常確定內容本來就是機器穩定產生的 base64 時，才直接使用 `data`。

## 使用者原本卡住的點

- 容易把 Secret 理解成「本地 YAML 裡的一段內容」，而不是叢集中的獨立資源物件。
- 雖然直覺知道 Secret 更新後 app 不一定立刻變，但一開始還沒有把「Secret 已更新到叢集」和「既有 Pod 是否已吃到新值」清楚拆成兩層。
- 對 `rollout restart` 的語境還不夠穩，容易把它和觀察指令混在一起；也一度把 `rollout status` 想成單次摘要查詢，而不是會在前景持續等待的追蹤指令。

## Command drill 收斂了什麼

- 第一輪先用 `kubectl describe secret` 建立資源物件觀念，確認 `weamind-secret` 確實存在於叢集、namespace 正確、key 結構大致合理。
- 第二輪用 `kubectl get deployment -o yaml` 直接看到 `envFrom + secretRef` 寫在 Pod template 裡，確認這是新 Pod 建立時才套用的注入模型。
- 第三輪重新設計後，先把「觀察入口」獨立出來，用 `kubectl get rs` 站到正確層次看 Deployment 底下的版本切換痕跡；同時也釐清它只能提供痕跡，不能單靠自己證明這次 Secret 更新已經觸發新的 rollout。
- 第四輪才把 `kubectl rollout restart` 放回正確情境：只有在已確認 Secret 資源已更新，而且目前設定確實要靠新 Pod 建立時重新注入的前提下，它才是合理的下一步。
- 補跑 `kubectl rollout status` 之後，也補上一個操作層認知：它不是只瞬間印一次結果，而是會在前景持續等待 rollout 完成的追蹤指令。

## 今天最重要的核心 takeaway

- 這堂課真正建立的不是「Secret 指令清單」，而是 Secret debug 的最小判斷順序：先確認叢集裡的 Secret 資源物件，再確認 Deployment 怎麼引用它，再判斷 Pod 是否仍是舊 Pod，最後才決定是否需要 `rollout restart`。
- 另一個核心是把錯誤層次放對：像 `invalid UTF-8` 這種 `CreateContainerError`，第一輪應回到 Pod / runtime / Secret 寫法與 events，而不是先期待 app logs 會告訴你答案。

## 我現在已能講清楚什麼

- WeaMind 為什麼會在 Secret 更新後，既有 Pod 仍繼續吃舊值。
- `envFrom + secretRef` 和 `env + valueFrom` 的主要語意差異，以及為什麼目前 repo 採用前者。
- `CreateContainerError (invalid UTF-8)` 這次踩坑的症狀、根因、修法與後續規則。
- `kubectl describe secret`、`kubectl get deployment -o yaml`、`kubectl get rs`、`kubectl rollout restart`、`kubectl rollout status` 在這條 debug sequence 裡各自回答哪一層問題。

## 仍需補強的地方

- 還要再更熟 `kubectl get rs` 的證據邊界，分清楚哪些輸出只是版本痕跡，哪些觀察才能把 Secret 更新、Pod 重建與新值生效串成更完整的因果鏈。
- 之後可再補一次 `describe pod` / events / `get pods` 的節奏對照，把「CreateContainerError 先看哪一層」練得更順。
- 這堂課先只處理 `envFrom` 情境；若未來要延伸，還可以再比較 Secret 以 volume mount 方式提供時，更新行為為何不同。

## 下一步

- 先把今天這條 Secret debug sequence 壓成更短的面試版答題稿。
- 再視需要補進 `04-report.md` 或後續 lesson：當 `CreateContainerError` 發生時，`describe pod`、events、`logs`、`logs --previous` 各自的使用時機。

