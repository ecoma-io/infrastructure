# CI/CD

## Workflow

1. Push to `main` branch.
2. GitHub Actions will:
   - Connect to Tailscale.
   - Run Terraform to provision VMs across configured providers.
   - Terraform will generate outputs (see the example `docs/output.json`).
   - Generate Ansible inventory (see the example `docs/inventory.yaml`).
   - Run Ansible to configure OS, Storage, and K3s.

## Examples (external files)

- Example Terraform output JSON: `docs/output.json`
- Example Ansible inventory YAML: `docs/inventory.yaml`

Placeholders are provided in `docs/` so CI authors and reviewers can inspect canonical examples without embedding large blocks in the main README.
