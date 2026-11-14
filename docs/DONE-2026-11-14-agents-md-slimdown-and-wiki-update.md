# 2026-11-14 AGENTS.md 瘦身、單 worker 定案與 CodeWiki 增量更新

整理日期：2026-11-14

## MEMOS

給沒有上下文的下一個 AI：先讀這一節。

- **目前狀態：** 三件事都已完成並 commit 在 `main`：單一 uvicorn worker 定案（`83259ec`）、`AGENTS.md` 改寫（`e72cd5b`）、CodeWiki 增量更新（`059ab07`）。
- **已 push：** 2026-11-14 把上面三個 commit 與這份文件一起推上 `origin/main`。同一次 push 還帶出兩個更早就留在本機的 commit：`42bfd20`（版號界線同日修訂的註記）與 `0fc59ee`（`AGENTS.md` 的 Discuss Before Acting 與 Public Repo Boundary）。push 會觸發 `.github/workflows/pages.yml` 部署 wiki。
- **沒有發版：** 這三件事都沒有改變叢集狀態，Kyo 決定不 release。理由見「為什麼不發版」。
- **下次要更新 wiki：** 直接照「CodeWiki 增量更新」一節的指令與檢查清單做，那一節記了這次踩到的兩個坑。
- **下次要改 `AGENTS.md`：** 先讀「AGENTS.md 改寫」一節的定位，不要把「淡化學習過程」誤解成「拿掉學習」。
- **待處理事項：** 見文末「待處理」。沒有卡住的工作。

## 單一 uvicorn worker 定案

Kyo 決定每個 Pod 固定一個 uvicorn worker。`manifests/deployment.yaml` 的 `--workers "1"` 值沒變，只把註解從「Step 3 診斷」改成設計理由，所以沒有觸發 rollout，`kubectl diff -f manifests/` 無差異。

理由與完整紀錄在 `docs/DONE-2026-11-14-node-maintenance-availability.md` 的「待決事項」第 3 項，這裡不重複。要記得的一點：這個 repo 沒有 HPA，副本數固定為 2，所以理由要寫「擴展靠副本數」，不要寫「靠 HPA」。

這個決定沒有寫進 `CHANGELOG.md`。

## AGENTS.md 改寫

### 定位

Kyo 已經找到 DevOps 工作。這個 repo 不再需要為了求職而展示「有條理的學習過程」，但它仍然是用來學習、實驗、部署的 repo，邊做邊學（例如 GitOps），成果要讓別人看得見。

所以改寫的方向是：**規則保留，淡化的是計畫與進度追蹤那一層**。AI 第一次提案時把它理解成「把學習內容移出主檔」，被 Kyo 糾正。之後再動 `AGENTS.md` 時以這個定位為準。

### Kyo 做的三個決定

| 問題 | 決定 |
| --- | --- |
| 新主題的預設流程 | 先 prework，再討論、實作驗證、寫紀錄。lesson（`QA`、`command` drill、報告）要 Kyo 開口才走 |
| 計畫與進度的規則（active plan 權威順序、Formal Progress Anchor、每日記錄規則） | 從主檔刪掉。12 週計畫與各 phase 計畫都已完成 |
| 修改範圍 | 起初只改主檔；review 後改成連 `learning/` 裡互相矛盾的幾行一起改 |

### 結果

`AGENTS.md` 從 170 行降到 104 行。

- `Goal`：改成現況描述，mock interview 改成正面寫法，`optimize for` 從五條併成三條。
- `Learning Workflow`：四個步驟，每一步都有完成條件（prework 建好後停住等 Kyo；討論到範圍與驗收條件談定；逐條驗證；只記實際做了、實際學會的）。
- `Source of Truth and Memory` 改名 `Reference Files`，只留「什麼情況讀哪裡」；`PROGRESS.md` 與舊計畫標成歷史。
- `CKA Repository Boundary`：五條縮成一段。
- `Configuration Work` 之後的維運小節沒有動。

`learning/` 的三個規則檔同步對齊：

- `learning/AGENTS.md`：進 lesson 的條件改成 Kyo 開口要；新主題的實作不經 lesson。
- `learning/prework/AGENTS.md`：prework 之後回到主檔的設計討論；拿掉更新 `28day-progress.md`。
- `learning/lessons/AGENTS.md`：維護方式只剩視需要更新 `ai-memories.md`；lesson 內給具體鼓勵那一條從主檔搬到這裡。

### Review 的做法

初稿寫完後，依 `writing-for-agents` skill 的規則做了一次獨立 review：兩個不同模型的唯讀 reviewer 各自看同一份說明，再由主 agent 對照 repo 驗證後整合。

採納的主要發現：

- 主檔與 `learning/` 規則互相矛盾（主檔說 lesson 要開口才走、進度檔不必更新，下層卻相反）。
- 流程步驟沒有完成條件。
- `Goal` 裡有 AI 用不到的歷史敘述。
- 刪掉了一條該留的規則：只把實際學會的寫成學會的。

沒有採納的：把 `Release Management` 的兩條常駐規則收進 `references/release-management.md`。重複是刻意的，理由記在 `docs/DONE-2026-11-14-release-management.md`。

## CodeWiki 增量更新

`docs/wiki/` 是 CodeWiki 生成的，經 `pages.yml` 發布在 GitHub Pages 的 `/wiki/`。它原本停在 2026-11-06 的 commit `e3def01`，`v1.0.0` 與 `v1.1.0` 的變動都不在裡面，這次更新到 `e72cd5b`。

### 指令

```sh
codewiki generate --update --output docs/wiki --github-pages --exclude ".agents"
```

- `--update` 只重寫受影響的頁面，語言與版面沿用 `docs/wiki/metadata.json` 存的設定。
- `--github-pages` 重新產生 `index.html`，Pages 上看到的是這個檔案。
- `--exclude ".agents"` 排除 vendored 的 stack-diagram skill。不加的話相依圖會從 16 個元件變成 76 個，其中 31 個來自 `.agents/`，wiki 會開始描述 skill 的腳本。

2026-11-06 當初完整生成用了哪些旗標沒有留下紀錄，以後以上面這一行為準。CLI 的旗標會隨版本變，執行前先用 `codewiki generate --help` 確認。

### 坑一：在 Codex 的沙盒裡跑會靜默失敗

第一次由 Codex agent 在它的沙盒裡執行，結果：

```
ERROR  Update agent for overview failed: [Errno 1] Operation not permitted
✓ Documentation generated successfully!
```

exit code 是 0，但 `overview.md` 一個字都沒改。CodeWiki 的 provider 是 `codex`，寫頁面時要再啟動一個 `codex` 行程；那次呼叫 0.001 秒就以 `PermissionError` 結束，沒有發生任何模型呼叫。改成在沙盒外執行同一條指令後成功。原因是推論，沒有另外隔離驗證，但兩次的差別只有沙盒與 `--exclude`。

所以不能只看 exit code 與成功訊息。**判斷是否真的更新，要看 `docs/wiki/update_record.json`：**

- `pages_written` 不是空的
- `verdicts` 裡該頁的 `changed_on_disk` 是 `true`
- `calls` 裡沒有 `error`
- `fallback.fired` 是 `false`（`true` 代表退回完整重建）

### 坑二：失敗的執行會污染狀態，要先還原才能重跑

失敗那次雖然沒改內容，卻做了兩件事：

1. 把 `metadata.json` 的 `commit_id` 寫成新的 commit。
2. 把 `docs/wiki/temp/dependency_graphs/` 裡存檔的相依圖覆寫成新版。

兩者都會讓下一次 `--update` 認為沒有東西要改。還原步驟：

```sh
git checkout -- docs/wiki/index.html docs/wiki/metadata.json docs/wiki/codewiki-icon.png
rm -f docs/wiki/update_record.json
cd docs/wiki/temp/dependency_graphs
/bin/cp -f weamind_infra_dependency_graph.prev.json weamind_infra_dependency_graph.json
```

- `docs/wiki/temp/` 被 `.gitignore` 排除，相依圖只能靠 CodeWiki 自己留下的 `.prev.json` 換回來。
- 這台機器的 `cp` 會互動式詢問是否覆寫，要用 `/bin/cp -f`。
- `temp/artifact_index.json` 也被覆寫而且沒有備份。這次沒有還原它，之後的增量更新仍然成功。

### 這次的結果

- 增量模式，沒有退回完整重建；`overview` 頁的判定是 `patch`。
- 一次模型呼叫，輸入約 24.3 萬 token（其中約 20 萬是快取讀取），輸出 1,638。
- `overview.md` 新增或修正的內容：image `1.3.0`、單 worker 的設計理由、PodDisruptionBudget、兩份 NetworkPolicy、hostname 拓撲分散、不掛載 ServiceAccount token、Grafana RBAC 與 sidecar 設定、`release.yml`，以及一節介紹 `references/` 的「應用容器與工作流程參考」。
- 新增的敘述對照過 manifest、`helm/watchmind-values.yaml` 與 `references/Makefile`，沒有發現與 repo 不符。唯一的簡化：PDB 只寫「至少一個 Pod 可用」，沒交代它只限制自願性驅逐。

### Kyo 對生成結果的三個決定

- `codewiki-icon.png` 從 256×256、40 KB 變成 1254×1254、558 KB：保留新的，大小可以接受。
- `docs/wiki/update_record.json` 進 git。原則是能進 git 就進 git，不輕易排除。進 git 前掃過，裡面沒有 IP、SSH 設定或叢集版本。
- 「應用容器與工作流程參考」一節留著，`references/` 不排除。

### 派工方式

Kyo 要求這類實作不要由主 agent 自己跑，而是經 `herdr-collaboration` skill 派給 subagent；這次用的是 Codex。主 agent 保留 git、還原與驗證。交辦時寫明：只跑指定的那一條指令、只動 `docs/wiki/`、不手改檔案、失敗就停下回報不換旗標重試。第一次失敗時 worker 確實照這個約定停下，才沒有把污染的狀態蓋掉。

## 為什麼不發版

Kyo 原本想為這次的改動發一版，討論後決定不發。依據是 `references/release-management.md`：

- tag 代表已同步到叢集並驗證過的狀態。從 `v1.1.0` 到現在，`manifests/`、`helm/`、`terraform/` 的差異只有 `deployment.yaml` 的一行註解，叢集狀態沒有變。
- 版號規則套不上：minor 是引進新機制，patch 是調整既有的值、版本或數量；註解、`AGENTS.md`、wiki 兩種都不是。
- `## [Unreleased]` 是空的，`release.yml` 遇到空段落會失敗。

可以沿用的判斷：只改文件、註解或 agent 規則時，push 就好，不打 tag。想讓某個沒有改變叢集的設計決策出現在 `CHANGELOG.md`，就先寫在 `## [Unreleased]`，等下次有叢集變更時一起帶出去。

## 待處理

- **新的學習流程還沒實際跑過。** `AGENTS.md` 的四個步驟第一次使用預計是 GitOps 的 prework，屆時才知道完成條件合不合用。
- **`AGENTS.md` 的 `Record File Style` 沒有精簡。** reviewer 建議縮成一段，Kyo 沒有選這一項。
- **`learning/` 還有兩句「若有 active plan」。** 在 `learning/AGENTS.md` 的 Continue Requests 與 `learning/prework/AGENTS.md` 的產生流程裡。兩句都是條件式，沒有計畫時不會觸發，這次沒改。
- **wiki 多久更新一次沒有定規則。** 這次是發完 `v1.1.0` 後 Kyo 主動提的。要不要寫進發版流程，還沒討論。

叢集本身的待決事項（Traefik 與 CoreDNS 的副本數、GitOps 實作、drain 行為的實測）不屬於這份文件，記在 `docs/DONE-2026-11-14-node-maintenance-availability.md`。

## 相關文件

- `docs/DONE-2026-11-14-node-maintenance-availability.md`：單 worker 定案的理由，以及叢集的待決事項。
- `docs/DONE-2026-11-14-release-management.md`：release 管理的主文件。
- `references/release-management.md`：tag 定義與版號規則。
- `AGENTS.md`、`learning/AGENTS.md`：改寫後的規則本身。
- `docs/wiki/update_record.json`：這次增量更新的執行紀錄。
