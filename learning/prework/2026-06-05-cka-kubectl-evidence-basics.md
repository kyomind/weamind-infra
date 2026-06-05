# 2026-06-05 CKA Kubectl Evidence Basics

## Prework 內容

### 今日焦點

- 主題：CKA 雜項題中的 kubectl 篩選、logs、resource requests / limits 與快速驗證骨架
- 範圍：label selector、field selector、`kubectl logs`、Pod / Service filter、Pod resource requests / limits、輸出保存與驗證節奏
- 目標：把零散操作題收斂成「如何快速找到證據、修改最小欄位、驗證結果」的解題骨架
- 時間：45 到 60 分鐘

### 這份 prework 要怎麼用

- 這份文件是給外部 ChatGPT 類服務做今天的純知識預習。
- 直接把這份 outline 貼給外部 AI 即可，不需要額外補很多背景。
- 這份文件分成兩部分：前半段是今天要教的內容，後半段是最後要回填的學習報告。請先完成教學，再一次性產出報告，不要把報告模板當成新的教學任務。
- 今天的背景是：我正在刷 KillerCoda CKA 題庫，Architecture / Installation / Maintenance 類別裡有 Pod filter、Service filter、Pod Log、Pod Logs、Pod Resource、Node Resource、Create Pod 這類看起來很雜的題。請幫我建立通用的 kubectl 證據收集與解題骨架，不要擴展成完整 Kubernetes 指令大全。

### 今天一定要學會的最小骨架

1. label selector 是根據 resource labels 篩選，例如 `-l app=nginx`；field selector 是根據 Kubernetes resource 欄位篩選，例如 `status.phase=Running`。
2. Pod filter 與 Service filter 題的關鍵通常是先看 labels、selectors、namespace，再決定要用 `get`、`describe`、`-l` 或 output 格式。
3. `kubectl logs` 讀的是 container stdout / stderr；多 container Pod、previous container、namespace、selector 都會影響指令寫法。
4. resource requests 影響 scheduler 是否能排上 node；limits 是 runtime 上限，CPU 超過會 throttle，memory 超過可能 OOMKilled。
5. Node Resource 題通常要分清楚 allocatable、allocated requests / limits、實際使用量，三者不是同一件事。
6. Create Pod 題要先判斷 `kubectl run` 能不能直接完成；不能完成時，用 `--dry-run=client -o yaml` 生骨架再改。

### 建議教學順序

1. 先建立「找證據」的心智模型：namespace、resource kind、labels / selectors、狀態欄位、輸出格式。
2. 比較 label selector 與 field selector，並用 Pod filter / Service filter 題型示範怎麼選。
3. 講 `kubectl logs` 的幾個常見變化：namespace、多 container、`--previous`、selector、輸出重導向。
4. 講 Pod resources：requests / limits 的 YAML 位置、scheduler / runtime 差異、常見錯誤如 requests 大於 limits。
5. 講 Node Resource 題型：`describe node`、allocated resources、metrics 類輸出各自能證明什麼。
6. 最後整理 CKA 快速節奏：先用命令式生成可生成的部分，再用 YAML 補缺口，最後用 `get` / `describe` / `logs` 驗證。

### 學完後請產出學習報告

- 請在教學結束時，不要只在對話中簡短回答，而是幫我整理成一份結構化的學習報告。
- 下面這一段是回填模板，不是新的教學主題。
- 這份報告請至少包含以下內容：
  1. 今日主題與學習範圍。
  2. 我今天學到什麼。
  3. 我已經能用白話講清楚什麼。
  4. 我還卡住什麼。
  5. 今天最重要的 3 到 5 個觀念整理。
  6. 我回到 repo 內後，應該拿去做專案對照的 2 個問題。
- 如果可以，請把內容寫得比一般聊天回覆更完整一些，讓這份報告可以直接貼回學習紀錄保存。

---

## 學習報告

### 今日學到什麼

- 今天表面上學的是 Pod filter、Service filter、label selector、field selector、`kubectl logs`、Pod Resource、Node Resource、Create Pod 等零散題型，但更高層的收穫是建立 CKA 雜項題的共同解題骨架：先找到正確證據，再做最小修改，最後驗證結果。
- CKA 題目可以先拆成一條觀察流程：Namespace -> Resource Kind -> Labels / Selectors -> Status -> Output Format。先確認題目在哪個 namespace、目標 resource 是什麼、條件來自 label 還是 Kubernetes 狀態欄位、最後要不要輸出或存檔。
- Label selector 是根據人貼在 resource 上的 `metadata.labels` 篩選，例如 `app=nginx`、`env=prod`。Field selector 是根據 Kubernetes 自己維護的欄位篩選，例如 `status.phase=Running`、`spec.nodeName=worker-1`。
- Service 題要分清楚 `metadata.labels` 和 `spec.selector`。前者是 Service 自己的 label，後者是 Service 用來選 Pod 的條件。題目若要求找帶有某 label 的 Service，通常是在查 Service 的 `metadata.labels`，不是查它選到哪些 Pod。
- `kubectl logs` 看的是 container 的 stdout / stderr，不是 Pod 這個抽象物件本身的 log。多 container Pod 需要指定 container；CrashLoopBackOff 時，真正有價值的錯誤常在上一輪已死亡 container 的 logs 裡。
- CrashLoopBackOff 的基本 debug 節奏可以先收成 `describe` -> `logs` -> `logs --previous`。`describe` 看 Kubernetes 狀態與事件，`logs` 看目前 container 輸出，`logs --previous` 看上一輪失敗原因。
- Requests 和 limits 是給不同角色看的。Requests 給 Scheduler 看，決定 Pod 能不能被排上 node；limits 給 runtime 看，決定 container 執行時最多能使用多少資源。
- CPU 和 memory 超過 limit 的結果不同：CPU 超過 limit 會被 throttle，memory 超過 limit 可能 OOMKilled。
- Node Resource 題要分清楚 Capacity、Allocatable、Allocated Requests、Actual Usage。Scheduler 看的是 allocatable 扣掉已被 requests 預約的資源，不是實際使用量。
- Create Pod 題的穩定節奏是：先判斷 `kubectl run` 能不能完成；需求較複雜時，用 `--dry-run=client -o yaml` 產生骨架，再只改必要欄位，最後一定驗證。

### 已能白話講清楚什麼

- Label 是人貼的標籤，field 是 Kubernetes 自己維護的欄位。找 `app=nginx` 這種條件通常用 label selector；找 Running / Pending 或某個 node 上的 Pod，通常是 field selector 的思路。
- Service 自己的 label 和 Service 選 Pod 的 selector 是兩件事。`metadata.labels` 是貼在 Service 身上的標籤，`spec.selector` 才是 Service 拿來對 Pod labels 做配對的條件。
- `kubectl logs` 比較精準地說是在看 container stdout / stderr；Pod 只是容器的包裝單位，所以多 container Pod 要說清楚要看哪一個 container。
- Requests 決定能不能排上 node，limits 決定執行時最多能吃多少資源。
- Pod Pending 可能是因為 Scheduler 看到 requests 超過 node 剩餘可排程資源，不是因為 node 當下 actual usage 一定很高。
- Memory 超過 limit 可能 OOMKilled；CPU 超過 limit 通常是 throttle。
- CrashLoopBackOff 時要看 previous logs，因為真正造成上一輪 crash 的錯誤常常已經不在目前正在重啟中的 container 輸出裡。
- Actual Usage 很低仍可能排不上 Pod，因為 Scheduler 做排程時看的是 Allocated Requests，不是即時用量。

### 目前還卡住什麼

- Field selector 的實際語法還需要靠 KillerCoda 題目建立肌肉記憶。現在已經知道什麼情境該用，但還需要練到能快速寫出來。
- Node Resource 題的觀察順序還需要實戰強化，尤其是看到真實輸出時，要能快速辨認 Capacity、Allocatable、Allocated Resources、Usage 各代表什麼。
- `kubectl logs` 題的變化還需要多練，特別是 namespace、多 container、CrashLoopBackOff、`--previous` 這幾種容易失分的組合。

### 今日最重要的觀念

- 先找證據，再操作：Namespace -> Kind -> Labels / Status -> Output。
- Label 是人貼的；field 是 Kubernetes 自己維護的。
- `kubectl logs` 看的是 container stdout / stderr，不是 Pod 本身的抽象 log。
- Requests 給 Scheduler 看；limits 給 runtime 看。
- CPU limit 超過通常 throttle；memory limit 超過可能 OOMKilled。

### 帶回 repo 內對照的問題

1. 找出 line-bot Deployment：它有哪些 labels？Service 是靠哪些 selector 選到它？請把 `Service -> selector -> Pod labels` 的對應關係畫出來。
2. 檢查目前 line-bot Deployment：有設定 requests 嗎？有設定 limits 嗎？如果某個 Pod Pending，我會先看哪個 Node Resource 資訊？請把 requests、limits、allocatable、allocated requests 套回目前叢集觀察。
