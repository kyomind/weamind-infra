# 2026-03-25 K8s Debug Operations Note

## 學習注意事項

### 今天在整體 debug arc 的角色

- W3 Day 1 建立的是分層判讀框架。
- W3 Day 2 建立的是工具語意與證據類型。
- W3 Day 3 要做的是把前兩天接起來，練習遇到具體故障時，怎麼排出第一步、第二步與下一步。

### 今天進 lesson 前先記住的邊界

- 今天不重教 Pending、ImagePullBackOff、CreateContainerError、CrashLoopBackOff 的基本定義。
- 今天也不展開新的進階工具，例如 ephemeral container 或完整故障演練劇本。
- 今天只聚焦在 WeaMind 已經遇過或很合理的故障情境，練「先看哪裡、為什麼、下一步是什麼」。

### 今天要特別避免的誤判

- 不要把 `Pod Running` 或 `Ready=True` 誤讀成整條外部流量路徑一定沒問題。
- 不要把 `exec` 成功誤讀成 PostgreSQL、Redis、Ingress、LB、LINE webhook 路徑都已被驗證。
- 不要把 `404`、`500`、timeout 全部當成同一種故障；第一輪較值得懷疑的層次常不同。

## Notes

### 今天的最小操作骨架

1. 先用症狀判斷比較像哪一層先出事。
2. 先選一個最能縮小範圍的第一輪證據入口。
3. 根據輸出決定下一步，不預設把所有工具都跑過一遍。
4. 最後收斂成一句完整 debug sequence。

### 今天想練熟的口訣

- 先分層，再選工具。
- 先拿證據，再決定下一步。
- 每一輪操作都要回答：我現在在驗證哪一層。

### 待補的 lesson 中結論

- 待補

## Flashcards

- W3 Day 3 的最小目標是什麼？ #DevOps #card
	- 不是再背更多指令
	- 而是拿到具體故障情境後，能排出較合理的第一步與下一步
	- 並把觀察收斂成可重講的 debug sequence

- 為什麼 `Running` 與 `Ready=True` 不能直接代表整條系統沒問題？ #DevOps #card
	- 因為它只代表 Pod lifecycle 與 readiness 條件目前過關
	- 不代表 Ingress、LB、webhook path、外部 DNS 或外部依賴一定都正常
	- 仍要回到實際症狀判斷第一輪應先查哪一層

- debug 操作篇最重要的順序是什麼？ #DevOps #card
	- 先用症狀分層
	- 再挑第一個高價值觀察點
	- 看完輸出後再決定下一步，而不是一次把所有工具打滿
