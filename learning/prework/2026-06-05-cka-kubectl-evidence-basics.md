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

- 待填

### 已能白話講清楚什麼

- 待填

### 目前還卡住什麼

- 待填

### 今日最重要的觀念

- 待填

### 帶回 repo 內對照的問題

1.
2.

