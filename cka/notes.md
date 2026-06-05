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

