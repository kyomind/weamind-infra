locals {
  instance_tags = ["e2-micro-tw", "allow-http", "allow-https", "allow-ssh"]
}

# Cost-sensitive fields: Taiwan region, e2-micro, balanced disk size/type, and network tier.
resource "google_compute_instance" "e2_micro_tw" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = local.instance_tags

  metadata = {
    ssh-keys = "${var.ssh_username}:${trimspace(file(var.ssh_public_key_path))}"
  }

  boot_disk {
    initialize_params {
      image = "projects/${var.image_project}/global/images/family/${var.image_family}"
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network = var.network_name

    access_config {
      network_tier = "STANDARD"
    }
  }
}

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
