# Terraform 裡哪些是固定骨架，哪些是可自訂值？

這份文件用 W9 的 GCP Free Tier VM 練習做例子，整理一件很容易卡住的事：

Terraform 檔案裡看起來全部都像「名字」，但其實有些是 Terraform / provider 規定的骨架，有些才是你自己可以改的值。

若這件事沒分清楚，就很容易一邊看 HCL，一邊不知道哪些字不能動、哪些字能換。

## 先說結論

可以先把 Terraform 裡的東西分成三類：

1. 固定骨架：Terraform 或 provider schema 規定的語法、資源種類、欄位名、block 名。
2. 可自訂值：你自己命名的本地資源名、tag 字串、instance name、disk size 這類值。
3. 可改但受 API 限制的值：例如 `e2-micro`、`pd-standard`、`STANDARD`、zone、image family。這些不是欄位名，但也不是你想寫什麼都行。

一句話口訣：

**左邊多半是骨架；右邊多半是值。右邊再分成自由值與 API 限制值。**

---

## 用 `resource` 這一行做第一個判斷

以這行為例：

```tf
resource "google_compute_firewall" "allow_https" {
```

可以拆成三段看：

### 1. `resource`

- 這是 Terraform 關鍵字。
- 固定骨架，不能改成別的字。

### 2. `google_compute_firewall`

- 這是 Google provider 定義的資源種類。
- 固定骨架，不能自己發明新名字。
- 它的意思是：「我要宣告一個 GCP firewall 規則」。

### 3. `allow_https`

- 這是你在這份 Terraform 設定裡替這個資源取的本地名字。
- 這個可以自訂。
- 它的作用不是告訴 GCP 雲端要叫什麼，而是讓你在這份 Terraform 裡引用它時有個名字。

例如後面若要引用它，會寫成：

```tf
google_compute_firewall.allow_https.name
```

這個結構的意思是：

- `google_compute_firewall`：資源種類
- `allow_https`：本地名字
- `name`：該資源的一個欄位

---

## 用 VM resource 看「左邊固定、右邊是值」

以這段為例：

```tf
name         = var.instance_name
machine_type = var.machine_type
zone         = var.zone
tags         = local.instance_tags
```

### 左邊：固定骨架

- `name`
- `machine_type`
- `zone`
- `tags`

這些都是 provider schema 定義的欄位名，不能亂改。

### 右邊：值來源

- `var.instance_name`
- `var.machine_type`
- `var.zone`
- `local.instance_tags`

這些是值來源，所以通常才是你會調整的地方。

但右邊也要再分兩種：

### 完全可自訂的值

- `instance_name`
- tags 字串，例如 `free-tier-vm`、`allow-http`

### 可改但受 API 限制的值

- `machine_type` 最後不能亂填，必須是 GCP 接受的機型，例如 `e2-micro`
- `zone` 也不能亂寫，必須是合法 zone，例如 `us-east1-b`

所以這裡的重點不是「右邊都能亂改」，而是：

**右邊通常是可調區，但有些值仍要符合雲端 API 的合法選項。**

---

## block 名和欄位名也是固定的

以這段為例：

```tf
boot_disk {
  initialize_params {
    image = "projects/${var.image_project}/global/images/family/${var.image_family}"
    size  = var.boot_disk_size_gb
    type  = var.boot_disk_type
  }
}
```

這裡固定的有：

- `boot_disk`
- `initialize_params`
- `image`
- `size`
- `type`

這些都屬於 provider schema 決定的 block / 欄位名。

可以調整的則是右邊值：

- `var.image_project`
- `var.image_family`
- `var.boot_disk_size_gb`
- `var.boot_disk_type`

但限制程度不同：

- `boot_disk_size_gb` 幾乎是自由值
- `boot_disk_type` 則必須是合法 disk type，例如 `pd-standard`
- `image_project`、`image_family` 也不是亂填，而是要對到 GCP 上存在的 image 資訊

---

## 有些字串不是欄位名，但也不是自由命名

例如這些值：

- `e2-micro`
- `pd-standard`
- `STANDARD`
- `tcp`

它們都不是欄位名，但也不是自由命名。

更精準地說，它們屬於：

**值本身受 provider / API 合法選項限制。**

所以它們雖然在右邊，但不能改成：

- `cheap-machine`
- `super-hdd`
- `budget-tier`

這類 GCP 不認得的字串。

---

## `locals`、`var`、`resource` 這三種名字要分開看

### `var.xxx`

- 代表變數
- 例如 `var.instance_name`
- `instance_name` 是你自己在 `variables.tf` 定義的變數名，可自訂

### `local.xxx`

- 代表 local value
- 例如 `local.instance_tags`
- `instance_tags` 是你自己在 `locals` 區塊裡取的名字，可自訂

### `resource_type.resource_name`

- 例如 `google_compute_instance.free_tier_vm`
- `google_compute_instance` 是固定的資源種類
- `free_tier_vm` 是你自己替資源取的本地名字，可自訂

所以這三類名字雖然都長得像 `something.xxx`，但來源不一樣：

- `var.xxx`：變數
- `local.xxx`：local value
- `resource_type.resource_name`：資源引用

---

## 用 firewall rule 再看一次

以這段為例：

```tf
resource "google_compute_firewall" "allow_http" {
  name    = "${var.instance_name}-allow-http"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-http"]
}
```

### 固定骨架

- `resource`
- `google_compute_firewall`
- `name`
- `network`
- `allow`
- `protocol`
- `ports`
- `source_ranges`
- `target_tags`

### 可自訂

- `allow_http` 這個本地名字
- `"${var.instance_name}-allow-http"` 這種 resource name 模式
- `"allow-http"` 這個 tag 字串
- `"80"` 這個 port 值

### 可改但受限制

- `var.network_name` 必須指向存在的 network
- `"tcp"` 必須是合法 protocol
- `"0.0.0.0/0"` 必須是合法 CIDR

這裡最常見的誤解是：

以為 `target_tags` 是你自己命名的欄位。

不是。`target_tags` 是固定欄位名；真正自訂的是右邊的 tag 值，例如 `allow-http`。

---

## 最後整理成一張判斷表

| 類型                     | 範例                                                 | 能不能改           | 備註                       |
| ------------------------ | ---------------------------------------------------- | ------------------ | -------------------------- |
| Terraform 關鍵字         | `resource`, `locals`                                 | 不行               | 固定語法                   |
| Provider 資源種類        | `google_compute_instance`, `google_compute_firewall` | 不行               | provider schema 決定       |
| Schema 欄位名 / block 名 | `machine_type`, `boot_disk`, `target_tags`           | 不行               | provider schema 決定       |
| 本地資源名               | `free_tier_vm`, `allow_http`                         | 可以               | Terraform 內部引用名       |
| 變數名 / local 名        | `instance_name`, `instance_tags`                     | 可以               | 你自己定義                 |
| 自由值                   | `free-tier-vm`, `allow-http`, `25`                   | 可以               | 視命名規則而定             |
| API 限制值               | `e2-micro`, `pd-standard`, `STANDARD`                | 可以改，但不能亂改 | 必須是合法枚舉或合法資源值 |

## 一句話收斂

Terraform 最容易卡的，不是語法很難，而是沒有先分清楚：

**哪些字是骨架、哪些字是值；而值裡又哪些是自由命名、哪些受 API 限制。**

只要這一層先分清楚，之後讀任何 provider 的 resource block 都會快很多。
