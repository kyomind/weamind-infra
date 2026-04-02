# Notes for Implementation

## Hetzner LB 的 HTTP health check 到底在檢查什麼，和 Pod health 有什麼關係

- 這次很容易混淆的一點是：**Hetzner LB 的 health check 不是直接去看 Kubernetes Pod 的 liveness/readiness probe。** 它檢查的是「LB 這個 target node，能不能對這條外部入口路徑回出符合條件的結果」。
- 以 WeaMind 目前的 `http:80 -> 80` 來說，LB 送出的其實是一個 **真正的 HTTP request**：打 `80`、走 `/health`、帶 `Host: k8s.kyomind.tw`，然後期待收到 `200`。
- 所以它驗證到的不是單一 Pod 自身健康，而是 **一小段端到端入口鏈路** 是否成立：`LB -> worker node:80 -> Traefik entrypoint -> Ingress host/path match -> weamind Service -> app Pod -> /health 回 200`。
- 這也是為什麼當初沒帶正確 `Host` 時，即使 app 的 `/health` endpoint 沒壞，LB 仍然會看到 `404` 並把 target 判成 unhealthy。因為 **失敗點發生在 Ingress routing**，不是 Pod probe。
- 因此更精準的說法是：**Hetzner LB 現在做的是入口層的合成健康檢查（synthetic end-to-end check），不是 Kubernetes 原生的 Pod health probe。**
- 若要談 Pod 本身健康，應回頭看 Deployment / Pod 裡的 `readinessProbe`、`livenessProbe`；若要談外部使用者能不能真的經過入口打到服務，才看這個 LB health check。

## Hetzner UI 顯示 source port 固定、destination port 可改，這代表什麼

- 這次 UI 行為很關鍵：**Hetzner LB 的 service 是以 source port 為一個獨立 listener 來管理的。** 所以既有的 `80` listener 不能直接變成另一個 `443` listener；若要不同 source port，必須新建另一條 service。
- 因為 WeaMind 已經有一條 `tcp:443 -> 443`，所以你也不能再另外建第二條 source port `443` 的 service。這表示 **同一個 LB 上，同一個對外 port 只能有一條 service 佔用。**
- 更重要的是，當你把 `http:80 -> 80` 的 protocol 切成 `https` 時，UI 不是只在改 health check，而是在改 **整條 LB service 的協定語義**。這也是為什麼畫面立刻開始要求 `Add certificates`，並出現 `HTTP-Redirect (301)` 選項。
- 也就是說，這個 `https` 不是「保留原本 passthrough 架構，只讓 health check 偷偷改走 HTTPS」；它比較像是在說：**讓 Hetzner LB 自己成為 HTTPS listener / TLS termination 點。**
- `destination port` 可改，代表的是：**外部打進 LB 的某個 source port，可以被轉送到 target node 的另一個 port。** 例如理論上可做 `80 -> 443`，但那仍然是「外部入口是 80 這條 service」，不是在新增一條獨立的 `443` health check。
- 因此這次最重要的修正是：**先前以為可以在不動整體架構下，把 LB health check 單獨切到 HTTPS，這個推論過度樂觀。** 依 Hetzner 目前 UI 行為看，health check 與 service protocol 綁得比我們原先想像更緊。
- 對 WeaMind 而言，這代表後續若要補 `HTTP -> HTTPS redirect`，不能直接把現有 `80` service 改成 `https`，因為那會把 TLS termination 從 Traefik 拉回 Hetzner LB，和目前專案的 passthrough 設計衝突。

## 為什麼現在不能直接動 Hetzner LB，這其實是在動整個入口邊界

- 這次最需要拉高一層來看的，不是「某個欄位能不能改」，而是：**WeaMind 現在的 LB 設定其實已經承載了一整串過去收斂過的架構決策。**
- 從歷史脈絡看，這條線不是隨機長成現在這樣。當初先遇到的是 **HTTP health check 不帶 Host 會失敗**，所以 `80` 這條 service 被固定成「用 HTTP 做入口存活檢查」；後來又遇到 **Hetzner Managed Certificate 不適合 Cloudflare DNS**，於是 TLS 方案改走 **cert-manager + DNS-01**；再往後還踩到 **同一個 source port 不能重複宣告**，所以最終才收斂成現在這種：`80` 留給 HTTP 與 health check，`443` 留給 TCP passthrough，TLS termination 放在 Traefik。
- 也就是說，**目前的 LB 不是單純兩條 service 而已，而是一個已經和 K8s 內部責任邊界對齊的結果。** 它背後同時綁住了憑證生命週期、TLS 終止位置、LB 是否理解 HTTP、以及 Ingress 是否繼續作為唯一的 L7 路由入口。
- 因此現在若直接去動 Hetzner LB，風險不只是「health check 可能紅掉」，而是 **你可能在沒有明說的情況下，把 TLS 邊界從 Traefik 拉回 LB，或把原本分離好的責任重新混在一起。**
- 更麻煩的是，Hetzner 的限制讓這件事 **不太能用平行試跑的方式驗證**。因為 `443` source port 已經被既有 service 佔住，你不能再旁邊開另一條 `443` 來做對照；這代表任何改動都更像 **切換架構**，而不是 **局部微調**。
- 所以「現在不能動」更準確的意思不是永遠不能碰，而是：**在還沒重新定義 TLS 終止點、redirect 策略、health check 存活條件之前，不應把 Hetzner LB 當成可以直接試改的局部設定。**
- 若之後真的要動，前提也應該先變成一個新的設計題：究竟要維持 **LB 只做 L4、Traefik 做 TLS/L7**，還是要改成 **LB 也參與 HTTPS / redirect / certificate 管理**。這兩條路都能做，但不是同一個小修的延伸。

## 為什麼不能把 TLS termination 再拉回 Hetzner LB

- 這題可以再更直白一點：**不是我們不喜歡 Hetzner LB 做 termination，而是我們當初已經明確拒絕了它背後那整套前提。**
- 對 WeaMind 來說，若要讓 Hetzner LB 正規地做 HTTPS termination，最順的搭配通常就是 **Hetzner Managed Certificate**；但這條路的硬限制是 **憑證管理會綁到 Hetzner DNS 生態**。
- 而 WeaMind 的 DNS 明確留在 Cloudflare，這不是偶然，而是有意識的選擇。所以當初一旦拒絕「把網域託管搬去 Hetzner」，其實也就等於一起拒絕了「讓 Hetzner 成為我們主要 TLS 終止點」這條最自然的產品路徑。
- 也因此，現在的架構不是退而求其次的臨時 workaround，而是 **在保留 Cloudflare DNS 這個前提下，刻意收斂出來的穩定方案**：`443` 只做 TCP passthrough，真正的 TLS termination 留在 Traefik，憑證生命週期交給 `cert-manager + DNS-01`。
- 所以現在若又想把 termination 拉回 Hetzner LB，本質上不是優化同一條路，而是 **回頭推翻當初「DNS 不搬、憑證留在 K8s 內管理」這個核心決策。**

## Redirect 在 WeaMind 現況裡是 nice-to-have，不是非做不可

- 到目前為止，lesson 與外部實測都支持同一個判斷：**WeaMind 現在缺的是入口一致性，不是已知高危突破口。**
- 原因是目前能被 HTTP 直接命中的，主要是首頁與 `/health` 這類低敏感路徑；而比較關鍵的入口像 webhook 或 user API，仍然有應用層簽章或 token 驗證，不會因為單純走 HTTP 就直接成功。
- 所以這次研究 redirect 的價值，重點不只是「今天一定要把它做完」，而是 **把架構邊界、可行落點與 suspend 條件講清楚**。這對未來回頭補硬化時，會比硬做一個不乾淨的方案更有價值。
- 更精準地說，這題目前的成功標準可以拆成兩層：
- 第一層是 **技術上確認 Traefik / Middleware 能否優雅處理 redirect**。
- 第二層才是 **若方案不扭曲既有 TLS 邊界，就落地；若需要回頭碰 Hetzner termination 或讓 health check 變脆弱，就暫時 suspend。**

## 這次可以下比較強的結論了：Health check advanced settings 幾乎可視為獨立子系統

- 到這一步，判斷已經不只是停在 UI 猜測，而是有 **實際存檔後的行為證據** 支撐：你把 health check 的 `Destination` 改成 `443`、把 `TLS` 打開，並且在超過 5 分鐘的觀察後，`http:80 -> 80` 這條 service 與兩個 worker targets 仍然維持 healthy。
- 這代表對 WeaMind 目前這個案例來說，**Hetzner LB 的 health check advanced settings 與外層 listener / service 本身，至少在運作層面上具有相當高的獨立性。**
- 更精準地說，先前從 service 編輯畫面得到的印象是：「一碰 HTTPS，就像是在改整條 LB 的角色」；但 health check advanced settings 的實測結果顯示：**至少 health check 這一塊，Hetzner 允許你在不改 listener 協定邊界的前提下，獨立指定要怎麼探測 target。**
- 這也解釋了為什麼這套 UI 會讓人誤判。因為在概念上，`http:80 -> 80` 這條 service 與它底下的 health check 設定都被包在同一個介面裡，看起來很像同一組不可分割的設定；但從實際行為看，**它們不是完全綁死的。**
- 因此這次更成熟的結論應該是：**service listener 邊界與 health check 探測邏輯，要分開理解。** 前者仍然牽涉 LB 是否做 termination、source port 是否衝突；後者則可能有更高的獨立度，允許針對 target 探測做 HTTPS / destination port 這類細部調整。
- 這個發現很重要，因為它把我們的策略從「不能碰 Hetzner LB」修正成更精準的版本：**不能隨便改 Hetzner 的 listener / termination 邊界，但可以在有回退方案的前提下，研究 health check 這個較獨立的子系統。**

## 這次也證明了：最小 redirect 可以落在 Traefik，而不需要把 TLS 拉回 Hetzner

- 在 health check 已成功獨立切到 `Destination=443` 與 `TLS=Enabled` 之後，我們再把 `HTTP -> HTTPS redirect` 放到 Traefik `Middleware`，並掛到既有 `Ingress` 上，結果外部實測成立：
- `curl -i http://k8s.kyomind.tw/health` 回 `301 Moved Permanently`
- `curl -iL http://k8s.kyomind.tw/health` 最後成功到 `https://k8s.kyomind.tw/health` 並回 `200`
- `curl -i https://k8s.kyomind.tw/health` 直接回 `200`
- 這個結果很重要，因為它表示 **WeaMind 不需要回頭改 Hetzner listener，也不需要把 TLS termination 拉回 LB，就能補上 HTTPS-only 的入口一致性。**
- 也就是說，這次真正可行的優雅做法是：**Hetzner LB 保持既有入口角色，Traefik 負責 redirect 與 TLS termination，而 health check 另外獨立走 HTTPS 探測。**
- 從架構角度看，這是一條比原先預期更乾淨的路，因為三個責任邊界沒有重新混在一起：LB 仍是外部入口與轉送層，Traefik 仍是 L7 / TLS 層，health check 則是可獨立調整的探測子系統。

## 這次 YAML 到底改了什麼，為什麼要這樣改

### 新增 `middleware-https-redirect.yaml`

- 這份新檔案的角色很單純：**把 `HTTP -> HTTPS redirect` 這個行為，明確做成一個 Traefik `Middleware` 資源。**
- `redirectScheme.scheme: https` 表示命中這個 middleware 的 HTTP request 應被導向 HTTPS。
- `permanent: true` 表示這不是暫時跳轉，而是正式的永久導向；外部會看到 `301` 這類永久 redirect 行為。
- 把 redirect 獨立成一個 `Middleware`，而不是直接把邏輯塞進別的地方，好處是責任清楚：**這份 YAML 只回答一個問題，就是「命中的 HTTP 請求要不要被導向 HTTPS」。**
- 這也符合這次實作的原則：我們不回頭碰 Hetzner listener，也不把 TLS 拉回 LB，而是把 redirect 放在本來就負責 L7 行為的 Traefik 層。

### 更新 `ingress.yaml`

- 這次對 `Ingress` 的更新只有一個核心動作：加上 `traefik.ingress.kubernetes.io/router.middlewares: weamind-https-redirect@kubernetescrd` 這個 annotation。
- 這行的意思不是改變後端 Service，也不是改變 TLS secret，而是：**告訴 Traefik，當這條 Ingress 規則被命中時，要先套用哪一個 middleware。**
- `weamind-https-redirect@kubernetescrd` 這個值，對應到的就是剛新增那個 `weamind` namespace 裡的 `https-redirect` middleware。
- 因此這次 `Ingress` 本身的 host/path/backend/tls 結構其實沒有被推翻；我們做的只是 **在既有入口規則前面，多掛上一層 redirect 行為**。
- 這也是為什麼這次改動可以很小，但效果很完整：外部 HTTP 請求先被 Traefik 轉到 HTTPS，真正的 TLS termination 與後續 routing 仍沿用原本已成立的路徑。

## Annotation 在這裡為什麼不是「只是給人看的註解」

- 這題要先把兩種完全不同的東西拆開：**YAML / 程式碼裡的 comment** 跟 **Kubernetes resource 的 `metadata.annotations`** 不是同一種東西。
- 像 `# some note` 這種 comment，真的只是給人看的，送進 Kubernetes API 之後根本不會被保存，也不會被 controller 看到。
- 但 `annotations` 不一樣。它雖然也屬於 metadata，不像 `spec` 那樣直接描述「我要幾個 Pod」或「port 是多少」，但它會被 **完整保存到資源物件裡**，而且 controller 可以主動去讀它、依它改變行為。
- 所以更精準的說法不是「annotation 本身天生會改變行為」，而是：**annotation 提供一種擴充入口，讓特定 controller 願意把它當成設定來解讀。**
- 在 WeaMind 這個案例裡，真正讓行為改變的不是 annotation 這四個字本身，而是 **Traefik 這個 Ingress controller 會主動讀 `traefik.ingress.kubernetes.io/router.middlewares` 這個 key，並把它解讀成『這條 router 要先套用哪些 middleware』。**
- 所以如果今天換成一個完全不認 Traefik annotation 的 controller，這行 metadata 可能就只會安靜地躺在物件裡，不產生任何效果。也就是說，**annotation 能不能影響行為，取決於有沒有對應的 controller 願意讀它。**
- 這也可以順手和 `label` 對照理解：`label` 比較像穩定、通用、可被 selector 使用的分類欄位；`annotation` 比較像不參與 selector、但可承載 controller-specific 設定或補充資訊的擴充欄位。
- 因此這次 `Ingress` 上那行 annotation 的本質，不是「寫給人看的備註」，而是 **寫給 Traefik controller 看的行為指令入口**。
