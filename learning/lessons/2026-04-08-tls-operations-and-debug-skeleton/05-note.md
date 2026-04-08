# 2026-04-08 TLS Operations and Debug Skeleton Note

## 學習注意事項

- 今天主題聚焦在 WeaMind 目前的 TLS 接法、cert-manager 資源鏈與最小排查順序。
- 今天不展開完整 PKI、CA 信任鏈、openssl 細節，也不把焦點擴成所有 Traefik 進階設定。
- 若中途出現和今天主線無關的延伸問題，先記在這裡，不讓 QA 或 command drill 膨脹。

## Notes

### Kubernetes 為什麼可以有 `Certificate` 這種物件？

- 可以。Kubernetes 本身就允許擴充 API，不是只能用內建的 `Pod`、`Service`、`Deployment` 這些資源。
- 內建資源是 Kubernetes 核心 API 已經定義好的物件；像 cert-manager 這類擴充元件，則可以透過 CRD（CustomResourceDefinition）把新的資源型別註冊進叢集，例如 `Certificate`、`CertificateRequest`、`Order`、`Challenge`。
- 一旦 CRD 被安裝完成，這些物件對 Kubernetes 來說就會變成「叢集認得的 API 資源」。所以你才能用 `kubectl get certificate`、`kubectl get certificaterequest` 這類指令去查它們。
- 這些物件和 Kubernetes 內建物件的差別，不在於「是不是合法資源」；差別在於 **誰定義它的 schema，誰負責實作控制邏輯**。內建物件由 Kubernetes 核心專案定義與實作；`Certificate` 這類 CRD 物件則由 cert-manager 定義 schema，再由 cert-manager controller 負責 watching 與 reconcile。
- 可以把它想成兩層：Kubernetes 提供可擴充的 API 平台與控制器模型；cert-manager 則是在這個平台上額外加了一組「憑證領域」專用資源與 controller。
- 所以更精準的說法是：Kubernetes 確實先定義了一批核心物件，但也允許你追加自訂物件；前提是你要先把對應的 CRD 與 controller 安裝進叢集。沒有 controller，物件通常只會「存在」，但不會真的產生有意義的行為。

## Flashcards

<!-- 待補 -->
