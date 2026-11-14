---
description: "Release weamind-infra: check that main matches the cluster, suggest a version, ask Kyo to choose it, then finalize CHANGELOG.md, tag, push, and verify the GitHub Release."
---

# Release weamind-infra

## 任務目標

發出 weamind-infra 的一個版本：確認 `main` 與叢集一致、建議版號並請 Kyo 選定、整理 `CHANGELOG.md`、打 tag、推送，最後驗證 GitHub Release。

tag 的定義與版號規則以 `references/release-management.md` 為準，開始前先讀。

## 核心規則

1. 使用 zh-TW。
2. **版號由 Kyo 選定。** 先提出建議與理由，再詢問；有內建提問功能時用它讓 Kyo 選，沒有時列出選項詢問。得到明確的版號之前，不 commit、不打 tag、不 push。
3. Kyo 選定版號，就是核可這次發版的 commit、tag 與 push，不必再逐步詢問。
4. 任一檢查失敗就停止並說明失敗點，不要跳過或自行修正叢集。
5. 這個 prompt 不部署、不更動叢集；`kubectl` 只用唯讀指令。

## 流程

### 1. 檢查前提

- 目前分支是 `main`，工作樹乾淨，且與 `origin/main` 同步。
- 取得最新 tag：`git describe --tags --abbrev=0`。沒有任何 tag 代表這是首次發版。
- 讀 `CHANGELOG.md` 的 `## [Unreleased]` 段落，以及最新 tag 之後的 commit：`git log --oneline <最新 tag>..HEAD`。

### 2. 確認 `main` 與叢集一致

- GitOps 實作前：`kubectl diff -f manifests/` 必須沒有任何差異。
- GitOps 實作後：Argo CD 的 Application 必須是 Synced 且 Healthy。

有差異代表變更還沒套用或驗證，停止並回報差異內容。

### 3. 判斷發版內容

- **`Unreleased` 有內容**：這些就是本次發版的內容。
- **`Unreleased` 是空的，且最上面的版本段落還沒有對應的 tag**：直接發那個版本，不必改 `CHANGELOG.md`（首次發版屬於這種情況）。這時建議的版號就是該段落的版號。
- **`Unreleased` 是空的，但最新 tag 之後有會改變叢集狀態的 commit**：代表漏記。依那些 commit 草擬條目，寫進 `Unreleased`（不 commit），在下一步連同版號一起給 Kyo 看。
- **以上皆非**：沒有東西可發，回報後結束。

### 4. 建議版號並詢問

依 `references/release-management.md` 的版號規則，取影響最大的那一筆決定升級幅度，然後向 Kyo 提出：

- 建議的版號，以及一句理由（哪一筆變更決定了幅度）。
- 本次發版的 CHANGELOG 變更：先用建議的版號把第 5 步第 1 點的改名寫進工作樹（不 commit），讓 Kyo 自己看 `git diff`。Kyo 要先看過 diff 才選版號；在回應裡貼出內容不能取代這一步。
- 其他合理的版號選項。

等 Kyo 選定。Kyo 要求修改條目或選了別的版號時，改在工作樹裡，請他再看一次 diff。

### 5. 整理 CHANGELOG 並發版

1. 需要改名時：把 `## [Unreleased]` 改成 `## [X.Y.Z] - YYYY-MM-DD`（台北日期），上方補一個新的空 `## [Unreleased]`。這一點在第 4 步已經先寫進工作樹，這裡確認版號與 Kyo 選定的一致。
2. 用與 workflow 相同的指令確認該版本取得出非空段落：

   ```sh
   awk -v h="## [X.Y.Z]" 'index($0, "## [") == 1 { p = index($0, h) == 1; next } p' CHANGELOG.md
   ```

3. `CHANGELOG.md` 有變更時，commit 為 `Release vX.Y.Z` 並推上 `main`。
4. 打 tag 並推送：`git tag vX.Y.Z && git push origin vX.Y.Z`。

### 6. 驗證

- `gh run list --workflow release.yml -L 1`：這次的 run 成功。
- `gh release view vX.Y.Z`：Release 存在，內文是該版本的 CHANGELOG 段落。

workflow 失敗時回報錯誤內容；不要刪除 tag 或重推，除非 Kyo 要求。

## 完成後回報

1. 發出的版號與 tag 所在的 commit
2. 包含的條目
3. GitHub Release 連結
4. 驗證結果
