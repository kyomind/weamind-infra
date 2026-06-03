variable "project_id" {
  description = "GCP project ID for the Taiwan e2-micro VM exercise."
  type        = string
}

variable "region" {
  description = "Taiwan region for this paid VM exercise."
  type        = string
  default     = "asia-east1"

  validation {
    condition     = var.region == "asia-east1"
    error_message = "This exercise is intentionally pinned to Taiwan region asia-east1."
  }
}

variable "zone" {
  description = "Zone under the selected Taiwan region."
  type        = string
  default     = "asia-east1-b"

  validation {
    condition     = startswith(var.zone, "asia-east1-")
    error_message = "The zone must stay inside Taiwan region asia-east1."
  }
}

variable "instance_name" {
  description = "Name of the VM instance."
  type        = string
  default     = "e2-micro-tw"
}

variable "machine_type" {
  description = "Machine type for the low-cost Taiwan VM."
  type        = string
  default     = "e2-micro"

  validation {
    condition     = var.machine_type == "e2-micro"
    error_message = "This exercise is intentionally limited to e2-micro."
  }
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB, initially kept at 25 GB to leave billing buffer."
  type        = number
  default     = 25

  validation {
    condition     = var.boot_disk_size_gb == 25
    error_message = "The first-month billing observation baseline uses a 25 GB boot disk."
  }
}

variable "boot_disk_type" {
  description = "Boot disk type for the VM."
  type        = string
  default     = "pd-balanced"

  validation {
    condition     = var.boot_disk_type == "pd-balanced"
    error_message = "This exercise intentionally uses pd-balanced to match the chosen console-style boot disk."
  }
}

variable "image_project" {
  description = "Project that hosts the boot image."
  type        = string
  default     = "debian-cloud"
}

variable "image_family" {
  description = "Image family for the boot disk."
  type        = string
  default     = "debian-12"
}

variable "network_name" {
  description = "Network used by the VM."
  type        = string
  default     = "default"
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to SSH into the VM."
  type        = list(string)
}

variable "ssh_username" {
  description = "Linux username used for SSH login via instance metadata."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Absolute path to the SSH public key file used for VM login."
  type        = string
}
