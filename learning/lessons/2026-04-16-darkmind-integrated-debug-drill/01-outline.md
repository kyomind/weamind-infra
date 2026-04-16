# 2026-04-16 Darkmind Integrated Debug Drill Outline

## 今日主題

- 用 `darkmind` 的既有壞情境，回收 W6 Day 1 到 Day 3 已練過的工具與觀察點，練成較完整的排查 sequence。

## 這次要解的專案問題

1. 今天面對一個壞 Pod 情境時，第一步應該怎麼選，才不會變成把所有指令輪流打一遍。
2. `get`、`describe`、`events`、`logs`、`exec`、`rollout` 各自回答不同層級的問題時，怎麼把它們接成一條縮圈路徑。
3. W6 Day 1 到 Day 3 練過的局部觀察點，怎麼收斂成一段 5 到 10 分鐘可口頭講完的完整排查敘述。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：今天不是新概念日，而是 W6 的整合驗收日；難點在於把已學過的工具與判讀順序串起來，而不是補通用機制。

## 要對照的 repo 檔案

1. `darkmind/README.md`
2. `darkmind/healthy.yaml`
3. `darkmind/scenarios/image-pull-error.yaml`
4. `darkmind/scenarios/crash-loop.yaml`
5. `darkmind/scenarios/bad-rollout-02-bad.yaml`
6. `.privatedocs/六週版學習計畫.md`

## 建議學習順序

1. 先做 `02-qa.md` 的 2 題短 QA，收斂今天的縮圈原則與第一步選擇標準。
2. 再做 `03-command.md` 的 3 題整合情境題；每題都先選第一步，再視輸出決定第二步與第三步。
3. 若過程中出現值得保留的延伸觀察，先記到 `05-note.md`，不要讓 QA 與 command 膨脹。
4. 最後回到 `04-report.md`，收斂今天真正練出的排查 sequence 與仍不穩的地方。

## 今日 command 練習

- 今天建立 `03-command.md`。
- 這不是 command 先於 QA 的例外日；仍先做短 QA，再進整合式 command 情境。
- 今天的 command 重點不是多跑輪數，而是練出「先看什麼、為什麼先看、看到後下一步怎麼縮圈」這條完整路徑。

## 文件分工

1. `01-outline.md`：規劃今天 W6 Day 4 的範圍與順序。
2. `02-qa.md`：記錄今天的短 QA、回答摘要與修正。
3. `03-command.md`：記錄 3 題整合情境的第一步選擇、後續觀察、判讀與一句話收斂。
4. `04-report.md`：在互動完成後收斂今天真正學到的整合式排查骨架。
5. `05-note.md`：承接延伸問答、暫時結論與之後可長成卡片的素材。

## 這次要追問的 Why / How 題

1. 為什麼整合式排查的第一步重點不是「先想到最多指令」，而是先選最能縮小範圍的證據入口。
2. 為什麼同樣是壞 Pod，`ImagePullBackOff`、`CrashLoopBackOff`、bad rollout 這三種情境不應套用同一條固定指令順序。
3. 為什麼今天真正要驗收的不是單一工具會不會用，而是能不能把觀察、判讀與下一步決策串成穩定 sequence。

## 這份 lesson 的完成標準

1. 能用自己的話說出今天整合情境的第一步選擇原則。
2. 能完成至少 2 題整合情境題，並在每一步說出自己正在驗證哪一層。
3. 能用 5 到 10 分鐘口頭講完一段完整排查流程，而不是只列指令名稱。
