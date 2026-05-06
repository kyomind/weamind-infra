locals {
  instance_tags = ["free-tier-vm", "allow-http", "allow-https", "allow-ssh"]
}

# Main cost-sensitive fields: machine type, disk type/size, and network tier.
resource "google_compute_instance" "free_tier_vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = local.instance_tags

  metadata = {
    ssh-keys = "${var.ssh_username}:${trimspace(file(var.ssh_public_key_path))}"
  }

  boot_disk {
    initialize_params {
      # Keep the boot disk on standard HDD.
      image = "projects/${var.image_project}/global/images/family/${var.image_family}"
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network = var.network_name

    access_config {
      # Keep the external network tier on STANDARD.
      network_tier = "STANDARD"
    }
  }
}

# Allow inbound HTTP/HTTPS for this VM.
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

resource "google_compute_firewall" "allow_https" {
  name    = "${var.instance_name}-allow-https"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-https"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.instance_name}-allow-ssh"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["allow-ssh"]
}