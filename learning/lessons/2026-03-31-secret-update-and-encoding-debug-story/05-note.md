# 2026-03-31 Secret Update And Encoding Debug Story Note

## 學習注意事項

### 今日 lesson 邊界

- 今天主題是 WeaMind 內的 Secret 引用方式、更新影響與 `invalid UTF-8` debug story。
- 今天不展開 Secret at-rest 保護機制，例如 etcd encryption、RBAC 細節與外部 secret manager。
- 今天也不展開 volume mount 型 Secret 更新行為的完整比較，只先收斂 WeaMind 目前 `envFrom` 情境。

### 今天要特別觀察的 repo 事實

- `manifests/deployment.yaml` 目前用 `envFrom` 搭配 `secretRef`，不是逐 key `valueFrom`。
- `PROGRESS.md` 已正式記錄：人工撰寫 Secret 一律用 `stringData`，且曾發生 `CreateContainerError (invalid UTF-8)`。
- `.privatedocs/weamind/踩坑清單.md` 有保留更短版的問題、解法、根因，可用來壓成面試可講的 debug story。

### 今天不展開的項目

- Secret 不是加密，這題保留到後續補強或面試延伸。
- Ingress `tls` 與 Secret 的關係，不納入今天主線。

## Notes

### Secret 不是只是 YAML

- 使用者在 Q4 提出一個關鍵卡點：直覺上容易把 Secret 當作「YAML 裡的一段內容」，但更準確的理解是，YAML 只是宣告方式；真正的 Secret 是 `kubectl apply` 後存在 Kubernetes API server 裡的一個資源物件。
- 因此排查時要分開看兩件事：本地 YAML 是否已修改，以及叢集裡的 Secret 資源是否已更新成功。前者是編輯狀態，後者才是工作負載真正會引用到的狀態。

### 第一層怎麼確認 Secret 已更新到叢集

- 第一動作通常是先 `kubectl apply -f` 將 Secret YAML 套用到叢集。
- 套用後不能只憑終端成功訊息就結束，還要再看叢集裡的 Secret 物件。
- `kubectl describe secret` 適合先確認物件是否存在、名稱是否正確、基本 metadata 是否合理。
- `kubectl get secret -o yaml` 或 `kubectl get secret -o jsonpath=...` 更適合進一步對照目前叢集裡的內容是否已是預期值。
- 這一步的重點不是背哪個指令，而是建立「先確認資源已更新，再談 Pod 是否吃到新值」的排查順序。

### 進 Pod 看 env 的位置

- `kubectl exec` 進 Pod 看環境變數可以作為第二層或第三層的驗證手段，但不應該拿來取代第一層。
- 因為若 Secret 根本還沒正確更新到叢集，直接進 Pod 看 env 只會看到舊值，卻無法分辨是「資源沒更新」還是「Pod 沒重建」。
- 所以較穩的順序是：先看 Secret 物件，再看 Pod 是否為舊 Pod，最後才在需要時進 Pod 驗證實際環境變數。

## Flashcards

- WeaMind 為什麼 Secret 更新後，既有 Pod 不一定會自動拿到新值？ #DevOps #card
	- 因為目前是用 `envFrom + secretRef` 把 Secret 在新 Pod 建立時注入成環境變數
	- Secret 資源物件更新，不等於已存在 container 的 environment 會被即時回寫

- 排查 Secret 更新沒生效時，第一輪判斷順序是什麼？ #DevOps #card
	- 先確認叢集裡的 Secret 資源是否真的已更新
	- 再看 Deployment 如何引用它，確認是否屬於新 Pod 建立時才套用的模型
	- 最後才判斷 Pod 是否仍是舊 Pod，以及是否需要 `rollout restart`

- `kubectl describe secret` 在這條 debug sequence 裡回答什麼？ #DevOps #card
	- 它先回答「Secret 這個資源物件是否真的存在於叢集、namespace 是否正確、key 結構是否合理」
	- 它適合第一眼建立資源物件觀念，但不能單靠它確認敏感值內容已更新成預期值

- 為什麼 `kubectl get deployment -o yaml` 比 `describe deployment` 更適合看這題的 Secret 注入方式？ #DevOps #card
	- 因為這題要看的是 Pod template 裡的 `envFrom + secretRef` 結構，而不是摘要資訊
	- YAML 視角能更直接看到設定寫在哪一層，從而判斷它是新 Pod 建立時才套用的模型

- `kubectl get rs` 在這堂課裡的價值與邊界是什麼？ #DevOps #card
	- 它是看 Deployment 底下版本切換與 Pod 重建痕跡的第一眼入口
	- 但它只能提供痕跡，不能單靠自己證明這次 Secret 更新已經觸發新的 rollout

- 什麼前提下，`kubectl rollout restart` 才是合理的下一步？ #DevOps #card
	- 前提是你已先確認 Secret 資源本身有更新，而且目前設定是透過新 Pod 建立時重新注入環境變數
	- 如果太早 restart，會把「資源根本沒更新成功」和「只是 Pod 還沒重建」混成同一類問題

- `kubectl rollout status` 在操作手感上最容易被誤解的是什麼？ #DevOps #card
	- 它不是單次快照查詢，而是偏 watch 的等待型指令
	- 所以它會占住前景，持續追蹤 rollout，直到成功或失敗有更明確的結果

- WeaMind 這次 `CreateContainerError (invalid UTF-8)` 的真正根因是什麼？ #DevOps #card
	- 問題不是 app 邏輯，而是 Secret 錯用 `data` 欄位並放入不符合預期格式的內容
	- 解碼後得到不合法的 bytes，container runtime 在建立容器時無法把它當成正常字串環境變數處理

- 這次踩坑後，repo 對 Secret 寫法收斂出的規則是什麼？ #DevOps #card
	- 人工撰寫 Secret 一律用 `stringData`，直接寫明文，交給 Kubernetes 處理轉換
	- 只有在非常確定內容本來就是機器穩定產生的 base64 時，才直接使用 `data`
