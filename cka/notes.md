# CKA Practice Notes

## jsonpath 取 Secret 單一 key

`-o jsonpath='{.data.<KEY>}'` 直接取 raw 值，可 pipe 給 `base64 -d`：

```bash
k get secret my-secret -n ns -o jsonpath='{.data.DB_PASSWORD}' | base64 -d > decoded.txt
```

比 `-o yaml` 乾淨，不帶多餘內容。

## 單一值直接複製最快

`k get secret -o yaml` 複製值，再：

```bash
echo c2VjcmV0 | base64 -d > decoded.txt
```

考試計時下，這比打 jsonpath 語法快。jsonpath 留給多值或腳本化場景。

## CKA 預設 Linux 基礎

`base64`、`openssl`、`systemctl`、`journalctl`、`curl` 等不在 K8s 文件裡，考試預設你會。不確定時用 `--help`。

## create secret 要接類型

```bash
k create secret generic my-secret --from-file=data.txt
```

`secret` 後面必須接類型，不能直接接名稱。三種：`generic`、`docker-registry`、`tls`，CKA 幾乎都用 `generic`。

## --from-file vs --from-env-file

`--from-file=data.txt`：整個檔案塞進一個 key，key 名是檔名

```yaml
data:
  data.txt: <整個檔案內容的 base64>
```

`--from-env-file=data.txt`：檔案裡每行 `KEY=value` 變成獨立的 key

```yaml
data:
  DB_User: <value1 的 base64>
  DB_Password: <value2 的 base64>
```

要指定 key：`--from-file=mykey=data.txt`

## kubectl run 的 -- 和 --command 差異

```bash
k run x --image=nginx -- sleep 5         # 進 args（Docker CMD）
k run x --image=nginx --command -- sleep 5  # 進 command（Docker ENTRYPOINT）
```

題目說「用 command」就要加 `--command`。沒有 `--args` flag，因為 `--` 後面預設就是 args。

## jsonpath 必須指定資源名稱

```bash
k get svc -o jsonpath='{.spec.ports[0].targetPort}'       # 錯：沒指定名稱，查全部 svc
k get svc redis-service -o jsonpath='{.spec.ports[0].targetPort}'  # 對
```

不指定名稱時結果是 list，路徑變成 `.items[*].spec...`，原本的 `.spec...` 對不上。

## jsonpath 一律用單引號

```bash
# 安全
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# 有風險：* 可能被 shell glob 展開
kubectl get pods -o jsonpath="{.items[*].metadata.name}"
```

單引號不解析任何內容，雙引號會嘗試展開 `*`、`$`、`!` 等。考試不用記哪些安全，統一單引號。

## jsonpath 基本語法

把 YAML 層級用 `.` 串起來，陣列加 `[]`：

| 語法 | 用途 | 範例 |
|------|------|------|
| `.spec.field` | 取單一欄位 | `.spec.clusterIP` |
| `.items[*]` | 遍歷陣列 | `.items[*].metadata.name` |
| `.items[0]` | 取特定索引 | `.spec.ports[0].targetPort` |
| `?(@.key==val)` | 條件過濾 | `.items[?(@.metadata.name=="redis")]` |
| `{"\n"}` | 換行輸出 | 多筆結果時好讀 |

實戰：先 `-o yaml` 看結構，再把層級翻譯成 jsonpath。

## --sort-by 也是 jsonpath，一律加單引號

`--sort-by` 用的是 jsonpath 語法。官方文件有時省略引號，但有 `[]` 等字元時 shell 會嘗試展開。統一加單引號最安全：

```bash
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'
```

## boolean flag 不能空格接值

Boolean flag 出現即是 true，不需要帶值。空格後的字會被當成下一個參數。

```bash
k logs pod --all-containers true   # 錯：true 被當成 container name
k logs pod --all-containers        # 對：出現即 true
k logs pod --all-containers=true   # 對：明確寫法
k logs pod --all-containers=false  # 要關掉才需要 =false
```

所有 boolean flag 同理：`--watch`、`--dry-run`、`--force` 等。

## 已知 pod name，找它在哪個 namespace

```bash
k get pod -A | grep <pod-name>
k get pod --all-namespaces | grep <pod-name>
```

`-A` 是 `--all-namespaces` 的簡寫。

## kubectl logs 記得加 --all-containers

```bash
k logs <pod> --all-containers > logs.txt
```

考試題目可能是多容器 pod，養成習慣加這個 flag，避免漏掉其他 container 的 log。

## kubectl top node --sort-by

找資源用量最高/最低的 node：

```bash
k top node --sort-by memory
k top node --sort-by cpu
```

此時 `--sort-by` 只接受 `cpu` 或 `memory` 兩個值。

## tab completion 不補 flag 的值

Tab 補齊範圍：子命令、flag 名稱、資源類型、資源名稱。

Flag 的可選值（如 `--sort-by` 的 `cpu`/`memory`）不在補齊範圍，要自己打完整字串。

## CKA 改卷看結果不看過程

能用眼睛看出答案就直接手寫，不需要硬湊 pipeline。省下的時間拿去做下一題。

```bash
echo "$(k config current-context),controlplane" > high_memory_node.txt
```

## k config current-context

取得當前 context 名稱，題目常要求輸出格式包含 context。

```bash
k config current-context
```

## CKA 常用兩層子命令

不用背，`-h` 看一眼就知道有哪些子命令。

| 命令群組 | 常用子命令 | CKA 用途 |
|----------|------------|----------|
| `config` | `current-context`, `get-contexts`, `use-context`, `set-context` | context 切換、查詢 |
| `rollout` | `status`, `history`, `undo`, `restart` | Deployment 滾動更新 |
| `certificate` | `approve`, `deny` | CSR 簽發 |
| `auth` | `can-i` | RBAC 權限檢查 |
| `top` | `node`, `pod` | 資源用量查詢 |
| `cluster-info` | `dump` | 叢集資訊 |

## kubectl logs 沒有內容過濾參數

`kubectl logs` 的參數都是時間/行數/容器層級，不做內容過濾：

| 參數 | 過濾什麼 |
|------|----------|
| `--since=1h` | 最近 1 小時 |
| `--tail=100` | 最後 100 行 |
| `--previous` | 前一個容器的 log |
| `-c <name>` | 指定容器 |

內容過濾交給 shell：`grep`、`awk` 等。

## CKA 常用 grep

| 用法 | 效果 |
|------|------|
| `grep "ERROR"` | 只看含 ERROR 的行 |
| `grep -i "error"` | 不分大小寫 |
| `grep -c "ERROR"` | 算有幾行符合 |
| `grep -v "INFO"` | 反向——排除含 INFO 的行 |

速記：`grep "關鍵字"` = 只留匹配行，`-v` = 反向排除

## CKA log 題套路

kubectl 負責取、grep 負責篩、`>` 負責存：

```bash
k logs <pod> | grep "ERROR" > errors.txt
```

