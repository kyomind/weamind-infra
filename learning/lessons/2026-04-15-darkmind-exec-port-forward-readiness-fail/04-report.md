# 2026-04-15 Darkmind Exec Port Forward Readiness Fail Report

## 今日主題

- 用 `darkmind` 的 healthy baseline 與 `readiness-fail` 情境，釐清 `exec`、`port-forward`、`readiness`、`Service endpoints` 的排查邊界。

## 狀態

已完成 QA 與 5 輪 command drill，今天的核心邊界已能收斂成口頭版本。

## QA 收斂了什麼

- 收斂了 `Running` 與 `Ready` 不是同一件事：`Running` 比較接近 Pod / container 已啟動在跑，`Ready` 才更接近是否具備接流量能力。
- 收斂了 `kubectl exec` 與 `kubectl port-forward` 不是互相取代的工具：`exec` 偏 container 內部視角，`port-forward` 偏本機到叢集內目標的臨時 tunnel。
- 收斂了 `readinessProbe` 失敗時，除了 Pod 狀態，還一定要把 `Service endpoints` 一起看，因為真正回答「Service 會不會送流量」的是後端名單，而不是單看 Pod 有沒有活著。

## 使用者原本卡住什麼

- 原本對 `port-forward` 的實務用途與資料路徑不夠熟，雖然知道它存在，但還沒真正操作過，也不確定它在排查鏈裡回答的是什麼問題。
- 原本對 `exec` 的定位較直覺，但還沒有完全把「能進 container」和「服務已正常回應」這兩件事拆開。
- 原本對 readiness fail 的理解方向是對的，但還需要更穩定地把 `Running`、`Ready`、`endpoints` 三者分開講。

## 今日 command 練習收斂

- 先用 healthy baseline 建立對照組：確認 Pod 是 `1/1 Running`，而且 Service 後面確實有 `endpoints`。
- 再用 `kubectl exec ... -- sh` 加上 container 內的 `wget http://127.0.0.1/`，確認服務在 container 內部視角下有正常回應。
- 再用 `kubectl port-forward` 加上本機 `curl`，確認 debug 用的本機 tunnel 可打到叢集內 Service，但這不等於正式外部流量已驗證完成。
- 最後用 `readiness-fail` 情境把差異釘死：Pod 可以是 `0/1 Running`、`exec` 也仍然成功，但 `endpoints` 仍然是空的，表示 Service 不會把流量送給它。

## 今日真正留下來的核心收穫

- 今天真正留下來的核心收穫不是某一條指令，而是 **五個觀察點的邊界**：`Running`、`exec`、`port-forward`、`Ready`、`endpoints`。
- 這五個觀察點分別回答不同層級的問題；它們可以同時互相支持，也可以同時給出不同答案，不能用單一成功訊號替代全部結論。

## 學完後已能講清楚什麼

- 能講清楚為什麼 `Running` 不等於 `Ready`，以及為什麼 `Ready` 最終會影響 Service 是否把流量送進去。
- 能講清楚 `exec` 與 `port-forward` 各自回答什麼問題，並說出它們都不等於正式流量驗證。
- 能講清楚在 readiness fail 情境裡，為什麼 Pod / container 仍可能活著，但 `endpoints` 仍然是空的。

## 仍待補強什麼

- `port-forward` 的資料路徑與常見實務情境雖已理解，但還需要再多做一兩次，讓反應更直覺。
- 還可以再補一輪口頭收斂，把今天的五個觀察點壓縮成更短、更像面試回答的版本。
- 若之後要延伸到真實 WeaMind 應用，可再做一次對 line-bot Service 的 `port-forward` 練習，進一步對照 debug tunnel 與正式流量路徑的差異。

## 下一步

- 可把今天的核心邊界整理成短版答題稿或 flashcards，讓之後複習時能快速回想 `Running`、`Ready`、`exec`、`port-forward`、`endpoints` 的分工。
- 若接續 W6 後段，下一個合理方向是用今天的邊界當基礎，回頭做一次更短、更快的整合複習，或延伸到真實 WeaMind Service 的 `port-forward` 演練。
