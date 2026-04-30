# Lesson Patterns

- 學習內容預設要先開一個獨立 git 分支並 checkout，再用 PR 方式合併回 main。
- 從 2026-03-23 起，學習分支命名規則統一為 `lesson/<slug>`。
- 預設的 `<slug>` 直接使用當天 lesson 的 slug，但要去掉日期部分。
- 例如 lesson 名稱若是 `2026-03-16-deployment-basics`，對應分支名應為 `lesson/deployment-basics`。
- 若同一個分支會承接多天、但本質上屬於同一條學習主軸，可改用週級或主題級 slug；例如 W3 debug 主題可使用 `lesson/k8s-debug-and-troubleshooting`。
- 命名重點是保留 `lesson/` 前綴，並讓 slug 反映這個分支實際承接的學習主題；不要把日期放進分支名稱。

- 2026-03-16 Deployment lesson 可回查：`learning/lessons/2026-03-16-deployment-basics/03-command.md` 的 Command 4。
- 這一輪題型是先看 `kubectl get pods -n weamind --show-labels`，再要求使用者把 Pod 名稱前綴與 `pod-template-hash` 對回 ReplicaSet `weamind-5985b7f7f6`。
- 這題的價值不在直接讀答案，而在於讓使用者從輸出推理 `Deployment -> ReplicaSet -> Pod` 的執行期對應，適合保留成 command drill 的經典觀察題。
- 若之後新對話要複用這種題型，先回看 `learning/lessons/2026-03-16-deployment-basics/05-note.md` 的「為什麼第 4 題是高價值的 command drill？」再決定是否沿用。
- `05-note.md` 的正式版型以 `learning/lessons/lesson-template.md` 為準，不在 repo memory 重複維護同一套結構規則。
- lesson 過程中補寫 `05-note.md` 時，預設優先採 append 模式追加新 note；只有明顯為了同主題關聯性與可讀性，才插回前面既有段落之間。
- QA 只保留主答案與最小修正；延伸追問、額外原理、旁支理解預設移到 `05-note.md`。
- Flashcards 只有在使用者明確下指令時才建立或更新；不要在補 note 或補 QA 時順手新增。
- lesson / note 內容若出現「這樣做的好處是：」「最小鏈路可以收成：」這類上層項目，下面的子項目要做明確縮排，不和上層 bullet 混成同一層。
