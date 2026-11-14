# 2026-11-14 導入 release 管理：CHANGELOG、tag 與 release workflow

整理日期：2026-11-14

## MEMOS

給沒有上下文的下一個 AI：先讀這一節。

- **目前狀態：** release 管理的檔案已合併進 `main`（PR #13，merge commit `9ad3ffe`）。**`v1.0.0` 尚未打 tag，也還沒有 GitHub Release。**
- **規則的主文件：** `references/release-management.md`。`AGENTS.md` 的 `Release Management` 小節只留引用與兩條常駐規則。要改發版規則，改 references 那份。
- **發版入口：** `.github/prompts/release.prompt.md`。AI 先建議版號、請 Kyo 選定，再整理 CHANGELOG、打 tag、推送並驗證。
- **下一步：** 依該 prompt 推出 `v1.0.0`。推出後確認 `release.yml` 首次執行成功，並把結果補進本文件的「驗證」。
- **尚未驗證的事：** `.github/workflows/release.yml` 沒有在 GitHub 上實際跑過。
- **暫緩、不在本次範圍：** WeaMind 的 topology spread 與 PDB（Kyo 於 2026-11-14 指示先不做），以及 GitOps（Argo CD 已安裝，沒有任何 Application）。

## 背景

Kyo 決定從 2026-11-14 起，像 app repo（`WeaMind`）一樣替 weamind-infra 做版本管理。這裡的版本更新主要是部署設定的變更，不是應用邏輯。這個 repo 有作品集展示性質，所以 `CHANGELOG.md` 是給人讀的：每筆變更要寫出理由與取捨，讓讀者看得出架構思維。

## 已確認的決策

| 項目 | 決策 | 理由 |
| --- | --- | --- |
| tag 的意義 | 已同步到叢集並驗證過的狀態，事後標記 | 這個 repo 的 tag 沒有下游會讀它；定義成「已驗證的部署狀態」才有回滾點的用途 |
| GitOps 之後 | Argo CD 追 `main`，Synced 且 Healthy 後才打 tag；原則上禁止手動 `kubectl apply` | 若改成追 tag，app 每次發版開的 image bump PR 合併後，還要在這裡再發一版才會上線 |
| 版號 | 獨立的 SemVer，不跟 app 版本連動 | major 為架構改變，minor 為部署行為改變，patch 為 image bump 與數值微調 |
| `CHANGELOG.md` | 要有，手動編輯 | 自動產生的 release notes 只是 PR 標題清單，看不出設計理由 |
| 工具 | 不搬 app repo 的 `changelog.sh`、Makefile 指令與核可關卡 | 變更頻率低：2026-10-01 至 11-14 的 27 個 commit 中，只有 3 個動到 `manifests/` |
| 規則放哪 | `references/release-management.md`，`AGENTS.md` 只引用 | 發版不是每次工作都會用到，不該占 `AGENTS.md` 的篇幅 |

`AGENTS.md` 仍保留兩條常駐規則，因為它們的觸發時機不是發版當下：會改變叢集狀態的 PR 要在 `Unreleased` 寫一筆；沒被要求不要打 tag 或發版。

## 結果

以 commit `ca053d6` 提交，經 PR #13 合併。

- `CHANGELOG.md`：開頭說明 tag 定義與版號規則；空的 `## [Unreleased]`；`## [1.0.0] - 2026-11-14` 是現有架構的基準摘要，分六組共 17 項。
- `.github/workflows/release.yml`：push `v*` tag 時，用 `awk` 取出該版本的 CHANGELOG 段落，以 `gh release create --notes-file --verify-tag` 建立 Release。段落不存在或為空時失敗。沒有使用第三方 action。
- `references/release-management.md`：tag 定義、版號規則、CHANGELOG 流程。
- `.github/prompts/release.prompt.md`：可執行的發版流程。2026-11-14 稍晚新增，因為只給 Kyo 一行 git 指令不好用。
- `AGENTS.md`：新增 `Release Management` 小節。
- `README.md`、`README.en.md`：各加一個 `CHANGELOG.md` 連結。

基準摘要原本有一項「每個 Pod 只跑一個 uvicorn worker」，已刪除。`manifests/deployment.yaml` 的註解寫的是「Step 3 診斷」，那是排查指標問題時的暫時設定，不是設計決策。該設定要定案還是改回多 worker，尚未處理。

## 驗證

- **基準與叢集一致：** 2026-11-14 合併前後各跑一次 `kubectl diff -f manifests/`，都沒有差異。只涵蓋 `manifests/`；`helm/` 與 `terraform/` 沒有比對。
- **段落擷取：** 在本機用 workflow 的同一段指令測試。`1.0.0` 取出內容；`9.9.9`（不存在）、`Unreleased`（空段落）、`1.0`（不完整的版號）都判定失敗。
- **workflow YAML：** 可解析。本機沒有 `actionlint`，沒有做 lint。
- **基準摘要的內容：** 對照過 Grafana RBAC、NetworkPolicy、ServiceAccount token、Load Balancer passthrough、`Makefile` 的部署指令等項目的來源檔，沒有逐項查完全部。

## 待辦

1. 依 `.github/prompts/release.prompt.md` 推出 `v1.0.0`。該 prompt 會先建議版號並請 Kyo 選定，再打 tag、推送並驗證。
2. 確認 `release.yml` 首次執行成功，Release 內文是 `1.0.0` 段落。
3. 把上面兩步的結果補進本文件，並更新 MEMOS。

## 限制

- tag 與叢集是否一致靠人為紀律維持，GitOps 實作前沒有機制強制。
- 發版時把 `Unreleased` 改成版號的那個 commit，要先進 `main`，tag 才能打在它上面。走 PR 或直接 commit 沒有規定。
- Release 內文裡的相對連結會失效，所以 `CHANGELOG.md` 提到 repo 內的檔案時用行內路徑，不用 Markdown 連結。
