# 2026-05-01 WeaMind CD Minimum Skeleton Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 以完整 release version 為 deploy source，建立 WeaMind 第一版 CD 最小 skeleton，優先驗證版本如何可靠進到 infra repo 的 deployment state。

## 今日實作順序

1. 先確認 infra repo 目前的 deployment state 與今天要改的最小邊界。
2. 再決定 skeleton 要落在文件、manifest 或 workflow 哪一層，並完成第一版變更。
3. 最後用最小證據驗證今天這版 skeleton 已能清楚回答 deploy source、更新策略與 rollback 邊界。

## 使用提醒

1. step 數量不設上限；若後續發現某一步過大，應直接往下拆成新的 `Step N`，不要勉強維持少量大步驟。
2. `06-implementation.md` 不需要在每一輪對話後即時逐字更新。若某個 step 會經過多輪討論、試錯或策略收斂，可以先在互動中推進，等到出現較大的進展、形成一段可複習的證據鏈，或該 step 結尾時，再把主要結果擇要回填。
3. 若某個 step 目前只完成設計稿或查詢草案，`實際執行內容` 可以先完整保留操作稿；`結果` 應明寫尚未實作驗證，`AI 判讀與收斂` 也只應收斂到是否已可進入實作，不應提前寫成已驗證完成。

## 驗收訊號與回退點

### 驗收訊號

- repo 內能看到以完整 release version 為 deploy source 的最小 skeleton，並能指出它實際停在哪一跳。
- 今天留下的 implementation 證據足以說明 deployment state 與完整 CD 還差哪段 automation。

### 回退點

- 若真正可執行的 automation 需要額外秘密管理或跨 repo 權限，先回退到只保留 skeleton 與 version state 變更。
- 若今天的變更無法形成清楚的 rollback 邊界，就縮圈到 manifest 與設計稿層，不硬做 deploy automation。

### Step 1

#### 這一步要驗證什麼

- infra repo 目前的 deployment state 是不是仍停在 `latest`，以及今天最小值得先改動的落點在哪裡。

#### 預計採取的動作

- 對照 `manifests/deployment.yaml`、W8 CD reference 與設計文件，確認今天第一步是 manifest version state、流程文件，還是 workflow skeleton。

#### 實際執行內容

- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 2

#### 這一步要驗證什麼

- 今天選定的最小 skeleton 能不能在不破壞 repo 邊界的前提下，清楚表達 release version 如何進到 infra repo。

#### 預計採取的動作

- 實作或補上最小 skeleton，讓 deploy source、更新策略與邊界能直接對 repo 內容講清楚。

#### 實際執行內容

- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 3

#### 這一步要驗證什麼

- 今天這版 skeleton 已解的問題、未解的問題，以及 rollback / release 邊界能不能被短版口述。

#### 預計採取的動作

- 用最小檢查或證據回看今天的變更，確認這版 skeleton 不會被誤講成完整 CD，並整理可複習的收斂句。

#### 實際執行內容

- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始
