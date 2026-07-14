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

6○4
https://killercoda.com/sachin/course/CKA/clusterip
沒什麼，只要要記得 `k endpoint` 顯示的是 pod 們的ip！

```bash
root@controlplane:~$ k get endpoints
NAME            ENDPOINTS                                           AGE
kubernetes      172.30.1.2:6443                                     17d
nginx-service   192.168.1.145:80,192.168.1.226:80,192.168.1.53:80   20s
```
這3個是pod ip

---

7⭐️24
https://killercoda.com/sachin/course/CKA/network-policy

第一個思考點是，np可以直接create嗎？**不行！**
⭐️**那就要查文件、看yaml了**
https://kubernetes.io/docs/concepts/services-networking/network-policies/#networkpolicy-resource
複製該yaml來改！

這題的第一個坑是，killercoda就真的要兩條規則：
- Allow incoming traffic only from pods.
- Allow incoming traffic from a specific pod with the label app=trusted
儘管它們有明顯的集合關係，但就要這樣寫才行
```yaml
  - from:
    - podSelector: {}
    - podSelector:
        matchLabels:
          app: trusted
```
結果它要兩條獨立的`from`才肯罷休！😂

第二個是真正重點，那就是"保護的pod"的選擇，不是整個ns，要去deploy找label
```yaml
spec:
  podSelector:  # 不是 {} 就好了，要指定要保護的 pod
    matchLabels:
      app: my-app
```

---

8⭐️5
https://killercoda.com/sachin/course/CKA/nodeport-1
這題讓我對NodePort更加了解了
> 沒錯，這就是考試的高效操作。--type NodePort 讓骨架自帶 nodePort 欄位，你只需要改一個數字，比從 ClusterIP 改起來少動好幾行。
只要題目是NodePort，一定要在指令用`--type NodePort`，edit時只要改port號很方便

第二個重點是，建立expose，**--port是必填的**(只能自行選擇)，如果能去deploy、pod找到相關於訊息的容器port，那也只是少一步

> 考試時的安全做法：expose 完一定 k get svc 看一眼，確認三個 port 都是你要的值。

---

9⭐️⭐️⭐️20
https://killercoda.com/sachin/course/CKA/coredns
第一次看到要建立rs的題目
我覺得是這樣環境真的有誤，不然它應該被安排在ts，而且以ts來說，它也太難了

指令不能建rs，ai建議用create deploy然後改yaml
注意，這必然要先輸出yaml，因為kubectl edit 只能改 spec，不能改 kind，你不可能edit物件讓它從deploy變成rs

```bash
root@controlplane:~$ k create deployment dns-rs-cka --replicas 2 -n dns-ns --image registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 --dry-run=client -o yaml  -- sleep 3600 > rs
```
重導向一定在最後，哪怕這裡有command

結果dns不通，要troubleshoot！
最後是kube-system的coredns svc沒有指定正確的pod label，以下是spy

從零開始，你拿到的狀況是：

```bash
k exec -n dns-ns dns-rs-cka-qmp7m -- nslookup kubernetes.default
;; connection timed out; no servers could be reached
```

**第一步：理解錯誤訊息**

「no servers could be reached」→ Pod 連不到 DNS server → 這是叢集 DNS 問題，不是你的 Pod 問題。

**第二步：確認 Pod 的 DNS 設定指向誰**

```bash
k exec -n dns-ns dns-rs-cka-qmp7m -- cat /etc/resolv.conf
```

看到 `nameserver 10.96.0.10` → 這是 `kube-dns` Service 的 ClusterIP。所以問題在這個 Service 或它背後的 Pod。

**第三步：從 Service 往下追**

```bash
k get svc -n kube-system kube-dns
```

確認 ClusterIP 是 `10.96.0.10` → Service 存在，IP 也對。那問題在 Service 有沒有把流量送到後端。

**第四步：查 Endpoints**

```bash
k get endpoints -n kube-system kube-dns
```

`<none>` → Service 找不到任何後端 Pod。兩種可能：
- CoreDNS Pod 沒在跑
- selector 對不上

**第五步：確認 CoreDNS Pod 狀態**

```bash
k get po -n kube-system -l k8s-app=kube-dns
```

Running → Pod 活著，所以是 selector 問題。

**第六步：比對 selector vs labels**

```bash
k get svc -n kube-system kube-dns -o jsonpath='{.spec.selector}'
k get po -n kube-system --show-labels | grep coredns
```

發現 selector 寫 `core-dns`，Pod label 是 `kube-dns` → 改 Service selector → 修好。

📌 速記：DNS 故障排查 = 從 `resolv.conf` 開始，沿著 `Service → Endpoints → Pod → selector` 一路往下追。

## Storage

1⭐️⭐️⭐️25
https://killercoda.com/sachin/course/CKA/pv-pvc
這題有點太殘忍了，難怪weight 8

pv、pvc都**沒有指令**可以生成
pv遇到`hostpath`也是要小心
乖乖看文件吧！而且這題還有pv的node親和要求「Ensure that the PV is created on node01 , where the /opt/gold-stc-cka directory already exists.」
> 要加上 nodeAffinity，指定 nodeSelectorTerms.matchExpressions，key 通常是 `kubernetes.io/hostname`，value 填 node01。
以上就靠文件了解吧

第一部分是建立pv，而且要有node親和與hostpath兩大要素，重點是，要去哪裡抄？
答案是：volumes(不是pv，是pv的上層文件)的local！這超級重要
https://kubernetes.io/docs/concepts/storage/volumes/#local
有相當完整的demo：
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-pv
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - example-node
```
但還沒完，這個demo並不是「hostpath」這部分要改

`--show-lables`能看到 node 關鍵資訊
```bash
root@controlplane:~$ k get node --show-labels
NAME           STATUS   ROLES           AGE   VERSION   LABELS
(略)
node01         Ready    <none>          17d   v1.35.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=node01,kubernetes.io/os=linux
```
確實有`kubernetes.io/hostname=node01`

第二部分，pvc demo，又要去文件哪裡拿呢？沒錯，是pv底下的pvc
https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims

忘記加selector了！而且pvc的spec是immutable！
加了後就成功了，雖然還是pending，因為是 WaitForFirstConsumer

---

2○11
https://killercoda.com/sachin/course/CKA/sc-pv-pvc
STEP足足有三個，但沒有特別難點

這題要自建sc，**沒有指令**，顯然也要看文件
https://kubernetes.io/docs/concepts/storage/storage-classes/
題目沒講的欄位我都刪了，看樣子都不是必須，請看筆記即可，其實只有`provisioner`是必填，其餘都不是

建pv時，還是要確定一下cp的hostname叫啥，因為要設定node親和
```bash
root@controlplane:~$ k get node --show-labels
NAME           STATUS   ROLES           AGE   VERSION   LABELS
controlplane   Ready    control-plane   18d   v1.35.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=controlplane,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
```
確實是`kubernetes.io/hostname=controlplane`

最後的一個小陷阱是，要主動用`volumeName`指定要綁定的pv，因為SC用`WaitForFirstConsumer`，題目又要求要bound
如果不指定 `volumeName`，PVC 會一直處於 Pending，直到有 Pod 使用它

---

3○3
https://killercoda.com/sachin/course/CKA/pv
沒什麼，只是前兩題的一部分，純建pv

雖然用hostPath，但範例還是要去local那個拿最快，再自己改
apply後，記得k get pv檢驗一下

---

4⭐️20
這題我驗不過
https://killercoda.com/sachin/course/CKA/Shared-Volume
這題又有點多了，而且是shared volume

這題只和 pod 與 pvc 有關，pod 要求新增 sidecar 容器，透過 pvc 共用 volume，sidecar 跟 main container 都要 mount 同一個 pvc 的 volume
> 記得在 pod spec 的 volumes 與 containers.volumeMounts 都要正確設定，否則無法共用資料。

關於是要去哪裡抄文件，有 pvc 設定的 pod 檔
答案是！⭐️Claims As Volumes！灰常重要
https://kubernetes.io/docs/concepts/storage/persistent-volumes/#claims-as-volumes
一樣在pv頁，和pvc一樣都是透過anchor找到

有了這個demo，這題就簡單了——完美fit
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: myfrontend
      image: nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: mypd
  volumes:
    - name: mypd
      persistentVolumeClaim:
        claimName: myclaim
```

本題要求新的容器要叫 `sidecar-container`，這完全無法從題意得知，但驗證器會擋！
第二次被擋，要求用`command: ["bin/sh", "-c", "tail -f /dev/null"]`寫法，不可以用 `command: ["tail", "-f","/dev/null"]`，但其實兩者結果等價
結果我改的時候，少了`/`——要是 `"/bin/sh"` 不是 `"bin/sh"`。真的不可不慎

---

5○15
https://kubernetes.io/docs/concepts/storage/persistent-volumes/
weight 10，4個元件都要建立，太狠了

還好第一部分sc的文件很顯眼
https://kubernetes.io/docs/concepts/storage/storage-classes/

關鍵又在於，使用pvc的pod要去哪複製
答案是pv頁的claim as volume

輕鬆過關，就是建立4個元件很耗時，而且都要抄文件去改

---

6○5
略
跟上一題大同小異，只是建3個元件，重複性100%

只要記得最後 `k get pv,pvc` 檢查 bound 狀態即可

---

7○2
略
這題更簡單，因為只有建pvc

---

8○7
https://killercoda.com/sachin/course/CKA/pvc-pod

一切與上面幾題差不多，唯一的挑戰是要幫pod加上toleration，有點忘記在哪了
文件搜"toleration"
基本上就有了 https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
開頭就有寫法，基本上就那4行而已，然後是pod層級，其實也很簡單

---

9○2
https://killercoda.com/sachin/course/CKA/pvc-resize
2分 改pvc請求大小，用k edit即可

關鍵是怎麼「Ensure that the PVC successfully resizes to the new size and remains in the Bound state.」
我也不確定，因為bound後的空間只會顯示pv的總空間，我只確認是否還bound
不過應該是可以get看一下pvc的yaml格式
```yaml
  spec:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 60Mi
```

---

10○2
略
更簡單，建立sc，都包含在前面的題型了！

## Architecture, Installation & Maintenance

1○5
https://killercoda.com/sachin/course/CKA/sa-cr-crb
rbac三元素都有了，要求更新role的權限，算很基本

想說奇怪怎麼沒有自動完成，結果是把clusterrole搞錯成role，那物件當然不存在

可以edit：
```bash
root@controlplane:~$ k edit clusterrole group1-role-cka
clusterrole.rbac.authorization.k8s.io/group1-role-cka edited
```

---

2○4
https://killercoda.com/sachin/course/CKA/log-reader
log reader，顯然是多容器pod問題

題目就只有一行，我卻無從下手：
`log-reader-pod` pod is running, save All pod logs in `podalllogs.txt`

好 懂了，只是要把pod中的logs輸出而已！
所以要`root@controlplane:~$ k logs log-reader-pod > podalllogs.txt`
就這麼簡單！

---

3○10
https://killercoda.com/sachin/course/CKA/service-filter
這題完全就是考怎麼寫kube指令的jsonpath參數！

好，是這樣的，我忘記要大括號了！
所以標準是這樣
`k get svc redis-service -o jsonpath='{.spec.xxx...}'`
有array的話需要`[x]`，x是index數字，通常不會是全列出來，全列就是`[*]`
有了！
```bash
root@controlplane:~$ k get svc redis-service -o jsonpath='{.spec.ports[0].targ
etPort}'
6379root@controlplane:~$
```
實際輸出入犯的錯：
- 沒有大括號
- 竟然用`*`.spec開頭，其實不需要*字號！
- ports打成port
不過打錯就不會有結果，所以應該不難debug

問題二，指令放入shell腳本中，無法執行！
結果原來是，我複製的時候，連換行都被複製了
這…

---

4○13
https://killercoda.com/sachin/course/CKA/etcd-restore
etcd restore，我記得restore應該比save簡單，畢竟參數比較少

關鍵一：先確認自己是在cp上！
可以查，也可以直接ssh cp(題目有給指令)
```bash
root@controlplane:~$ k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   24d   v1.35.1
node01         Ready    <none>          24d   v1.35.1
root@controlplane:~$ hostname
controlplane
root@controlplane:~$
```
注意，get no是無法確認自己在哪個node的，只能知道cluster有哪些node

咦，restore不是utl嗎？
```bash
root@controlplane:~$ etcdutl restore /opt/cluster_backup.db --data-dir /root/default.etcd
Error: unknown command "restore" for "etcdutl"
Run 'etcdutl --help' for usage.
```

好，問題不大，少了子命令 `snapshot`！！
```bash
# ✓ 正確
etcdutl snapshot restore /opt/cluster_backup.db --data-dir /root/default.etcd
```

好，忘記輸出了到文字檔了，要砍掉這個data-dir才行

然後輸出記得用`&>`

好，題目只要求要 restore，沒有明確要求說要重啟 Static Pod。我也沒有重啟，但是通過了。可是我覺得這種不明確感真是討厭
ai認為：
>📌 速記：restore 後要不要改 manifest，看題目有沒有要求「讓 cluster 使用還原的資料」——沒講就不動。

---

5○4
https://killercoda.com/sachin/course/CKA/node-resource
很簡單的 k top題，對象是node，看memory

基本上，直接`k top node`肉眼看就好
如果真的很多，就加上`--sort-by memory`
其中`memory`無法自動完成
而且是字串排序，可能會坑人
我寧可肉眼慢慢看！

這題還要看`current_context`
指令我記得是…
```bash
root@controlplane:~$ k config current-context
kubernetes-admin@kubernetes
```

---

6○
https://killercoda.com/sachin/course/CKA/secret-1
decode secret

可以用jsonpath抓值，但我覺得沒必要！
```yaml
root@controlplane:~$ k get secrets -o yaml -n database-ns
apiVersion: v1
items:
- apiVersion: v1
  data:
    DB_PASSWORD: c2VjcmV0
```
注意，最後的輸出結果是整個鍵值，也就是data的內容
但只有`c2VjcmV0`被base64，所以要針對它處理
`base64 -d <<< "c2VjcmV0"`
再把鍵值對塞入

---

7○
