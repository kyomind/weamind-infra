# 2026-04-01 LB Health Check Skeleton Command

## 今日指令練習目標

1. 把「Health Check 失敗」拆成 Host header 問題，而不是直接說 app 壞掉。
2. 把「LB 後端只放 worker」對回 Deployment、node label 與 Pod 落點證據。
3. 把「為什麼只有一個 Traefik endpoint，三個 node 還能成為入口」拆成 `Service`、`DaemonSet` 與 `Endpoints` 三層來看。
4. 驗證 WeaMind 目前是否真的缺少 HTTP→HTTPS redirect，並把「TLS 已存在」和「HTTPS-only 已成立」拆開。

## 這次要驗證的路徑或問題

1. host-based Ingress 規則下，沒有 Host header 的 `/health` 為什麼會回 `404`。
2. `nodepool=worker`、Pod 排程位置與 LB 後端設計之間是怎麼連起來的。
3. `svclb-traefik`、`traefik` Service 與實際 backend endpoint 之間如何分工，為什麼入口 node 數量不必等於 Traefik Pod 數量。
4. 為什麼外網直接打 `http://k8s.kyomind.tw/...` 也能拿到回應，以及目前到底有沒有 HTTP→HTTPS redirect。

## 今天要看的資源

1. Ingress
2. Deployment
3. Nodes
4. Pods
5. `kube-system/traefik` Service
6. `svclb-traefik` DaemonSet
7. 外部 `http://k8s.kyomind.tw/health` 與 `https://k8s.kyomind.tw/health` 的實際行為

---

## Command 1

### 要驗證的問題

- 當 LB Health Check 沒帶正確的 Host header 時，問題到底是 app `/health` 壞掉，還是 Ingress host-based routing 沒被命中？

### 三個可選指令

```bash
curl http://127.0.0.1/health
curl -H 'Host: k8s.kyomind.tw' http://127.0.0.1/health
kubectl get ingress weamind -n weamind -o yaml
```

### 指令

```bash
curl -H 'Host: k8s.kyomind.tw' http://127.0.0.1/health
curl http://127.0.0.1/health
kubectl get ingress weamind -n weamind -o yaml
```

### 關鍵輸出

```bash
curl: (7) Failed to connect to 127.0.0.1 port 80 after 0 ms: Couldn't connect to server

root@weamind-001:~# curl -H 'Host: k8s.kyomind.tw' http://127.0.0.1/health
{"status":"ok"}

root@weamind-001:~# curl http://127.0.0.1/health
404 page not found

spec:
	ingressClassName: traefik
	rules:
	- host: k8s.kyomind.tw
		http:
			paths:
			- backend:
					service:
						name: weamind-line-bot
						port:
							number: 80
				path: /
				pathType: Prefix
	tls:
	- hosts:
		- k8s.kyomind.tw
		secretName: k8s-kyomind-tw-tls
status:
	loadBalancer:
		ingress:
		- ip: 10.0.0.3
		- ip: 10.0.0.4
		- ip: 10.0.0.5
```

### 使用者選擇理由

- 先用帶正確 `Host` header 的 `curl` 建立對照組。若在 `Host: k8s.kyomind.tw` 正確的情況下仍然失敗，才更有理由懷疑是 app `/health` endpoint 或後端鏈路本身有問題；也就是先固定一個關鍵變因，區分到底是 host-based routing 問題，還是 app 壞掉。

### AI 判讀與修正

- 這次失敗**不是**因為 `Host` header 判斷錯了，而是因為**執行環境不對**。`127.0.0.1` 永遠是「你目前正在執行指令的那台機器自己」，如果在本機 Mac 上跑，它只會指向你的 Mac，不會自動指向 K3s 節點。
- 這條指令原本是在驗證 **node 上的 Traefik 入口**，因此正確的執行位置應該是 **K3s 叢集某一台 node 上**，尤其是 worker node。這和 [PROGRESS.md](PROGRESS.md#L111) 的歷史驗證是一致的：當時的描述本來就是「以 worker 節點實測驗證差異」。
- 這裡也順便釐清一個容易混淆的點：**不是 Pod container 內才會成立**。若你在 Pod 內打 `127.0.0.1:80`，通常只會打到那個 Pod 自己，不是在測 Ingress 入口；而 WeaMind app Pod 自己實際監聽的也不是 `80`，而是容器內 `8000`。所以這條題目的目的不是測 Pod 本地回應，而是測 **node 入口層是否能命中 Traefik / Ingress 規則**。
- 就今天已知的 runtime 觀察來看，因為 `svclb-traefik` DaemonSet 會在各 node 建立並綁 `HostPort 80/443`，所以 **control-plane 與 worker node 技術上都可能測得到 `127.0.0.1:80`**；但若要最貼近 Hetzner LB 的 target 設計，**優先在 worker node 上測更合理**。
- 所以這一輪真正釐清的是：**要測 `curl -H 'Host: ...' http://127.0.0.1/health` 這種 Ingress 入口行為，執行位置必須是 K3s node，不是本機 Mac、不是 bastion，也不是 app Pod 內。**
- 使用者後續刻意在 `weamind-001`（control-plane）上重跑同一條指令，成功得到 `{"status":"ok"}`。這個結果很有價值，因為它證明了：**control-plane 雖然不是 Hetzner LB 的 target，但在目前 K3s runtime 狀態下，node 本地仍然具備 Traefik 入口能力。**
- 也就是說，**「LB 沒有把 control-plane 納入 target」不等於「control-plane 本機完全沒有 80/443 入口」**。前者是外層流量設計選擇，後者是叢集內 `svclb-traefik` / Traefik 入口是否存在的 runtime 事實。
- 接著再補上沒有 `Host` 的對照：同樣在 `weamind-001` 上執行 `curl http://127.0.0.1/health` 得到 `404 page not found`，這就把因果關係釘得很清楚了。**同一台 node、同一個 path，只差 `Host` header，結果就從 `200` 變成 `404`，因此問題在 Ingress host-based routing 沒命中，而不是 app `/health` endpoint 本身壞掉。**
- `kubectl get ingress weamind -n weamind -o yaml` 這條指令的學習價值在於，它把「為什麼會這樣」直接攤在 YAML 上：`ingressClassName: traefik` 說明這條規則由 Traefik 接管；`rules.host: k8s.kyomind.tw` 說明 **這是一條 host-based routing 規則**；`path: /` + `pathType: Prefix` 說明該 host 底下的路徑會被送到 `weamind-line-bot:80`；`tls.hosts` 與 `secretName` 則說明同一個 host 也配置了 HTTPS 憑證。
- `status.loadBalancer.ingress` 中出現 `10.0.0.3`、`10.0.0.4`、`10.0.0.5` 也再次呼應了前面的 runtime 觀察：**Traefik / ingress 入口能力目前覆蓋三個 node**。這不等於 Hetzner LB 一定會把外部流量送到三台 node，但代表 ingress controller 對外宣告的入口資訊確實包含這三個 IP。

### 一句話收斂

- 在 K3s node 上對同一路徑做「有 `Host`」與「沒 `Host`」的對照，能直接證明 `/health` 的 `404/200` 差異來自 Traefik 的 host-based routing，而不是 app endpoint 壞掉。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- 如果要證明「LB 後端只放 worker」不是口號，而是對應到目前 app Pod 的實際落點，你會先看哪一層？

### 三個可選指令

```bash
kubectl get deployment weamind -n weamind -o yaml
kubectl get nodes -L nodepool
kubectl get pods -n weamind -o wide
```

### 指令

```bash
kubectl get pods -n weamind -o wide
kubectl get deployment weamind -n weamind -o yaml
```

### 關鍵輸出

```bash
NAME                      READY   STATUS    RESTARTS   AGE   IP           NODE
weamind-c7659784b-gbhjc   1/1     Running   0          42h   10.42.2.18   weamind-003
weamind-c7659784b-hgsgl   1/1     Running   0          42h   10.42.1.19   weamind-002

spec:
	replicas: 2
	selector:
		matchLabels:
			app: weamind
	template:
		metadata:
			labels:
				app: weamind
		spec:
			nodeSelector:
				nodepool: worker
status:
	availableReplicas: 2
	readyReplicas: 2
	replicas: 2
	updatedReplicas: 2
```

### 使用者選擇理由

- 先比較了三個候選指令後，判斷 `kubectl get pods -n weamind -o wide` 雖然能最快看見「當下兩個 Pod 跑在哪些 node」，但它只能證明目前狀態，**無法證明未來重建 / 重啟後仍然只會落在 worker**。
- 因此最後選擇 `kubectl get deployment weamind -n weamind -o yaml` 作為主答案，因為它能直接看到 `template.spec.nodeSelector.nodepool=worker` 這個長期約束條件；也就是從「目前剛好如此」上升到「配置保證它應該如此」。

### AI 判讀與修正

- 你的判斷是對的，而且這題最有價值的地方正是你自己講出來的那個區分：**`pods -o wide` 給你的是當下觀察，`deployment -o yaml` 給你的是排程約束。**
- `kubectl get pods -n weamind -o wide` 很適合做第一眼確認，因為它快速告訴你目前兩個 Pod 確實落在 `weamind-002` 與 `weamind-003`，也就是兩台 worker 上。但這只能說明「現在是這樣」，還不能排除只是剛好被排到 worker。
- `kubectl get deployment weamind -n weamind -o yaml` 則把真正關鍵的證據攤出來了：`spec.template.spec.nodeSelector.nodepool=worker`。這表示 **Deployment 在 Pod template 層明確要求新的 Pod 只能被排到帶有 `nodepool=worker` label 的 node**。
- 所以這題若要回答「LB 後端只放 worker 不是口號，而是和實際 workload placement 對得起來」，**最有确信度的主證據應該是 Deployment 的 `nodeSelector`，而 Pods 的實際落點則是用來補強『設定確實生效』的觀察證據。**
- 第二個候選 `kubectl get nodes -L nodepool` 也不是沒價值，它能補上「worker node 的 label 是否真的存在」這一塊；只是如果只看它，仍然無法直接證明 app Pod 一定受這個 label 約束。
- 所以這一輪可以收斂成一個很穩的 debug 口訣：**先用 `pods -o wide` 看現況，再用 Deployment YAML 看約束；『現況』和『約束』都對上時，才叫真正證明 workload 被固定在 worker。**

### 一句話收斂

- `kubectl get pods -o wide` 能證明 WeaMind Pods 現在確實跑在 worker；`kubectl get deployment -o yaml` 則能證明這不是偶然，而是被 `nodeSelector.nodepool=worker` 明確約束的結果。

### 狀態

- 已完成

---

## Command 3

### 要驗證的問題

- 為什麼 `traefik` Service 目前看起來只有一個 backend endpoint，但三個 node 仍然都可能成為入口？

### 三個可選指令

```bash
kubectl get daemonset -n kube-system
kubectl get pods -n kube-system -o wide | rg 'traefik|svclb'
kubectl describe daemonset svclb-traefik-e5d4d01b -n kube-system
```

### 指令

```bash
kubectl get daemonset -n kube-system
kubectl get pods -n kube-system -o wide | rg 'traefik|svclb'
kubectl describe daemonset svclb-traefik-e5d4d01b -n kube-system
kubectl get svc traefik -n kube-system -o wide
kubectl get endpoints traefik -n kube-system -o yaml
```

### 關鍵輸出

```bash
NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   AGE
svclb-traefik-e5d4d01b   3         3         3       3            3           82d

svclb-traefik-e5d4d01b-2dwhk   Running   weamind-001
svclb-traefik-e5d4d01b-s2pwj   Running   weamind-002
svclb-traefik-e5d4d01b-kxr4j   Running   weamind-003
traefik-6f5f87584-g5knx        Running   weamind-001

Host Port:  80/TCP
DEST_IPS:   10.43.235.250
Host Port:  443/TCP
DEST_IPS:   10.43.235.250
Node-Selectors: <none>
Tolerations: node-role.kubernetes.io/control-plane:NoSchedule op=Exists

traefik   LoadBalancer   10.43.235.250   10.0.0.3,10.0.0.4,10.0.0.5   80:30417/TCP,443:31051/TCP

subsets:
- addresses:
	- ip: 10.42.0.9
		nodeName: weamind-001
		targetRef:
			name: traefik-6f5f87584-g5knx
```

### 使用者選擇理由

- 想釐清為什麼只有一個 `traefik` endpoint，但三個 node 看起來都能成為入口，並確認 GUI 裡看到的 `svclb-traefik-...` DaemonSet 到底在做什麼。

### AI 判讀與修正

- **第一層先看入口鋪設**：`svclb-traefik-e5d4d01b` 是 `DaemonSet`，而且 `DESIRED=3`、三個 `svclb-traefik` Pods 分別落在 `weamind-001`、`weamind-002`、`weamind-003`，表示 **每個 node 都有一個 ServiceLB 入口 Pod**。
- **第二層看它實際做什麼**：`describe daemonset` 可看到兩個 container 都綁 `Host Port` `80/443`，並把流量送往 `DEST_IPS=10.43.235.250`，也就是 `traefik` Service 的 `ClusterIP`。這代表 **`svclb-traefik` 的角色是把每個 node 的主機埠流量導進 `traefik` Service**，不是它自己做 Ingress routing。
- **第三層看 Service 能力範圍**：`traefik` Service 是 `LoadBalancer`，`EXTERNAL-IP` 同時列出 `10.0.0.3,10.0.0.4,10.0.0.5`，所以 **三個 node 都在 Traefik 的入口集合裡**。
- **第四層看真正 backend 在哪**：`endpoints traefik` 只有一個 backend address `10.42.0.9`，而且對應 `traefik-6f5f87584-g5knx` on `weamind-001`，表示 **當下真正處理 Traefik 請求的 backend Pod 只有一個**。
- 因此這輪最重要的拆解是：**三個 node 都能成為入口，是因為 `svclb-traefik` DaemonSet 把入口鋪在每個 node 上；只有一個 `traefik` endpoint，則是因為 Service 後面目前只接到一個 Traefik Pod**。這兩件事屬於不同層，不矛盾。
- 更口語一點說：**入口可以分散在三台機器上，但實際接手處理流量的 Traefik backend 當下可以只在其中一台上**。

### 一句話收斂

- `svclb-traefik` DaemonSet 讓三個 node 都能接住進站流量，再把流量導進 `traefik` Service；而 `traefik` Service 後面目前只有一個 backend Pod，所以「三個入口、單一 Traefik endpoint」是完全可能的正常狀態。

### 狀態

- 已完成

---

## Command 4

### 要驗證的問題

- WeaMind 目前到底有沒有做 HTTP→HTTPS redirect，還是 HTTP 與 HTTPS 其實都能直接命中同一條 Ingress 規則？

### 三個可選指令

```bash
curl -I http://k8s.kyomind.tw/health
curl -I -L http://k8s.kyomind.tw/health
kubectl get ingress weamind -n weamind -o yaml
```

### 指令

```bash
curl -I http://k8s.kyomind.tw/health
curl -I -L http://k8s.kyomind.tw/health
```

### 關鍵輸出

```bash
HTTP/1.1 405 Method Not Allowed
allow: GET
content-length: 31
content-type: application/json
server: uvicorn

HTTP/1.1 405 Method Not Allowed
allow: GET
content-length: 31
content-type: application/json
server: uvicorn
```

### 使用者選擇理由

- 先直接跑兩個 `curl` 變體，但同時意識到自己其實還不熟 `-I` 與 `-L` 的意義，所以希望先釐清這兩個參數到底在測什麼，再判斷這份輸出是否真能回答「有沒有 redirect」。

### AI 判讀與修正

- 這一輪最關鍵的機制點是：**`curl -I` 不是一般的 GET，它會送出 `HEAD` request。** `HEAD` 的用途是只拿 response headers、不拿 body，所以很適合檢查 redirect、status code、server headers 這類入口行為。
- `curl -L` 的意思是：**如果伺服器先回 `301`、`302`、`307`、`308` 這種 redirect，`curl` 會自動跟著跳下去。** 所以 `-L` 本身不是在改 request 方法，而是在告訴 `curl`「如果遇到 redirect，就繼續追」。
- 你這次兩條都看到 `405 Method Not Allowed`，而且 response header 明寫 `allow: GET`，這代表 **目前 `/health` endpoint 不接受 `HEAD`，只接受 `GET`**。所以 `curl -I` 在還沒來得及幫我們回答「有沒有 redirect」之前，就先因為 method 不被接受而被 app 擋下來了。
- 這也正好解釋了為什麼瀏覽器打開是 `200`：**瀏覽器一般送的是 `GET`，不是 `HEAD`**。所以瀏覽器和 `curl -I` 根本不是在送同一種 request，回應不一樣是合理的。
- `curl -I -L` 之所以和 `curl -I` 得到同樣的 `405`，是因為 **前一步根本沒有拿到 redirect response**，而是直接拿到 `405`；既然沒有 `301/302/307/308` 可追，`-L` 自然也沒有事可做。
- 所以這輪最重要的修正是：**目前這兩條指令不能直接證明「有沒有 redirect」，它們首先證明的是 `/health` 不接受 `HEAD`。** 若要真正驗證 redirect，下一個更合理的做法應該是改用 `GET` 去看最終 URL 或完整 response，而不是繼續用 `-I`。
- 這也是為什麼我們前面外部實測會改用一般 `GET`，並看到 `http://k8s.kyomind.tw/health` 與 `https://k8s.kyomind.tw/health` 都能直接拿到 `200`，而且 `curl -L http://k8s.kyomind.tw/health` 的最終 URL 仍然是 `http://...`。那組證據才真正回答了「目前沒有 HTTP→HTTPS redirect」。

### 一句話收斂

- `curl -I` 送的是 `HEAD`，不是 `GET`；這輪看到的 `405` 先證明 `/health` 不接受 `HEAD`，而不是先證明有沒有 redirect，所以要驗證 redirect 仍應改用一般 `GET` 來看最終 URL。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- 用 `kubectl get daemonset -n kube-system`、`kubectl get pods -n kube-system -o wide | rg 'traefik|svclb'` 與 `kubectl describe daemonset ...` 看清楚 `svclb-traefik` 是 **每個 node 各一個的入口 DaemonSet**。
- 用 `kubectl get svc traefik -n kube-system -o wide` 與 `kubectl get endpoints traefik -n kube-system -o yaml` 看清楚 `traefik` Service 的入口涵蓋三個 node，但目前實際 backend endpoint 只有一個 `traefik` Pod。
- 用 `curl -I` 與 `curl -I -L` 釐清：`-I` 其實是在送 `HEAD` request，`-L` 只是在遇到 redirect 時追跳轉；因此 `/health` 回 `405` 代表 app 不接受 `HEAD`，不能直接把這個輸出當成 redirect 證據。

### 練習後還不順手的地方

- 一開始容易把 `svclb-traefik` DaemonSet 和真正的 `traefik` backend Pod 混成同一層。
- 之後若要再查，優先記得把問題拆成 `DaemonSet / Service / Endpoints` 三層，不要只盯著 Pod 數量。

### 補充

- 若需要，可補一輪把 `curl https://k8s.kyomind.tw/health` 與 TLS termination 的觀察接起來。
- 若要把 `Command 3` 的觀察補完整，可再加看 `kubectl get svc traefik -n kube-system -o wide` 與 `kubectl get endpoints traefik -n kube-system -o yaml`。
