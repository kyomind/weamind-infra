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

### Step 4

#### 這一步要驗證什麼

- 若 version update PR 要更新 `manifests/deployment.yaml` 的 image 欄位，第一版最合理的目標格式應該是完整 release version、minor / major tag，還是 `latest`。

#### 預計採取的動作

- 對照 app repo 的 release image publish workflow 與 `references/phase2/w8-cd-minimum-spec.md`，確認 infra repo 第一版應追哪一種 image tag 格式。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 對照 `references/weamind-app-publish-release.yml` 與 `references/phase2/w8-cd-minimum-spec.md`，確認 app repo release workflow 會產出完整版本、minor、major 三層 tag。
- 使用者明確同意：第一版 version update PR 必須追完整 release version，而不是 `latest`、minor 或 major tag。
- 額外驗證時，AI 先嘗試用 `gh api` 查 GHCR package versions，但目前登入缺少 `read:packages` scope，因此改以公開 package 頁面補證據，確認目前可見 tag 類型同時包含 `latest`、`sha-*`、完整版本、minor、major。

#### 結果

- app repo release workflow 目前會從像 `v1.2.1` 這類 Git tag 解析出 `1.2.1`、`1.2`、`1` 三層 image tag。
- `references/phase2/w8-cd-minimum-spec.md` 已明確收斂：第一版正式 deploy source 應該是完整 release version tag。
- GHCR 公開 package 頁面目前也能看到 `latest`、`sha-*`、`1.2.1`、`1.2`、`1` 這幾類 tag 同時存在，表示完整 release version 並不是理論上的格式，而是目前真的存在的可用 tag。
- 因此若 version update PR 要更新 `manifests/deployment.yaml` 的 image 欄位，第一版最合理的目標格式應該是完整 release version image tag。

#### AI 判讀與收斂

- Step 4 的短結論是：version update PR 若要更新 `manifests/deployment.yaml` 的 image 欄位，第一版應改成完整 release version image tag，例如 `ghcr.io/kyomind/weamind:1.2.1`，而不是 `latest`、minor 或 major tag。
- 這一步也順便補強了一個實務面結論：完整 release version 不只是 spec 上的偏好，而是 app repo workflow 與 GHCR 現況都已支援的格式。

#### 目前狀態

- 已完成

### Step 5

#### 這一步要驗證什麼

- 若 app repo 之後要自動開一個 infra repo 的 version update PR，第一版最小 diff 應該長什麼樣，才既誠實又足以表達 deployment state 的更新。

#### 預計採取的動作

- 以 `manifests/deployment.yaml` 的 image 欄位為中心，先收斂這個 PR 在第一版是否只需要更新單一 image 行，以及這樣的 diff 應如何表達完整 release version 變更。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先根據前面已完成的 Step 3 與 Step 4，提出第一版最小 diff 應只改 `manifests/deployment.yaml` 的 image 行，不額外擴張到其他檔案或 metadata。
- 使用者同意：第一版 version update PR 的最小 diff，應只更新 `manifests/deployment.yaml` 的 image 行，將 `latest` 改成對應的完整 release version。

#### 結果

- 第一版最小 diff 的修改面，仍只落在 `manifests/deployment.yaml` 的 image 欄位。
- 這個 diff 的核心表達方式，是把 `ghcr.io/kyomind/weamind:latest` 改成對應的完整 release version，例如 `ghcr.io/kyomind/weamind:1.2.1`。
- 目前沒有額外證據顯示第一版一定還需要同步修改其他 manifests、附帶 metadata，或加入更多 deployment state 欄位。

#### AI 判讀與收斂

- Step 5 的短結論是：第一版 version update PR 的最小 diff，應只更新 `manifests/deployment.yaml` 的 image 行，將 `latest` 改成對應的完整 release version。
- 這一步讓第一版 skeleton 又往前收斂了一層：現在不只知道該改哪個檔案、該用哪種 tag，也已經知道最小 PR 內容應該保持在單行 image 變更，不額外膨脹。

#### 目前狀態

- 已完成

### Step 6

#### 這一步要驗證什麼

- 若 app repo 之後要自動產生 infra repo 的 version update PR，這個 PR 的產生點應該掛在 WeaMind 的哪一條流程上，才不會和目前 `latest` / `sha-*` 的 main 路徑混在一起。

#### 預計採取的動作

- 對照 WeaMind app repo 目前的 `publish-ghcr.yml` 與 `publish-release.yml`，確認 version update PR 第一版應附著在 release image publish path，而不是 main 分支的持續 publish path。
- 若這個判斷成立，再把之後的測試目標先對齊成新增一個 release，例如 `1.2.2`。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 對照 WeaMind app repo 的 `publish-ghcr.yml` 與 `publish-release.yml`，確認目前 main 路徑會持續產出 `latest` / `sha-*`，release 路徑才會產出完整 release version、minor、major。
- 使用者同意：只有在有新的 release 發生時，才需要對 `weamind-infra` 提交新的 version update PR；普通 `latest` 更新不需要開這個 PR。
- 使用者也先把後續測試目標對齊成新增一個 release，例如 `1.2.2`。

#### 結果

- `publish-ghcr.yml` 對應的是 main 分支上的持續 publish path，主要產出 `latest` 與 `sha-*`。
- `publish-release.yml` 對應的是 release image publish path，會從 `v*` tag 解析出完整 release version、minor、major。
- 因此 infra repo 的 version update PR 若要代表正式 deploy version 更新，第一版就不應掛在 main 的持續 publish path。
- 更精確地說：只有在新的 release 發生時，才需要對 `weamind-infra` 開一個新的 version update PR；普通 `latest` 更新不需要。

#### AI 判讀與收斂

- Step 6 的短結論是：第一版 infra version update PR 的產生點，應掛在 WeaMind app repo 的 release image publish path，而不是 main 分支的 `latest` / `sha-*` publish path。
- 這一步也把觸發條件收得更精確：不是每次 image 更新都要對 infra repo 開 PR，而是只有在新的 release 發生時才需要；若後續要實測，目標可先對齊新增 release `1.2.2`。

#### 目前狀態

- 已完成

### Step 7

#### 這一步要驗證什麼

- 第一版 infra version update PR 的實作形式，應該是由 app repo workflow 直接改 `weamind-infra` branch 並開 PR，還是先產生 patch / commit 資料，再由其他動作送出，才比較符合目前專案邊界與可維護性。

#### 預計採取的動作

- 先比較兩種最小做法的責任邊界與操作成本：
- app repo workflow 直接對 `weamind-infra` 建 branch、提交 image 更新、再開 PR。
- app repo workflow 只產生變更內容或 patch，再由另一層流程負責送出 PR。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先比較兩種做法：
- app repo 的 release workflow 直接對 `weamind-infra` 建 branch、修改 image 行並開 PR。
- app repo 只產生 patch / commit 資料，再由另一層流程或另一個系統負責送出 PR。
- 使用者與 AI 一致偏向第一種，因為第一版目標是最小、可落地、可驗證，不需要先多拆一層中介流程。
- 作為補充理解，AI 也整理第二種做法的常見實踐：例如先輸出 patch 檔、先產生 machine-readable artifact 給另一個 workflow 消費，或由 GitOps / release orchestration 層統一代送 PR。

#### 結果

- 第一版較合理的做法，是讓 app repo 的 release workflow 直接對 `weamind-infra` 建 branch、提交 image 更新並開 PR。
- 這樣已足夠表達 deploy version 更新，而且與前面已收斂的「單行 image diff」相容，不需要再額外設計一個 patch 交接層。
- 第二種做法不是錯，但通常更適合在下列情境出現：
- PR 送出責任要集中在另一個 orchestration workflow。
- 需要先把變更產物標準化，供多個環境或多個 infra repo 重複消費。
- 想讓 app repo 只負責產生 version intent，而不直接持有跨 repo 寫入權限。

#### AI 判讀與收斂

- Step 7 的短結論是：第一版 infra version update PR 的實作形式，應以 app repo 的 release workflow 直接對 `weamind-infra` 建 branch、提交 image 更新並開 PR 為主；先不額外拆成 patch 產生層與另一個送 PR 流程。
- 第二種方式的常見實踐可以理解成「先產生變更意圖，再由另一層系統送出 PR」；它比較適合更大規模或更強調權限分層的情境，但對 WeaMind 第一版來說會先增加抽象與維護成本。

#### 目前狀態

- 已完成

### Step 8

#### 這一步要驗證什麼

- 若第一版由 app repo release workflow 直接對 `weamind-infra` 開 PR，這個 PR 的 branch name、commit message、PR title 與 PR body 最小應該長什麼樣，才足夠表達 version update 意圖，又不會膨脹成過度設計。

#### 預計採取的動作

- 先收斂第一版最小 PR metadata 應包含哪些資訊：release version、變更檔案、變更內容、是否需要附上 release 對應來源。
- 再判斷 branch / commit / title / body 是否都應採固定模板，以及模板應壓到多短。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先提出第一版最小 PR metadata 應保持精簡：branch name、commit message、PR title 都直接帶 release version，PR body 只保留變更檔案、image 從哪個版本改到哪個版本，以及對應的 release。
- 使用者同意先採最小做法，因為這次變更面很小，不需要把 PR body 膨脹成長篇說明。

#### 結果

- 第一版可接受的最小 metadata 方向是：branch name 帶 release version，commit message 與 PR title 直接表達 image bump，PR body 只保留變更檔案、image tag 變更與對應 release。
- 這類 infra version update PR 第一版不需要展開 app 層改動摘要；若要補充來源，附 release reference 即可。

#### AI 判讀與收斂

- Step 8 的短結論是：第一版 infra version update PR 的 metadata 應保持最小且直接，夠清楚表達 deployment version 更新即可，不需要過度設計。
- app 層變更摘要與 release reference 的取捨，改整理到 `05-note.md`，避免 `06-implementation.md` 在這一步重複展開。

#### 目前狀態

- 已完成

補充：若今天的主線超過 2 個步驟，直接繼續往下新增 `Step 3`、`Step 4`、`Step 5`。每個 step 盡量只承接一個主要驗證點或一組緊密相關的操作，避免單一步驟過大。

補充：回填 step 時，優先保留主要決策、關鍵操作、代表性證據、結果與 AI 收斂，不需要把每次中間來回或所有試錯細節完整照錄。
