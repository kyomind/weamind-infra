# 2026-03-24 K8s Debug Tools Note

## 學習注意事項

### 外部預習回帶重點

- 今天不另外做外部 prework，直接承接昨天已完成的 W3 Day 1 debug 分層框架。
- 今天的前提不是重背 Pod 狀態定義，而是把昨天的分層判讀接到工具選擇上。

### 今天進 lesson 前先記住的邊界

- 今天要解的是工具語意與證據類型，不是把所有 debug 故事全部重講一次。
- 今天會延續昨天的分層框架，但重點是回答「當我懷疑這一層時，先開哪種工具比較划算」。
- 今天會做最小 command drill，但不是大量堆指令；每一輪都要能回到為什麼選這個工具。

### 待驗證的 repo 對照點

- `manifests/deployment.yaml` 裡的 image、command、`envFrom`、probes，要對回 `describe` / `logs` / `logs --previous` 的較適合使用情境。
- `manifests/service.yaml` 與 `manifests/ingress.yaml`，要對回哪些情境其實不該第一步就 `exec` 進 Pod。
- `PROGRESS.md` 與 `docs/LINE-Webhook-切換流程.md`，要對回真實案例中各工具的第一輪證據價值。

### 暫時不在今天展開的點

- 今天先不展開 debug Pod、ephemeral container 或更進階的 troubleshooting workflow。
- 今天先不整理完整 flashcards，等 QA 或 command drill 累積到足夠穩定的結論後再補。

## Notes

## Flashcards
