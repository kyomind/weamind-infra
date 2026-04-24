# 2026-04-24 Observability Targets ServiceMonitor Dashboard Implementation

## 這份文件的角色

- 這份檔案用來記錄今天實作主體的每個 step 閉環，不是一般 command drill。
- 今天的主體是把已安裝好的 `kube-prometheus-stack` 往前推到 target discovery、`ServiceMonitor` / `PodMonitor` 與 Grafana 最小 dashboard 驗收。
- `07-implementation-note.md` 與本檔綁定，只承接本檔過程中的 implementation-specific 補充觀察。

## 今日實作主題

- 檢查 Prometheus targets 與 CRD discovery 現況，確認 WeaMind app metrics 若要接進來的最小邊界，並盡量收斂出一版可 demo 的 dashboard 驗收結果。

## 今日實作順序

1. 先確認 `observability` namespace 內的 Prometheus / Grafana / `ServiceMonitor` / `PodMonitor` 現況。
2. 釐清目前 Prometheus 已 scrape 到哪些 targets，哪些是 cluster baseline，哪些還不是 WeaMind app metrics。
3. 對照 WeaMind `Deployment` / `Service`，判斷 app metrics 若要被 scrape 的最小接法。
4. 視現況收斂一版 Grafana 最小 dashboard 驗收結果或缺口定位。

## 驗收訊號與回退點

### 驗收訊號

- 能拿到 Prometheus 目前 target 與監控 CRD 的最小現況證據。
- 能明確區分 cluster baseline metrics 與 WeaMind app metrics 的邊界。
- 至少完成一條可 demo 的 dashboard / metrics 驗收鏈，或明確定位今天卡點。

### 回退點

- 若 Prometheus target 頁或 API 不易直接查看，先用 Kubernetes 資源層證據縮圈，不急著做 UI 操作。
- 若 `ServiceMonitor` / `PodMonitor` 資源很多，先抓結構與 selector 模式，不要求今天一次逐個讀完。
- 若 app metrics 缺口落在 repo 外的應用程式碼，先把 infra 端邊界講清楚，不硬補不存在的觀測資料。

### Step 1

#### 這一步要驗證什麼

- `observability` namespace 內目前有哪些 `ServiceMonitor`、`PodMonitor`、Prometheus 與 Grafana 資源，確認 Operator discovery 模型已經落在叢集裡的哪一層。

#### 預計操作

```bash
kubectl get prometheus,servicemonitor,podmonitor -n observability
kubectl get svc -n observability
kubectl get ingress -n observability
```

#### 實際輸出 / 操作結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 2

#### 這一步要驗證什麼

- Prometheus 目前實際 scrape 到哪些 targets，並區分這些 target 主要是 node / Kubernetes baseline，還是已經包含 WeaMind app。

#### 預計操作

```bash
kubectl port-forward -n observability svc/observability-kube-prometh-prometheus 9090:9090
```

#### 實際輸出 / 操作結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 3

#### 這一步要驗證什麼

- 以 repo 內 WeaMind `Deployment` / `Service` 為錨點，判斷 app metrics 若要被 scrape，目前缺的是 `ServiceMonitor`、`/metrics` 暴露，還是兩者都缺。

#### 預計操作

```bash
rg -n "metrics|prometheus|port:" manifests/deployment.yaml manifests/service.yaml
```

#### 實際輸出 / 操作結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始

### Step 4

#### 這一步要驗證什麼

- 今天是否已具備一版可 demo 的 Grafana 最小觀測結果；若沒有，缺口究竟是在 datasource / target / app metrics 哪一層。

#### 預計操作

```bash
kubectl port-forward -n observability svc/observability-grafana 3000:80
```

#### 實際輸出 / 操作結果

- 待回填

#### AI 判讀與收斂

- 待回填

#### 目前狀態

- 未開始
