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

7○20
https://killercoda.com/sachin/course/CKA/cluster-upgrade
cluster升級就是要看升級的文件。
打"upgrade"搜，但是第二個才是，標題為「Upgrading kubeadm clusters」
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
本題要升級的是minor版本，1.27.x，x升到**當前的下一個**！(注意，不是最新)
要求升級三個東東：
- kubeadmin
- cluster
- kubelet
不包含 kubectl
最後要驗證！

反正這題就是照文件來
先用 get node 看一下版本，是 1.35.1，所以要升到1.35.2
文件中的指令：
```bash
# replace x in 1.36.x-* with the latest patch version
sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm='1.36.x-*' && \
sudo apt-mark hold kubeadm
```
不能直接用，因為只有要升到下一版，而且我們是1.35
要改一下，變成「1.35.2」其餘應該不用改

第四步一樣要改！
```bash
sudo kubeadm upgrade apply v1.36.x
改成
sudo kubeadm upgrade apply v1.35.2
```
按y，最後要看到成功msg，版本是我們的版本
**這步要等很久！**
```bash
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.36.x". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```

其中"For the other control plane nodes"部分可別執行


🐱：這一段是不需要的！多做了！因為題意只要升級cp而已
第二步，worker node
要在get一次node名稱，執行指令
`kubectl drain <node-to-drain> --ignore-daemonsets`
即
`kubectl drain node01 --ignore-daemonsets`

然後又有改動點：
```bash
sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y kubelet='1.35.2-*' kubectl='1.35.2-*' && \
sudo apt-mark hold kubelet kubectl
```

最後要檢查：
```bash
k get node
k version
kubeadm version
```

不難，但耗時！

---

8○20
https://killercoda.com/sachin/course/CKA/secret
給定一個檔，建立secret！

先看檔的內容
```bash
root@controlplane:~$ cat database-data.txt
DB_User=REJfVXNlcj1teXVzZXI=
DB_Password=REJfUGFzc3dvcmQ9bXlwYXNzd29yZA==
```

好，重點在於怎麼使用參數而已，應該是from file之類的，還是from env，可以先查一下：
`k create secret generic -h`
別忘了 generic

有了！
```
--from-env-file=[]:
        Specify the path to a file to read lines of key=val pairs to create a secret.
```
注意，內容是array，元素顯然是path字串，不要寫錯

一直出錯！只好問ai
>📌 速記：kubectl help 裡的 `[]`、`<>` 是文件語法標記（代表型別或選填），**不是要你原樣輸入的字元**。

最後要檢查
```bash
root@controlplane:~$ k get secrets
NAME                  TYPE     DATA   AGE
database-app-secret   Opaque   2      12s
root@controlplane:~$ k describe secrets database-app-secret
Name:         database-app-secret
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
DB_Password:  34 bytes
DB_User:      20 bytes
```
結果過不了！奇怪
結果是，要用`--from-file`而不是`--from-env-file`
題意也不算很清楚，可惡

---

9○`
https://killercoda.com/sachin/course/CKA/log-reader-2
k logs 加上 grep 應用題xd，因為只能輸出error
沒啥難度
`k logs pod-name | grep "ERROR" > poderrorlogs.txt`

---

10○2
https://killercoda.com/sachin/course/CKA/pod-create
題目「Create a pod called sleep-pod  using the nginx  image and also sleep (using `command` ) for give any value for seconds.」
重點在command

我這樣寫，結果只是arg！
`k run sleep-pod --image nginx -- sleep 3`
顯然要用`--command`參數才是對的
`k run sleep-pod --image nginx --command -- sleep 3`
果然！
```yaml
spec:
  containers:
  - command:
    - sleep
    - "3"
    image: nginx
    imagePullPolicy: Always
    name: sleep-pod
```

---

11○1
https://killercoda.com/sachin/course/CKA/log-reader-1
和前面那題一樣，但更簡單，因連grep都不用

---

12○10
https://killercoda.com/sachin/course/CKA/etcd-backup
這題是etcd備份！反正就兩種題目：備份跟還原
備份就是指令比較長啦，然後要複製的內容比較多
在 CLI 的情況下，一定要使用 Grep 去篩選，才能夠上下對照

留意這個寫法：`grep -- "--"`
`k get po etcd-controlplane -n kube-system -o yaml | grep -- "--"`
效果：
```bash
root@controlplane:~$ k get po etcd-controlplane -n kube-system -o yaml | grep -- "--"
    - --advertise-client-urls=https://172.30.1.2:2379⭐️
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt⭐️
    (略)
    - --key-file=/etc/kubernetes/pki/etcd/server.key⭐️
    (略)
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt⭐️
    - --watch-progress-notify-interval=5s
```
然後就可以一邊看一邊寫指令+參數了！
好，四個參數，我沒有完全記得！直接複習吧！
```bash
ETCDCTL_API=3 etcdctl snapshot save /opt/cluster_backup.db \
  --endpoints=https://172.30.1.2:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```
除了注意參數，也要留意值，值可能會搞錯，例如 endpoints、cert 路徑、key 路徑都要和實際環境一致

> 如果忘記路徑，直接查看 etcd 靜態 Pod 的定義檔：cat /etc/kubernetes/manifests/etcd.yaml | grep -E "**trusted-ca-file|cert-file|key-file**" 即可快速對照路徑。
上面這幾個key的對應很重要，然後最後要 `&>`

---

13○10
https://killercoda.com/sachin/course/CKA/pod-filter
又要考jsonpath了！可惡
雖然是非常非常基本的一題，只要會jsonpath寫就行

結果，這題目充滿危險！講幾個重點吧！
- jsonpath 格式再說一下：`k get po nginx-pod -o jsonpath='{.spec.containers[0].name}'`
- 結果這題是要你去拿某個label key，我完全沒看懂題目，大錯
- 輸出為指令腳本，**這個指令腳本一定要自己執行看看**。因為指令如果是錯誤，結果就是空白

---

14⭐️20
https://killercoda.com/sachin/course/CKA/pod-log
純粹是建pod，但要求很多，包含使用configmap作為volume

第一個是要判斷能不能不要生yaml，應該是沒辦法，因為同時要求了args和command，那就不可能了，畢竟`--`只一個！
- 就算沒有上面，它要設定容器名——那就不可能不建yaml了！
- 其三，其實 volume 的使用也無法靠指令去建
乖乖生吧！

注意這指令的結構與順序，非常重要
```bash
k run alpine-pod-pod --image alpine:latest --restart Never --dry-run=client -o yaml  -- tail -f /config/log.txt > pod
```
- 重導向一定在最後
- 任何參數一定要在`--`之前

後來想想參數應該用command，修改比較容易！
然後，volume要打很多，直接去文件吧！
查"volume"，第一個，下面就有了
https://kubernetes.io/docs/concepts/storage/volumes/
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
    - name: test
      image: busybox:1.28
      command: ['sh', '-c', 'echo "The app is running!" && tail -f /dev/null']
      volumeMounts:
        - name: config-vol
          mountPath: /etc/config
  volumes:
    - name: config-vol
      configMap:
        name: log-config
        items:
          - key: log_level
            path: log_level.conf
```

其中一個隱藏提示是：mountPath path是否？
答案就是`['tail -f /config/log.txt']`的這個path！

犯錯：插入volume**沒改好全部的縮排**！

執行，有錯！path字串少了一個單引號，可惡，這裡：
```yaml
    volumeMounts:
        - name: config-volume
          mountPath: /config/log.txt'
```
其實可以不用引號的！但如果有，就要成雙成對

這題驗證器有問題，我們command有加`-c`它覺得不對，但不加一定不行
這題就這樣，不管了

---

15○15
https://killercoda.com/sachin/course/CKA/pod-log-1
跟pod env有關，不是很直覺

簡單講，要設定env，然後在command的指令裡面使用這個env
後者要怎麼寫？

先設定env吧！
env怎麼寫我也忘了，去文件，查"env"，第一條就有！
https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/
```yaml
spec:
  containers:
  - name: envar-demo-container
    image: gcr.io/google-samples/hello-app:2.0
    env:
    - name: DEMO_GREETING
      value: "Hello from the environment"
    - name: DEMO_FAREWELL
      value: "Such a sweet sorrow"
```
我寫這樣，但顯然是錯的，因為用k logs看就知道變數沒還原
```yaml
spec:
  containers:
  - command:
    - sh
    - -c
    - echo '"$TV" && sleep 3600'
    env:
    - name: TV
      value: "Sony Tv Is Good"
```
重點是 command 裡面要用單引號（'）包住**整個 shell 指令**，這樣 shell 才會展開 env 變數。如果用雙引號或直接寫，k8s 會把 $TV 當字串，不會展開。

正確寫法，這樣就夠了！
```yaml
command:
- sh
- -c
- echo "$TV" && sleep 3600
```
🐱：但`"$TV"`是對的！
切記`$`要跟變數名稱黏緊緊！
光這個變數寫法就花了我10分鐘去了！

---

16○4
https://killercoda.com/sachin/course/CKA/pod-resource
是 k top 題

我一樣，不管排序，肉眼看！
`k top pod -h`先查參數，知道兩個關鍵的：
- -A，因為要查全cluster
- 排序--sort-by，此時只能填cpu或memeory
本題查cpu

`k top pod -A --sort-by cpu`
寫入文件中
`echo "kube-apiserver-controlplane,kube-system" > high_cpu_pod.txt`

---

17○
https://killercoda.com/sachin/course/CKA/sa-cr-crb-1
rbac題

三個都要建！
熊熊忘記這三個有指令直接create嗎？不過試試就知道了
- `k create serviceaccount app-account` ok，而且這個很單純

`k create role app-role-cka -h` ok，但要查參數
看權限和資源怎麼寫，其實還有api group
```
    --resource=[]:
        Resource that the rule applies to
    --resource-name=[]: 應該不是這個
        Resource in the white list that the rule applies to, **repeat this flag for multiple items**
    --verb=[]:
        Verb that applies to the resources contained in the rule
```
就這兩個，並沒有api group的參數

好 試試
```bash
root@controlplane:~$ k create role app-role-cka --verb 'get' --resource pods
role.rbac.authorization.k8s.io/app-role-cka created
```

最後是role binding
這個指令相對簡單，但第一次忘記給名稱了
```bash
root@controlplane:~$ k create rolebinding --serviceaccount app-account --role app-role-binding-cka
error: exactly one NAME is required, got 0
See 'kubectl create rolebinding -h' for help and examples
```
又犯了一個最常見錯誤！
```bash
root@controlplane:~$ k create rolebinding app-role-binding-cka  --serviceaccou
nt app-account --role app-role-binding-cka
error: serviceaccount must be <namespace>:<name>
```
題外話，知道當前所在ns的方法：
```
kubectl config view --minify -o jsonpath='{..namespace}'
```
其實不太容易知道！還好本題就是要預設ns
```bash
root@controlplane:~$ k create rolebinding app-role-binding-cka  --serviceaccount default:app-account --role app-role-binding-cka
```
這個指令有誤，這裡`--role app-role-binding-cka`
砍掉這個role binding
重點是，做完要檢查，使用指令
`k auth can-i get pods --as=system:serviceaccount:default:app-account`
當然，describe確認一下，對照，也是可以

總之，通常情況，三者都會create，很難直接驗證或看出來哪個有問題，只能靠實際測試權限或 describe 來確認

所以要驗證這題是否通過，也是要`k auth can-i`
```bash
root@controlplane:~$ k auth can-i get pods --as=system:serviceaccount:default:app-account
yes
```
參數這段也只能背了！--as=system:serviceaccount:<namespace>:<serviceaccount>

## Troubleshooting

1○5
https://killercoda.com/sachin/course/CKA/pod-issue-6
這題實際是卡pvc，access mode不合

access mode無法k edit，只能重做
結果我犯了一個大錯，沒匯出pvc就先刪了它！
這在考試中就gg了！

就一個點，很簡單，但誤刪真的很可怕！

---

2⭐️20
https://killercoda.com/sachin/course/CKA/controller-manager-issue
改變repica，那用scale就好了

`k scale deployment video-app --replicas 2`
改完後確認一下：
```bash
root@controlplane:~$ k get deployments.apps
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
video-app   0/2     0            0           103s
```
沒用，yaml還有問題
但要先看pod為何起不來才是正道，要describe
目前沒有任何pod存在，只能去describe deploy
看不出deploy yaml有何問題，重點應該在UP-TO-DATE 為0

結果這題是控制器問題
>因為 controller-manager 是負責監控 Deployment/ReplicaSet 並生成對應 Pod 的元件，它掛了
也就是controller-manager沒running：
```bash
kube-controller-manager-controlplane   0/1     CrashLoopBackOff   6 (3m56s ago)   9m22s
```
要修好它！
要修static pod的yaml，看有沒有問題，此時知道path很重要，我忘了！
`cat /etc/kubernetes/manifests/kube-controller-manager.yaml`
一眼看不出來，丟給ai，是指令錯了！
```yaml
command:
- kube-controller-manegaar    # ⚠️ 打錯字
```

這題也花了20分鐘，但其實關鍵只有一個！
而且想想，其實static pod，絕對都是錯在指令，尤其是第一行

---

3⭐️20
https://killercoda.com/sachin/course/CKA/cronjob-issue
cronjob題

監控svc的cronjob不wrok，於是先看一下svc，還有endpoints，發現沒有後者
```bash
root@controlplane:~$ k get endpoints
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME          ENDPOINTS         AGE
cka-service   <none>            2m13s
kubernetes    172.30.1.2:6443   2d6h
```
表示svc沒有正確導流，通常是 selector 沒有對到 pod label
看一下pod
```bash
root@controlplane:~$ k get po
NAME                         READY   STATUS    RESTARTS      AGE
cka-cronjob-29746202-x5xbr   0/1     Error     4 (97s ago)   2m22s
cka-cronjob-29746203-zt8ds   0/1     Error     4 (44s ago)   82s
cka-cronjob-29746204-5ffds   0/1     Error     2 (21s ago)   22s
cka-pod                      1/1     Running   0             3m20s
```
結果是pod本身根本沒有labels！
來人，上labels——但要先看svc選的是啥
```yaml
    selector:
      app: cka-pod
```

好，指令怎麼下？
```bash
root@controlplane:~$ k label po cka-pod app=cka-pod
pod/cka-pod labeled
```
labels貼上應該會立刻生效，因為這不是pod spec

結果還沒完！
```bash
NAME                         READY   STATUS             RESTARTS        AGE
cka-cronjob-29746204-5ffds   0/1     CrashLoopBackOff   5 (2m ago)      4m54s
cka-cronjob-29746205-xvs9f   0/1     Error              5 (2m16s ago)   3m54s
cka-cronjob-29746206-j9mbc   0/1     CrashLoopBackOff   4 (80s ago)     2m54s
cka-cronjob-29746207-956b6   0/1     Error              4 (77s ago)     114s
cka-cronjob-29746208-m9tsr   0/1     Error              3 (39s ago)     54s
cka-pod                      1/1     Running            0               7m52s
```
這裡要有想法⭐️——看這些pod的失敗原因是什麼
這是一開始就要做的事了⭐️筆記都有寫debug順序
```bash
root@controlplane:~$ k logs cka-cronjob-29746212-6tkts
curl: (6) Could not resolve host: cka-pod
```
再搭上這個就懂了！
```bash
root@controlplane:~$ k get svc
NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
cka-service   ClusterIP   10.98.163.77   <none>        80/TCP    13m
kubernetes    ClusterIP   10.96.0.1      <none>        443/TCP   2d7h
```
應該是cka-service！
cka-cronjob 裡 curl 指令**應該打 service 名稱（cka-service）**，不是 pod 名稱（cka-pod）。
```yaml
spec:
  concurrencyPolicy: Allow
  failedJobsHistoryLimit: 1
  jobTemplate:
    metadata: {}
    spec:
      template:
        metadata: {}
        spec:
          containers:
          - command:
            - curl
            - cka-pod # 錯誤！
```
結果還沒完！
```bash
root@controlplane:~$ k get po
NAME                         READY   STATUS             RESTARTS        AGE
cka-cronjob-29746214-fx5sq   0/1     CrashLoopBackOff   5 (2m39s ago)   5m43s
cka-cronjob-29746215-fz645   0/1     CrashLoopBackOff   5 (103s ago)    4m43s
cka-cronjob-29746216-7nbvj   0/1     Error              5 (2m1s ago)    3m43s
cka-cronjob-29746217-nql76   0/1     Error              4 (2m6s ago)    2m43s
cka-cronjob-29746218-s4jfj   0/1     Completed          0               103s
cka-cronjob-29746219-64ltl   0/1     Completed          0               43s
cka-pod                      1/1     Running            0               18m
```
還是not ready，只是變成Completed
只好再看最新的一批pod的logs
結果應該是對的，not ready只是執行完畢，pod已經關了，關掉變成Completed
驗證器沒通過可能是還有失敗的，我來主動砍掉

我想到了，這題最終無法驗過，是因**為cron的時間語法**，不管了

---

4○7
https://killercoda.com/sachin/course/CKA/deployment-issue
fix deploy yaml，我感覺這應該比較容易

起手式一定要先apply，看錯誤
結果可以create，那就要看錯在哪了
```bash
root@controlplane:~$ k get po
NAME                                  READY   STATUS                       RESTARTS   AGE
postgres-deployment-6d5b9f49c-pv7xm   0/1     CreateContainerConfigError   0          20s
```
應該是和環境變數有關
先describe pod，發現
```bash
tgres-container}: Error: secret "postgres-secrte" not found
```
secrte，拼錯了
```bash
root@controlplane:~$ k get secrets -o yaml
apiVersion: v1
items:
- apiVersion: v1
  data:
    password: ZGJwYXNzd29yZAo=
    username: ZGJ1c2VyCg==
  kind: Secret
(略)
    name: postgres-secret  # 重點
    namespace: default
    resourceVersion: "5226"
```

修完後，新pod錯誤是：
`Error: couldn't find key db_user in Secret default/postgres-secret`
顯然是`username`和`password`
再修，就ok了

---

5⭐️10
https://killercoda.com/sachin/course/CKA/deployment-issue-1
一樣，修deploy，但不是yaml，是物件

```bash
root@controlplane:~$ k get po
NAME                                READY   STATUS     RESTARTS   AGE
nginx-deployment-776565b456-942lq   0/1     Init:0/1   0          81s
root@controlplane:~$ k get deployments.apps
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   0/1     1            0           93s
```
重點錯誤：`Init:0/1`，再describe pod
`failed for volume "nginx-config" : configmap "nginx-configuration" not found`
乍看有點難懂：
```yaml
      volumes:
      - configMap:
          defaultMode: 420
          name: nginx-configuration
        name: nginx-config
```
其實一個是configMap的名字，一個是volume的名字，這就不難懂了
這裡是cm的名字錯了
重跑還是錯，再看pod，錯誤換成
`error during container init: exec: "shell": executable file not found in $PATH`
command有錯
```yaml
      - command:
        - sh
        - echo 'Welcome To KillerCoda!'
```
這樣改是不夠的，⭐️因為少了`-c`！！！！

---

6○2
https://killercoda.com/sachin/course/CKA/deployment-issue-2
一樣，改deploy yaml

先是ns不存在，這個簡單，先create
只有這樣而已，done

---

7○3
https://killercoda.com/sachin/course/CKA/deployment-issue-3
一樣deploy，這次是物件

`CreateContainerConfigError`
其中有Config字樣，我好像不太熟悉，只能先describe
只有一個po的時候，就不必複製po名稱了
`Error: configmap "postgres-db-config" not found`
正確：postgres-config

k edit時，留意了secret，出去看了一下，也是錯的，再改
這題算很簡單

---

8⭐️6
https://killercoda.com/sachin/course/CKA/deployment-issue-4
一樣，物件

get po是pending，那不是pvc就是親和，結果是前者
`  Warning  FailedScheduling  52s   default-scheduler  0/2 nodes are available: persistentvolumeclaim "postgres-db-pvc" not found. not found`
```bash
root@controlplane:~$ k get pvc
NAME           STATUS    VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
postgres-pvc   Pending   postgres-pv   0                         standard       <unset>                 102s
```
這時要改deploy，而不是pvc的名稱！

改完還是pending，因為沒有bound！
`pod has unbound immediate PersistentVolumeClaims. not found`
這下就要改pvc了

兩個地方要改，access mode還有空間要縮小
好像要砍掉pvc才行，要先輸出！不然就gg了
apply後先看有沒有bound，最好等5秒再看，不會立刻bound
成功了！再看deploy的po

---

9○5
https://killercoda.com/sachin/course/CKA/deployment-rollout-resume
這題比較特別，沒有up to date
```bash
root@controlplane:~$ k get deployments.apps
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
stream-deployment   0/0     0            0           47s
```

沒頭緒，先des一下deploy，可發現
```bash
Replicas:               0 desired | 0 updated | 0 total | 0 available | 0 unavailable
```
k edit發現`  replicas: 0`
結果改1似乎就ok了
關鍵是切入點！怎麼切入，怎麼觀察
這題並沒有很快解決

---

10⭐️10
https://killercoda.com/sachin/course/CKA/ds-issue
daemonSet！

cp沒建pod，一定是被taint擋了，要幫在pod template中加tolerations
這肯定要查文件了，那個很難寫耶
但要先查cp的taint長啥樣

```bash
root@controlplane:~$ k get no controlplane -o yaml
apiVersion: v1
kind: Node
(略)
spec:
  podCIDR: 192.168.0.0/24
  podCIDRs:
  - 192.168.0.0/24
  taints:  # 這裡
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
```
再來就是要怎麼查文件，我就查"taint"就好
就有怎麼寫的說明了
🐱：其實親和比較複雜，t&t是比較單純的，文件如下：
```yaml
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"

# 第二種
tolerations:
- key: "key1"
  operator: "Exists"
  effect: "NoSchedule"
```

選了第一個，結果再回去看，這個taint沒有value！
所以應該要用第二個，可惡
DONE！

---

11⭐️13
https://killercoda.com/sachin/course/CKA/etcd-backup-issue
純etcd備份題，又要考驗你的grep大法還有參數一對一能力xd
而且又要輸出成文件，一定要`&>`且不要忘記只有一次機會
🐱：不是純備份題，而是要先處理kubelet不正常

你熟悉的`k get -n kube-system po etcd-controlplane  -o yaml | grep -- '--'`
主要是第二、三、四參數很容易confused
記得，第二個是trust ca file
三、四的檔都是server，它們有對稱關係！

```bash
root@controlplane:~$ etcdctl snapshot save /opt/cluster_backup.db \
> --endpoints=https://172.30.1.2:2379 \
> --cacert=/etc/kubernetes/pki/etcd/ca.crt \
> --key=/etc/kubernetes/pki/etcd/server.key \
> --cert=/etc/kubernetes/pki/etcd/server.crt &> backup.txt
```

結果沒過，理由是：
> The **kubelet service is currently inactive** on the controlplane node — this is why the node shows NotReady. You'll need to address that first before the etcd backup can proceed successfully.

ai說：
> 這題其實不是備份指令錯，而是 controlplane 節點的 kubelet 沒有啟動，導致 **node 狀態是 NotReady**，etcd 也無法正常備份。⭐️要先把 kubelet service 啟動起來（`systemctl start kubelet`），確認 node 變成 Ready，再執行 etcdctl snapshot save 才會成功。
原來是node，我想說，po明明都正常
```bash
root@controlplane:~$ k get no
NAME           STATUS     ROLES           AGE    VERSION
controlplane   NotReady   control-plane   3d7h   v1.35.1
node01         Ready      <none>          3d7h   v1.35.1
```
還真的！
重新啟動kubelet就過了

---

12○5
https://killercoda.com/sachin/course/CKA/kubectl-issue
修kubectl的config檔，這題比較簡單是port有錯，寫成644333
修完後，你再打，就有了
因為每一次使用k指令都會讀檔

---

13○
https://killercoda.com/sachin/course/CKA/kubelet-issue
要很了解kubelet的連線機制，先略過

---

14○
