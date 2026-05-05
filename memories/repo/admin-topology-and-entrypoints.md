# Admin Topology And Entry Points

- Infra 拓撲已確認為：1 台 bastion / data VM、1 台 K3s control-plane、2 台 K3s workers、1 台 Hetzner LB。
- 固定主機角色已確認：bastion 是資料層 VM；另有 1 台 control-plane 與 2 台 workers。
- 四台 VM 透過 Hetzner Private Network 互連，私網 IP 依序為：bastion `10.0.0.2`、control-plane `10.0.0.3`、worker `10.0.0.4`、worker `10.0.0.5`。
- bastion 不是 K8s node；它同時承載 PostgreSQL、Redis、weamind-data 與管理入口角色。
- 本機 laptop 可操作 cluster。
- bastion 已安裝 `kubectl` 並持有可用 `kubeconfig`，可作為正式 admin host。
- control-plane 也可本地執行 `kubectl`，但較好的敘事是把 bastion 視為主要遠端管理入口，而不是把 node 當主要入口。
- 目前已知 bastion 是 ARM；K3s cluster nodes 是 x86。談到 `kubectl` binary、tooling binary 或 container image 時要注意架構相容性。
- SSH 主要是用於登入 bastion / control-plane 與搬運設定；`kubectl` 的核心連線對象仍是 `kubeconfig` 指向的 Kubernetes API server。
- 若本機透過 SSH proxy / 通道間接連 cluster，該通道逾時後 `kubectl` 可能出現 `127.0.0.1:6443 connection refused`；此時應先提醒使用者重新打開通道，再判斷是否為 cluster 資源異常。