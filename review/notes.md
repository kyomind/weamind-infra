# Lesson 複習筆記

## Endpoints 是怎麼產生與動態更新的？

Endpoints 可以理解成「某個 Service 在執行期實際可以導流到哪些後端 Pod IP / port」。在 WeaMind 這個 repo 裡，`weamind-line-bot` Service 不是手動指定 Pod IP，而是靠 `manifests/service.yaml` 裡的 selector：

```yaml
selector:
  app: weamind
```

這個 selector 會去對 `manifests/deployment.yaml` 建出來的 Pod label：

```yaml
labels:
  app: weamind
```

當 Service selector 選到符合 label 的 Pod，而且 Pod 已經進入**可接流量**的狀態時，**Kubernetes 會把這些 Pod 的 IP 和目標 port 整理成 Service 對應的 Endpoints**。對 WeaMind 來說，就是把 `weamind-line-bot:80` 對到後端 Pod 的 `8000`。

⭐️它是**動態更新**的，不是固定寫死。當 Deployment 建新 Pod、舊 Pod 被刪除、Pod IP 改變、**Pod readiness 狀態改變**，或 Service **selector 被修改**時，Kubernetes **控制器**會重新計算這個 Service 後面有哪些可用後端。現在 Kubernetes 內部更主要使用 EndpointSlice，但 `kubectl get endpoints weamind-line-bot -n weamind` 仍然是很直覺的觀察點。

Endpoints 會是空的，通常代表 `Service -> Pod` 這一段還沒有成立。第一輪先查：

- Service selector 是否真的對得到 Pod label：`app: weamind` 對 `app: weamind`
- Pod 是否存在，而且是否 Running / Ready
- Deployment 是否成功建立 Pod，例如 image pull、排程、啟動或 readiness probe 是否失敗
- namespace 是否查對，這裡應該是 `weamind`

所以面試時可以收斂成：Service 是穩定入口，Endpoints 是 Kubernetes 根據 Service selector、Pod label 和 Pod readiness 動態整理出的後端清單；如果 Endpoints 是空的，我會先對照 Service selector 和 Deployment 的 Pod labels，再看 Pod 是否 Ready，而不是先跳去查 PostgreSQL 或 Redis。

## Service 是否有自己的內部 DNS 和 Port？

這個理解大方向是合理的，但可以修得更精準：Service 是 Kubernetes 裡一個獨立資源，它會提供一個穩定的 cluster 內入口；這個入口通常包含穩定的 Service name / DNS 名稱、ClusterIP，以及 Service port。

在 WeaMind 裡，`weamind-line-bot` Service 宣告在 `weamind` namespace，因此叢集內可以用類似 `weamind-line-bot` 或完整一點的 `weamind-line-bot.weamind.svc.cluster.local` 來解析它。這個 DNS 名稱不是在 YAML 裡另外手寫一個 `dns` 欄位，而是 Kubernetes/CoreDNS 根據 Service 的 `metadata.name` 和 `metadata.namespace` 自動提供。

真正需要在 Service spec 裡明確宣告的是 selector 與 ports。例如這個 repo 裡的 Service 宣告：

```yaml
selector:
  app: weamind
ports:
  - name: http
    port: 80
    targetPort: 8000
```

這代表：打到 `weamind-line-bot:80` 的 cluster 內流量，會被 Service 導向符合 `app: weamind` 的 Pod，並轉到 Pod 的 `8000` port。

所以比較準確的說法是：Service 一旦被建立，就會**因為自己的 name / namespace 取得 cluster 內 DNS 名稱**；而 Service port、targetPort、selector 則是我們在 manifest 裡明確宣告的路由規則。不是「DNS 和 port 兩者都要手動聲明才算 Service」，而是「建立 Service 並宣告 port/selector 後，Kubernetes 會自動提供對應的 cluster 內 DNS 入口」。

## Service metadata.name 如何影響內部 DNS？

`metadata.name` 不是一個專門的 DNS 欄位，但它會成為 Kubernetes Service 內部 DNS 名稱的核心部分。

以 WeaMind 來說，Service manifest 裡宣告：

```yaml
metadata:
  name: weamind-line-bot
  namespace: weamind
```

因此在同一個 namespace 裡，Pod 通常**可以直接用短名 `weamind-line-bot` 連到**這個 Service；若要寫完整一點，可以是：

```bash
weamind-line-bot.weamind.svc.cluster.local
```

這個完整名稱可以拆成：⭐️

```bash
<service-name>.<namespace>.svc.cluster.local
```

⭐️⭐️⭐️
所以 `metadata.name: weamind-line-bot` **會影響 DNS 的第一段**，也就是 Service name；`metadata.namespace: weamind` 會影響第二段。這就是為什麼 Ingress backend 可以寫 `name: weamind-line-bot`，⭐️而**叢集內(任一 node)測試時**也可以打 `http://weamind-line-bot/health`：它們都在指向同一個 Service 入口。

比較精準的講法是：我們沒有在 Service 裡另外宣告 DNS 記錄，但我們宣告了 Service 的 name 和 namespace；Kubernetes/CoreDNS 會**根據這兩個值產生可解析的 cluster 內 DNS 名稱**。
