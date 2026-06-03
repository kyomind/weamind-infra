output "project_id" {
  description = "Project ID used for this exercise."
  value       = var.project_id
}

output "instance_name" {
  description = "Created VM instance name."
  value       = google_compute_instance.e2_micro_tw.name
}

output "instance_zone" {
  description = "Zone where the VM is created."
  value       = google_compute_instance.e2_micro_tw.zone
}

output "machine_type" {
  description = "Machine type of the VM."
  value       = google_compute_instance.e2_micro_tw.machine_type
}

output "boot_disk_type" {
  description = "Boot disk type of the VM."
  value       = var.boot_disk_type
}

output "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  value       = var.boot_disk_size_gb
}

output "external_ip" {
  description = "Ephemeral external IP of the VM."
  value       = google_compute_instance.e2_micro_tw.network_interface[0].access_config[0].nat_ip
}
