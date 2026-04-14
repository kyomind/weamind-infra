# 2026-04-14 Darkmind Logs Previous Rollout Report

## 今日主題

- 用 `crash-loop` 與 `bad-rollout` 兩種情境，建立 Day 2 的 log / rollout 排查骨架。

## 狀態

- 進行中

## QA 收斂了什麼

- QA 先把 Day 2 的三個核心邊界講準了：`logs` 是 app / container 執行期證據，`logs --previous` 是上一輪已退出 container 的證據，而 rollout 類指令看的則是 Deployment / revision / 回退這個控制面層級。
- 也補正了幾個容易混淆的點：`CrashLoopBackOff` 不是 create container 前段失敗，而是 container 有啟動過又很快退出；`rollout history` 看的不是單純「每次成功或失敗報表」，而是 revision 軌跡。

## 使用者原本卡住什麼

- 一開始對 `Running` 與 `Ready` 的差異、`current log` 和 `previous log` 的邊界、以及 rollout 類指令到底在看哪一層還不夠穩。
- 另外也追問了幾個很有實務價值的細節：rollback 前後壞 Pod logs 的可見性、`CrashLoopBackOff` 是否會自動停住或刪 Pod、第一次 apply 算不算 rollout、`CHANGE-CAUSE` 為什麼是 `<none>`。

## 今日 command 練習收斂

- 今天完整走完了兩條 Day 2 最小排查鏈。第一條是 `crash-loop`：先建立健康基準，再套情境，用 `get pods` 確認 `CrashLoopBackOff`，再看 `logs` 與 `logs --previous`。第二條是 `bad-rollout`：先用 good version 建基準，再套 bad version，用 `rollout status` 確認 timeout，用 `rollout history` 看 revision，最後用 `rollout undo` 回退並再次確認 rollout 成功。
- 這次不只照指令跑，還刻意把幾個步驟分時間執行，觀察狀態如何收斂或如何卡住，這對理解 rollout 與 crash 類問題很有幫助。

## 今日真正留下來的核心收穫

- `logs` / `logs --previous` 和 `rollout status` / `history` / `undo` 不是同一層工具；前者偏 app / container 證據，後者偏 Deployment 控制面證據。
- `CrashLoopBackOff` 通常會繼續重試，不會自動刪 Pod，但 `--previous` 的可見性不穩，重要證據要早點留。
- `kubectl rollout undo` 回的是內容，不是 revision 編號；因此 undo 後 revision 會增加，而不是倒退。

## 學完後已能講清楚什麼

- 能講清楚 `Running` 和 `Ready` 的差異，以及 readiness probe 在 Ready 判定中的角色。
- 能講清楚 `current log` 與 `previous log` 的分工、為什麼在 crash loop 類問題裡兩者常要一起看。
- 能講清楚 Deployment rollout 卡住時，為什麼要改看 `status`、`history`、`undo`，以及 timeout、revision、rollback 各自代表什麼。

## 仍待補強什麼

- rollout 卡住時如何再搭配 `describe`、`events`、`get rs` 做更細的控制面排查，還可以再補一輪。
- `CHANGE-CAUSE` 這類變更紀錄在真實團隊工作流裡如何維護，還可再補 CI/CD 情境對照。

## 下一步

- 若今天繼續互動，可先收你接下來的追問，再視需要補進 `05-note.md`。
- 若今天先收尾，下一步就是執行固定 cleanup，然後把 lesson 狀態收斂成完整 report。
