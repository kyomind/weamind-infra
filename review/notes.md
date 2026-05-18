# Lesson 複習筆記

## CI workflow 的兩個 job 是平行還是先後關係

簡答：這兩個 job 是平行，不是先後。

- 在 [references/weamind-app-ci.yml](references/weamind-app-ci.yml) 裡，`code-quality-check` 和 `docker-build-validate` 都直接寫在 `jobs:` 底下，而且沒有 `needs:`，這代表 GitHub Actions 會把它們當成彼此獨立的 job，能同時就同時跑。
- 比較準的說法是：它們在 workflow 結構上沒有先後依賴，但整份 CI workflow 會等兩個 job 都結束，才形成這次 CI 的整體成功或失敗結果。
- 所以不是「先做 quality checks，再做 Docker build validation」；而是「同一個 CI 裡分成兩條獨立檢查線，同步驗證程式品質與 Docker build 路徑」。

一句話記法：沒有 `needs` 的 jobs，預設就是平行跑；CI 要等兩條線都跑完，才算整體過關。

## Publish Workflow 跟前面的 CI Workflow 是什麼關係

簡答：Publish workflow 是接在 CI workflow 後面的第二段自動化，但它不是吃 CI 某個 job 的產物，而是等整份 CI 成功後，才用同一個 commit 重新 build 並 push image。

- 在 [references/weamind-app-publish-ghcr.yml](references/weamind-app-publish-ghcr.yml) 裡，觸發條件是 `workflow_run`，而且指定前一份 workflow 名字就是 `CI`，所以它和前面的 CI 是前後兩份獨立 workflow，不是在同一份 YAML 裡串 job。
- CI 的角色是先做品質檢查、測試和 Docker build validation，確認這個 commit 值得往後走。
- Publish 的角色是等那次 CI 整體成功，而且事件來源真的是 `main` 上的 `push`，才 checkout 同一個 `head_sha`，重新 build，然後 push 到 GHCR。
- 所以它們的關係比較像：CI 是品質閘門，Publish 是通過閘門後的出貨動作。

一句話記法：CI 先證明這個 commit 過關，Publish 再把那個 commit 對應的 image 重新 build 並推到 GHCR。

## 為什麼 PR merge 成功也會算成 push 事件

簡答：對，這可以視為 GitHub 的事件模型規則。因為 PR merge 進 `main` 的那一刻，本質上就是讓 `main` 分支指向一個新的 commit，而分支引用被更新這件事，對 GitHub 來說就是一次 `push`。

- `pull_request` 事件描述的是「PR 這個討論與審查物件」的生命週期，例如 opened、synchronize、closed。
- 但當 PR 真的 merge 完成後，真正被改動的是目標分支，例如 `main`。`main` 出現新的 commit，等於有人把新的 revision 推進這個分支。
- ⭐️GitHub Actions 的 `push` 事件不是只看你有沒有手動執行 `git push` 指令；它看的是「某個 branch 或 tag 的 ref 被更新了沒有」。
- 所以從 workflow 角度，更準的說法不是「PR merge 這個動作本身等於 push 指令」，而是⭐️「PR merge 的**結果**會讓 `main` 發生一次**符合** `push` 條件的 ref 更新」。

因此，WeaMind 這份 publish workflow 才會用 `github.event.workflow_run.event == 'push'` 去排除單純 PR 檢查成功的情況，只接受 merge 後真正落到 `main` 的那次 CI 成功。

一句話記法：不是因為有人手動打了 `git push` 才叫 push，而是因為 merge 讓 `main` 指到新 commit，GitHub 就把這種分支更新當成 push 事件。
