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

