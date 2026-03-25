# 2026-03-11 K3s Traffic Path And Node IP Debug Notes

## 1. Traefik 對外入口怎麼形成？

- Traefik 在這個專案裡的實際對外入口怎麼形成，正式 repo 文件目前只穩定寫到 Hetzner LB 會把外部流量送進 Traefik。
- 正式 repo 文件目前只穩定寫到：外部流量由 Hetzner LB 進到 Traefik。
- 歷史對話可補到更細的實作脈絡：Traefik service 曾出現 `80:30417`、`443:31051` 這類對外入口，且曾看到 `svclb-traefik` Pods，表示 K3s ServiceLB 參與了入口建立。
- 因此回答時可說 Traefik 前面有節點入口，但不要先把它過度簡化成「每個 worker 各一個 Traefik Pod」。

## 2. Traefik Service Type 到底是哪一種？

- 如果問題是指 Traefik 這個 service，單靠目前正式 repo 文件無法直接下定論，因為 repo 內沒有直接管理 Traefik service 的 YAML。
- 但從歷史對話可判斷，當時 `kubectl get svc -n kube-system traefik -o wide` 的結果是 `LoadBalancer`，而且顯示 `80:30417/TCP,443:31051/TCP`。
- 這代表比較精準的說法是：Traefik service 在當時是 `LoadBalancer` type，但底層同時透過 K3s ServiceLB / NodePort 機制把入口開到節點上。
- 所以回答時不要簡化成「它就是 NodePort」；更準確是「K3s 裡看到的 Traefik service type 是 LoadBalancer，但會伴隨節點入口與 NodePort 類行為」。
