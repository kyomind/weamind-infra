# WeaMind 系列連結統一遷移至部落格

整理日期：2026-07-12

## MEMOS

- WeaMind 系列文章清單已從 GitHub `blogs/README.md` 遷移至 `https://blog.kyomind.tw/weamind-series/`
- 所有指向 GitHub blogs/ 的連結已更新完畢，WeaMind repo 的 `blogs/` 目錄已刪除
- 無待處理事項

## 背景

blog repo 完成 navbar 調整後（見 `blog/themes/even/docs/DONE-2026-07-12-navbar-tags-weamind-adjustment.md`），WeaMind 系列文章清單從 GitHub README 搬遷至部落格站內頁面 `/weamind-series/`。

這導致多個 repo 的 README 連結需要同步更新，原本指向 `https://github.com/kyomind/WeaMind/blob/main/blogs/README.md` 的連結都要改為 `https://blog.kyomind.tw/weamind-series/`。

## 變更內容

### 1. weamind-infra README

中英文 README quick-links 表格：

| 項目 | 變更前 | 變更後 |
|------|--------|--------|
| 表頭 | 📝 系列文章 / 📝 Blog Posts | 📝 系列文章 / 📝 Blog Series |
| anchor | blogs/ | 文章清單 / Posts |
| 連結 | GitHub blogs/README.md | blog.kyomind.tw/weamind-series/ |

### 2. WeaMind README

同上調整 quick-links 表格，另外：

- 表頭從「📝 系列文章介紹」簡化為「📝 系列文章」
- 第 130 行「系列文章」連結也從 GitHub 改為部落格

### 3. weekly-review

兩篇週報的 WeaMind 系列連結更新：

- `2025/ep-29.md`：WeaMind 系列連結
- `2025/ep-31.md`：清單連結

### 4. 刪除 WeaMind blogs/ 目錄

確認無其他引用後，刪除 `WeaMind/blogs/` 目錄。

不需更新的檔案：
- `FLOW/archive/` 底下的草稿存檔（對應的部落格文章已在先前更新）
- `blog/themes/even/docs/DONE-...` 紀錄文件（描述歷史狀態，不需修改）

## 設計決策

### anchor 文字選擇

採用「標題—內容」分層結構，避免重複：

| | 中文 | 英文 |
|---|---|---|
| 標題 | 📝 系列文章 | 📝 Blog Series |
| 內容 | 文章清單 | Posts |

### 刪除 vs 保留重定向

選擇直接刪除 `blogs/` 目錄，理由：
1. 已知連結都已更新（2 個 repo README + 7 篇部落格文章 + 2 篇週報）
2. 個人專案，外部流量有限
3. 保留重定向說明看起來像「忘了清理」

## 涉及 Repo 與 Commit

| Repo | Commit | 說明 |
|------|--------|------|
| weamind-infra | `87b359a` | README 連結更新 |
| WeaMind | `cdd1f98` | README 連結更新 + 刪除 blogs/ |
| weekly-review | `26c1945` | 2 篇週報連結更新 |

## 如法炮製

若未來有類似「內容從 A 位置遷移到 B 位置」的情況：

1. 先用 `rg` 搜尋所有引用 A 的檔案
2. 區分「需要更新」與「不需更新」（紀錄文件、草稿存檔等）
3. 更新所有需要更新的連結
4. 確認無引用後再刪除原檔案
5. 分 repo commit，各自說明變更內容
