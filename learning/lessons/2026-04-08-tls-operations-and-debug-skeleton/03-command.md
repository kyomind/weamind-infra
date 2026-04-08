# 2026-04-08 TLS Operations and Debug Skeleton Command

> 提示：今天的 command drill 重點是把 TLS 問題拆到正確資源層，不是把所有 `kubectl` 指令都背下來。

## 今日指令練習目標

1. 看懂 Ingress `tls` 區塊與 Secret 的連接。
2. 看懂 `Certificate` 是否 ready，以及失敗時往下追 `CertificateRequest`、`Order`、`Challenge`。
3. 練習把「憑證資源問題」和「正式流量路由問題」分層排查。

## 這次要驗證的路徑或問題

1. Ingress 現在到底引用哪個 TLS Secret。
2. 那個 Secret 背後是否有 ready 的 `Certificate`。
3. 若憑證未 ready，如何順著 cert-manager 資源鏈往下找。

## 今天要看的資源

1. Ingress
2. Secret
3. Certificate
4. CertificateRequest
5. Order
6. Challenge

---

## Command 1

### 要驗證的問題

- 怎麼先確認目前的 Ingress 到底引用哪個 TLS Secret，而不是憑感覺猜。

### 三個可選指令

```bash
kubectl get ingress weamind -n weamind -o yaml
kubectl describe service weamind-line-bot -n weamind
kubectl get pods -n weamind
```

### 指令

```bash
kubectl get ingress weamind -n weamind -o yaml
```

### 關鍵輸出

```bash
spec:
	ingressClassName: traefik
	rules:
	- host: k8s.kyomind.tw
	tls:
	- hosts:
		- k8s.kyomind.tw
		secretName: k8s-kyomind-tw-tls
```

### 使用者選擇理由

- 使用者選擇這條指令，是因為要直接看 Ingress 本身到底宣告使用哪個 TLS Secret，而不是從 Service 或 Pods 間接推測。

### AI 判讀與修正

- 這個選擇是對的，因為這一輪要驗證的是 Ingress `spec.tls.secretName`，最直接的證據就應該來自 Ingress 自己，而不是 Service 或 Pod。
- 從輸出可直接確認兩件事：第一，這份 Ingress 的 host 是 `k8s.kyomind.tw`；第二，它在 `spec.tls` 底下明確引用的 TLS Secret 是 `k8s-kyomind-tw-tls`。
- 這也再次證明：若要先確認「入口現在打算用哪張憑證」，第一步不是去猜 cert-manager 幫你生了什麼，而是先看 Ingress 正在引用哪個 Secret。
- 輸出裡的 `traefik.ingress.kubernetes.io/router.middlewares: weamind-https-redirect@kubernetescrd` 也順便提醒你：**redirect middleware 和 TLS Secret 是同一份 Ingress 上的兩個不同責任區塊。** 前者在處理 HTTP request 是否導轉，後者在處理 HTTPS 要用哪張憑證。

### 一句話收斂

- 要確認入口現在引用哪個 TLS Secret，最直接就是看 Ingress 自己的 `spec.tls.secretName`，而不是從 Service 或 Pods 旁敲側擊。

### 狀態

- 已完成

---

## Command 2

### 要驗證的問題

- 怎麼確認 TLS Secret 背後對應的憑證資源是否 ready。

### 三個可選指令

```bash
kubectl get certificate -n weamind
kubectl get secret k8s-kyomind-tw-tls -n weamind -o yaml
kubectl logs deployment/weamind-line-bot -n weamind
```

### 指令

```bash
kubectl get certificate -n weamind
kubectl get secret k8s-kyomind-tw-tls -n weamind -o yaml
```

### 關鍵輸出

```bash
NAME             READY   SECRET               AGE
k8s-kyomind-tw   True    k8s-kyomind-tw-tls   77d

metadata:
	annotations:
		cert-manager.io/certificate-name: k8s-kyomind-tw
		cert-manager.io/issuer-kind: ClusterIssuer
		cert-manager.io/issuer-name: letsencrypt-cloudflare
	name: k8s-kyomind-tw-tls
	namespace: weamind
type: kubernetes.io/tls
```

### 使用者選擇理由

- 使用者判斷第一條才是這一輪的正解，因為要先確認「對應的憑證資源是否 ready」，最直接就是看 `Certificate` 本身的 `READY` 狀態。
- 使用者也順手執行了第二條，因為它同樣很吸引人，而且能從 Secret annotation 反查這個 Secret 確實是由哪個 `Certificate` 與 `Issuer` 關聯出來。

### AI 判讀與修正

- 這一輪你的判斷是對的：若題目是「怎麼確認 TLS Secret 背後對應的憑證資源是否 ready」，**第一優先應該看 `Certificate`，不是先看 Secret。** 因為 `Certificate` 直接暴露了 cert-manager 這一層最關鍵的狀態欄位：`READY=True/False`。
- 你貼回的第一條輸出已經直接回答這一輪：`k8s-kyomind-tw` 這個 `Certificate` 在 `weamind` namespace 下存在，`READY=True`，而且它對應輸出的 Secret 就是 `k8s-kyomind-tw-tls`。
- 第二條輸出雖然不是這一輪的主答案，但很有價值。它補充證明了這個 Secret 不是手工亂放的一個 TLS 檔，而是被 cert-manager 管理的結果，因為 annotation 已明確寫出 `cert-manager.io/certificate-name: k8s-kyomind-tw`，以及 `issuer-name: letsencrypt-cloudflare`。
- 也就是說，這一輪兩條指令的關係可以講成：**`kubectl get certificate` 用來看「狀態是否 ready」；`kubectl get secret -o yaml` 用來看「這個 Secret 是否真的是 cert-manager 產物，以及它和哪個 Certificate / Issuer 相關」。**
- 你在這一輪延伸出的三個問題都很有價值，而且值得獨立記錄到 note：
- 第一，為什麼 `Certificate` 明明是 cert-manager 的資源，卻放在 `weamind` namespace。
- 第二，怎麼系統性地知道叢集中有哪些資源型別，而不是因為先知道 cert-manager 才「剛好去查 certificate」。
- 第三，在 Headlamp 這種 GUI 裡，`Certificate` 這類 CRD 通常會出現在哪裡。

### 一句話收斂

- 要確認 TLS Secret 背後的憑證是否健康，先看 `Certificate READY`；若要補證據，再看 Secret annotation 反查它是不是 cert-manager 管理的產物。

### 狀態

- 已完成

---

## Command 3

### 要驗證的問題

- 如果 `Certificate` 沒 ready，下一步要怎麼沿著 cert-manager 資源鏈往下查。

### 三個可選指令

```bash
kubectl get certificaterequest,order,challenge -n weamind
kubectl describe ingress weamind -n weamind
kubectl get endpoints weamind-line-bot -n weamind
```

### 指令

```bash
kubectl get certificaterequest,order,challenge -n weamind
```

### 關鍵輸出

```bash
NAME                                                  APPROVED   DENIED   READY   ISSUER                   REQUESTER                                         AGE
certificaterequest.cert-manager.io/k8s-kyomind-tw-2   True                True    letsencrypt-cloudflare   system:serviceaccount:cert-manager:cert-manager   17d

NAME                                                     STATE   AGE
order.acme.cert-manager.io/k8s-kyomind-tw-2-3296853819   valid   17d
```

### 使用者選擇理由

- 使用者選擇第一條，是因為若 `Certificate` 沒 ready，最合理的下一步就是沿著 cert-manager 的後續資源鏈往下看，確認是 `CertificateRequest`、`Order`、還是 `Challenge` 哪一層卡住。

### AI 判讀與修正

- 這個選擇是對的，因為這一輪的核心不是再回頭看 Ingress 或 Service，而是要把問題收斂到 cert-manager / ACME 流程內部。
- 你貼回的輸出代表：目前這條鏈其實是健康的。`CertificateRequest` 已經 `APPROVED=True`、`READY=True`；`Order` 也已經是 `STATE=valid`。這表示至少就這次留下來的 workflow artifact 來看，簽發流程沒有卡在申請或 ACME order 這一層。
- 這裡沒看到 `Challenge` 物件，不應直接解讀成「沒有做 challenge」。更合理的解讀是：**challenge 在當時流程進行時確實存在，但完成後已被清掉或目前沒有進行中的 challenge，所以 `get` 當下沒有列出來。**
- 這一輪也順手幫你建立了一個很重要的 debug 順序：若 `Certificate` 不 ready，不要立刻跳去看 app log，而是先看 `CertificateRequest`、`Order`、`Challenge` 這些 workflow 資源，把問題收斂到 cert-manager 流程的哪一站。
- 你這輪的延伸疑問也很重要：這些資源到底是不是一堆流程記錄 / metadata。比較準確的答案是：**它們不只是被動記錄，而是 Kubernetes 控制器模型裡的「狀態物件」。** `Certificate` 比較偏期望狀態與結果狀態；`CertificateRequest`、`Order`、`Challenge` 比較偏 workflow artifact，代表控制器為了完成簽發而建立的中間狀態資源。真正的憑證 material 則是最後寫進 `Secret` 裡。

### 一句話收斂

- 若 `Certificate` 沒 ready，下一步就沿著 `CertificateRequest`、`Order`、`Challenge` 往下查，把問題定位在 cert-manager workflow 的哪一層，而不是先跳去看 app。

### 狀態

- 已完成

---

## 最後收斂

### 今天用哪些指令看懂了什麼

- 用 `kubectl get ingress weamind -n weamind -o yaml` 確認目前入口實際引用的 TLS Secret 是哪一個。
- 用 `kubectl get certificate -n weamind` 確認對應的憑證資源是否 `READY=True`，再用 `kubectl get secret ... -o yaml` 補看 Secret annotation，確認它確實由 cert-manager 管理。
- 用 `kubectl get certificaterequest,order,challenge -n weamind` 確認 cert-manager workflow 後續各層是否健康，避免把憑證流程問題誤判成 Ingress 或 app 問題。

### 練習後還不順手的地方

- 使用者目前已能抓到排查順序，但對這些 cert-manager 資源到底是「真實資料本體」、「期望狀態」，還是「流程中間狀態」的分工還不夠穩定。

### 補充

- 若今天只完成部分輪次，這裡只保留已完成的最小結論。
