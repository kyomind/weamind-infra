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

## imagePullPolicy Always 用白話怎麼理解

簡答：`imagePullPolicy: Always` 不是自動更新開關，它比較像是「只要這個 Pod 要重開，我就再去 registry 看一次 image」。

- 你可以把它想成：Pod 已經在跑的時候，Kubernetes 不會因為 GHCR 出現新 image，就主動把它換掉。
- 只有當 Pod 因為 rollout、restart、節點問題或其他原因被重新建立時，kubelet 才會再去拉這個 image。
- 所以 `Always` 保證的是「重建時重新確認 image」，不是「平常自動追最新版本」。
- 如果 GHCR 裡的 `latest` 已經更新，但你現有的 Pods 都沒重建，那它們還是繼續跑舊版本。

一句話記法：`Always` 只保證重開時重拉，不保證有新版就自動換版。

## rollout restart 會不會重建 Pod

簡答：對，這題只要先記住最核心的一句就夠了。`kubectl rollout restart` 會保證 Deployment 底下的 Pods 被重建。

- 它的重點就是讓舊 Pod 被換掉，建立新的 Pod。
- 所以如果你原本誤以為 rollout restart 不會重建 Pod，這裡要修正成：它就是會觸發重建。

一句話記法：`rollout restart` 的**核心作用，就是重建 Pod。**

## production 更新 image 時，什麼情況才需要 rollout restart

簡答：如果你已經把 manifest 裡的 image tag 改成新版本，重新 apply 之後通常就會自己 rollout，不一定還要再手動 restart。比較需要 `rollout restart` 的情況，是 tag 名字沒變，但你想強制把 Pod 重建一次。

- tag 有變：像 `v1.1` 改成 `v1.2`，Deployment 會看出 Pod template 變了，通常 apply 之後就會自己換 Pod。
- tag 沒變：像還是用 `latest`，表面上 YAML 沒變，但你想讓現有 Pods 重建，這時才更像是 `rollout restart` 的使用情境。
- 所以不是每次更新 image 都一定要走「改 YAML、apply、restart」三步。

一句話記法：tag 有改，通常 apply 就夠；tag 沒改但想重建 Pods，才比較需要 rollout restart。

## image tag 改了時，為什麼不能只做 rollout restart

簡答：對，如果你要把 image tag 從 `latest` 改成 `1.2.2`，光做 `rollout restart` 不夠。因為 `rollout restart` 只會重建 Pod，不會修改 Deployment spec 裡的 `image` 欄位。

- Deployment 目前記住的是哪個 image，要看它自己的 spec，不是看你本機 YAML 改了沒。
- 如果你只是在檔案裡把 tag 改掉，但還沒 `kubectl apply`，叢集裡的 Deployment 還是舊設定。
- 這時你做 `rollout restart`，Kubernetes 只會**照「目前叢集裡那份舊 spec」重建 Pod**，所以 tag 當然不會變。
- 要讓 tag 真正從 `latest` 變成 `1.2.2`，你必須先更新 Deployment spec。常見做法是 `kubectl apply -f ...`，或直接用 `kubectl set image`。
- 更新完 spec 之後，Deployment controller 本來就會因為 Pod template 變了而自動 rollout，通常不需要再多做一次 `rollout restart`。

一句話記法：`rollout restart` 只會重建現有設定的 Pod；要改 image tag，先改 Deployment spec。

## kubectl apply 之後，怎麼看 rollout 有沒有完成

簡答：`kubectl apply` 本身通常只會告訴你資源有沒有成功送進叢集，例如 `configured`、`created`、`unchanged`，不會像 `rollout status` 那樣一路幫你追到 rollout 結束。

- 所以 `apply` 比較像是在說：「新設定我收到了。」
- 但它不等於在說：「新的 Pods 已經全部換完，而且都 Ready 了。」
- 如果你想看 rollout 有沒有真的完成，最直接就是接著跑：

```bash
kubectl rollout status deployment/weamind
```

- 如果你想邊看 Pod 變化邊觀察，也可以用：

```bash
kubectl get pods -n weamind -w
```

- 所以實務上常見節奏是：先 `apply`，再 `rollout status` 確認它真的滾完。

一句話記法：`apply` 告訴你設定送進去了；`rollout status` 才告訴你新版本有沒有真的滾完。

## kubectl get pods 後面的 -w 是不是筆誤

簡答：不是，`-w` 是 `watch` 的縮寫。

- `kubectl get pods -w` 的意思是：先列出目前的 Pods，然後持續監看變化。
- 所以當 Pod 被刪掉、重建、進入 Running 或 Ready 狀態時，你會在同一個畫面看到更新。
- 這很適合拿來觀察 rollout 過程。

一句話記法：`-w` 不是筆誤，它是 watch，意思是持續看變化。

## apply 之後要看更新變化，是不是就用 rollout status

簡答：對，通常就是這樣。`apply` 之後，如果你想確認這次 Deployment 更新有沒有真的開始、而且最後有沒有完成，最常用的就是接 `kubectl rollout status`。

- `apply` 負責把新設定送進叢集。
- `rollout status` 負責告訴你這次 rollout 有沒有成功滾完。
- 如果你還想看到 Pod 一個一個被換掉的過程，可以再搭配 `kubectl get pods -w`。

一句話記法：`apply` 之後，預設就接 `rollout status` 看更新有沒有完成。

## DNS-01 與 HTTP-01 的白話差異

簡答：DNS-01 是證明「我能改這個網域的 DNS」；HTTP-01 是證明「我能控制這個網域對外的 HTTP 入口」。

- DNS-01 驗證的是 DNS 控制權，重點是能不能在 `_acme-challenge` 底下新增指定的 TXT record。
- HTTP-01 驗證的是公開 HTTP 路徑控制權，重點是 Let's Encrypt 能不能從 `/.well-known/acme-challenge/` 拿到指定內容。
- HTTP-01 不是直接證明你能改 DNS，而是證明目前這個網域指到的 HTTP 服務由你控制。

所以差別不是「哪個比較高級」，而是驗證點不同：DNS-01 走 DNS 控制面，HTTP-01 走公開流量路徑。單機 Nginx 架構下 HTTP-01 通常很直覺；但在 WeaMind 這種 LB + Ingress 架構裡，HTTP-01 就比較容易被 routing、redirect 或 Ingress 設定影響。

一句話記法：DNS-01 證明我能改 DNS；HTTP-01 證明我能控制公開 HTTP 入口。

## 為什麼 WeaMind 偏向 DNS-01

簡答：因為 WeaMind 的 DNS 在 Cloudflare，不在 Hetzner；既然不走 Hetzner Managed Certificate，憑證就交給 K3s 內的 cert-manager + Traefik，而 DNS-01 剛好能避開正式流量路徑。

- Cloudflare 繼續負責 DNS，所以 cert-manager 可以用 Cloudflare API Token 寫 `_acme-challenge` TXT record。
- Hetzner LB 在這個設計裡退回 L4 TCP passthrough，不負責保管或簽發 TLS 憑證。
- Traefik 在叢集內做 TLS termination，實際使用 cert-manager 準備好的 TLS Secret。
- HTTP-01 理論上也能做，但它會讓憑證驗證依賴 LB、Ingress、redirect、solver path 這整條公開流量路徑。

所以這裡不是 DNS-01 永遠比 HTTP-01 好，而是 WeaMind 已經選擇 Cloudflare DNS + Hetzner L4 LB + Traefik termination。DNS-01 可以讓憑證申請與續期主要留在 DNS 控制面，不必為了 ACME challenge 去調整正式入口設計。

一句話記法：WeaMind 用 DNS-01，是為了讓憑證驗證走 Cloudflare DNS，不要綁住 LB + Ingress 的正式流量路徑。
