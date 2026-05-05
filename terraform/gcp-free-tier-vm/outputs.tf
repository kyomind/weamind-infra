output "project_id" {
  description = "Project ID used for this exercise."
  value       = var.project_id
}

output "instance_name" {
  description = "Created VM instance name."
  value       = google_compute_instance.free_tier_vm.name
}

output "instance_zone" {
  description = "Zone where the VM is created."
  value       = google_compute_instance.free_tier_vm.zone
}

output "machine_type" {
  description = "Machine type of the VM."
  value       = google_compute_instance.free_tier_vm.machine_type
}

output "external_ip" {
  description = "Ephemeral external IP of the VM."
  value       = google_compute_instance.free_tier_vm.network_interface[0].access_config[0].nat_ip
}