# WeaMind 架構圖：以 stack-diagram 產生並取代 README Mermaid

整理日期：2026-11-03

## MEMOS

- `README.md` 與 `README.en.md` 的 Architecture 區塊已從 Mermaid 改為 `<picture>` 嵌入 PNG，GitHub 會依讀者主題自動切換亮/暗圖
- 圖的唯一原始檔是 `docs/architecture-diagram/src.html`；`docs/site/index.html` 與兩張 PNG 都是由它產生的成品，**不要直接改成品**
- 互動版 HTML 透過 GitHub Pages 公開在 https://kyomind.github.io/weamind-infra/ ；`.github/workflows/pages.yml` 只部署 `docs/site/`，`docs/` 其他文件不會上 Pages
- README 的圖點下去就會開互動版，圖下方另有文字連結
- 重建指令寫在 `src.html` 開頭的 HTML 註解裡（build → render 兩行）
- 產圖工具 stack-diagram skill 已放進 repo：`.agents/skills/stack-diagram/`（本體）+ `.claude/skills/stack-diagram`（symlink）+ `skills-lock.json`
- Argo CD 尚未實作（使用者於 2026-11-03 確認），所以不進圖；圖示已預先抓好（`docs/architecture-diagram/icons/argocd.svg`），實作後再加
- 所有 commit 已 push 到 `origin/main`
- 待處理：見文末「待處理事項」

## 背景

README 原本用 Mermaid flowchart 畫架構，只涵蓋 LINE → LB → Traefik → Pods → PostgreSQL/Redis。cert-manager、監控、CI/CD 都不在圖上。這次用 stack-diagram skill 產生一張有品牌 logo、群組框和正交箭頭的工程圖，取代 Mermaid。

選擇取代而非並存：新圖是 Mermaid 的超集合，兩份並存遲早有一份過時。Mermaid 的「純文字可 diff」優點，由 `src.html` 進版控補回。

## 圖的內容與依據

內容依據 `README.md`、`docs/WeaMind Infra核心架構.md`、`manifests/`、`PROGRESS.md`、`Makefile`。

| 群組 | 節點 |
| --- | --- |
| （外部） | LINE Platform、Cloudflare DNS（`k8s.kyomind.tw`）、Let's Encrypt |
| GitHub | GitHub Actions（ci build）、GHCR（image registry） |
| Hetzner Cloud | Hetzner LB（tcp passthrough） |
| Hetzner Cloud › K3s · 3 nodes | Traefik、line-bot ×2（FastAPI）、cert-manager、Prometheus、Grafana |
| Hetzner Cloud › Bastion VM | PostgreSQL、Redis |

邊的三種樣式：

- 藍色實線（主要請求路徑）：LINE →`HTTPS`→ Hetzner LB →`TCP :443`→ Traefik →`HTTP`→ line-bot →`private net`→ PostgreSQL
- 灰色實線（內部）：line-bot → Redis；cert-manager →`TLS secret`→ Traefik；cert-manager →`DNS-01`→ Cloudflare、→`ACME`→ Let's Encrypt；Prometheus →`scrape`→ line-bot；Grafana →`PromQL`→ Prometheus
- 灰色虛線（dev/deploy）：GitHub Actions →`push`→ GHCR →`pull image`→ line-bot

刻意沒畫的：

- **Argo CD**：尚未實作（使用者確認）。現行部署仍是 `make deploy`（`kubectl apply`），`manifests/` 也沒有 `argocd-app.yaml`
- **堡壘機 SSH 管理路徑**、**單機版 `api.kyomind.tw` 入口**：會干擾主流程，需要時另畫小圖

## 檔案結構

```
docs/
├── architecture-diagram/
│   ├── src.html          # 唯一原始檔，圖示用 %%ICON_<name>%% token
│   └── icons/            # 圖示 + manifest.json（每個圖示的來源）
├── site/
│   └── index.html                  # build 產物，自包含（字型與圖示皆 base64 內嵌，約 205 KB），Pages 只部署這個資料夾
├── weamind-architecture.png        # render 產物（亮色）
└── weamind-architecture-dark.png   # render 產物（暗色）

.agents/skills/stack-diagram/   # skill 本體（MIT，caru-ini/stack-diagram）
.claude/skills/stack-diagram    # → ../../.agents/skills/stack-diagram（相對 symlink）
skills-lock.json                # skill 來源與 hash
```

## 如何修改並重建

1. 編輯 `docs/architecture-diagram/src.html`（座標規則見 `.agents/skills/stack-diagram/references/geometry.md`）
2. 需要新圖示時：

   ```bash
   python3 .claude/skills/stack-diagram/scripts/fetch_icons.py docs/architecture-diagram/icons <spec>...
   ```

3. 從 repo 根目錄重建：

   ```bash
   S=.claude/skills/stack-diagram
   python3 $S/scripts/build.py docs/architecture-diagram/src.html docs/architecture-diagram/icons docs/site/index.html --fonts $S/assets/fonts
   uv run --with playwright python $S/scripts/render_png.py docs/site/index.html docs/weamind-architecture.png --selector .canvas --scale 2
   ```

   `render_png.py` 會同時輸出 `weamind-architecture.png` 與 `weamind-architecture-dark.png`。本機沒裝 Playwright，所以用 `uv run --with playwright`。第一次跑要先執行 `uv run --with playwright python -m playwright install chromium`

4. **一定要打開兩張 PNG 實際看過**：箭頭不穿過文字、群組標籤不被線壓到、暗色下圖示可見

### 座標速記（現行版面）

- canvas 1160×900；node 寬 132，`left = centerX - 66`，tile 60×60，node box 約高 100
- 列的 tile top：GitHub 列 84、主流程列 382、第二列 522、底列 760
- 欄的 centerX：LINE 90、LB 290、Traefik/cert-manager 480、line-bot/Prometheus 640、Grafana 800、PG/Redis 1020；Cloudflare 320
- 群組：GitHub `390,24,340×210`；Hetzner `200,274,934×422`；K3s `390,322,500×350`；Bastion `930,322,180×350`
- 可用的垂直走廊：x=910（K3s 右緣 890 與 Bastion 左緣 930 之間，line-bot → Redis 的 elbow 用它）、x=560（Traefik 與 line-bot 之間）、x=720（Prometheus 與 Grafana 之間）

### 加 Argo CD 的建議做法

Argo CD 跑在叢集內，從 GitHub repo（`weamind-infra` 的 `manifests/`）拉期望狀態。可以把它放在 K3s 群組內，從 GitHub 群組拉一條虛線（`sync` / `git pull`）進來，再拉一條灰線到 line-bot（`apply`）。K3s 群組目前右側到 x=890 還有空間，必要時擴大 canvas。GitHub 群組內也可以補一個 `weamind-infra repo` 節點作為 Argo CD 的來源。

## 實作中的決策與踩坑

- **圖示來源**：svgl → devicon → gilbarbara/logos 都找不到的，改用官方檔案
  - LINE：Wikimedia `LINE_logo.svg`
  - Hetzner：hetzner.com 的 `apple-icon-180x180.png`（官網沒有 SVG favicon）
  - cert-manager：CNCF artwork repo
  - Traefik：devicon 的 `traefikproxy`
  - Hetzner LB 沒有專屬 logo，用 Lucide `split` 圖示
  - Bastion VM 用 skill 內建的 `assets/generic/server.svg`，暗色下加 `plate` class（白底襯）才看得見
- **群組配色**：Hetzner 群組把 template 的暖色 palette hue 從 55 調到 22（Hetzner 紅）；K3s 與 GitHub 用 accent 藍
- **第一版的碰撞問題**：K3s 群組標籤原本是 `K3s cluster · 1 control plane + 2 workers`，太長，壓到 `pull image` 虛線，縮短為 `K3s · 3 nodes`；`DNS-01` / `ACME` 標籤原本落在 Hetzner 框線上，往下移到 y=736
- **README 亮暗自動切換**：`<picture>` + `<source media="(prefers-color-scheme: dark)">` 是 HTML 標準，GitHub 的 sanitizer 允許，且 `prefers-color-scheme` 跟隨 GitHub 主題設定。不支援的檢視器會 fallback 到 `<img>` 的亮色圖
- **HTML 亮暗自動切換**：template 只有 `[data-theme="dark"]`，預設亮色。在 `<head>` 加了一行 `matchMedia('(prefers-color-scheme: dark)')` script 設定 `data-theme`。`render_png.py` 截亮色圖前會先 `removeAttribute('data-theme')`（`render_png.py:89`），所以截圖不受影響；已用 Playwright 模擬 light/dark 驗證
- **GitHub 上看不到渲染後的 HTML**：repo 內的 `.html` 只會顯示原始碼，raw 也是 `text/plain`。README 原本寫了一行原始檔路徑，但點了打不開，已刪除
- **只公開一頁的 Pages**：Pages 的 branch 部署來源只能選 `/` 或 `/docs`，會把整個 `docs/` 公開，且 Jekyll 可能被 `{{ }}` 弄壞 build。改用 GitHub Actions 部署（`upload-pages-artifact` 指定 `path: docs/site`），workflow 只在 `docs/site/**` 變更時觸發，也可手動 `workflow_dispatch`。Pages 設定的來源為「GitHub Actions」（`build_type=workflow`）
- **skill 進版控**：原本 `.claude/` 未追蹤，換機就無法重建。決定 vendor 進 repo（MIT 授權允許）。`.claude/settings.local.json` 是個人 skill 開關設定，改為 gitignore
- **macOS 檔**：repo 原本就沒追蹤任何 Apple metadata，`.DS_Store` 也早已 ignore。順手把 `._*`、`.AppleDouble`、`Icon\r`、`.Spotlight-V100` 等常見項補進 `.gitignore`

## Commits（已 push 到 origin/main）

| Commit | 內容 |
| --- | --- |
| `6795fb9` | Add WeaMind architecture diagram source and renders |
| `d02f693` | Replace README Mermaid diagram with rendered architecture image |
| `01f8e6d` | Ignore Claude Code local settings |
| `29cdabb` | Vendor stack-diagram skill for rebuilding the architecture diagram |
| `e88a9e1` | Ignore common macOS metadata files |

HTML 自動亮暗 script 與重截的 PNG 已包含在 `6795fb9` 內。

## 待處理事項

1. **Argo CD 上圖**：等 Argo CD 實際實作完成後，依上方建議加進圖並重建
2. **（可選）公開圖庫分享**：stack-diagram 可分享到 https://stacks.caru.moe ，但圖上有 `k8s.kyomind.tw`，分享前建議拿掉；需使用者明確同意才可送出
