# Phase2 學習計畫

> WeaMind 深化期的三週版摘要。保留高層架構，不展開每日 lesson。
> 目標是把 observability、Helm/CD、Terraform/IaC 這三段 Phase 2 主線，整理成可實作、可解釋、可在面試中講清楚的經驗。

---

## 計畫總覽

| 週次 | 日期        | 主軸                                     | 產出                            |
| ---- | ----------- | ---------------------------------------- | ------------------------------- |
| W7   | 4/20 - 4/24 | 可觀測性骨架、Prometheus、Grafana        | 觀測筆記、dashboard、短版答題稿 |
| W8   | 4/27 - 5/1  | Helm 進階、WeaMind CD 設計與最小實作     | CD 設計稿、實作稿或文章骨架     |
| W9   | 5/4 - 5/8   | Terraform、GCP Free Tier、IaC 基礎與收斂 | IaC 練習紀錄、答題稿、經驗整理  |

### 版本定位

- 這份文件是 Phase 2 的中層摘要，介於總計畫和每日 lesson 之間。
- 它保留每週主軸、主要產出與節奏，不寫到 command-level 或每日 QA / command drill 細節。
- 若要看完整每日安排，回到三週版詳細計畫；若要看跨階段路線，回到 12 週計畫。

---

## 執行節奏

- 週一到週三：主學習日
- 週四：半天主線推進 + 半天補強 / 收斂
- 週五：固定彈性日
- 每日主線：約 3 小時
- 週上限：12 到 15 小時
- 英文：每日 45 分鐘，獨立於主線之外
- 若當週主題膨脹，優先保住最小可驗收成果，不硬追工具深水區。
- 週六日保留為緩衝，不把它們算進主線輸出。

---

## Phase2 重點

- W7：先把 Metrics Server、Prometheus、Grafana、Alertmanager、HPA 的最小分工切清楚，再完成一套最小可觀察骨架。
- W8：把 Helm 從「會裝」推進到「能解釋 release / values / chart 的模型」，並接回 WeaMind 現有 CI / image publish 脈絡，收斂成 CD 設計與最小實作。
- W9：建立 Terraform 的 core workflow、state、drift 與宣告式 IaC 基礎，並用 GCP Free Tier 做一次最小練習。

### 每週驗收方向

- W7：能不能說清楚 observability 工具分工，並做出一版可 demo 的最小觀測成果。
- W8：能不能講清楚 Helm 與 raw manifests / Kustomize 的差異，並把 WeaMind 的 CD 邊界與最小方案說明白。
- W9：能不能走完一次 Terraform 的基本循環，並講清楚 state、drift 與 Kubernetes manifest 的差異。

### Phase2 定位

- 這一階段不是把 Prometheus、Grafana、Helm、Terraform 學成專家，而是補到「履歷有、做過、被問時講得出來」的程度。
- 驗收優先看三件事：是否真的做過、是否知道它在整體系統裡解什麼問題、是否能講出自己的做法與取捨。
- 每個主題都要盡量對回 WeaMind 的真實部署、交付與 operations 脈絡，不把工具當成孤立名詞背誦。

### 常見風險

- 風險一：把工具學習擴成無限深挖，結果主線產出反而失焦。
- 風險二：只記住安裝步驟，卻講不出元件分工、責任邊界與 trade-off。
- 風險三：把學習內容和實作內容混在一起，最後無法明確驗收「今天到底做了什麼」。
- 風險四：只談抽象 DevOps 名詞，沒有回到 WeaMind 目前 repo、部署流程與實際限制。

### 產出原則

- 每週至少保留一個可以對外說明或面試重講的結果。
- 實作不是為了做大，而是為了留下可驗收、可解釋、可對照 repo 的證據。
- 先顧主題骨架與邊界，再補最小操作與答題稿，不反過來。

---

## 一句話總結

用三週把 WeaMind 的 observability、Helm/CD、Terraform/IaC 主線補到能做、能講、能對回真實系統脈絡的程度，同時維持可收尾、可驗收的節奏。
