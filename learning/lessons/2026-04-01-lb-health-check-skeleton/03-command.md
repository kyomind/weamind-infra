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

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待回答

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

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

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待回答

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

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

```

### 關鍵輸出

```bash

```

### 使用者選擇理由

- 待回答

### AI 判讀與修正

- 待補

### 一句話收斂

- 待補

### 狀態

- 未開始

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- 用 `kubectl get daemonset -n kube-system`、`kubectl get pods -n kube-system -o wide | rg 'traefik|svclb'` 與 `kubectl describe daemonset ...` 看清楚 `svclb-traefik` 是 **每個 node 各一個的入口 DaemonSet**。
- 用 `kubectl get svc traefik -n kube-system -o wide` 與 `kubectl get endpoints traefik -n kube-system -o yaml` 看清楚 `traefik` Service 的入口涵蓋三個 node，但目前實際 backend endpoint 只有一個 `traefik` Pod。

### 練習後還不順手的地方

- 一開始容易把 `svclb-traefik` DaemonSet 和真正的 `traefik` backend Pod 混成同一層。
- 之後若要再查，優先記得把問題拆成 `DaemonSet / Service / Endpoints` 三層，不要只盯著 Pod 數量。

### 補充

- 若需要，可補一輪把 `curl https://k8s.kyomind.tw/health` 與 TLS termination 的觀察接起來。
- 若要把 `Command 3` 的觀察補完整，可再加看 `kubectl get svc traefik -n kube-system -o wide` 與 `kubectl get endpoints traefik -n kube-system -o yaml`。
