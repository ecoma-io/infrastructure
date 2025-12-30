# Ecoma Infrastructure

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

* `ansible/playbook.yaml` Definition playbook

## Prerequisites

## Github Action Secrets

**Terraform Cloud**: We are using terraform cloud for storage terraform state

- `TF_API_TOKEN`: Terraform Cloud API Token
  **Tailscale**: We are using tailscale for networking and for security resean
- `TS_OAUTH_CLIENT_ID`: Tailscale OAuth Client ID.
- `TS_OAUTH_SECRET`: Tailscale OAuth Secret.
  **SSH Info**: Config ssh info for ssh remote to VM (Password for verify sudo only. Need to ssh with SSH Key)
- `SSH_USERNAME`: The username for access to ssh VM
- `SSH_PASSWORD`: The password for access to ssh VM
- `SSH_PUBLIC_KEY`: Public key for VM access.
- `SSH_PRIVATE_KEY`: Private key for Ansible access to VM
  **Cluster CA**: Using static cluster CA for idenpodemt ansible run
- `CLUSTER_CA_SERVER_CA`:
- `CLUSTER_CA_SERVER_CA_KEY`:
- `CLUSTER_CA_CLIENT_CA`:
- `CLUSTER_CA_CLIENT_CA_KEY`:
- `CLUSTER_CA_REQUEST_HEADER_CA`:
- `CLUSTER_CA_REQUEST_HEADER_CA_KEY`:
  **Proxmox Config**: Using promox
- `PROXMOX_IP`: Proxmox API Tailscale IP.
- `PROXMOX_API_KEY`: Proxmox API KEY
- `PROXMOX_API_SECRET`: Proxmox API SECRET

> Can run `generate-cluster-ca.sh` for generate `CLUSTER_CA_*` files

## Proxmox (On Premise Provider)

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
        "region": "us-east",        
        "zone": "us-east-1",
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
        "region": "us-east",        
        "zone": "us-east-1",
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
        "region": "us-east",        
        "zone": "us-east-1",
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
    ansible_user: "***"
    ansible_become_password: "***"
    ansible_ssh_private_key_file: "/tmp/ssh_key"
    ansible_python_interpreter: "/usr/bin/python3.11"
    ansible_connect_timeout: 60
    cluster_cert_root: "/tmp/cluster_certs"
  children:
    cpl:
      hosts:
        cpl-1:
          ansible_host: 192.168.1.111
          provider: proxmox
          region: us-east
          zone: us-east-1
          disks:
            - name: "os"
              tier: "hot"
        cpl-2:
          ansible_host: 192.168.1.112
          provider: proxmox
          region: us-east
          zone: us-east-2
          disks:
            - name: "os"
              tier: "hot"
        cpl-3:
          ansible_host: 192.168.1.113
          provider: proxmox
          region: us-east
          zone: us-east-2
          disks:
            - name: "os"
              tier: "hot"
    ops:
      hosts:
        ops-1:
          ansible_host: 192.168.1.104
          provider: proxmox
          region: us-east
          zone: us-east-2
          disks:
            - name: "os"
              tier: "warm"
            - name: "data-0"
              tier: "swap"
    sts:
      hosts:
        sts-1:
          ansible_host: 192.168.1.105
          provider: proxmox
          region: us-east
          zone: us-east-1
          disks:
            - name: "os"
              tier: "hot"
            - name: "data-0"
              tier: "cold"
    wkr:
      hosts:
        wkr-1:
          ansible_host: 192.168.1.106
          provider: proxmox
          region: us-east
          zone: us-east-2
          disks:
            - name: "os"
              tier: "warm"
```

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
