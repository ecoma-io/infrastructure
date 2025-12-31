# Ecoma Infrastructure

This repository contains the **Infrastructure as Code (IaC)** for Ecoma. It utilizes **Terraform** and **Ansible** to define, provision, and automatically deploy the infrastructure via CI/CD pipelines.

## Requirement

Prommox already install on the server.
Debian 12 generic cloud image template vm with id 9000

## Architecture

### Design principles

- On‑premise baseline: the on‑prem Proxmox environment hosts the core, persistent, and stateful services to minimize steady‑state cost and keep critical data under direct control.
- Cloud bursting: cloud providers are used as ephemeral capacity for stateless workloads during spikes; cloud nodes are not the baseline and should be treated as disposable.
- Provider‑agnostic, modular Terraform: declare core infrastructure and connectivity once, reuse modules for different providers, and keep autoscaling decisions outside low‑level modules.

### Roles

The system divides nodes into five roles:

1. Control Plane (cpl)

- Runs k3s server components (API, scheduler) and must remain highly available.
- No user workloads to preserve API uptime.

2. Operator (ops)

- Management and monitoring components (ArgoCD, Prometheus/Grafana, logging).

3. Statefulset (sts)

- Runs system stateful applications (MongoDB, RabbitMQ, SeaweedFS, etc.).
- Prefer vertical scaling and strong data locality on‑prem.

4. Worker (wkr)

- Stateless application workloads, horizontally scalable, suitable for cloud bursting.

### Terraform scope

- Terraform modules in this repo declare core components and persistent connectivity only: Proxmox resources, cloud worker templates, VPC/Subnet definitions, and the Tailscale agents/pods used for overlay connectivity.
- Terraform produces canonical outputs (for example `ansible_inventory`) that downstream processes consume.
- Autoscaling decisions (when to add/remove cloud workers) are made by higher‑level automation (metrics-driven autoscalers, CI/CD workflows, or operator runbooks), which invoke Terraform modules as needed.

### Cloud bursting workflow (overview)

- Trigger: defined metric thresholds (CPU, queue length, latency) or a manual CI trigger.
- Provision: CI or autoscaler runs Terraform to provision cloud worker modules for the selected provider; newly provisioned nodes join the Tailscale overlay and appear in the inventory.
- Configure: Ansible is executed to configure OS, storage mounts, and join the cluster.
- Teardown: automated teardown policies and cost controls destroy cloud resources when load recedes; resources must be tagged and monitored for cost tracking.

### Networking & security

- All nodes (on‑prem and cloud) join a Tailscale overlay with subnet routing to provide a secure, consistent network fabric across providers.
- Proxmox SDN and cloud VPCs are logically connected through Tailscale; services rely on the overlay for control plane and management traffic.
- Admin and CI/CD access is via Tailscale and SSH keys; secrets are stored in GitHub Secrets or a vault and follow least‑privilege principles.

### Operational notes

- Keep stateful services on‑prem; use cloud only for stateless scale‑out workloads.
- Implement monitoring and alerting for burst events and teardown failures.
- Enforce cost controls, tagging, and automatic rotation/revocation of credentials used by CI to provision cloud resources.
- Regularly test the bursting path in staging to ensure the full provisioning → configuration → teardown cycle works reliably.

### Logical diagram

- On‑prem core (Proxmox) → Tailscale overlay ↔ Cloud workers (ephemeral)

This README documents the intended architecture and operational workflows; specific automation (metric thresholds, autoscaler types, and Terraform module names) should be recorded in deployment runbooks and CI workflow definitions.

## Storage Strategy

The storage strategy ensures that data is organized by performance tiers (`swap`, `hot`, `warm`, `cold`).

### 1. Disk Allocation Rules

- **Minimum Requirement**: Every node has at least **1 OS disk**.
- **Additional Disks**: Nodes may have additional attached disks for data or swap.
- **Tiering**: Every disk (including the OS disk) is assigned a specific tier.
- **Constraint**: A node can have only **one disk per tier**.
  - _Max Capacity_: Up to 4 disks per node (1 OS + 3 Data/Swap).

### 2. Mounting Structure

All storage is consolidated under `/var/storage`.

1. **Directory Creation**:
   - Based on the OS disk's tier, a corresponding subdirectory is created: `/var/storage/<os-tier>`.
   - Subdirectories for other attached disks are created: `/var/storage/<disk-tier>`.
   - _Requirement_: At least one of `hot`, `warm`, or `cold` directories must exist.

2. **Mount Points**:
   - The OS disk serves as the root filesystem.
   - Additional disks are mounted to their respective tier directories:
     - `/var/storage/hot`
     - `/var/storage/warm`
     - `/var/storage/cold`
   - Swap disks are activated as system swap.

## IP range planning

IP CIDR:

- Tailscale: 100.64.0.0/10
- Link local: 169.254.0.0/16
- K3S:
  - Pods 10.42.0.0/16
  - Services: 10.43.0.0/16
- Nodes:
  - Proxmox SDN: 10.41.1.0/24

Static IP:

- Core DNS: 10.43.0.10
- Local Node DNS: 169.254.20.10
- Kube VIP: 10.41.1.254
- Promix SDN Vnet Gateway: 10.41.1.1

## Lables

`topology.ecoma.io/provider`: The cloud/on-primise provider

## Getting Started

- **Terraform**:

* `terraform/main.tf`: Root module orchestrating sub-modules for different providers.
* `terraform/modules/`: Contains provider-specific logic (proxmox_compute, aws_compute, gcp_compute, oci_compute).
* `terraform/providers.tf`: Provider configuration (Proxmox, AWS, GCP, OCI).
* `terraform/variables.tf`: Declarations of input variables and default values used by the module.
* `terraform/terraform.tfvars`: Centralized configuration for all VMs across all providers.
* `terraform/outputs.tf`: Aggregated outputs exported by Terraform (includes `ansible_inventory` JSON used to generate Ansible inventory).

- **Ansible**:

* `ansible/playbook.yaml` Definition playbook
