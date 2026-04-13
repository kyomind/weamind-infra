# Review Notes 寫作規則

## 目的

`review/notes.md` 是 WeaMind infra 複習模式的即時問答筆記。

它不是正式 lesson，也不是完整報告；它的用途是把使用者複習時臨時提出的疑問，整理成之後可以快速回看的短版解析。

## 適用時機

當使用者啟用 `review-mode`，或明確表示現在是在複習、不要進行課程時，AI 應依照本文件寫入 `review/notes.md`。

只記錄使用者真正提出的技術問題、架構問題、debug 問題或需要保留的概念釐清。

不用記錄：

- 純確認語氣，例如「了解嗎」
- 沒有形成技術疑問的閒聊
- 使用者明確說不要記下來的內容
- 只是在要求 AI 改文件格式的中介指令，除非該指令本身就是要保留的 Review 規則

## 基本格式

`review/notes.md` 的每個 H2 都是一個使用者問題。

```md
## <使用者問題的精簡標題>

<回答與解析>
```

標題可以稍微整理使用者的口語問法，但要保留原本技術意圖。若使用者用語音輸入造成小錯字或轉錄偏差，直接改成正確術語，不需要特別指出。

## 內容寫法

以普通段落為主，必要時才使用 bullet list、短指令區塊或簡短對照。

每一題的內容應該：

- 先直接回答問題
- 補上必要原因、邊界或 trade-off
- 盡量使用 WeaMind repo 內的實際架構、manifest、文件或 lesson note 作為依據
- 寫成使用者之後能直接拿來重講的版本
- 避免把一題擴成完整 lesson

若需要列指令，使用 `bash` code block：

```bash
kubectl get ingress -n weamind
kubectl describe ingress -n weamind
```

## 長度原則

預設每題控制在短篇筆記等級。

可以比一般聊天回答更完整，但不要寫成報告。若問題本身很大，先收斂成當下最有用的觀念與判斷順序，必要時在結尾加一小段「可以延伸但先不展開」。

## Repo 依據

回答需要 repo-backed context 時，優先使用：

- `docs/WeaMind Infra核心架構.md`
- `docs/WeaMind-README.md`
- `PROGRESS.md`
- `learning/lessons/`
- `.privatedocs/六週版學習計畫.md`
- `.privatedocs/28day-progress.md`
- `.privatedocs/ai-memories.md`

不要為了 Review 問答自動啟動 lesson workflow。Review 模式下，這些文件是查證與補脈絡用，不是排課入口。

## 寫入方式

新問題一律追加在 `review/notes.md` 檔案末尾。

如果使用者追問同一個問題，可以選擇：

- 在原本 H2 底下補一段「補充」
- 或另開一個新的 H2，標題清楚表示它是延伸問題

判斷標準是：如果追問仍在同一個概念內，補在原題；如果已經換成新的判斷軸或 debug 情境，另開新題。

## 隱私與公開性

`review/notes.md` 位於專案根目錄的 `review/`，預設視為可公開文件。

不要寫入：

- 真實密碼、token、secret、API key
- 私有 IP 或敏感 domain 的完整值，除非 repo 內公開文件已經允許使用
- 會讓系統攻擊面過度具體化的細節

需要提到敏感設定時，使用描述性代稱，例如「保壘機內網 IP」、「K8s 對外網域」、「LINE webhook URL」。

## 完成前檢查

寫入後快速確認：

- 每個新增區塊都是 `##` 問題標題
- 回答沒有不必要地展開成課程
- 沒有寫入敏感資訊
- 內容和 repo 事實不衝突
- 語氣像複習筆記，不像正式報告或行銷文
