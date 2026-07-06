# 第二輪練習摘要

## Workloads & Scheduling

https://killercoda.com/sachin/course/CKA/pod-svc
用時：8
pod的容器名是不可改的！不可以k edit，只能乖乖輸出了
但你別灰心，RUN 了之後，你輸出會更快，不需要重跑
`k get pod app-pod -o yaml > pod`
驗證器吹毛求庛，無法通過
ai覺得不必管它，cka不會這樣考

---

https://killercoda.com/sachin/course/CKA/deployment
用時：1
記得要驗證pod和deploy

---

https://killercoda.com/sachin/course/CKA/configmap-deploy，這題也是無法解
用時：10+
重點： `--from-literal` 參數！
這是我是用 `k create  configmap webapp-deployment-config-map -h`查的！
```bash
kubectl create configmap my-config --from-literal=key1=config1 --from-literal=key2=config2
```

卡點：要改成吃cm檔
```yaml
- env:
  - name: APPLICATION
    value: web-app
```
用 k explain 確實很有用！只如果只是查欄位，也算快
注意，這真的很難寫對！indent
```yaml
command: # 明確指定啟動指令（覆蓋 Dockerfile 的 CMD/
envFrom: # 批次注入環境變數（比 env 更簡潔）
  - configMapRef:
      name: weamind-config # 注入非敏感配置
  - secretRef:
      name: weamind-secret # 注入敏感資料（會自動 base64 decode）
```
檢查器要求必須是以下寫法：
```yaml
env:
- name: APPLICATION
  valueFrom:
    configMapKeyRef:
      name: webapp-deployment-config-map
      key: APPLICATION
```
不能用envFrom
但兩種都要會！

---

4⭐️⭐️⭐️24
https://killercoda.com/sachin/course/CKA/deployment-rollout
好長的題目

create deploy 沒有 --labels！
並且注意三個label都要一致，還好k8s會幫你生欄位，改值就好了，大幸！但注意要用":"而不是"="

這題還考了`Configure the MaxUnavailable field to 30% and the MaxSurge field to 45% .`
yaml寫法要查文件，在https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment
成品，複製更快！
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 30%
    maxSurge: 45%
```

在此又犯了一個錯，`strategy`與`template`是同一層，小`spec`一層！
導致api server報錯

rollout好久xd

---


