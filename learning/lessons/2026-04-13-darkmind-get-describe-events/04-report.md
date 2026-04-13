# 2026-04-13 Darkmind Get Describe Events Report

## 今日主題

- 啟用 `darkmind` 練習環境，建立 Day 1 的固定觀察套路：`get`、`describe`、`events`。

## 狀態

- 已完成

## QA 收斂了什麼

- 今天的 QA 沒有重講大塊理論，而是先把 Day 1 的觀察順序對齊：先用 `get` 拿高層摘要，再用 `describe` 看單一 resource 細節，最後用 `events` 補時間序列。
- 也把幾個原本不夠穩的概念講準了：`get` 不是在看 YAML 級設定細節，而是在看第一層狀態摘要；`describe` 比較像 Kubernetes 對單一 resource 的展開式說明；`Event` 本身是 resource kind，而且不只記錯誤，也會記正常流程。
- 健康基準這件事也已收斂成穩定說法：不是多做一步而已，而是建立後續辨認異常偏離的比較座標系。

## 使用者原本卡住什麼

- 一開始對 `kubectl get` 第一眼到底在看什麼、`get` 和 `describe` 的根本差異、`events` 到底是什麼，還沒有足夠清楚的語言。
- 對 label 的使用雖然有直覺，但還沒有完全分清楚：何時適合用 label 做穩定鎖定，何時應回到具體 Pod 名稱精看單點。
- 對 `kubectl delete namespace darkmind` 的效果原本也沒有完整概念，不確定它是不是只刪掉 namespace 名稱本身。

## 今日 command 練習收斂

- 今天已完整走完 Day 1 的 5 輪最小排查鏈：建立健康基準、套用 `image-pull-error`、用 `get pods` 看第一層異常、用 `describe pod` 看單一資源細節、用 `get events` 補時間序列。
- 今天真正練到的不是多跑幾條指令，而是每一輪都知道自己正在驗證哪一層：`get` 看摘要、`describe` 看單點展開、`events` 看跨 resource 的事件流。
- cleanup 也已完成，知道 `kubectl delete namespace darkmind` 是把整個 lab 工作區打包清空，而不是單刪一個物件。

## 今日真正留下來的核心收穫

- 排查不是一開始就往最細處鑽，而是先建立正常基準，再逐層縮圈。
- image pull 類問題可以靠一組很穩的訊號快速判讀：`get` 先看到 `ImagePullBackOff`，`describe` 再確認 `State=Waiting`、`Reason=ImagePullBackOff`、`Restart Count=0`，最後用 `events` 看完整因果鏈。
- label 很適合做穩定範圍鎖定，但多 replica 時，真正要精看某一顆 Pod，通常還是先用 `get` 選目標，再回到具體 Pod 名稱。

## 學完後已能講清楚什麼

- 能講清楚 `kubectl get`、`kubectl describe`、`kubectl get events --sort-by=.lastTimestamp` 三者各自較適合回答什麼問題。
- 能解釋為什麼 `Event` 不是純錯誤清單，而是 Kubernetes 的事件流。
- 能描述 Day 1 這條最小排查鏈，並用 `image-pull-error` 情境說出每一步在驗證哪一層。
- 能講清楚 `kubectl delete namespace darkmind` 的效果與為什麼它適合當 lab 收尾。

## 仍待補強什麼

- 多 replica 情境下，如何更熟練地用 `get` 挑出最值得深挖的 Pod，之後再對單點做 `describe`。
- `kubectl get events` 的篩選手法還要再練，尤其是 `--field-selector` 的實際使用。
- Day 2 還要再把 `logs`、`logs --previous` 與今天的 Day 1 骨架接起來，讓 image pull 類問題和 app crash 類問題的分界更穩。

## 下一步

- 進入 Day 2，主題改成 `logs`、`logs --previous`、`rollout`，把今天的 Day 1 觀察鏈往下一層推進。
