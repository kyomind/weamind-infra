# 2026-04-01 LB Health Check Skeleton Outline

## 今日主題

把 WeaMind 的 Hetzner LB 設計、Health Check 踩坑與 TCP passthrough / TLS termination 分工，收斂成可以口頭講清楚的專案骨架。

## 這次要解的專案問題

1. 為什麼 Hetzner LB 後端只放 worker，而不是把 control-plane 一起放進去。
2. 為什麼 LB 的 HTTP health check 不能只打 `/health`，還必須帶正確的 Host header。
3. 在 WeaMind 架構裡，TCP passthrough 跟 HTTP termination / TLS termination 分別落在哪一層。
4. 如果未來又看到 LB target 變成 unhealthy，第一輪應該如何拆解成 Ingress 規則、Host header、節點角色與流量分工問題。

## 這份 lesson 是否需要外部預習

- 不需要。
- 原因：這個主題已經有足夠的 repo 證據可直接對照，包括 `README.md` 的架構圖、`PROGRESS.md` 的 LB health check debug story、`manifests/ingress.yaml` 的 host-based routing，以及 `manifests/deployment.yaml` 的 worker 排程設定。今天重點是把專案設計與 incident 講清楚，不是補新的通用概念骨架。

## 要對照的 repo 檔案

1. `README.md`
2. `PROGRESS.md`
3. `manifests/deployment.yaml`
4. `manifests/ingress.yaml`
5. `docs/WeaMind Infra核心架構.md`

## 建議學習順序

1. 先用 `README.md` 與 `docs/WeaMind Infra核心架構.md` 對齊今天的流量骨架：LINE → LB → Traefik → Service → Pods。
2. 再看 `manifests/deployment.yaml`，回答為什麼這個專案要把 app Pod 固定排到 worker，進一步接到「LB 後端為什麼只放 worker」。
3. 接著回到 `manifests/ingress.yaml` 與 `PROGRESS.md`，把 host-based routing 與 health check 404 的因果鏈接起來。
4. 然後收斂 Hetzner LB、Traefik、Ingress、Service 之間的邊界，講清楚 TCP passthrough 與 TLS termination 的落點。
5. QA 後用 `03-command.md` 做最小 command drill，驗證 host header 假設與 worker 排程證據。
6. 若今天直接動到真實叢集設定，額外用 `06-implementation.md` 記錄「要改什麼、怎麼改、改完看到什麼、目前結論是什麼」。
7. 若實作過程中累積了值得獨立複習的觀察，再用 `07-implementation-note.md` 承接實作專屬的補充 note。
8. 最後回 `04-report.md`，收斂成可口述的短版答題骨架。

## 今日 command 練習

今天建立 `03-command.md`。

原因：這個主題很適合用最小操作把兩個容易混淆的點拆開來看，一個是「Health Check 為什麼未帶 Host header 會失敗」，另一個是「worker-only 後端」到底只是口號，還是有 Deployment / node label / Pod 落點證據可對回。流程仍維持 `QA -> command -> report`。

## 文件分工

1. `01-outline.md`：規劃今天主題、順序與邊界。
2. `02-qa.md`：記錄今天的 repo-backed 問題、使用者回答摘要與 AI 修正。
3. `03-command.md`：記錄今天的最小 command drill，重點放在 Host header 與 worker 排程證據。
4. `04-report.md`：收斂今天真正學到的 LB / health check 骨架。
5. `05-note.md`：記錄延伸補充、暫時結論與後續可接到 image pipeline / TLS lesson 的邊界。
6. `06-implementation.md`：當 lesson 內需要真的修改 cluster 設定時，記錄每一輪實作的目標、操作、結果與判讀。
7. `07-implementation-note.md`：承接實作過程中值得保留、但不適合塞回 `05-note.md` 的實作專屬補充理解。

## 這次要追問的 Why / How 題

1. 為什麼 control-plane 雖然也是節點，但不該當成 LB 的正常流量後端。
2. 為什麼 `/health` 本身沒有問題，卻會因為沒帶 Host header 而在 Ingress 層回 `404`。
3. 為什麼 WeaMind 要讓 Hetzner LB 做 TCP passthrough，而不是直接在 LB 終止 TLS。
4. 如果別人只說「LB 壞掉了」，你要怎麼把問題拆成節點、Ingress、Host routing、TLS 終止位置四層來排查。

## 這份 lesson 的完成標準

1. 能說出為什麼 WeaMind 的 Hetzner LB 後端只放 worker，而不是 control-plane + worker 全放。
2. 能用 `ingress.yaml` 與 `PROGRESS.md` 的 incident 證據，解釋 Health Check 為什麼需要正確的 Host header。
3. 能用 WeaMind 架構講清楚 Hetzner LB 的 TCP passthrough 與 Traefik 的 TLS termination 分工。
4. 能用 3 到 5 句話口述今天的最小答題稿，不把後續 cert-manager 細節混進來。
