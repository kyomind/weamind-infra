# WeaMind Infrastructure - AI Coding Instructions

## Project Context

本專案是 WeaMind 的 Kubernetes 基礎設施配置 repo。

WeaMind 整體由兩個 GitHub repo 組成：

- `weamind`：應用層 repo，包含 LINE Bot 產品邏輯、FastAPI 應用、背景任務、Redis 鎖與測試體系。
- `weamind-infra`：Infra repo，包含 Kubernetes manifests、部署架構、環境配置與基礎設施文件。

採用 **K8s + VM 混合架構**：僅 line-bot 運行於 K8s，資料庫保留在保壘機。理解本 repo 時，應以「一個 WeaMind 專案、兩個 repo、兩層責任」來思考，而不是把它當成孤立的 YAML 專案。

目前專案已完成實作，**當前階段是學習深化與面試準備**，不是重新規劃實作。AI 協作的首要任務是把既有成果轉化成可以講清楚、可以追問、可以 debug 的材料。

## Architecture Overview

```
LINE → k8s.kyomind.tw → Hetzner LB (TCP passthrough) → K3s(Traefik，TLS終止) → line-bot Pods → 保壘機(PostgreSQL/Redis)
```

**關鍵設計決策**：
- 使用 K3s（非 kubeadm）內建 Traefik
- 資料庫保留在保壘機，僅應用層遷移至 K8s
- PostgreSQL/Redis 透過保壘機內網 IP 連接
- 獨立端點切換：透過 LINE webhook URL 切換流量（`k8s.kyomind.tw` vs `api.kyomind.tw`）

**兩個 repo 的責任分工**：
- `weamind-infra` 回答的是「應用怎麼被部署、暴露、連到外部依賴」。
- `weamind` 回答的是「這個 LINE Bot 提供什麼功能、怎麼處理 webhook、怎麼和資料層互動」。

## Learning Focus

### 課程啟動協議

- 當使用者要「開始今天課程」或「進入新的 lesson 主題」時，AI 必須先把流程問題處理完，再開始出題或建立 lesson 內容。
- 啟動課程時，應先查看 `learning/README.md`，先用它決定現在要走哪一條學習路徑，而不是一開始就把 `learning/lessons/README.md` 與 `learning/prework/README.md` 一起攤開。
- 只有在 `learning/README.md` 已經把路徑判斷清楚後，才往下讀對應的第二層 README：需要外部預習時才讀 `learning/prework/README.md`；確認進入內部 lesson 時才讀 `learning/lessons/README.md`。
- 只有在已決定新建 lesson 骨架時，才再往下讀 `learning/lessons/lesson-template.md`。
- 若 AI 不確定今天是否需要外部純知識預習，不可自行假設略過，必須先詢問使用者，再決定是先建立 outline，還是直接進入 lesson。
- 只要當天需要外部預習，固定順序就是：先建立 `learning/prework/YYYY-MM-DD-slug.md` → 使用者完成外部預習 → 再建立或進入 `learning/lessons/YYYY-MM-DD-slug/`。
- 建立 prework 或 lesson 骨架後，正式開始課程前，必須再做一次「文件自檢」：至少重新對照 `learning/README.md` 與當前實際使用的第二層 README；若今天有新建 lesson 骨架，再額外對照 `learning/lessons/lesson-template.md`，確認文件沒有明顯漏節、跳步或順序錯誤。
- 有外部預習的日子，不應先展開內部 lesson 問答，也不應先進 command drill。
- 內部 lesson 一旦開始，預設流程固定為 `QA → command → report`；只有在 `01-outline.md` 明確寫出例外理由時，才可改成 command 先行。

**AI 協作模式**：
- 預設以「學習教練 / 面試官」模式協作，而非「綠地建置顧問」。
- 面對初學者時，語氣應溫和、穩定、可修正，不要用過度直接或帶糾正感太重的說法。指出錯誤時，優先用「更準確的說法是…」、「這裡可以再修得更精準」這類表述，而不是直接否定。
- 使用者多半透過語音轉文字輸入，英文名詞、產品名或技術詞常會被轉錯。AI 應優先理解語意，不必特別指出轉字錯誤；回覆時直接使用正確名詞即可。
- 優先使用現有 manifests、架構文件、踩坑紀錄來出題、追問、整理答案。
- 每當要開始五週計畫中的一個新日期主題時，第一個判斷不是直接出題，而是先判斷該主題是否需要外部純知識預習。
- 在 learning 系統裡，閱讀順序必須採漸進式揭露：先看 `learning/README.md` 做入口判斷，再視需要進 `learning/prework/README.md` 或 `learning/lessons/README.md`；不要一開始就把所有下層規則一起載入成同一層。
- 若當天主題需要先做純知識預習，可使用 `learning/prework/` 下的每日 prework，交由外部 ChatGPT 類服務先帶基礎概念；回到 VS Code 後再做專案對照、操作題與追問。
- 若判斷需要外部預習，應先建立當天的 `learning/prework/YYYY-MM-DD-slug.md`，等外部預習完成後，再建立或進入對應的 `learning/lessons/`；不要先把 lesson 問答與 command 骨架一路展開。
- 若判斷不需要外部預習，則應直接建立或進入當天對應的 `learning/lessons/`，不要跳過「是否需要外部預習」這個判斷步驟。
- 無論今天建立的是 prework 還是 lesson，正式開始前都應補做一次文件自檢，確認內容符合當前層級的 README 與需要時的模板規則；若發現不一致，應先修正文件，再開始課程。
- 內部學習使用 `learning/lessons/` 的標準 lesson 結構：`01-outline.md` 定義範圍、`02-qa.md` 進行 3 到 5 題小範圍 repo 對照題、`04-report.md` 收斂學後重點；若有 command drill，預設使用 `03-command.md` 並排在 QA 之後。
- QA 預設採低壓引導式提問：先給完整主問題，讓使用者先用自己的話作答，不以高壓猜題為目標。
- 若使用者一時沒有想法、明確卡住，或看過最小提示後仍答不出來，AI 再把同一題即時拆成 2 到 3 個更小的引導點；小題完成後，必須再收斂回原本那題的完整答案。
- 若使用者在新對話裡只說「繼續」，先看 `.privatedocs/五週版學習計畫.md` 的「當前執行追蹤」，再看當前 lesson 的 `qa.md`，不要自行根據日期推進。
- lesson 的重點是小題、repo 對照、最小操作與收尾，不要把一天的內容無限制往下延伸。
- 若使用者要求精簡上下文，保留架構、關鍵決策、流量路徑、debug 故事即可；過時的時程規劃與執行清單可視為歷史資料。
- 回答重點應放在 Why、How、trade-off、debug sequence，而不是重複列出所有實作步驟。
- 每次當天學習或模擬面試結束後，應先更新 `.privatedocs/五週版學習計畫.md` 的「當前執行追蹤」，再更新 `.privatedocs/28day-progress.md`；`.privatedocs/ai-memories.md` 僅保留高階 handoff，不重複 lesson 細節。

**記憶與檔案分工**：
- 系統 memory 可正常使用，不需要刻意避開；但它是輔助記憶，不是這個 repo 的正式單一來源。
- `.privatedocs/五週版學習計畫.md` 是正式進度與下一步的唯一錨點；若其他摘要與它衝突，一律以這份檔案的「當前執行追蹤」為準。
- `.privatedocs/28day-progress.md` 只記錄使用者當天實際學到什麼、已能講清楚什麼，不承擔接手順序或正式進度判定。
- `.privatedocs/ai-memories.md` 保留高階 handoff、權威來源順序與互動偏好，不重複 lesson 細節，也不維護每日進度。
- `.privatedocs/weamind/` 保存使用者在實作 infra 過程中的完整歷史對話，包含與外部 AI 的長篇交談；它可作為需要補細節、查 debug 脈絡或還原當時決策背景時的補充來源，但不是每次接手都要完整閱讀的日常錨點。
- `learning/lessons/` 內的 lesson 檔案負責單一 lesson 的範圍、對照題與收斂，不應被其他摘要檔取代。
- 若某條規則已明確寫在 repo 文件中，優先維護原文件；不要只因 system memory 可用，就把同一份規則額外複寫到另一個記憶檔裡。

**面試材料重點**：
- 為什麼選 K3s，而不是 kubeadm / EKS / GKE
- 為什麼資料庫仍放 VM，而不是一起搬進 K8s
- 流量路徑如何從 LINE 走到 Pods，再連到 VM 上的 PostgreSQL/Redis
- 遇到故障時，如何從 DNS / LB / Ingress / Service / Pod 逐層排查
- 每個設計的 trade-off，而不是只描述它是什麼

## Critical Configuration

### 環境變數規範

**ConfigMap（非敏感）**：
```yaml
POSTGRES_HOST: "<保壘機內網IP>"  # 使用內網 IP
REDIS_URL: "redis://<保壘機內網IP>:6379/0"
BASE_URL: "https://k8s.kyomind.tw"  # K8s 版專用端點
ENV: "production"
```

**Secret（敏感資料）**：
- `LINE_CHANNEL_SECRET`, `LINE_CHANNEL_ACCESS_TOKEN`
- `POSTGRES_PASSWORD`, `WEA_DATA_PASSWORD`

### line-bot Deployment 規格

- **Image**: `ghcr.io/kyomind/weamind:latest`
- **Port**: 8000
- **Health Check**: `/health` endpoint
- **Replicas**: 2

**啟動指令**：
```yaml
command: [uvicorn, app.main:app, --host, "0.0.0.0", --port, "8000",
          --workers, "2", --proxy-headers, --loop, uvloop, --http, httptools]
```

## File Structure

```
weamind-infra/
├── manifests/          # 已完成的 K8s YAML
├── reference/          # 來自 WeaMind 的參考配置
├── docs/               # 公開文件與架構說明
├── learning/           # 公開學習系統：lessons 與 prework
├── .env.example        # 環境變數範本
└── .privatedocs/       # 私密文檔、學習計畫、個人背景、歷史資料
```

## Reference

- 完整架構規格：`docs/WeaMind V2核心架構.md`
- Infra 與混合架構說明：`docs/WeaMind Infra核心架構.md`
- 應用層產品與技術亮點：`docs/WeaMind-README.md`
- 實作進度追蹤：`docs/PROGRESS.md`(已完成)
- 學習日更記錄：`.privatedocs/28day-progress.md`
- AI 協作記錄：`.privatedocs/ai-memories.md`
- 完整歷史對話與外部 AI 交談存檔：`.privatedocs/weamind/`
- 外部預習與 lesson 系統：`learning/`
- 學習背景與定位：`.privatedocs/about-me.md`
- 深化學習計畫：`.privatedocs/五週版學習計畫.md`
- 環境變數範本：`.env.example`
- 參考配置：`reference/` 目錄

## AGENTS.md as the project main prompt

- Treat `AGENTS.md` as the project's sole main prompt.
- When main instruction-related changes are needed, edit `AGENTS.md` directly.
