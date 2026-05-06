variable "project_id" {
  description = "GCP project ID for the free-tier VM exercise."
  type        = string
}

variable "region" {
  description = "Free Tier eligible region for the VM."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "Zone under the selected region."
  type        = string
  default     = "us-east1-b"
}

variable "instance_name" {
  description = "Name of the VM instance."
  type        = string
  default     = "free-tier-vm"
}

variable "machine_type" {
  description = "Machine type for the free-tier VM."
  type        = string
  default     = "e2-micro"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB, kept inside the free-tier boundary."
  type        = number
  default     = 25
}

variable "boot_disk_type" {
  description = "Boot disk type for the VM."
  type        = string
  default     = "pd-standard"
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