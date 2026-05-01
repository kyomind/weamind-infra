# 2026-05-01 WeaMind CD Minimum Skeleton Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 補充觀察、設計取捨與一般 lesson 延伸內容，統一整理到 `05-note.md`。

## 今日實作主題

- 以 WeaMind 現有 release 與 infra 邊界為基礎，實作完成第一版可運作的 CD：讓 app repo 在新 release 發生時，能自動對 `weamind-infra` 提出 version update PR。

## 今日實作順序

1. 先確認 infra repo 目前的 deployment state 與第一版 CD 目標之間的最小差距。
2. 收斂第一版 CD 所需的最小設計與責任邊界，避免把 deploy automation 一次做太多。
3. 在 app repo 接上 release -> infra version update PR 這條最小自動化路徑。
4. 用新的 release 實際驗證 `weamind-infra` 是否能收到對應 PR。

## 使用提醒

1. step 數量不設上限；若後續發現某一步過大，應直接往下拆成新的 `Step N`，不要勉強維持少量大步驟。
2. `06-implementation.md` 不需要在每一輪對話後即時逐字更新。若某個 step 會經過多輪討論、試錯或策略收斂，可以先在互動中推進，等到出現較大的進展、形成一段可複習的證據鏈，或該 step 結尾時，再把主要結果擇要回填。
3. 若某個 step 目前只完成設計稿或查詢草案，`實際執行內容` 可以先完整保留操作稿；`結果` 應明寫尚未實作驗證，`AI 判讀與收斂` 也只應收斂到是否已可進入實作，不應提前寫成已驗證完成。
4. 每個 step 的 `實際執行內容` 第一個 bullet，應先標記這次主要由誰實作，例如：`本次由 AI 實作`、`本次由使用者實作`；若屬於明確分段協作，也可以寫成 `本次由 AI 與使用者協作`。

## Session 開場提醒

- `06-implementation.md` 的實際帶法不要寫死在模板裡；開場規則、step 推進與提問邊界改讀 `references/lesson-plugins/implementation/implementation-guide.md`。

## 驗收訊號與回退點

### 驗收訊號

- app repo 在新的 release 發生後，能自動對 `weamind-infra` 開出 version update PR。
- PR 內容只更新 `manifests/deployment.yaml` 的 image 行，並改成完整 release version。
- 我們能實際看到第一版 CD 的核心路徑已經打通，而不只是停在方案或 skeleton。

### 回退點

- 若今天還不能完整打通 release -> infra PR，至少保留已驗證過的設計收斂與最小 workflow 草稿，不假裝第一版 CD 已經完成。

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

### Step 9

#### 這一步要驗證什麼

- 若第一版要由 app repo 的 release workflow 直接對 `weamind-infra` 建 branch 並開 PR，最小可行的權限與憑證做法應該是什麼，才足以跨 repo 寫入，又不會過度放大權限。

#### 預計採取的動作

- 先對照 WeaMind app repo 目前 workflow 內已有的權限設定，確認現有 `GITHUB_TOKEN` 主要只覆蓋 repo 內讀取與 package publish。
- 再比較第一版跨 repo PR 可能需要的最小做法，例如 PAT、fine-grained token，或後續更正式的 GitHub App / bot 方案。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先指出：WeaMind app repo 目前並沒有現成的跨 repo PR 權限或流程，這是正常現象，因為這條 path 以前從未實作過。
- 使用者與 AI 一致認為：第一版應先採最常見、最通用、最容易落地的做法，先把 release workflow 到 infra PR 這條路做通，再視需要升級成更正式的方案。
- AI 補充比較：第一版可先考慮最小可行的跨 repo token 做法，例如 PAT 或 fine-grained token；GitHub App / bot 方案保留給之後真的出現權限治理或多 repo 擴張需求時再升級。

#### 結果

- 現有 WeaMind app repo workflow 主要只有 repo 內讀取與 package publish 權限，還沒有跨 repo branch push / PR 的現成配置。
- 對 WeaMind 第一版來說，較合理的方向不是一開始就上 GitHub App 或更分層的 orchestration，而是先用最常見、最可落地的跨 repo token 做法把流程做通。
- 這代表第一版的權限策略應該追求：足夠完成跨 repo branch 更新與開 PR，但不要把設計提前膨脹成更重的治理方案。

#### AI 判讀與收斂

- Step 9 的短結論是：第一版應先用最常見、最通用、最容易落地的跨 repo token 做法，把 app repo release workflow 直接對 `weamind-infra` 建 branch 並開 PR 這條路做通；GitHub App / bot 等更正式方案留到後續真的有需要時再升級。
- 這一步的核心不是選最漂亮的權限架構，而是先選最容易做成、最容易 debug、也最容易解釋的做法。對目前這個階段來說，這個順序比一開始就追求最完整的治理更正確。

#### 目前狀態

- 已完成

### Step 10

#### 這一步要驗證什麼

- 若第一版要在 app repo 內真正接上 `release -> weamind-infra PR`，這段跨 repo 更新邏輯應該如何落地，才符合目前 repo 的實作習慣，不把大段腳本硬塞進 GitHub Actions YAML。

#### 預計採取的動作

- 先以 WeaMind app repo 既有 `scripts/` 目錄為準，收斂第一版應新增一個專用 shell script，負責更新 `weamind-infra` 的 deployment image 並建立 PR。
- 再決定 workflow 最小應只保留哪些責任，例如傳入 release version，再呼叫該 script；其餘 branch / commit / PR metadata 盡量收在 script 內部。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 使用者先提出偏好：第一版若用 shell 會比 Python 更安全，因為 Python 在 runner 中還要多考慮執行環境，對這個任務來說沒有明顯必要。
- AI 隨後對照 WeaMind app repo 既有 `scripts/` 內容，確認目前 repo 本來就同時存在 shell 與 Python script，但偏 workflow orchestration、repo 操作、文字替換這類任務，主要都是以 shell 為主。
- AI 與使用者因此先收斂：第一版應新增一個專用 shell script，負責執行 release 後的 repo automation；GitHub Actions workflow 只保留版本解析與呼叫 script 的薄層責任，不再把大段邏輯直接塞進 YAML。

#### 結果

- Step 10 對 script 形式的結論已收斂：第一版應使用 shell，而不是 Python。
- 這個 script 的角色，應是承接 `release -> weamind-infra PR` 這條最小自動化路徑中的 repo automation 工作，例如更新 deployment image、準備 branch、提交 commit、建立 PR。
- workflow 本身則應維持精簡，只負責提供 release version 並呼叫這個 script；不再把主要流程邏輯直接寫在 workflow YAML 中。

#### AI 判讀與收斂

- Step 10 的短結論是：第一版跨 repo 更新邏輯，應落在 WeaMind app repo 的專用 shell script，而不是內嵌在 GitHub Actions YAML，也不需要為了這個任務額外引入 Python 執行環境假設。
- 這一步的核心理由不是「Python 不好」，而是這個任務本質上就是一串 shell 世界的操作：`git`、文字替換、`gh pr create`。第一版直接用 shell 更貼近任務本質，也更符合目前 repo 既有 script 風格。
- 這一步完成後，後續就能把下一個實作問題收斂成更具體的 script 邊界：檔名、輸入參數、哪些行為要做、哪些行為暫時不做。

#### 目前狀態

- 已完成

### Step 11

#### 這一步要驗證什麼

- 若第一版要新增一個專用 shell script 來承接 `release -> weamind-infra PR`，那它的檔名、最小輸入參數、責任範圍與刻意不做的事應該怎麼切，才不會一開始就把邊界做得過大。

#### 預計採取的動作

- 先根據目前已收斂的事實點，提出第一版 shell script 的最小介面草案：檔名、必要參數、預設寫死的常數，以及 workflow 只需要傳入哪些值。
- 再把 script 內應負責的動作和暫時不納入第一版的責任分開，避免後續一邊實作一邊擴張範圍。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 使用者同意：在 Step 10 已先確定使用 shell 後，下一步應先把 script 的邊界定清楚，再回頭處理跨 repo 權限；順序上不應先掉進 token 細節。
- AI 依照目前已收斂的 repo 事實，提出第一版最小介面草案：script 檔名可先定為 `scripts/open_infra_version_pr.sh`，輸入先只收一個 release version，例如 `1.2.2`。
- AI 也同步說明第一版先不要把 repo 名稱、base branch、目標檔案路徑、image repo 都做成參數，因為在 WeaMind 這條第一版路徑裡，這些值目前都屬於固定事實：target repo 是 `kyomind/weamind-infra`、base branch 是 `main`、要改的檔案是 `manifests/deployment.yaml`、image repo 是 `ghcr.io/kyomind/weamind`。
- AI 與使用者因此先收斂：workflow 第一版只需要把 release version 傳給 script；其餘常數與 PR 產生流程，先由 script 內部負責。
- 對於責任邊界，AI 進一步切開：第一版 script 應負責驗證參數、取得 `weamind-infra` 工作目錄、建立 branch、更新 deployment image、建立 commit、push branch、建立 PR；但不負責自動 merge、實際 deploy、同時更新多個 manifests、做多 repo 通用化，也不在這一步先處理權限治理細節。

#### 結果

- Step 11 已先把第一版 shell script 的最小介面與責任邊界收斂完成。
- 目前較合理的第一版命名方向，是 `scripts/open_infra_version_pr.sh`。
- 第一版最小輸入參數先只收 release version；其餘 repo 與檔案相關資訊先維持為 script 內部常數，不急著抽象化成通用參數。
- 第一版責任範圍，已收斂為「對 infra repo 提出 version update PR 所需的最小 Git automation」；超出這個範圍的治理、部署與通用化工作先明確排除。

#### AI 判讀與收斂

- Step 11 的短結論是：第一版不要急著設計一個通用的 cross-repo automation 工具，而是先做一個明確服務 WeaMind 目前場景的專用 shell script。
- 這個收斂的關鍵不是偷懶，而是避免在第一版過早參數化。只要 target repo、base branch、目標檔案與 image repo 目前都沒有變體需求，就不該先把它們包裝成可配置介面，否則只會讓 script 的表面靈活度增加，但真正可驗證性下降。
- 這一步完成後，下一個更自然的問題就不是「script 要不要再更通用」，而是「這個 script 建 branch、commit、PR metadata 時要採什麼固定模板」，也就是把第一版的輸出格式再收斂一層。

#### 目前狀態

- 已完成

### Step 12

#### 這一步要驗證什麼

- 若第一版的 branch name、commit message、PR title、PR body 都應由 shell script 產生，那這些輸出格式最小應該長什麼樣，才足夠表達 version update 意圖，又不會把 metadata 設計得過重。

#### 預計採取的動作

- 先根據 Step 8 已收斂的最小 PR metadata 原則，提出第一版固定模板草案。
- 再確認這些模板中，哪些值應由 workflow 傳入，哪些值應由 script 根據 release version 與既有常數自行組出。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先提出第一版固定模板草案：branch name 可採 `infra/bump-weamind-1.2.2`，commit message 與 PR title 可採 `chore: bump weamind image to 1.2.2`，PR body 則保留最小必要資訊，包含目標檔案、image tag 變更與 release reference。
- 使用者隨後修正兩個關鍵點。第一，branch name 不需要再加 `infra/` 前綴，因為目標 repo 本來就是 infra repo；在這個脈絡下，`bump-weamind-1.2.2` 已經足夠表意。第二，commit message 不需要刻意採 conventional commit；對這個單人專案來說，直接使用 `Bump weamind image to 1.2.2` 這種更貼近既有 repo 風格的寫法即可。
- AI 接受這個修正，並與使用者收斂：第一版 branch name 採 `bump-weamind-<version>`，commit message 採 `Bump weamind image to <version>`，PR title 與 commit message 保持一致，PR body 則延續前面已同意的最小結構。
- 對於 workflow 與 script 的責任切分，雙方也保持一致：workflow 只負責把 release version 傳進 script；branch name、commit message、PR title、PR body 都由 script 根據 version 與既有常數組出。

#### 結果

- Step 12 已把第一版四個輸出欄位的模板方向收斂完成。
- 目前較合理的第一版模板如下：branch name 為 `bump-weamind-<version>`，commit message 為 `Bump weamind image to <version>`，PR title 與 commit message 相同，PR body 則只保留 deployment image 變更與 release reference。
- 這個收斂也明確排除了兩種不必要的第一版設計：不需要再加 `infra/` 這類在 target repo 內語意重複的前綴，也不需要為了形式一致而硬套 conventional commit。

#### AI 判讀與收斂

- Step 12 的短結論是：第一版 template 應優先追求 repo 內語意自然、可搜尋、可重跑，而不是追求抽象上的一致命名體系。
- 使用者對 branch name 與 commit message 的修正是合理的，因為這兩個欄位本來就應該服從 target repo 的在地語境，而不是沿用外部通用規則。對 `weamind-infra` 來說，branch 再加 `infra/` 前綴只是重複資訊；對目前的 commit 風格來說，直接寫 `Bump weamind image to <version>` 也比硬套 `chore:` 更自然。
- 這一步完成後，script 的輸入、邊界與輸出模板都已基本收斂。下一個更自然的問題就不再是「文字怎麼命名」，而是「這個 script 內部的實際執行順序要怎麼排」，也就是開始進入真正的實作步驟。

#### 目前狀態

- 已完成

### Step 13

#### 這一步要驗證什麼

- 若第一版 shell script 已經收斂了輸入、責任邊界與輸出模板，那它的內部執行順序最小應該怎麼排，才便於實作、除錯與重跑。

#### 預計採取的動作

- 先提出第一版 script 的建議執行順序，確認哪些步驟必須先做、哪些步驟可以延後處理。
- 再把這個順序對齊成真正實作時的骨架，避免下一步一寫 script 就把驗證、clone、改檔、push、開 PR 混在一起。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先提出第一版 shell script 的建議執行順序，依序為：驗證輸入參數、組出固定字串、取得 `weamind-infra` 工作目錄、建立或切換 branch、更新 deployment image、檢查是否真的有 diff、建立 commit、push branch、建立 PR。
- 使用者同意這個順序。
- 這個順序背後的核心切法，是先把 script 內部的本地 repo 狀態處理乾淨，再做遠端 branch push，最後才建立 PR；不要把驗證、改檔、push、PR 建立混成一團。
- AI 也特別把「檢查是否真的有 diff」保留成一個獨立步驟，因為若 target repo 已經是相同 version，第一版就不應再繼續 commit、push、開 PR。

#### 結果

- Step 13 已把第一版 shell script 的最小執行順序收斂完成。
- 目前較合理的第一版順序是：先驗證輸入並組出模板，再處理 target repo working tree，確認有實際 diff 之後才進入 commit、push、PR 建立。
- 這個順序把失敗點切得更清楚：參數問題、target repo 取得問題、改檔問題、Git push 問題、PR 建立問題，都能在不同階段被辨識，而不是全部堆在最後一起炸開。

#### AI 判讀與收斂

- Step 13 的短結論是：第一版 script 的執行順序，應優先追求可除錯性與可重跑性，而不是追求把所有動作壓成最短流程。
- 這個收斂的關鍵在於先把本地 repo 狀態做對，再把它轉成遠端 branch，最後才包成 PR。這不只比較符合 Git 的自然操作順序，也讓之後任何失敗都比較容易定位在「哪一層出問題」。
- 到這一步為止，第一版 script 的設計已經收斂到相當具體：輸入、責任邊界、輸出模板、內部執行順序都已成形。下一個自然步驟就不再是抽象設計，而是開始把這個 script 真正寫出來。

#### 目前狀態

- 已完成

### Step 14

#### 這一步要驗證什麼

- 若前面已把第一版 shell script 的設計收斂完成，那接下來在 WeaMind app repo 落地實作時，應該直接在 `main` 修改，還是應先開分支、修改 script 與 release workflow，再用 PR 驗證，才比較符合這次變更的風險與邊界。

#### 預計採取的動作

- 先對齊這次變更的實際範圍：不只新增一個 script，還會修改 release workflow，使它在 release path 上呼叫該 script。
- 再依這個變更範圍決定：app repo 應採分支 + PR 還是直接在 `main` 進行，並以此作為後續實作的落地方式。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- 使用者先提出疑問：若只是新增一個 script，是否可以直接在 `main` 做；但進一步思考後也意識到，這次其實不只新增 script，還會一起修改 app repo 的 release workflow，因此分支與 PR 可能仍然比較合理。
- AI 判斷：這次不應直接在 `main` 修改，而應先在 app repo 開一個工作分支，再把 script 與 workflow 變更放在同一個 PR 中。理由不是形式，而是這次的變更已經明確碰到 release path，本身就值得保留獨立 diff、驗證點與回退點。
- 實際執行上，AI 先確認 WeaMind app repo 當下工作樹乾淨、位於 `main`，接著建立分支 `feat/release-infra-pr-script`。
- 在該分支上，AI 新增 `scripts/open_infra_version_pr.sh`，並修改 `publish-release.yml`，讓 release image push 完成後以最薄方式呼叫這支 script。
- 針對這個實作 slice，AI 也立即做窄驗證：先用 `bash -n` 檢查 shell script 語法，再用診斷確認 workflow 與 script 兩個檔案都沒有錯誤；之後又補了一次小修正，把 workflow 的呼叫方式改為 `bash ./scripts/open_infra_version_pr.sh ...`，避免依賴 executable bit。

#### 結果

- Step 14 的結論已收斂：這次 app repo 的變更應採分支 + PR，而不是直接在 `main` 修改。
- 這個決策也已經實際落地：目前 WeaMind app repo 的第一版實作已經放在 `feat/release-infra-pr-script` 分支上，包含一支新的 infra PR shell script，以及 release workflow 對它的最小串接。
- 目前已完成的窄驗證結果是：`bash -n` 通過，workflow 與 script 的檔案診斷也都通過。

#### AI 判讀與收斂

- Step 14 的短結論是：只要這次變更已經碰到 release workflow，就不再只是「加一個小工具檔」而已；它已經屬於 release path 的行為修改，因此應保留分支與 PR 作為最小安全邊界。
- 這一步的關鍵不是追求形式上的 Git 流程完整，而是讓這次變更能夠被清楚 review、獨立驗證、必要時獨立回退。對 release path 來說，這種邊界是值得保留的。
- 到這一步為止，第一版設計不只完成紙上收斂，也已經正式進入 app repo 實作。下一個更自然的問題，不再是「要不要這樣做」，而是「這支 script 在實際 release 執行時，權限與 runtime 行為是否都能跑通」。

#### 目前狀態

- 已完成

### Step 15

#### 這一步要驗證什麼

- 若第一版 release workflow 已經接上跨 repo PR script，那正式版應使用的專用 token 最小需要哪些權限，才足夠對 `weamind-infra` clone、push branch、建立或更新 PR，同時避免沿用過大的既有憑證。

#### 預計採取的動作

- 先根據第一版 script 的實際動作，反推出 token 真正需要覆蓋的 GitHub 能力範圍。
- 再收斂成一個適合使用者到 GitHub GUI 建立 fine-grained token 的最小權限清單，避免把權限給得過寬。

#### 實際執行內容

- 本次由 AI 與使用者協作實作
- AI 先根據第一版 script 的實際動作反推正式 token 的最小權限範圍，指出這顆 token 真正需要覆蓋的能力其實很窄：讀取 `kyomind/weamind-infra`、push branch、建立或更新 PR。
- AI 因此建議正式版改採 fine-grained personal access token，而不是沿用先前從 `gh` CLI 現成憑證接進 secret 的做法。
- 在 repository access 上，AI 建議只選 `kyomind/weamind-infra`，不要放寬到所有 repositories。
- 在 repository permissions 上，AI 建議第一版先只開兩項最小權限：`Contents: Read and write` 與 `Pull requests: Read and write`；其餘如 Actions、Issues、Secrets、Administration 等都先不開。
- 使用者同意這個最小權限方向，並實際到 GitHub GUI 建立新的 fine-grained token，之後用它覆蓋 WeaMind app repo 既有的 `WEAMIND_INFRA_PR_TOKEN` secret。

#### 結果

- Step 15 已把正式版跨 repo token 的最小權限方向收斂完成。
- 目前較合理的第一版正式配置，是使用只限 `kyomind/weamind-infra` 的 fine-grained PAT，並只開 `Contents: Read and write` 與 `Pull requests: Read and write`。
- 使用者也已完成 token 建立與 secret 覆蓋，因此第一版 release workflow 現在已經不再依賴先前那種來自 `gh` CLI 現成憑證的臨時 wiring。

#### AI 判讀與收斂

- Step 15 的短結論是：正式版權限應該根據 script 的實際動作反推，而不是直接複用一顆用途更廣的既有憑證。
- 這一步的關鍵不是「一定要用 GUI」，而是把 token 的權限邊界縮到剛好覆蓋 clone、push branch、建立或更新 PR 這三件事。對 WeaMind 第一版來說，fine-grained PAT 正好能把這個邊界鎖得很清楚。
- 到這一步為止，權限設計本身已經完成；下一個自然的問題不再是「該給什麼權限」，而是「這組權限在真實 release path 上能不能跑通」。

#### 目前狀態

- 已完成

### Step 16

#### 這一步要驗證什麼

- 若正式 token 已經建立並覆蓋到 `WEAMIND_INFRA_PR_TOKEN`，那第一版 release path 在真實 runtime 中是否真的能成功完成 clone `weamind-infra`、push branch、建立或更新 PR。

#### 預計採取的動作

- 先決定第一版要用哪種方式做 runtime 驗證，例如直接推送 app repo 分支並開 PR，或進一步做一次真實 release 觸發。
- 再依選定的驗證方式，觀察 release workflow 的實際行為與失敗點，確認目前這組權限與 script 實作是否足夠跑通。

#### 實際執行內容

- 待回填

#### 結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 骨架已建立

補充：若今天的主線超過 2 個步驟，直接繼續往下新增 `Step 3`、`Step 4`、`Step 5`。每個 step 盡量只承接一個主要驗證點或一組緊密相關的操作，避免單一步驟過大。

補充：回填 step 時，優先保留主要決策、關鍵操作、代表性證據、結果與 AI 收斂，不需要把每次中間來回或所有試錯細節完整照錄。
