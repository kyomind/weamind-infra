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

- 怎麼確認 TLS Secret 背後對應的憑證資源是否 ready。

### 三個可選指令

```bash
kubectl get certificate -n weamind
kubectl get secret k8s-kyomind-tw-tls -n weamind -o yaml
kubectl logs deployment/weamind-line-bot -n weamind
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

- 如果 `Certificate` 沒 ready，下一步要怎麼沿著 cert-manager 資源鏈往下查。

### 三個可選指令

```bash
kubectl get certificaterequest,order,challenge -n weamind
kubectl describe ingress weamind -n weamind
kubectl get endpoints weamind-line-bot -n weamind
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

- 待補

### 練習後還不順手的地方

- 待補

### 補充

- 若今天只完成部分輪次，這裡只保留已完成的最小結論。
