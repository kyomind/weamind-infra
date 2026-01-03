# GitHub Container Registry (ghcr.io) 設定指南

本文件說明如何使用 GitHub Container Registry 來託管 Docker Image，用於 Kubernetes 部署。

---

## 為什麼使用 ghcr.io？

- ✅ **完全免費**：Public images 無限儲存與流量
- ✅ **整合 GitHub**：與代碼 repo 同位置管理
- ✅ **零阻力部署**：Public repo → Public image → K8s 無需認證拉取
- ✅ **業界標準**：展現 CI/CD 思維

---

## WeaMind 專案配置（最簡單路徑）

| 項目          | 狀態     | 需要額外設定 |
| ------------- | -------- | ------------ |
| GitHub Repo   | 公開     | 無           |
| ghcr.io Image | 公開     | 無           |
| K8s 拉取      | 無需認證 | 無           |

**總設定時間：約 20-30 分鐘**

---

## 設定步驟

### 步驟 1：生成 GitHub Personal Access Token（3 分鐘）

1. 登入 GitHub → Settings → Developer settings
2. Personal access tokens → Tokens (classic) → Generate new token (classic)
3. 勾選權限：
   - `write:packages`
   - `read:packages`
   - `delete:packages`（選用）
4. Generate token，**立即複製並安全保存**

---

### 步驟 2：本地 Docker 登入（1 分鐘）

```bash
# 設定環境變數（建議加入 ~/.zshrc 或 ~/.bashrc）
export GITHUB_TOKEN=<your_github_token>

# 登入 ghcr.io
echo $GITHUB_TOKEN | docker login ghcr.io -u <your_github_username> --password-stdin
```

**範例**：
```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
echo $GITHUB_TOKEN | docker login ghcr.io -u kyomind --password-stdin
```

成功會看到：`Login Succeeded`

---

### 步驟 3：構建 Docker Image（5-10 分鐘）

```bash
# 切換到應用程式目錄
cd /path/to/your/app

# 構建 image（使用 ghcr.io 命名規範）
docker build -t ghcr.io/<username>/<image-name>:<tag> .
```

**範例**：
```bash
cd ~/Code/weamind
docker build -t ghcr.io/kyomind/weamind-line-bot:latest .
```

**Image 命名規範**：
- `ghcr.io/<github_username>/<image_name>:<tag>`
- tag 範例：`latest`, `v1.0.0`, `dev`, `prod`

---

### 步驟 4：推送 Image（5-10 分鐘）

```bash
docker push ghcr.io/<username>/<image-name>:<tag>
```

**範例**：
```bash
docker push ghcr.io/kyomind/weamind-line-bot:latest
```

推送成功後，可在 GitHub 個人頁面看到 Packages 區塊。

---

### 步驟 5：設定 Image 為 Public（推薦）

1. 前往 GitHub → Packages → 點擊剛推送的 image
2. Package settings → Change visibility → **Public**
3. 確認變更

**完成後**：
- ✅ K8s 可直接拉取，無需任何認證配置
- ✅ Deployment YAML 只需指定 image 路徑即可
- ✅ 零額外步驟，最簡單路徑

```yaml
# Deployment 範例（無需 imagePullSecrets）
spec:
  containers:
  - name: line-bot
    image: ghcr.io/kyomind/weamind-line-bot:latest
```

---

## 進階：Private Image 配置（可選）

<details>
<summary>如果需要使用 Private Image（展開查看）</summary>

### 步驟 6：K8s 配置 imagePullSecret

#### 6.1 建立 Secret

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<your_github_username> \
  --docker-password=$GITHUB_TOKEN \
  --namespace=<your_namespace>
```

**範例**：
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=kyomind \
  --docker-password=$GITHUB_TOKEN \
  --namespace=weamind
```

#### 6.2 Deployment 引用 Secret

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: line-bot
  namespace: weamind
spec:
  template:
    spec:
      imagePullSecrets:
      - name: ghcr-secret  # 引用剛建立的 secret
      containers:
      - name: line-bot
        image: ghcr.io/kyomind/weamind-line-bot:latest
```

</details>

---

## 驗證 Image 可拉取

### 本地驗證

```bash
# 刪除本地 image
docker rmi ghcr.io/<username>/<image-name>:<tag>

# 從 ghcr.io 拉取
docker pull ghcr.io/<username>/<image-name>:<tag>

# 執行測試
docker run -p 8000:8000 ghcr.io/<username>/<image-name>:<tag>
```

### K8s 驗證

```bash
# 建立測試 Pod
kubectl run test-pod --image=ghcr.io/<username>/<image-name>:<tag> -n <namespace>

# 查看 Pod 狀態
kubectl get pods -n <namespace>

# 如果出現 ImagePullBackOff，檢查日誌
kubectl describe pod test-pod -n <namespace>

# 清理
kubectl delete pod test-pod -n <namespace>
```

---

## 常見問題

### Q1: `unauthorized: authentication required`

**原因**：Image 是 private，但未配置 imagePullSecret

**解決**：
1. 設定 image 為 public（最簡單）
2. 或按步驟 6 配置 imagePullSecret

---

### Q2: `denied: installation not allowed to Write organization package`

**原因**：組織權限不足

**解決**：
- 使用個人帳號而非組織
- 或調整組織設定允許 package 寫入

---

### Q3: 如何更新 Image？

```bash
# 重新構建
docker build -t ghcr.io/<username>/<image-name>:v1.0.1 .

# 推送新版本
docker push ghcr.io/<username>/<image-name>:v1.0.1

# 更新 K8s Deployment
kubectl set image deployment/<deployment-name> \
  <container-name>=ghcr.io/<username>/<image-name>:v1.0.1 \
  -n <namespace>
```

---

### Q4: 如何刪除舊 Image？

```bash
# GitHub Packages 頁面手動刪除
# 或使用 GitHub CLI
gh api -X DELETE /user/packages/container/<image-name>/versions/<version-id>
```

---

## CI/CD 自動化（進階）

### GitHub Actions 範例

```yaml
# .github/workflows/build-and-push.yml
name: Build and Push Docker Image

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      packages: write
      contents: read

    steps:
      - uses: actions/checkout@v3

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:latest
```

---

## 安全建議

1. **Token 安全**：
   - 不要將 token 提交到 Git
   - 使用環境變數或密鑰管理工具
   - 定期輪換 token

2. **Image 掃描**：
   - 使用 `docker scan` 檢查漏洞
   - GitHub 自動掃描 public images

3. **版本管理**：
   - 避免只用 `latest` tag
   - 使用語義化版本（`v1.0.0`）
   - 保留多個版本以便回滾

---

## 參考資源

- [GitHub Packages 官方文件](https://docs.github.com/en/packages)
- [Working with the Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Login 文件](https://docs.docker.com/engine/reference/commandline/login/)

---

**最後更新**：2026-01-03
**適用專案**：WeaMind K8s 部署
