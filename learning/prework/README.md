# Prework

`learning/prework/` 用來存放每日外部預習 prework。

少數情況下，這裡也可以承接 lesson 結束後才補建的輕量 homework；這類檔案仍放在 `learning/prework/`，但內文必須明確標示它是課後補強，不是正式課前預習。

這些檔案主要給外部 ChatGPT / TradeGPT 類型的對話服務使用，目的是先建立純知識骨架，再把學習報告帶回 VS Code 做 repo 對照。

## 文件分工

- `README.md`：說明這個目錄的用途、檔案分工與閱讀入口。
- `AGENTS.md`：prework 的 AI 工作規則、命名、段落骨架、輸出要求與 lesson 銜接方式。
- `prework-template.md`：prework 檔案格式骨架。

## 內容定位

外部 AI 負責：

- 名詞理解
- 白話解釋
- 最小骨架建立
- 輕量理解確認

VS Code 內的 AI 再負責：

- 對照實際 manifests 與文件
- 指出專案特定設計選擇
- 帶操作題與 debug 題
- 追問 Why、trade-off、debug sequence
- 更新必要的學習紀錄

## 閱讀入口

進入 prework 前，應先由 `learning/AGENTS.md` 判斷今天確實需要外部預習，或確認這是 lesson 後的 homework 型補強。

已確認要建立或維護 prework 時，再讀本目錄的 `AGENTS.md` 取得規則。
