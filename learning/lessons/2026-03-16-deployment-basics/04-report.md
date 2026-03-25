# 2026-03-16 Deployment Basics Report

## 今日主題

從 WeaMind 的 `manifests/deployment.yaml` 收斂 Deployment、ReplicaSet、Pod 的管理鏈，並把 `replicas`、自動修復、滾動更新轉成可對 repo 說清楚的答案。

## 狀態

已完成 QA 與 command drill 收斂。

## QA 收斂了什麼

- 已把 WeaMind 裡的管理鏈穩定收斂成 `Deployment → ReplicaSet → Pod`，並能對回 `manifests/deployment.yaml` 的 selector、template 與 `replicas: 2`。
- 已能更精準說出 `replicas: 2` 在這個專案裡的實際價值：單 Pod 故障時不中斷、Service 導流有彈性、rolling update 不需要整批停機。
- 已補清楚為什麼 line-bot 應掛在 Deployment，而不是直接手寫裸 Pod，以及為什麼 repo 沒手寫 ReplicaSet YAML 仍能支撐自動修復與滾動更新。

## 使用者原本卡住什麼

- 一開始容易把 Deployment 的管理鏈和 Pod 建立後的執行鏈混在一起。
- 對 `CURRENT` / `READY`、namespace 內所有 ReplicaSets 與某個 Deployment 底下的 ReplicaSet 之間的查法與邊界還不夠穩。
- 對 Pod 要怎麼對回 ReplicaSet，以及 `rollout status` 到底在看什麼，原本也還沒有穩定說法。

## 今日 command 練習收斂

- 已用 `kubectl get deployment`、`kubectl get rs`、`kubectl describe deployment`、`kubectl get pods --show-labels`、`kubectl rollout status` 把 Deployment、ReplicaSet、Pod 三層資源對成同一條管理鏈。
- 已能區分不同指令的最佳使用情境：`get deployment` 看期望副本與現況、`get rs` 快速掃承接中的 ReplicaSet、`describe deployment` 從 Deployment 視角看新舊 ReplicaSet、`get pods --show-labels` 用名稱前綴與 hash 對 Pod、`rollout status` 看更新是否完成。
- 今天最有價值的一輪是 Pod 與 ReplicaSet 對照題，因為它要求從輸出中的名稱前綴與 `pod-template-hash` 推回目前承接中的 ReplicaSet，而不是只靠直接答案。

## 今日真正留下來的核心收穫

- Deployment 題目不能只停在名詞定義，真正穩定的理解是能把 YAML、控制器層級與 `kubectl` 輸出串成同一條線。
- ReplicaSet 雖然沒被手寫在 repo 裡，但它在執行期是可觀察、可判讀、而且對理解自動修復與滾動更新很關鍵的一層。
- command drill 的高價值不在於看最多輸出，而在於能不能從有限輸出把資源關係自己拼起來。

## 學完後已能講清楚什麼

- 已能講清楚 Deployment、ReplicaSet、Pod 的管理鏈，以及各自負責什麼。
- 已能講清楚 `replicas: 2`、`CURRENT` / `READY`、`NewReplicaSet` / `OldReplicaSets` 在 WeaMind 裡各自代表什麼。
- 已能用實際指令解釋目前是哪個 ReplicaSet 在承接、這些 Pods 是怎麼對回 ReplicaSet，以及 rollout 為什麼可視為已完成。

## 仍待補強什麼

- `rollout status`、Deployment conditions、rolling update strategy 三者之間的更細緻關係還可以再往下補。
- Pod 建立後的最小執行鏈，也就是 Scheduler、kubelet、container runtime 這段，仍要放到後續 lesson 再補穩。

## 下一步

- 進入下一個主題：Pod 管理與 Probe，補上 liveness probe、readiness probe、nodeSelector，以及 rollout 相關指令的更完整語意。