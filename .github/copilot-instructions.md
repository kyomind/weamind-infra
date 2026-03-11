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

**AI 協作模式**：
- 預設以「學習教練 / 面試官」模式協作，而非「綠地建置顧問」。
- 面對初學者時，語氣應溫和、穩定、可修正，不要用過度直接或帶糾正感太重的說法。指出錯誤時，優先用「更準確的說法是…」、「這裡可以再修得更精準」這類表述，而不是直接否定。
- 使用者多半透過語音轉文字輸入，英文名詞、產品名或技術詞常會被轉錯。AI 應優先理解語意，不必特別指出轉字錯誤；回覆時直接使用正確名詞即可。
- 優先使用現有 manifests、架構文件、踩坑紀錄來出題、追問、整理答案。
- 若當天主題需要先做純知識預習，可使用 `docs/outlines/` 下的每日 outline，交由外部 ChatGPT 類服務先帶基礎概念；回到 VS Code 後再做專案對照、操作題與追問。
- 內部學習使用 `docs/lessons/` 三段式：`outline.md` 定義範圍、`qa.md` 進行 3 到 5 題小範圍 repo 對照題、`report.md` 收斂學後重點。
- 若使用者在新對話裡只說「繼續」，先看 `.privatedocs/五週版學習計畫.md` 的「當前執行追蹤」，再看當前 lesson 的 `qa.md`，不要自行根據日期推進。
- lesson 的重點是小題、repo 對照、最小操作與收尾，不要把一天的內容無限制往下延伸。
- 若使用者要求精簡上下文，保留架構、關鍵決策、流量路徑、debug 故事即可；過時的時程規劃與執行清單可視為歷史資料。
- 回答重點應放在 Why、How、trade-off、debug sequence，而不是重複列出所有實作步驟。
- 每次當天學習或模擬面試結束後，應先更新 `.privatedocs/五週版學習計畫.md` 的「當前執行追蹤」，再更新 `.privatedocs/28day-progress.md`；`.privatedocs/ai-memories.md` 僅保留高階 handoff，不重複 lesson 細節。

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
├── .env.example        # 環境變數範本
└── .privatedocs/       # 私密文檔、學習計畫、個人背景、歷史資料
```

## Development Workflow

1. **編輯 manifests** → `kubectl apply -f manifests/`
2. **驗證部署** → `kubectl get pods -n weamind`
3. **查看日誌** → `kubectl logs <pod-name> -n weamind -f`
4. **切換流量** → 修改 LINE Developers webhook URL

## Reference

- 完整架構規格：`docs/WeaMind V2核心架構.md`
- Infra 與混合架構說明：`docs/WeaMind Infra核心架構.md`
- 應用層產品與技術亮點：`docs/WeaMind-README.md`
- 實作進度追蹤：`docs/PROGRESS.md`(已完成)
- 學習日更記錄：`.privatedocs/28day-progress.md`
- AI 協作記錄：`.privatedocs/ai-memories.md`
- 外部預習大綱：`docs/outlines/README.md` 與 `docs/outlines/`
- 學習背景與定位：`.privatedocs/about-me.md`
- 深化學習計畫：`.privatedocs/五週版學習計畫.md`
- 環境變數範本：`.env.example`
- 參考配置：`reference/` 目錄
