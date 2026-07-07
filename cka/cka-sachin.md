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

4○1
https://killercoda.com/sachin/course/CKA/pod
這題的重點是，pod yaml spec是無法更改的！
先匯出，改，砍pod，重新apply

記得apply後要驗證，用get -o yaml看一下即可

---

5⭐️10
https://killercoda.com/sachin/course/CKA/deployment-secret

記得加generic
```bash
k create secret generic db-secret --from-literal DB_Host=mysql-host --from-literal DB_User=root --from-literal DB_Password=dbpassword
secret/db-secret created
```

本題另一重點是，怎麼在depoy中引用secrt，yaml寫法
要看文件，搜「secret」
https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables
然後不在上面那裡xd，但有連結，再找到：
https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#configure-all-key-value-pairs-in-a-secret-as-container-environment-variables
最好能背下來
```yaml
spec:
  containers:
  - name: envars-test-container
    image: nginx
    envFrom:
    - secretRef:
        name: test-secret
```

然後驗證很重要，雖然這題重載新的secret我也不確定怎麼驗，但至少pod是新的！而且確實有rollout
```bash
root@controlplane:~$ k rollout history deployment webapp-deployment
deployment.apps/webapp-deployment
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

root@controlplane:~$ k get deployments.apps webapp-deployment
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
webapp-deployment   1/1     1            1           10m
root@controlplane:~$ k get pod
NAME                                 READY   STATUS    RESTARTS   AGE
webapp-deployment-6db65c69f5-9r7dc   1/1     Running   0          68s
```

---

6○1
https://killercoda.com/sachin/course/CKA/deployment-scale
主要就靠scale指令
```bash
root@controlplane:~$ k scale deployment -n redis-ns redis-deploy --replicas 3
deployment.apps/redis-deploy scaled
root@controlplane:~$ k get pod -n redis-ns
NAME                            READY   STATUS    RESTARTS   AGE
redis-deploy-66f68997fd-ktkjf   1/1     Running   0          84s
redis-deploy-66f68997fd-pwqc2   1/1     Running   0          13s
redis-deploy-66f68997fd-xvm6r   1/1     Running   0          13s
root@controlplane:~$
```

---


7⭐️⭐️⭐️24
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

8○2
https://killercoda.com/sachin/course/CKA/deployment-history
沒啥特別

---

9○
https://killercoda.com/sachin/course/CKA/deployment-1
抓yaml錯誤題型，記得先apply看錯誤

一定要驗證，成功apply，但其中一個pod資源不足！
這種情況要把舊的刪掉，而不是把那個pending的刪了
```bash
root@controlplane:~$ k get po
NAME                                 READY   STATUS    RESTARTS   AGE
my-app-deployment-57f7984db7-clh78   1/1     Running   0          2m56s
my-app-deployment-5cc5fd65f-7gbr4    1/1     Running   0          64s
my-app-deployment-5cc5fd65f-d8mjh    0/1     Pending   0          8s
```
成功
```bash
root@controlplane:~$ k get po
NAME                                READY   STATUS    RESTARTS   AGE
my-app-deployment-5cc5fd65f-7gbr4   1/1     Running   0          112s
my-app-deployment-5cc5fd65f-d8mjh   1/1     Running   0          56s
```

---

10○3
https://killercoda.com/sachin/course/CKA/rollback
沒啥特別，就是要驗證

---

11⭐️7
https://killercoda.com/sachin/course/CKA/pod-svc-1
這題看似是建pod與expose，結果坑是要讓ubuntu容器持續run，要給指令
通常 ubuntu 容器預設跑完就結束，要加 `-- /bin/sh -c "sleep infinity"` 或 `-- tail -f /dev/null` 讓 pod 持續運行。

這題另一個錯是我沒錯意到svc要自定義名稱！天啊
請檢查endpoints
```bash
root@controlplane:~$ k get endpoints
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME             ENDPOINTS           AGE
kubernetes       172.30.1.2:6443     16d
ubuntu-service   192.168.1.42:8080   18s
```
