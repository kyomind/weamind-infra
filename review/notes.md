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

簡答：因為 WeaMind 的 DNS 在 Cloudflare，不在 Hetzner；既然不走 Hetzner Managed Certificate，憑證就交給 K3s 內的 cert-manager + Traefik，而 DNS-01 剛好**能避開正式流量路徑**。

- Cloudflare 繼續負責 DNS，所以 cert-manager 可以用 Cloudflare API Token 寫 `_acme-challenge` TXT record。
- Hetzner LB 在這個設計裡退回 L4 TCP passthrough，不負責保管或簽發 TLS 憑證。
- Traefik 在叢集內做 TLS termination，實際使用 cert-manager 準備好的 TLS Secret。
- HTTP-01 理論上也能做，但它會讓憑證驗證依賴 LB、Ingress、redirect、solver path 這整條公開流量路徑。

所以這裡不是 DNS-01 永遠比 HTTP-01 好，而是 WeaMind 已經選擇 Cloudflare DNS + Hetzner L4 LB + Traefik termination。DNS-01 可以讓憑證申請與續期主要留在 DNS 控制面，不必為了 ACME challenge 去調整正式入口設計。

一句話記法：WeaMind 用 DNS-01，是為了讓憑證驗證走 Cloudflare DNS，不要綁住 LB + Ingress 的正式流量路徑。

## HTTP-01 成功後，續約為什麼還要再走驗證

簡答：因為憑證續約不是單純延長舊憑證，而是重新向 CA 申請一張新憑證；CA 仍然要確認你現在還控制這個網域。

- 第一次 HTTP-01 成功，只代表當時你能控制公開 HTTP challenge 路徑。
- 到了續約時間，Let's Encrypt 不會只因為你以前成功過，就直接相信你現在仍然控制這個網域。
- 如果 cert-manager 的 Issuer / solver 還設定成 HTTP-01，續約時就會再次建立 HTTP-01 challenge，讓 CA 重新驗證。

所以更精準地說，不是 ACME 規定「第一次用 HTTP-01，以後永遠不能改」。而是你的自動化設定如果仍然使用 HTTP-01，後續每次續約都會照這個 solver 再跑一次。要改成 DNS-01，必須調整 Issuer / ClusterIssuer 與相關 Secret 設定。

一句話記法：續約其實是重新拿新憑證；solver 沒改，就會用同一種驗證方式重新證明網域控制權。

## HTTP-01 驗證時保留外部 80 常見嗎

簡答：常見。因為 HTTP-01 的驗證入口就是公開 HTTP，也就是 CA 需要能透過 port 80 打到 `/.well-known/acme-challenge/`。

- HTTP-01 不需要你的正式服務長期提供不加密內容，但需要 challenge 路徑在驗證當下可被外部存取。
- 很多架構會保留 80，然後把一般 HTTP 流量導到 HTTPS，只對 ACME challenge 路徑保留例外。
- 如果完全關掉外部 80，HTTP-01 通常就沒辦法完成，除非前面還有其他元件能替你處理這段 challenge。

所以「保留 80」常見，但它的目的不是鼓勵正式流量走 HTTP，而是讓 HTTP-01 驗證有入口。像單機版 Nginx + certbot 常見做法就是：一般路徑全部 redirect 到 HTTPS，只有 `/.well-known/acme-challenge/` 這條驗證路徑在 Nginx config 裡保留例外，讓 CA 可以用 HTTP 讀到 challenge 檔案。

一句話記法：HTTP-01 常需要外部 80；一般流量可以 redirect，ACME challenge 路徑要保留 HTTP 可讀。

## cert-manager 的 Issuer 和 solver 是什麼

簡答：Issuer 是「我要去哪個 CA 申請憑證、用哪個帳號與規則申請」；solver 是「遇到 ACME 驗證時，要用哪種方法證明我控制這個網域」。

- Issuer / ClusterIssuer 像是 cert-manager 的憑證簽發設定檔，會指定 CA，例如 Let's Encrypt，以及 ACME 帳號資訊。
- solver 是 Issuer 裡面負責解 challenge 的方法，可以是 DNS-01，也可以是 HTTP-01。
- DNS-01 solver 會去寫 DNS TXT record；HTTP-01 solver 會建立公開 HTTP challenge 路徑，讓 CA 讀到指定內容。
- Certificate 物件會引用某個 Issuer / ClusterIssuer，cert-manager 再依照裡面的 solver 設定完成驗證與簽發。

所以不要把 Issuer 和 solver 想成兩個同層級的東西。Issuer 是「整份申請憑證的規則來源」，solver 是其中「怎麼通過網域驗證」的那一段設定。

一句話記法：Issuer 決定向誰申請憑證；solver 決定用 DNS-01 還是 HTTP-01 證明網域控制權。

## 為什麼單機 Nginx redirect 後 HTTP-01 仍能成功

簡答：因為它不是把所有 HTTP 請求都無條件 redirect，而是先讓 ACME challenge 路徑例外通過，其他一般路徑才轉去 HTTPS。

- HTTP 80 的 server block 會先對 `/.well-known/acme-challenge/` 設獨立 `location`。
- 這個 `location` 會把 certbot webroot 裡的 challenge 檔案提供給 Let's Encrypt 讀取。
- 只有一般 `location /` 的請求才會被 `301` redirect 到 HTTPS。

所以重點不是「HTTP-01 不怕 redirect」，而是 redirect 規則有保留 ACME challenge 例外。這也是單機版 HTTP-01 能長期續約成功的關鍵：續約時 CA 還是能透過 HTTP 讀到驗證檔案。

一句話記法：HTTP 可以整體轉 HTTPS，但 `/.well-known/acme-challenge/` 要先被 Nginx 放行。

## 為什麼單機版新服務常要先拿掉 HTTPS 區塊

簡答：問題不在 HTTP-01，而在 Nginx 啟動順序。

- Nginx 啟動時會讀設定檔，如果 443 那段寫了「用這個憑證檔」，但檔案還不存在，Nginx 直接起不來。
- 所以第一次新服務要先註解掉 HTTPS 區塊，不是 ACME 規定，而是要讓 Nginx 先能活著，才有辦法跑 certbot 拿憑證。
- 這是 bootstrap 的雞蛋問題：Nginx 要憑證才能啟動，certbot 要 Nginx 活著才能驗證。

一句話記法：先拿掉 HTTPS 區塊是為了讓 Nginx 先活著，不是 HTTP-01 的要求。

## TLS Secret 和一般 Secret 差在哪

簡答：本質上都是 Kubernetes Secret，差別在用途和消費者。

| | TLS Secret | 一般 Secret |
|---|---|---|
| type | `kubernetes.io/tls` | `Opaque` |
| 內容 | `tls.crt` + `tls.key` | 任意 key-value |
| 誰用 | Ingress / Traefik | App Pod |
| 誰建 | cert-manager 自動產生 | 人手寫 manifest |

一句話記法：都是 Secret，但 TLS Secret 給 Ingress 用，一般 Secret 給 App 用。

## k8s-kyomind-tw-tls 是什麼、誰建的、誰用的

簡答：這是一個 TLS Secret，裝的是 `k8s.kyomind.tw` 的憑證和私鑰。

- 名字是你建 `Certificate` 資源時在 `spec.secretName` 先決定的，不是 Ingress 自動生的
- cert-manager 看到 Certificate，去跑 DNS-01 驗證、申請憑證，然後把結果寫進這個 Secret 並持續維護
- Ingress 宣告「這個 host 要用哪個 TLS Secret」
- Traefik 真正讀這個 Secret，做 TLS termination
- Hetzner LB 只做 TCP passthrough，完全不碰憑證

常用指令：

```bash
# 看 Certificate 狀態與 secretName
kubectl -n weamind get certificate
kubectl -n weamind get certificate k8s-kyomind-tw -o yaml

# 看 TLS Secret 是否存在
kubectl -n weamind get secret k8s-kyomind-tw-tls

# 看 Ingress 引用哪個 Secret
kubectl -n weamind get ingress -o yaml | grep -A2 'tls:'
```

一句話記法：Certificate 決定 Secret 名字，cert-manager 建立並維護，Traefik 使用，LB 只 pass 流量。

## cert-manager 四層資源鏈怎麼理解

簡答：用「申請憑證像網購」來想。

| 資源 | 白話角色 |
|---|---|
| Certificate | 需求單：我要什麼憑證、結果放哪個 Secret |
| CertificateRequest | 這一次的正式申請 |
| Order | ACME 那邊建立的簽發訂單 |
| Challenge | 驗證你真的控制這個網域 |
| TLS Secret | 最終產物，裝憑證和私鑰 |

流程：Certificate 宣告需求 → cert-manager 建 CertificateRequest → ACME 建 Order → 跑 Challenge 驗證網域 → 成功後寫進 TLS Secret。

一句話記法：Certificate 是需求單，中間三層是流程，TLS Secret 是最終拿到的貨。

## HTTPS redirect middleware 做了什麼

簡答：把 HTTP 請求用 301 導去 HTTPS，僅此而已。

middleware 本身只有兩個設定：

```yaml
spec:
  redirectScheme:
    scheme: https    # 把 scheme 改成 https
    permanent: true  # 用 301 永久 redirect
```

要讓它生效，還需要在 Ingress 用 annotation 掛載：

```yaml
traefik.ingress.kubernetes.io/router.middlewares: weamind-https-redirect@kubernetescrd
```

注意：`Ingress.spec.tls` 只管 HTTPS 要用哪個憑證，不會自動 redirect。redirect 要靠這個 middleware。

一句話記法：tls 區塊管憑證，redirect 靠 middleware；兩件事分開設定。

## Ingress 三個設定維度是正交的

簡答：`rules`、`tls`、`middleware` 三者彼此獨立，可以任意組合。

| 維度 | 負責什麼 |
|---|---|
| `rules.host/path` | 路由匹配規則，HTTP 和 HTTPS 都用這份 |
| `spec.tls` | HTTPS 用哪個憑證 |
| middleware annotation | 是否把 HTTP redirect 到 HTTPS |

常見誤解：
- 以為 rules 只給 HTTPS 用 → 錯，HTTP 也用同一份 rules
- 以為設了 tls 就會自動 redirect → 錯，redirect 要另外掛 middleware

一句話記法：rules、tls、middleware 是三條獨立的軸，各管各的，改一個不會連動另一個。

## TLS Secret 和一般 Secret 的基本格式一樣嗎

簡答：一樣，都是 Kubernetes Secret，差別只在 `type` 和 `data` 的 key。

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ...
type: kubernetes.io/tls  # 或 Opaque
data:
  tls.crt: ...  # TLS 固定要有這兩個 key
  tls.key: ...
```

| | TLS Secret | 一般 Secret |
|---|---|---|
| type | `kubernetes.io/tls` | `Opaque` |
| data key | 固定 `tls.crt`、`tls.key` | 自訂 |

底層都是同一種資源，用同樣的 `kubectl get secret` 查。

一句話記法：結構一樣，差別在 type 和 key 的約定。

## Kubernetes 為什麼可以有 Certificate 這種物件

簡答：Kubernetes 本身就支援讓別人追加新物件。

- 內建的 `Pod`、`Service`、`Deployment` 是 Kubernetes 自己定義的
- `Certificate` 是 cert-manager 透過 CRD 機制掛進來的新物件
- 一旦 CRD 裝好，Kubernetes 就認得它，`kubectl get certificate` 就能查

重點不是 Kubernetes 原生有沒有 Certificate，而是 Kubernetes 的 API 本來就可以被擴充。cert-manager 裝進叢集後，就把憑證相關的物件型別一起帶進來了。

一句話記法：Kubernetes 是可擴充平台，cert-manager 用 CRD 把 `Certificate` 掛進去。

## Hetzner LB health check 和正式流量是什麼關係

簡答：兩件獨立的事。

- 正式流量有兩條：`80` 給 HTTP redirect，`443` 給真正的 HTTPS 請求
- health check 是 LB 自己發的探測，用來確認後端還活著
- 目前 WeaMind 的 health check 設定成走 `443 + TLS`，探測 `/health`

關鍵觀念：LB 的 listener 怎麼設，和 health check 怎麼探測，是分開設定的。它們可以走同一條入口，但不是綁死的。

一句話記法：正式流量是給使用者的；health check 是 LB 自己去敲門確認後端還活著。

## 正式流量 443 和 health check 443 差在哪

簡答：都走 `443`，但發起者和目的不同。

| | 正式 443 流量 | health check 443 |
|---|---|---|
| 誰發的 | 外部使用者、LINE webhook | LB 自己 |
| 目的 | 處理真實業務請求 | 確認後端還活著 |
| 請求內容 | 各種 path、method、payload | 固定打 `/health`，只看狀態碼 |

後半段共用同一套系統：Traefik → Ingress → Service → Pod。差別只在前面是誰發的、為了什麼。

一句話記法：正式流量是使用者的真實請求；health check 是 LB 用固定條件敲門確認通不通。

## 為什麼 Certificate 放在 weamind namespace 而不是 cert-manager namespace

簡答：因為 Secret 是 namespaced 資源，Ingress 只能引用同 namespace 的 Secret。

- cert-manager controller 跑在 `cert-manager` namespace
- 但 `Certificate` 產出的 TLS Secret 要給 `weamind` 的 Ingress 用
- Ingress 只能讀同 namespace 的 Secret，所以 Certificate 和 Secret 都要放 `weamind`

核心觀念：controller 跑在哪裡，和它管理的資源放在哪裡，是兩件事。

一句話記法：Certificate 跟著 Ingress 放，因為產出的 Secret 要給同 namespace 的 Ingress 用。

## Certificate、CertificateRequest、Order、Challenge 各自存什麼

簡答：分成三類來記。

| 資源 | 角色 |
|---|---|
| `Secret` | 最終產物，存實際的 `tls.crt` 和 `tls.key` |
| `Certificate` | 需求單 + 狀態回報：我要什麼憑證、現在 ready 沒 |
| `CertificateRequest` / `Order` / `Challenge` | 流程中間物件，驅動申請、驗證、簽發各階段 |

它們不只是被動記錄，controller 真的靠這些物件來推進流程、回報狀態。

一句話記法：Secret 是最終產物；Certificate 是需求單；中間三個是流程狀態物件。

## CoreDNS 在 Kubernetes 裡的角色

簡答：讓 Pod 能用名字找到 Service。

- 當 Pod 想連 `weamind-line-bot`，不用硬寫 IP，DNS 會解析成 Service 的 ClusterIP
- CoreDNS 跑在 `kube-system`，是叢集內建的 DNS server
- 每個 Pod 的 `/etc/resolv.conf` 預設就指向它

為什麼在 WeaMind 裡不顯眼：它是基礎設施，K3s 裝好就有，不用額外設定。只要 Service name 連線能通，CoreDNS 就在背後默默運作。

一句話記法：CoreDNS 讓 Pod 能用 Service name 找到對方，是叢集內建的 DNS。

## Flannel 在 Kubernetes 裡的角色

簡答：讓 Pod 跨 node 能互相連線。

- Flannel 負責 overlay network，建立 Pod-to-Pod 的虛擬網路
- 它站在比 Ingress 更底層：Ingress 管「外部流量怎麼導到 Service」，Flannel 管「Pod 之間怎麼連得到」

WeaMind 曾經踩過的坑：

| 參數 | 修的是什麼 |
|---|---|
| `--node-ip` | node 對叢集宣告的位址（用私網 IP，不要用公網） |
| `--flannel-iface` | overlay 封包要走哪張網卡（指定走私網介面） |

如果 Flannel 這層出問題，最先壞的是 Pod / node 之間的叢集內網路，不是單純某條 Ingress path。

一句話記法：Flannel 管 Pod 跨 node 連線；Ingress 管外部流量導入。兩層不同。

## kubectl get events 會出現在 CKA 嗎

簡答：會，排查問題時很實用。

常用變化：

```bash
kubectl get events -n <namespace>
kubectl get events --sort-by='.lastTimestamp'
kubectl get events --field-selector reason=Failed
```

不過 CKA 更常見的排查起點是 `kubectl describe pod`，它的 Events 區塊已經包含該 Pod 相關的事件。`get events` 比較適合想看整個 namespace 發生了什麼。

一句話記法：`describe pod` 看單一 Pod 事件，`get events` 看整個 namespace 發生了什麼。

## Namespace 的 YAML 長什麼樣

簡答：很短，只需要 `apiVersion`、`kind`、`metadata.name`，沒有 `spec`。

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: darkmind
```

- Namespace 是最單純的資源之一，核心就是宣告一個名字
- 頂多再加 `labels` 或 `annotations`，但很多時候連這些都不寫
- 和 `kubectl create namespace darkmind` 效果一樣，差別是 YAML 可以放進 Git、可以 `apply -f`

一句話記法：Namespace YAML 沒有 spec，只要 metadata.name 就夠了。

## kubectl get all 是什麼

簡答：一次列出 namespace 裡的常見資源，包括 Pod、Service、Deployment、ReplicaSet、Job 等。

- 名字有點誤導，它不是真的「all」
- ConfigMap、Secret、Ingress、PVC 這些不會出現
- 平常用來快速確認 Pod 和 Deployment 狀態很方便

想看真的全部：

```bash
kubectl api-resources --verbs=list --namespaced -o name | xargs -n1 kubectl get -n <namespace>
```

一句話記法：`get all` 列常見資源，不是真的全部；Secret、ConfigMap、Ingress 不在裡面。

## 用 label 查詢 Pod 的做法

簡答：用 `-l key=value` 指定 label selector，比用 Pod name 更穩。

```bash
kubectl get pods -n darkmind -l app=darkmind-image-pull-error
kubectl describe pod -n darkmind -l app=darkmind-image-pull-error
kubectl logs -n darkmind -l app=darkmind-image-pull-error
```

- Pod 重建後名字會變，但 label 通常不變
- 用 label 查，不管 Pod 重建幾次都能抓到同一組

常見 label 組合：

```bash
-l app=weamind              # 單一條件
-l app=weamind,env=prod     # 多條件（AND）
```

一句話記法：Pod name 會變，label 不會；查 Pod 優先用 `-l`。

## image pull 問題的標準訊號鏈

簡答：這幾個欄位組合起來，可以快速判斷問題卡在拉 image，不是 app 崩潰。

| 欄位 | 值 | 說明 |
|---|---|---|
| Status | Pending | Pod 還沒進入 Running |
| container State | Waiting | container 在等，不是跑完掛掉 |
| Reason | ImagePullBackOff | 拉 image 失敗，正在退避重試 |
| Ready | False | 還沒 ready |
| Restart Count | 0 | 沒重啟過，代表 container 根本沒跑起來 |

關鍵判斷：Restart Count = 0 + ImagePullBackOff → 卡在拉 image。

對照：如果是 app 啟動後崩潰，會看到 Restart Count > 0，Reason 會是 CrashLoopBackOff。

一句話記法：Restart Count = 0 + ImagePullBackOff = 拉不到 image；Restart Count > 0 + CrashLoopBackOff = app 崩潰。

## describe pod 和 get events 的差別

簡答：`describe pod` 看單一 Pod 發生了什麼；`get events` 看整個 namespace 的事件時間線。

```bash
kubectl get events -n darkmind --sort-by=.lastTimestamp
```

- 會列出所有資源的事件，按時間排序
- 可以一眼看出事件的先後順序和整體脈絡
- 不只列失敗，成功的事件也會列，所以它是「事件流」，不是「錯誤列表」

使用時機：想把問題的時間序列攤開來看，而不是只盯著一個 Pod。

一句話記法：`describe pod` 看單一 Pod；`get events --sort-by=.lastTimestamp` 看整個 namespace 的時間線。

## Kubernetes Event 是什麼

簡答：Event 是 Kubernetes API 裡的一種 resource，用來記錄事件，生命週期很短。

- 不只記錯誤，也記正常流程：`Scheduled`、`Pulled`、`Created`、`Started` 都是 Event
- debug 時特別注意 warning 或 failure 類事件，但它本身不是「錯誤清單」

一句話記法：Event 是 Kubernetes 的事件流，不是錯誤清單；故障排查時 warning event 最有訊號價值。

## app.kubernetes.io 系列 labels 在 production 常見嗎

簡答：常見，尤其是用 Helm 部署的應用幾乎都會自動帶這些 labels。

Helm 預設會加：

- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`
- `app.kubernetes.io/version`
- `app.kubernetes.io/component`
- `app.kubernetes.io/managed-by: Helm`

好處是跨團隊、跨工具時大家看得懂，Prometheus、Grafana、ArgoCD 這些工具也常用這些 label 來分類。

但不是強制的，很多團隊只用簡單的 `app: weamind` 也能正常運作。

一句話記法：Helm 部署會自動帶 `app.kubernetes.io/*` labels；手寫 manifest 可以不用，但大專案常見。

## 多 replica 時，label 和 Pod 名稱怎麼取捨

簡答：兩段式——先用 label 找集合，再用 Pod 名稱看單點。

```bash
# 1. 先用 label 找出這組 Pod 有哪些
kubectl get pods -l app=xxx

# 2. 從結果挑一個，用 Pod 名稱看細節
kubectl describe pod xxx-abc12
```

- label 適合鎖定範圍、找集合
- Pod 名稱適合看單點細節
- 如果只有一個 replica，用 label 就夠；多個 replica 時要兩段式

一句話記法：label 找集合，Pod 名稱看單點；多 replica 時兩段式。

## CrashLoopBackOff 時為什麼重心轉到 kubectl logs

簡答：因為 CrashLoopBackOff 代表 container 有啟動過但很快掛掉，問題出在 app 執行期，這時要看 app 自己印了什麼。

- `describe`、`events` 是 K8s 視角：K8s 認為這個 Pod 怎麼了
- `logs` 是 app 視角：container 裡的程式自己輸出了什麼
- 不是取代，是接力：Day 1 工具先縮小範圍、確認問題類型，再換 `logs` 深挖 app 層證據
- 只有 `logs` 還不夠：少了 `--previous`（上一輪最後輸出）和 K8s 視角的 restart count、state、reason

一句話記法：K8s 視角先縮小範圍，app 視角再深挖；兩層互補，不是互相取代。

## rollout status、history、undo 各做什麼

簡答：`status` 看這次發布進度、`history` 看版本軌跡、`undo` 做回退。

| 指令 | 用途 |
|---|---|
| `rollout status` | 這次發布現在進度如何、有沒有卡住 |
| `rollout history` | 這個 Deployment 之前推過哪些版本 |
| `rollout undo` | 回退到上一個版本 |

和單一 Pod 排查的差別：

- Pod 排查問「這顆 Pod 為什麼不健康」
- rollout 指令問「這次版本發布成功了嗎、要不要退版」

`status` 和 `history` 是觀察；`undo` 是恢復動作，會直接改變 Deployment 目標版本。

一句話記法：`status` 看進度、`history` 看軌跡、`undo` 做回退；前兩個觀察，最後一個是動作。

## kubectl logs -l 選到多個 Pod 怎麼辦

簡答：預設會報錯或只顯示一個，要嘛加 `--prefix` 一起看，要嘛先列再挑一個。

```bash
# 方法 1：加 --prefix，一次看多個但標出來源
kubectl logs -n darkmind -l app=xxx --prefix=true

# 方法 2：先列出來，再挑一個看
kubectl get pods -n darkmind -l app=xxx
kubectl logs -n darkmind <挑一個 pod name>
```

實務上：單 replica 用 `-l` 很方便；多 replica 通常先列再挑。

一句話記法：`-l` 選到多個時，加 `--prefix` 一起看，或先列再挑一個。

## rollout undo 後 revision 為什麼往前加不是倒退

簡答：`undo` 回的是內容，不是 revision 編號。它是「用舊內容做一次新 rollout」。

| revision | 內容 | 發生什麼 |
|---|---|---|
| 1 | good version | 第一次 apply |
| 2 | bad version | 第二次 apply |
| 3 | 和 revision 1 一樣 | undo 後產生 |

壞版本 rollout 卡住時的修復鏈：

```bash
# 1. 確認卡住
kubectl rollout status deploy/xxx --timeout=30s

# 2. 看 revision 軌跡
kubectl rollout history deploy/xxx

# 3. 回退
kubectl rollout undo deploy/xxx

# 4. 確認恢復
kubectl rollout status deploy/xxx
kubectl rollout history deploy/xxx
```

undo 後 revision 從 `2` 變 `3`，不是回到 `1`。因為 undo 是「用舊內容做一次新 rollout」，不是時光倒流。

一句話記法：`undo` 建立新 rollout 回到舊內容，revision 往前加，不會倒退。

## rollout undo 後壞 Pod 的 logs 還看不看得到

簡答：可能暫時還在，但不保證。`undo` 不是 log 保存機制。

- `undo` 只是改 Deployment 目標版本，控制器之後才會慢慢縮掉舊 ReplicaSet
- 壞 Pod 可能暫時還存在，但不保證留多久
- 想保留證據，要在 undo 前自己先存

實務取捨：production 正在受影響時，通常是先拿最小證據（`logs`、`describe`），再快速 `undo`，之後再深挖。

補充：如果有外部 log 系統（Loki、Datadog），壞 Pod logs 通常還查得到，因為已經被收走了。但只靠 `kubectl logs`，要在 Pod 被刪前先看。

一句話記法：`undo` 是恢復動作，不是 log 保存機制；想留證據要自己先存。

## 第一次 apply 建立 Deployment 算不算 rollout

簡答：算。

判斷標準不是「有沒有舊版」，而是：只要 Deployment controller 根據 Pod template 去建立或推進 ReplicaSet 與 Pods，就算 rollout。

第一次 apply 時，controller 確實根據 template 推了第一個 ReplicaSet 和第一批 Pods 出來，所以 `kubectl rollout status` 查得到。

| 情境 | 說明 |
|---|---|
| 第一次 apply | 第一次發布，沒有舊版對照 |
| 之後改 template 再 apply | 後續發布，有舊版對照 |

兩者都是 rollout。

一句話記法：有 Pod template 被推成 ReplicaSet 和 Pods，就是 rollout；跟有沒有舊版無關。

## 為什麼 namespace 只宣告一次，labels 卻要寫兩次

簡答：namespace 由 Deployment 決定，子資源自動繼承；labels 是各物件各自攜帶，所以要分開寫。

Pod template 不是獨立資源，它只是 Deployment spec 裡的「未來要建立的 Pod 規格」。當 Deployment 在 `darkmind` namespace，它建出來的 ReplicaSet 和 Pods 自然就在 `darkmind`。

| 位置 | 貼在誰身上 |
|---|---|
| `metadata.labels` | Deployment 本身 |
| `template.metadata.labels` | 未來建出來的 Pod |

namespace 是範圍，由上層決定；labels 是屬性，各物件各自攜帶。

一句話記法：namespace 繼承，labels 各寫各的。

## restartPolicy 在 Deployment 裡扮演什麼角色

簡答：Deployment 裡 restartPolicy 必須是 `Always`，這是強制的，不是習慣。

兩層責任要分清楚：

| 層級 | 負責什麼 |
|---|---|
| kubelet + restartPolicy | container 掛了，在同一顆 Pod 內重啟 |
| Deployment / ReplicaSet | 維持幾顆 Pod、用哪個 template、要不要 rollout |

container 掛掉時，不是 Deployment 馬上建新 Pod，而是 kubelet 先在同一顆 Pod 內重啟。只有當 Pod 本身消失或副本數不夠時，Deployment 才會建新 Pod。

一句話記法：container 掛了 kubelet 重啟；Pod 少了 Deployment 補。

## 怎麼停掉 crash-loop Pod 又不讓它自動重建

簡答：改 Deployment，不要只刪 Pod。

新手常見錯誤：

```bash
kubectl delete pod <crash-loop-pod-name>
```

沒用。Deployment 的期望狀態還是「我要 1 顆 Pod」，ReplicaSet 會立刻補一顆回來繼續 crash。

正確做法：

```bash
# 方法 1：暫停，保留 Deployment（之後可以 scale 回來）
kubectl scale deploy/xxx --replicas=0

# 方法 2：整個不要了
kubectl delete deploy xxx
```

一句話記法：要停自動重建，改 Deployment，不要只刪 Pod。

## 哪些欄位會觸發 rollout、哪些不會

簡答：看 `spec.template` 有沒有變。有變就 rollout，沒變只是調整控制器行為。

會觸發 rollout（Pod template 內）：

- `image`、`env`、`command`/`args`、`resources`
- `readinessProbe`/`livenessProbe`
- template 內的 `labels`/`annotations`
- volumes、volumeMounts、secret/config 引用

不會觸發 rollout（Deployment 外層控制欄位）：

- `replicas`（這是 scale，不是 rollout）
- `revisionHistoryLimit`
- `strategy.rollingUpdate.*`
- Deployment 外層的 `annotations`

常見誤解：改 `replicas` 後 Pod 數量變了，但不是 rollout。那是同一版多幾顆少幾顆，不是推新版。

一句話記法：`spec.template` 變了才是 rollout；外層欄位變了只是調整行為。

## CrashLoopBackOff 是 Pod 狀態，但真正重啟的是什麼

簡答：Pod 還是同一顆，是裡面的 container 一直掛掉、被 kubelet 重啟。

常見誤解：以為 Pod 被刪掉又重建很多次。

怎麼分辨：

| 觀察點 | container 重啟 | Pod 重建 |
|---|---|---|
| Pod 名稱 | 不變 | 會變（新 Pod） |
| RESTARTS | 一直增加 | 新 Pod 從 0 開始 |
| 誰在處理 | kubelet | Deployment / ReplicaSet |

`kubectl get pods` 的 STATUS 欄位是摘要顯示，把「container 正在 crash + backoff」濃縮成一個狀態。

一句話記法：畫面上是 Pod 狀態，底層是 container 重啟；Pod 名稱不變 + RESTARTS 增加 = container 在重啟。

## endpoints 粒度是 Pod 層級

- endpoints 記錄的是 Pod IP，不會再往下細分到 container
- Service 判斷「這個後端能不能用」的單位是 Pod，看的是 Pod 的 Ready condition
- 面試時比較準的說法是「Service 只會把 Ready 的 Pod 納入 endpoints」

一句話記法：endpoints 的粒度是 Pod；Ready 的 Pod 才會被納入。

## kubectl exec 裡的 `--` 是什麼

`--` 把「kubectl 自己的參數」和「要在 container 裡跑的指令」分開。

- `--` 前面：告訴 kubectl 怎麼連進去（哪個 namespace、哪個 Pod、要不要 `-it`）
- `--` 後面：進去之後要跑什麼（`sh`、`bash`、`cat /etc/hosts` 等）

一句話記法：`--` 前面是「怎麼進門」，後面是「進門後做什麼」。

## port-forward 最常用的對象

依實務順序：

1. **Service**：最常用。快速測應用有沒有回應，不用經過 Ingress/LB
2. **Pod**：第二常用。鎖定單一 Pod debug，不想讓 Service 幫你分流
3. **Deployment**：方便寫法，kubectl 會幫你挑一顆 Pod。但 debug 時通常還是直接指定 Pod 更明確

最常見的實際情境：叢集內管理 UI（Grafana、Prometheus、Argo CD）。這類工具通常不公開對外，用 port-forward 在本機瀏覽器打開最方便。

一句話記法：Service first、Pod second；管理 UI 幾乎天天用。

## 懷疑 rollout 交接問題時的排查順序

1. `kubectl rollout status` — 先看這次 rollout 有沒有卡住
2. `kubectl rollout history` — 看目前有幾個 revision
3. `kubectl describe deployment` — 需要更多細節時再用，看 conditions、ReplicaSets、可用副本數

關鍵判讀：
- `exceeded its progress deadline` = rollout 在時限內沒完成，是 Deployment 層級的失敗
- `history` 只列 revision 編號，不會直接告訴你哪版成功哪版失敗
- 想知道卡在哪，`describe deployment` 的 `Progressing=False` 和副本數更有用

一句話記法：rollout 問題先 `status` 確認卡住沒，再 `history` 看版本，細節用 `describe deployment`。

## 實務排查順序：從外到內、從便宜到貴

真實工作裡，錯誤通常不是先開 kubectl 發現的，而是外部症狀先跳出來：頁面打不開、API 回 5xx、QA 回報功能壞了、監控告警。

排查順序：

1. 看外部症狀 — 是 404、5xx、timeout 還是連不上？先判斷大概哪層出問題
2. `get` 看資源快照 — Pod、Deployment 狀態是什麼？ImagePullBackOff？CrashLoopBackOff？Running 但 0/1 Ready？
3. `describe` / `events` — Kubernetes 自己認為卡在哪
4. `logs` — 已確認 container 有跑過，想看 app 吐了什麼
5. `exec` — 需要進 container 內部看
6. `rollout` — 懷疑是版本切換問題
7. `port-forward` — 快速測某個 port 有沒有回應

一句話記法：先看外部症狀，再 `get`/`describe`/`events` 縮圈，之後才決定要不要 `logs`、`exec`、`rollout`。

## revision 看的是 Pod template 有沒有變

Deployment 的 revision 不是看你 apply 幾次，而是看 Pod template 有沒有變。

- 連續 apply 同一份 YAML，`spec.template` 沒改 → apply 成功但回傳 `unchanged`，不會產生新 revision，Deployment 不會產生新的 ReplicaSet，Pods 也不會重建
- 改到 Deployment 外層欄位但沒動 `spec.template` → 也不會觸發 rollout
- 改到 `spec.template`（image、env、probe、command 等）→ 才會建新 ReplicaSet、產生新 revision

一句話記法：revision 看的是 Pod template 有沒有變，不是 apply 了幾次。

## kubectl logs 真正看的是 Pod

`kubectl logs` 真正看的永遠是 Pod/container 的 logs，但它有方便寫法：

- `kubectl logs deployment/nginx` — kubectl 會幫你先找到這個 Deployment 底下的 Pod，再去抓 logs
- `kubectl logs job/hello` — 同理，先找 Job 管理的 Pod

所以不是 Deployment 或 Job 自己有 logs，而是 kubectl 幫你多走一步：從 workload 資源 → 找到 Pod → 抓 logs。

相對的，`Service`、`Ingress` 這種不承載 container 的資源，沒有 logs 可看，`kubectl logs svc/...` 會報錯。

一句話記法：logs 永遠是 Pod 的；Deployment/Job 只是方便寫法，kubectl 幫你找 Pod。
