# Ecoma's Infrastructure

This repository contains the **Infrastructure as Code (IaC)** for Ecoma. It utilizes **Terraform** and **Ansible** to define, provision, and automatically deploy the infrastructure via CI/CD pipelines.

## Getting Started

- **Terraform**:

* `terraform/main.tf`: Root module orchestrating sub-modules for different providers.
* `terraform/modules/`: Contains provider-specific logic (proxmox_compute, aws_compute, gcp_compute, oci_compute).
* `terraform/providers.tf`: Provider configuration (Proxmox, AWS, GCP, OCI).
* `terraform/variables.tf`: Declarations of input variables and default values used by the module.
* `terraform/terraform.tfvars`: Centralized configuration for all VMs across all providers.
* `terraform/outputs.tf`: Aggregated outputs exported by Terraform (includes `ansible_inventory` JSON used to generate Ansible inventory).

- **Ansible**:

* `ansible/playbook.yaml` Definitation playbook

## Architecture

### Roles

The system divides the nodes into 5 roles.

1. Control Plane Database (cdb)

- Run PostgreSQL as the K3s datastore instead of etcd.
- Prioritize IOPS (NVMe) to reduce API server latency.
- Low CPU variability, but require stable RAM for query caching.
- PostgreSQL installed directly on the host OS.

2. Control Plane (cpl)

- Run k3s server, manage scheduling, API, and core components.
- Do not run user workloads to ensure API uptime.

3. Operator (ops)

- Management and monitoring brain (ArgoCD, Grafana/Prometheus stack).
- Node balancing IO, CPU, and RAM.

4. Statefulset (sts)

- Run system stateful services: MongoDB, RabbitMQ, SeaweedFS, KurentDB.
- Primarily scale vertically rather than horizontally.

5. Worker (application workloads)

- Run business-logic microservices (stateless).
- Typically scaled horizontally (scale-out).
- Flexible resources, often CPU-intensive.
- Do not hold critical data and can be restarted at any time.

### Hybrid Cloud Infrastructure

- On-premise costs are typically lower than cloud, so on-premise resources handle steady-state workloads to reduce expenses.
- When compute demand spikes (e.g., promotional periods or large campaigns), the system can automatically expand to the cloud to handle the load without investing in additional on-site hardware (cloud bursting) until demand stabilizes and further on-premise investment is justified.
- Redundancy: the cloud environment serves as a standby for disaster recovery or maintenance, reducing downtime and ensuring stable operations.
- **Multi-Cloud Support**: The infrastructure is designed to be provider-agnostic, supporting Proxmox (On-Prem), AWS, GCP, and OCI seamlessly via modular Terraform architecture.

### Comunication/Security

- Nodes located on different infrastructures (cloud/on-premise) will communicate with each other via tailscale with subnet router configured.
- Administrators and CI/CD teams will be required to have permissions and join the Tailscale network in order to access and control the cluster via web-ui/ssh.
- All SSH access will use a separate account to ensure auditability and only SSH keys (not passwords) can be used to prevent brute-force attacks.

## CI/CD

1. Push to `main` branch.
2. GitHub Actions will:
   - Connect to Tailscale.
   - Run Terraform to provision VMs across configured providers.
   - Terraform will generate outputs (See example of output bellow)
   - Generate Ansible inventory (See example of inventory bellow)
   - Run Ansible to configure OS, Storage, and K3s.

## Example of outputs

```
{
  "username": "ssh_user",
  "password": "ssh_password",
  "vms": {
    "cdb": [
      {
        "hostname": "cdb-1",
        "ip": "192.168.31.102",
        "provider": "proxmox",
        "disks": [
          {
            "name": "os",
            "tier": "warm"
          },
          {
            "name": "data-0",
            "tier": "swap"
          }
        ]
      }
    ],
    "cpl": [
      {
        "hostname": "cpl-1",
        "ip": "192.168.31.103",
        "provider": "proxmox",
        "disks": [
          {
            "name": "os",
            "tier": "warm"
          }
        ]
      }
    ],
    "wkr": [
      {
        "hostname": "wkr-cloud-1",
        "ip": "3.1.2.3",
        "provider": "aws",
        "disks": [
          {
            "name": "os",
            "tier": "hot"
          },
          {
            "name": "data-0",
            "tier": "hot"
          }
        ]
      }
    ]
  }
}
```

## Example of inventory

```yaml
all:
  vars:
    ansible_user: "ssh_user"
    ansible_become_password: "ssh_password"
    ansible_ssh_private_key_file: "/tmp/ssh_key"
    ansible_python_interpreter: "/usr/bin/python3.11"
  children:
    cdb:
      hosts:
        cdb-1:
          ansible_host: 192.168.31.102
          provider: proxmox
          disks:
            - name: "os"
              tier: "warm"
            - name: "data-0"
              tier: "swap"
    cpl:
      hosts:
        cpl-1:
          ansible_host: 192.168.31.103
          provider: proxmox
          disks:
            - name: "os"
              tier: "warm"
    wkr:
      hosts:
        wkr-cloud-1:
          ansible_host: 3.1.2.3
          provider: aws
          disks:
            - name: "os"
              tier: "hot"
            - name: "data-0"
              tier: "hot"
```

## Secrets:

- `TF_API_TOKEN`: Terraform Cloud API Token
- `PM_IP`: Proxmox API Tailscale IP.
- `PM_USER`: Proxmox User.
- `PM_PASSWORD`: Proxmox Token/Password.
- `TS_OAUTH_CLIENT_ID`: Tailscale OAuth Client ID.
- `TS_OAUTH_SECRET`: Tailscale OAuth Secret.
- `SSH_USERNAME`: The username for access to ssh VM
- `SSH_PASSWORD`: The password for access to ssh VM
- `SSH_PUBLIC_KEY`: Public key for VM access.
- `SSH_PRIVATE_KEY`: Private key for Ansible access to VM

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
