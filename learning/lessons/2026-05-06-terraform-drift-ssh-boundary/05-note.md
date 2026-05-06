# 2026-05-06 Terraform Drift SSH Boundary Note

## 學習注意事項

### 今天的 lesson 邊界

- 今天採 implement-heavy mode，主體放在 `06-implementation.md`，先做 access path，再做邊界收斂，最後才視時間進 drift。
- 今天不把 lesson 擴成新的完整 GCP IAM / IAP / OS Login 設計題，也不展開完整主機初始化流程。
- 若提到 SSH 可達性，必須明確區分「Terraform 保證」和「project / network 既有狀態剛好讓它可用」。
- 若提到改善方向，優先維持 W9 的 20/80 範圍：最小可操作、可講清楚、可回到 repo。

### 今天要刻意記住的口頭模型

- `Terraform` 先負責把基礎設施與 access prerequisite 寫清楚，不等於它必須包辦所有作業系統初始化與服務配置。
- `SSH access` 解的是「人能不能安全地進去機器」；bootstrap / config management 解的是「進去之後怎麼把機器變成可持續運作的服務主機」。
- `state` 與 drift 的價值，不只在於看差異，而在於分辨目前看到的行為到底是 IaC 內的預期、IaC 外的偶然，還是已經偏離預期。

### 今天的實作優先順序

- 先把最小 SSH access path 補明確，並盡量留下一次登入驗證。
- 然後把 access / bootstrap 責任分界講清楚。
- 只有前兩項完成，才做最小 drift 對照。

## Notes

### 暫存區

<!-- lesson 進行中再回填 -->

## Flashcards

<!-- lesson 收尾後再統一生成 -->
