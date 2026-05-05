# Implementation AGENTS.md

這個子目錄負責 implement-heavy lesson 的 mode、骨架與 `06-implementation.md` 帶法，但三者的責任必須切開，不要互相膨脹。

## 分工

1. `learning/lessons/plugins/implementation/AGENTS.md`
   - 只負責說明 implementation 類文件的責任邊界。
2. `learning/lessons/plugins/implementation/implement-heavy-mode.md`
   - 只負責 implement-heavy mode 的適用情境、lesson flow 與和 QA / report 的關係。
3. `learning/lessons/plugins/implementation/implement-heavy-lesson-template.md`
   - 只負責 `01-outline.md` 與 `06-implementation.md` 的初始化骨架。
4. `learning/lessons/plugins/implementation/implementation-guide.md`
   - 負責 `06-implementation.md` 的實際帶法，例如 session 開場、step 推進、提問邊界與回填原則。

## 邊界提醒

1. mode 檔可以寫高階流程與節奏原則，但不要接手 `06` 的細部帶法。
2. template 檔可以保留和骨架形狀直接相關的提醒，但不要膨脹成操作手冊。
3. guide 檔負責說明 step 如何長出來、何時停下來、何時回填，不重複定義整份 lesson 的檔案清單。

## 一句話原則

- mode 檔回答「什麼時候用 implement-heavy」。
- template 檔回答「骨架怎麼長」。
- guide 檔回答「`06-implementation.md` 實際怎麼進行」。
