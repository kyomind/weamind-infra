# ISSUE: SSH Access for Personal Service VM

Date: 2026-05-05

## Background

This Terraform package currently creates a minimum GCP Free Tier VM exercise.

The first working scope is intentionally small:

- one Debian GCE VM
- one ephemeral external IP
- HTTP firewall rule for TCP `80`
- HTTPS firewall rule for TCP `443`
- basic outputs for instance identity and external IP

The current implementation is enough to prove a minimum Terraform workflow:

- `terraform plan`
- `terraform apply`
- post-apply inspection
- `terraform state` reading
- `terraform destroy`

However, the current Terraform spec does not explicitly define SSH access.

## Current Behavior

`main.tf` currently gives the VM these tags:

```hcl
["free-tier-vm", "allow-http", "allow-https"]
```

It also creates only these ingress firewall rules:

- TCP `80` from `0.0.0.0/0`
- TCP `443` from `0.0.0.0/0`

There is no Terraform-managed SSH firewall rule for TCP `22`.

There is also no Terraform-managed SSH key metadata, OS Login metadata, IAP tunnel configuration, or IAM binding related to VM login.

Therefore, applying the current Terraform does not guarantee that the user can SSH into the VM.

## Important Clarification

The VM might still be SSH-accessible in some GCP projects if the project or default network already has pre-existing SSH access configuration, for example:

- a default `default-allow-ssh` firewall rule
- user SSH keys already managed through GCP metadata
- `gcloud compute ssh` being able to add or use keys automatically
- OS Login already enabled at project level

If SSH works under those conditions, it is because of existing project or network state outside this Terraform package.

It should not be treated as a behavior guaranteed by this Terraform code.

## User Context

This VM is intended for personal use and may host an externally reachable service.

Given that context, requiring a fully enterprise-style access pattern from the beginning is too heavy. The user needs a practical path that allows SSH-based operation while still avoiding the most obvious unsafe default.

The useful target is not "never SSH into the VM."

This week's learning focus is Terraform, not deep GCP access-control design.

However, a VM created by Terraform should still be minimally operable. For this lesson, "the VM can be reached by SSH after apply" is a reasonable acceptance point because it proves the resource is not only created on paper, but can also be entered and inspected by the operator.

The goal is therefore not to expand the lesson into OS Login, IAP, or a complete IAM model. The goal is to include just enough SSH access in the Terraform spec so the user can connect to the VM after `terraform apply`.

The useful target is:

- SSH is explicitly described by IaC
- SSH uses key-based login
- SSH is not open to the whole internet when avoidable
- root/password login is not introduced
- the setup remains simple enough for one-person operation

## Recommended Practical Direction

For this repository and this VM, the next practical improvement is to add a Terraform-managed SSH firewall rule with restricted source ranges.

Recommended shape:

- add an `allow-ssh` VM tag
- add `variable "ssh_source_ranges"` as `list(string)`
- create `google_compute_firewall.allow_ssh`
- allow TCP `22`
- set `source_ranges = var.ssh_source_ranges`
- keep the default example narrow, not `0.0.0.0/0`

This makes SSH access explicit without turning the lesson into a full IAM, IAP, or production network design.

In lesson terms, the expected minimum acceptance flow becomes:

```bash
terraform apply
gcloud compute ssh free-tier-vm --zone us-east1-b
```

The exact project and zone values should still come from the Terraform inputs and outputs, but the important point is that SSH reachability becomes part of the minimum Terraform exercise, not an accidental side effect of the GCP project's existing defaults.

## Suggested Terraform Change

Example direction:

```hcl
variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to SSH into the VM."
  type        = list(string)
}
```

```hcl
locals {
  instance_tags = ["free-tier-vm", "allow-http", "allow-https", "allow-ssh"]
}
```

```hcl
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
```

The example variable file can use a placeholder:

```hcl
ssh_source_ranges = ["YOUR_PUBLIC_IP/32"]
```

## Security Notes

Avoid this as the default:

```hcl
source_ranges = ["0.0.0.0/0"]
```

For a personal VM, opening SSH to the whole internet may work, but it creates unnecessary exposure and noisy login attempts.

A more practical baseline is:

- allow TCP `22` only from the user's current public IP, home IP, VPN exit IP, or trusted CIDR
- keep SSH key-based login
- do not enable password login
- do not design around direct root login
- update `ssh_source_ranges` when the user's IP changes

## Handling Dynamic IPs

If the user's IP changes often, there are three practical options:

- update `ssh_source_ranges` and run `terraform apply` when needed
- use a stable VPN exit IP and allow only that CIDR
- later evaluate IAP tunneling if IP allowlisting becomes annoying

For the current learning phase, the first option is the simplest and most transparent.

## Implementation Status

No Terraform implementation has been applied for this issue yet.

This document records the issue analysis and the recommended implementation direction.

## Maintenance Guidance

When this issue is implemented, update this document with:

- the exact files changed
- whether SSH is managed by firewall source range, OS Login, IAP, or another mechanism
- the expected command for connecting to the VM
- any remaining manual step, such as providing a local public key or updating `ssh_source_ranges`

The implementation should stay scoped to this Terraform package unless the lesson explicitly expands into project-level IAM or network access design.
