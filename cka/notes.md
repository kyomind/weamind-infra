# CKA Practice Notes

## kubectl run 不需要寫 type

`kubectl run <pod-name> --image=<image>` 直接產 Pod，不用指定 type。
寫 `kubectl run pod mc-pod` 會讓 `pod` 變成 Pod 名稱。

對比 `kubectl create <type> <name>` 需要明確指定資源類型。

## kubectl flag 語法：多值與等號

多個 env 用重複 flag：`--env=A=a --env=B=b`，不是逗號分隔。

長 flag 的 `=` 可省略：`--image=nginx` 和 `--image nginx` 都行。

例外：`--dry-run=client` 必須用 `=`，否則 `client` 會被當成下一個參數。

注意：`--env A=a` 可以，但 `--env A a` 不行。flag 和 value 之間可用空格，value 內的 `KEY=VALUE` 不能拆。

