# Infrastructure Deployment

This repository contains the Terraform and Ansible code to deploy a K3s cluster and a PostgreSQL node on Proxmox.

## Prerequisites

1.  **Proxmox**:
    *   User with permissions to create VMs.
    *   Storage pools configured: `ssd` (SSD), `nvme` (NVMe), `hdd` (HDD).
    *   Cloud-init template (e.g., `debian12-template` with template id).
    *   Install tailscale with subnet router configured to allow access to the Proxmox network.
3.  **GitHub Secrets**:
    *   `TF_API_TOKEN`: Terraform Cloucd API Token
    *   `PM_IP`: Proxmox API Tailscal IP (e.g., `100.x.y.z`).
    *   `PM_USER`: Proxmox User (e.g., `terraform@pve!token`).
    *   `PM_PASSWORD`: Proxmox Token/Password.
    *   `TS_OAUTH_CLIENT_ID`: Tailscale OAuth Client ID.
    *   `TS_OAUTH_SECRET`: Tailscale OAuth Secret.
    *   `SSH_USERNAME`: The username for access to ssh VM
    *   `SSH_PASSWORD`: The password for access to ssh VM (Only use for sudo permision and direct console in promox. Can't remote ssh) 
    *   `SSH_PUBLIC_KEY`: Public key for VM access.
    *   `SSH_PRIVATE_KEY`: Private key for Ansible access to VM

## Customization

*   **Terraform**: Edit `terraform/terraform.tfvars` to change VMs definitations.
*   **Ansible**: Edit `ansible/group_vars/all.yml` to change K3s version or token.

## Architecture

- **Controlplan Database**: 2vCPU, 1.75GB RAM, 15GB SSD (OS), 10GB NVMe (6.5GB Data/3.5GB Swap).
- **Controlplan**: 2vCPU, 4GB RAM, 20GB SSD (OS), 4GB NVMe (Swap).
- **Ops**: 4vCPU, 8GB RAM, 120GB SSD (OS), 8GB NVMe (Swap).
- **Statefulset**: 6vCPU, 12GB RAM, 900GB NVMe (OS/Data), 4TB HDD (Data).
- **Worker**: 4vCPU, 4GB RAM, 30GB NVMe (OS/Data)

## CI/CD

1.  Push to `main` branch.
2.  GitHub Actions will:
    *   Connect to Tailscale.
    *   Run Terraform to provision VMs.
    *   Generate Ansible inventory.
    *   Run Ansible to configure OS, Storage, and K3s.