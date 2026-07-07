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

## Services & Networking

1⭐️20
https://killercoda.com/sachin/course/CKA/nslookup
重點是這句`Verify your ability to perform DNS lookups(use name: test-nslookup ) for the service name from within the cluster using the busybox:1.28 image.`，要開測試pod

先做好前置環境
```bash
root@controlplane:~$ k run nginx-pod-cka --image nginx
pod/nginx-pod-cka created
root@controlplane:~$ k expose pod nginx-pod-cka --name nginx-service-cka --port 80
service/nginx-service-cka exposed
```
測試pod才是重頭戲，我們只是為了它可以執行工具指令
```bash
root@controlplane:~$ k run test2 --restart Never --image busybox:1.28 -- nslo
okup nginx-service-cka
pod/test2 created
```
這個沒有`-it`，用`k logs test2`可以獲得結果，再重導向即可
有`-it`就會直接輸出
然後建議加`--rm`，不然一直換名字好煩
`--restart Never`絕對必要，不然會卡前景，參見筆記

這題的驗證器太機車，放棄

---

2⭐️20
https://killercoda.com/sachin/course/CKA/coredns-1
兩大重點，筆記也有
一是deploy的command只要直接接在`--`後即可，沒有`--command`參數！建立後直接就是容器的command了
二是這裡直接create deploy再k edit更快，因為只改一個欄位值

三則是在pod中跑指令，使用k exec
四是，這題要先建ns啊！
```bash
root@controlplane:~$ k create deployment dns-deploy-cka --replicas 2 --image registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 -n dns-ns -- sleep 3600
error: failed to create deployment: namespaces "dns-ns" not found
root@controlplane:~$ k create ns dns-ns
namespace/dns-ns created
```

這裡可以「沒有」`-it`參數，照樣能運作
```bash
k exec dns-deploy-cka-cc6b4ddcf-l5xgm -n dns-ns  -- nslookup kubernetes.default
```

最後又檔案問題，不管了！

---

3⭐️5
https://killercoda.com/sachin/course/CKA/nodeport
主要是這兩個要查文件：
- protocol TCP
- node port 31000

文件範例，`nodePort`是加在：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: NodePort  # 留意
  selector:
    app.kubernetes.io/name: MyApp
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30007  # 這裡
```
而且大小寫和`type`的值還不同

還有一個重點，我指令沒有寫`--type=NodePort`
結果是，`k edit`要改一下`type`，但不需要刪除既有的ClusterIP相關欄位
因為NodePort也有ClusterIP
```bash
root@controlplane:~$ k get -n nginx-app-space svc app-service-cka
NAME              TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
app-service-cka   NodePort   10.98.179.213   <none>        80:31000/TCP   4m3s
root@controlplane:~$
```

---

4○3
https://killercoda.com/sachin/course/CKA/svc

小重點，`port-forward`只能寫這樣：
```bash
k port-forward svc/nginx-service 80:80
```
寫 svc 然後空一格後，在那邊 tab 是沒用的！

---

5⭐️20
https://killercoda.com/sachin/course/CKA/ingress
這題要建立ingress進行內部導流！有點難

我的做法，先查文件
https://kubernetes.io/docs/concepts/services-networking/ingress/#the-ingress-resource
然後再用指令
`k create ingress nginx-ingress-resource -h`看一下參數
我覺得自己寫`--rule`可能有點難，考慮create一個空的然參考文件寫法就好
結果不行！至少要指令一個`default-backend`
```bash
root@controlplane:~$ k create ingress nginx-ingress-resource
error: not enough information provided: every ingress has to either specify a default-backend (which catches all traffic) or a list of rules (which catch specific paths)
```
這就是重要線索了！

`-h`的說明：
```bash
    --default-backend='':
        Default service for backend, in format of svcname:port
```
結果
```bash
root@controlplane:~$ k create ingress nginx-ingress-resource --default-backend nginx-service:80
ingress.networking.k8s.io/nginx-ingress-resource created
```
好，重點是我自己建立後，再去文件複製，我覺得那個default svc應該要刪除
```yaml
spec:
  defaultBackend:  # 指令建立，我覺得應該不是這個，要刪→結果是不需要刪除，只是不會用到而已！
    service:
      name: nginx-service
      port:
        number: 80
  rules:  # 以下是從文件複製來並客製化
  - http:
      paths:
      - path: /shop
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
```

驗證不過，因為沒有寫「ssl-redirect should be configured as false .」部分
但我不會寫，必須再查文件！
重點是，這個文件也沒有哪一個有。有耶，我全站搜尋都是論壇，這到時候查得到嗎？我不禁懷疑
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  creationTimestamp: "2026-07-07T07:38:08Z"
  (略)
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
```
然後布林值要有雙引號！

結論：必須學習`--rule`寫法，會加速很多。下次要3分鐘寫完

---

