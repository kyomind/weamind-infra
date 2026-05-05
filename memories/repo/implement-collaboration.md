# Implement Collaboration

- implement-heavy 流程中，建立下一個 step 骨架時，可以在同一個回合同步於對話中提出 AI 的當前看法與建議；不必刻意拆成「先建 step、下一輪才講看法」。
- 分工仍要清楚：`06-implementation.md` 先記錄這一步的任務事項或骨架；對話中則直接補上 AI 的判斷、建議方向與理由，方便使用者當下決策。
- 若使用者當回合已明確同意 AI 的方向，下一步可直接回填該 step；不用為了形式再額外插入一輪只重複同一個看法。
- 這條規則主要適用於 implement-heavy lesson 的 step 推進，不用擴張成所有一般 lesson 的通則。
- 若 `06-implementation.md` 這類 step 記錄檔被 patch 弄亂、順序錯位或出現重複 heading，不要連續做 3 到 5 次局部修補；通常更快、更穩的作法是直接刪掉重建乾淨版本。
- 重建時只保留已確定完成的 step，未由使用者親手執行的動作一律退回骨架狀態，避免把 AI 代跑結果誤寫成使用者已完成。
- 重建後立刻做一次最小驗證：重讀整份檔案，確認 step 順序、狀態與「誰執行」描述都正確；必要時再跑該 markdown 的 errors 檢查。
