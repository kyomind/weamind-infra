# 2026-03-24 K8s Debug Tools Report

## 今日主題

把 W3 Day 1 的 debug 判讀框架接到 W3 Day 2 的工具篇：用 WeaMind 的實際情境釐清 `describe`、`logs`、`logs --previous`、`exec` 各自適合看的證據與較好的使用時機。

## 狀態

已完成 W3 Day 2 lesson，QA 與 3 輪 command drill 均已收斂。

## QA 收斂了什麼

- 已把 `kubectl describe pod`、`kubectl logs`、`kubectl logs --previous`、`kubectl exec -it` 分回不同證據類型，而不是只背工具名稱。
- 已能把 Pending、ImagePullBackOff、CreateContainerError、CrashLoopBackOff 對回較適合的第一輪工具選擇，並說出想先拿到哪種證據。
- 已能把兩個 WeaMind 真實 `404` 案例分回外層 routing 問題，而不是一開始就誤判成 Pod 內部問題。
- 已把 `Conditions`、`readiness probe`、`liveness probe` 之間的關係補清楚，知道 `Conditions` 全 True 不等於整條系統完全正常。
- 透過課後 homework，又把 `describe pod` 裡的 `Events`、container `State`、`Conditions` 三種訊息來源切得更清楚，也把 `CrashLoopBackOff`、`Restart Count`、`logs`、`logs --previous` 放回同一條時間線理解。

## 使用者原本卡住什麼

- 一開始對四個工具之間的差別只有模糊直覺，還沒有穩定地把工具對回證據類型。
- 對 `describe pod` 該先看哪些欄位、`logs --previous` 為什麼重要、`exec` 到底是進 Pod 還是進 container，都還不夠穩。
- 也一度容易把外層 routing 問題和 Pod 內部問題混在一起，或把 `Conditions=True` 誤讀成系統全健康。

## 今日 command 練習收斂

- 已完成 3 輪最小 command drill，分別對照 Kubernetes 視角的 `describe`、上一輪已死 container 視角的 `logs --previous`、以及 Pod 內部視角的 `exec`。
- 雖然叢集當下沒有真的 CrashLoopBackOff Pod，但已用健康 Pod 的 `describe` 建立基準輸出，知道之後若遇到異常要先看哪些欄位。
- 在 `exec` 練習裡，已成功驗證環境變數注入與 Pod 內部設定一致，也補上一個實務判讀：`wget` / `nc` 不存在時，要先判成工具缺失，不是直接判成連線失敗。
- 課後 homework 又把這個實務點再釘穩了一次：exit code `127` 與 `executable file not found in $PATH` 應優先判讀成 binary 不存在，而不是網路失敗。

## 今日真正留下來的核心收穫

- 工具不是拿來背的，而是拿來對應不同層的證據。
- 還沒進到 app 穩定執行期的問題，第一輪通常更需要 Kubernetes / runtime 視角；已進到 app 執行期但反覆掛掉的問題，才更常先看 app log。
- `exec` 很有用，但它只能證明 Pod 內部視角看到的狀態，不能替外部 routing 問題背書。
- 指令執行不起來和指令執行了但失敗，是兩個完全不同的層次；前者先看 binary / PATH，後者才看網路或服務本身。

## 學完後已能講清楚什麼

- 我已能講清楚 `describe`、`logs`、`logs --previous`、`exec` 各自適合看什麼，以及它們在 debug 流程中的位置。
- 我已能講清楚為什麼 Pending、ImagePullBackOff、CreateContainerError 常先看 `describe`，而 CrashLoopBackOff 常接 `logs` 或 `logs --previous`。
- 我已能講清楚 `kubectl exec` 是以 Pod 為入口、實際在某個 container 內執行命令，並知道多 container Pod 要用 `-c` 指定。
- 我已能講清楚 `Conditions` 全 True 的正確邊界，以及 readiness / liveness probe 在 Pod lifecycle 中的大致位置。
- 我已能講清楚 `curl not found`、`wget not found`、exit code `127` 這類訊號優先代表工具不存在，而不是直接等於連線失敗。

## 仍待補強什麼

- 之後若有機會，可再用真的異常 Pod 練一次 `describe`、`logs --previous` 的完整輸出判讀，而不是只用健康 Pod 代理觀察。
- 若要在精簡容器映像中做更多內部連線測試，仍需補一套「容器內沒有 `curl` / `wget` / `nc` 時的替代手法」。
- 若之後要再往下補，可以再整理 readiness / liveness 共用 `/health` endpoint 的 trade-off，以及 PostgreSQL 短暫失敗時應影響 readiness 還是直接 crash 的判斷。

## 下一步

- 已完成 W3 Day 2：Debug 工具篇。
- 下一步銜接 W3 Day 3：Debug 操作篇，重點改為給定故障情境後，按順序挑選排查步驟並把觀察串成完整 debug 敘述。
