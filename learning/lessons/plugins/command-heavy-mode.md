# Command-Heavy Mode

## 用途

這份文件只處理 lesson 流程中的 command-heavy mode 例外規格。

它是按需讀取的 command-heavy 補充規則。

適用情境：

1. 今天的 lesson 明確以 command drill 為主，而不是概念展開型 lesson。
2. 今天需要把練習單位切得更小、判讀次數更高。
3. 今天雖然仍維持 QA → command → report，但 QA 只負責操作前定位，不負責展開大塊概念。

若今天不是這種 mode，則不需要讀本檔。

---

## 和 Lessons README 的分工

`learning/lessons/AGENTS.md` 仍是 `learning/lessons/` 的主規則檔。

本檔只補充兩件事：

1. command-heavy lesson 的 QA 應怎麼縮。
2. command-heavy lesson 的 `03-command.md` 應怎麼加密節奏。

換句話說：

1. 常態規則仍以 `learning/lessons/AGENTS.md` 與 `learning/lessons/rules/command.md` 為準。
2. 只有當天已判定為 command-heavy mode，才把本檔當成額外增量規則來讀。

---

## QA 的例外規格

若今天明確屬於 command-heavy mode，`02-qa.md` 仍應保留，但改成短版定位題。

建議調整為 2 到 3 題，角色是先對齊：

1. 這輪操作是在驗證哪一層。
2. 為什麼第一步先選這類指令。
3. 若看到某種輸出，下一步通常怎麼縮圈。

原則：

1. QA 仍然存在，但不要重講大塊概念。
2. 問題應短、小、直接，目的是讓後面的 command drill 有明確判讀座標。
3. 若某段延伸問答已超出這輪最小定位需求，優先放進 `05-note.md`，不要把 QA 再次撐大。

---

## Command Drill 的例外規格

若今天明確屬於 command-heavy mode，`03-command.md` 的骨架不再用常態的 2 到 4 輪，而改成固定 5 到 6 輪微情境。

這 5 到 6 輪的重點不是把每輪做大，而是：

1. 每輪只維持一個判讀閉環。
2. 增加判讀次數，而不是增加單輪複雜度。
3. 讓使用者能在較短週期內反覆做「選指令 → 看輸出 → 下結論 → 修正」這個循環。

建立與互動原則：

1. 建立 lesson 骨架時，就先把 5 到 6 輪主要題目骨架一次建好。
2. 每輪仍保留情境、候選指令、關鍵輸出、AI 判讀與一句話收斂。
3. 若今天輪次較多，建議分成兩小段，例如 3 輪加 3 輪，降低後段疲勞。
4. 每輪若需要額外追問，但已超出當輪最小閉環，詳細展開優先整理進 `05-note.md`。

---

## 不變的部分

即使今天是 command-heavy mode，下列常態規則仍然不變：

1. lesson 的內部預設流程仍是 QA → command → report；若要例外，仍需在 `01-outline.md` 寫明原因。
2. command drill 預設仍由使用者親手操作，AI 代跑只算輔助驗證。
3. `03-command.md` 仍以複習友善為優先，只保留最有判讀價值的輸出與結論。
4. `04-report.md` 仍在互動完成後再收斂，不預先代寫。

---

## 使用方式

若今天判定為 command-heavy mode，建議讀取順序為：

1. 先讀 `learning/AGENTS.md`，確認今天確實要進 lesson。
2. 再讀 `learning/lessons/AGENTS.md`，確認 lesson 的通用結構與檔案分工。
3. 最後再讀本檔，只拿 command-heavy 當天真的會用到的增量規則。

一句話原則：常態規則留在 `learning/lessons/AGENTS.md`，例外高密度節奏留在本檔，按需揭露。
