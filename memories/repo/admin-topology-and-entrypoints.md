# Admin Topology And Entry Points

- Infra 拓撲已確認為：1 台 bastion / data VM、1 台 K3s control-plane、2 台 K3s workers、1 台 Hetzner LB。
- bastion 不是 K8s node；它同時承載 PostgreSQL、Redis、weamind-data 與管理入口角色。
- 本機 laptop 可操作 cluster。
- bastion 已安裝 `kubectl` 並持有可用 `kubeconfig`，可作為正式 admin host。
- control-plane 也可本地執行 `kubectl`，但較好的敘事是把 bastion 視為主要遠端管理入口，而不是把 node 當主要入口。
- 目前已知 bastion 是 ARM；K3s cluster nodes 是 x86。談到 `kubectl` binary、tooling binary 或 container image 時要注意架構相容性。
- SSH 主要是用於登入 bastion / control-plane 與搬運設定；`kubectl` 的核心連線對象仍是 `kubeconfig` 指向的 Kubernetes API server。