# 2026-05-01 WeaMind CD Minimum Skeleton Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 以 WeaMind 現有 release 與 infra 邊界為基礎，做出第一版可驗收的 CD 最小 skeleton。

## 今日實作順序

1. 先確認 infra repo 目前的 deployment state 還停在哪裡，以及它和今天目標之間的最小差距。
2. 再決定第一個最誠實的落點應該是 version state、流程 skeleton，還是最小自動化骨架。

## 使用提醒

1. step 數量不設上限；若後續發現某一步過大，應直接往下拆成新的 `Step N`，不要勉強維持少量大步驟。
2. `06-implementation.md` 不需要在每一輪對話後即時逐字更新。若某個 step 會經過多輪討論、試錯或策略收斂，可以先在互動中推進，等到出現較大的進展、形成一段可複習的證據鏈，或該 step 結尾時，再把主要結果擇要回填。
3. 若某個 step 目前只完成設計稿或查詢草案，`實際執行內容` 可以先完整保留操作稿；`結果` 應明寫尚未實作驗證，`AI 判讀與收斂` 也只應收斂到是否已可進入實作，不應提前寫成已驗證完成。
4. 每個 step 的 `實際執行內容` 第一個 bullet，應先標記這次主要由誰實作，例如：`本次由 AI 實作`、`本次由使用者實作`；若屬於明確分段協作，也可以寫成 `本次由 AI 與使用者協作`。

## Session 開場提醒

- `06-implementation.md` 的實際帶法不要寫死在模板裡；開場規則、step 推進與提問邊界改讀 `references/lesson-plugins/implementation/implementation-guide.md`。

## 驗收訊號與回退點

### 驗收訊號

- repo 內能指出目前 deployment state 的真實位置，並能說清楚今天第一個最小落點準備落在哪一層。

### 回退點

- 若今天還不能安全落成真正 automation，至少保留清楚的 skeleton 與版本邊界，不假裝已完成 deploy automation。

### Step 1

#### 這一步要驗證什麼

- infra repo 目前的 deployment state 是否仍直接追 `ghcr.io/kyomind/weamind:latest`，以及這是否就是今天要先處理的最小落差。

#### 預計採取的動作

- 對照 `manifests/deployment.yaml` 與 `references/phase2/w8-cd-minimum-spec.md`，確認目前 state 與目標 state 的最小差距。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 對照 `manifests/deployment.yaml` 與 `references/phase2/w8-cd-minimum-spec.md`，先確認 repo 現況與今天目標之間的最小差距。
- 使用者同步確認目前 Deployment image 仍指向 `ghcr.io/kyomind/weamind:latest`，並同意這就是今天要先處理的第一個落差。

#### 結果

- `manifests/deployment.yaml` 目前仍直接使用 `ghcr.io/kyomind/weamind:latest`。
- `references/phase2/w8-cd-minimum-spec.md` 已明確收斂：正式 deploy source 應該是完整 release version tag，而不是 `latest`。
- 因此目前 infra repo 的 deployment state 仍沒有用 Git 明確記錄正式 release version。

#### AI 判讀與收斂

- Step 1 的短結論是：今天第一個最小落差，就是 infra repo 的 deployment state 仍追 `latest`，還沒有用 Git 明確記錄正式 release version。
- 這也說明今天後續的第一個有效落點，應該優先圍繞 version state 與其 repo-backed 表達方式，而不是直接假裝已經做成完整 deploy automation。

#### 目前狀態

- 已完成

### Step 2

#### 這一步要驗證什麼

- 在確認現況後，第一個最誠實的 repo-backed 落點應該放在哪一層，才不會假裝已經做成完整 CD。

#### 預計採取的動作

- 先在對話裡比較 version state、流程 skeleton、最小 automation 骨架三個候選落點，再收斂今天第一個最誠實的 repo-backed 落點。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先提出三個候選落點：直接改 version state、先做流程 skeleton、或先做最小 automation 骨架。
- 使用者判斷直接改 version state 幫助有限，因為今天要建立的是流程，不是只改一個結果值。
- 使用者同意今天第一個較合理的落點應該是流程 skeleton，而不是直接去做 version state 或過早進入 automation。
- 使用者同意先由 AI 起草第一版 skeleton，因為這一步主要是低摩擦、可 review 的文件整理。
- AI 新增 `references/phase2/w8-cd-flow-skeleton.md`，先把最小鏈路收斂成 `release -> image publish -> infra repo version update / PR`，並明確停在不做 deploy automation 的邊界。

#### 結果

- Step 2 先收斂出一個方向性結論：今天第一個 repo-backed 落點，應優先放在流程 skeleton。
- 這代表今天接下來應先把 release -> image publish -> infra version update / PR 這條最小鏈路寫成可驗收 skeleton，而不是直接假裝 deploy automation 已存在。
- 第一版 skeleton 已起草完成，並且已明文保留兩條邊界：不讓 app repo 直接持有 cluster credentials，也不在這一版就補 cluster apply / rollout automation。
- 使用者 review 後確認：這份流程就是目前需要的版本，而 PR merge 後 deploy 要採人工、半手動還是自動化，先留待後續再討論。

#### AI 判讀與收斂

- 目前的收斂是：流程 skeleton 比單純改 version state 更符合今天的 lesson 目標，也比直接進最小 automation 骨架更誠實。
- Step 2 已完成：我們不只選定了流程 skeleton 作為第一個 repo-backed 落點，也確認了目前的停點是正確的；PR merge 後的 deploy 方式刻意不在這一步定案。

#### 目前狀態

- 已完成

### Step 3

#### 這一步要驗證什麼

- 若 app repo 之後要對 infra repo 發出 version update PR，最小變更面在目前 repo 結構下到底落在哪個檔案與欄位。

#### 預計採取的動作

- 檢查 `manifests/` 目前有哪些檔案實際承載 WeaMind image version state，確認 version update PR 的最小修改面。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 檢查 `manifests/` 目錄與其中的 image reference，確認目前實際帶有 WeaMind image version state 的檔案位置。
- 使用者同意：以目前 infra repo 結構來看，version update PR 的最小變更面就是 `manifests/deployment.yaml` 的 image 欄位。

#### 結果

- 目前 `manifests/` 底下，只有 `manifests/deployment.yaml` 實際出現 `ghcr.io/kyomind/weamind:latest`。
- 這代表 deployment version state 目前只明確落在 `manifests/deployment.yaml` 的 image 欄位。
- 因此若要做一個最小的 version update PR，第一版最直接的修改面就是更新這一個欄位。

#### AI 判讀與收斂

- Step 3 的短結論是：以目前 infra repo 結構來看，version update PR 的最小變更面就是 `manifests/deployment.yaml` 的 image 欄位，因為 deployment version state 目前只落在這裡。
- 這也表示下一步若要把 skeleton 再往前推，重點就不再是「改哪裡」，而是「這個欄位要被改成什麼格式，以及 PR 內容要長成什麼樣子」。

#### 目前狀態

- 已完成

補充：若今天的主線超過 2 個步驟，直接繼續往下新增 `Step 3`、`Step 4`、`Step 5`。每個 step 盡量只承接一個主要驗證點或一組緊密相關的操作，避免單一步驟過大。

補充：回填 step 時，優先保留主要決策、關鍵操作、代表性證據、結果與 AI 收斂，不需要把每次中間來回或所有試錯細節完整照錄。
