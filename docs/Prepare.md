# Prepare

## On Premise/Cloud Account Prepare

### Terraform Cloud (HCP Terraform) Setup

Terraform Cloud is used to manage Remote State (preventing conflicts when multiple people work together) and automate plan/apply command execution.

Create Account: Visit app.terraform.io and create an account.

Create Organization & Workspace:

- Create a new Organization.
- Create a Workspace (choose "API-driven workflow" type).

Get API Token:

- Go to User Settings (top right corner) -> Tokens.
- Click Create an API token, name it `github-actions-token`.
- Copy this token and save it to GitHub Secret: `TF_API_TOKEN`.

### Tailscale OAuth Setup

Tailscale creates a virtual private network (Mesh VPN) so GitHub Actions can "see" your Proxmox server even if it is behind a firewall/NAT.

Create OAuth Client:

- Access Tailscale Admin Console -> Settings -> OAuth Clients.
- Click Generate OAuth Client.

Configure Scopes:

- Select scope: Devices (Read/Write).
- Important: Assign a Tag to this client (e.g., `tag:ci`). Assigning a tag allows the CI VM to be automatically authenticated without manual approval.

Get Secrets:

- Save Client ID to `TS_OAUTH_CLIENT_ID`.
- Save Client Secret to `TS_OAUTH_SECRET`.

### Google Cloud

You need to choose a unique project ID for Google Cloud.

```shell
PROJECT_ID="ecoma-management" # Must be unique
REPO_OWNER="ecoma-io"
REPO_NAME="infrastructure"

# 1. Create project & Set context
gcloud projects create $PROJECT_ID --name="Ecoma Management"
gcloud config set project $PROJECT_ID

# 2. Connect to billing
BILLING_ACCOUNT=$(gcloud billing accounts list --filter="open=true" --format='value(name)' --limit=1 | sed 's/.*\///')
gcloud beta billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT

# 3. Enable APIs
gcloud services enable \
    iam.googleapis.com \
    sts.googleapis.com \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com --project=$PROJECT_ID

# 4. Identity Setup
gcloud iam service-accounts create terraform-admin --display-name="Terraform Admin Account"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform-admin@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"

gcloud iam workload-identity-pools create "github-pool" \
    --location="global" \
    --display-name="GitHub Pool"

gcloud iam workload-identity-pools providers create-oidc "github-provider" \
    --location="global" \
    --workload-identity-pool="github-pool" \
    --display-name="GitHub Provider" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository_owner == '$REPO_OWNER'"

# 5. Final Binding (Using Project Number)
PROJ_NUM=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

gcloud iam service-accounts add-iam-policy-binding "terraform-admin@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/${PROJ_NUM}/locations/global/workloadIdentityPools/github-pool/attribute.repository/$REPO_OWNER/$REPO_NAME"

# 6. Get Secret values
gcloud iam workload-identity-pools providers describe "github-provider" \
    --location="global" \
    --workload-identity-pool="github-pool" \
    --format='value(name)'
```

After these commands, you will have the following values (See GitHub Action Secrets below to add them):

- `GCP_PROJECT_ID`: `<YOUR_UNIQUE_PROJECT_ID_YOU_SELECTED>`
- `GCP_SERVICE_ACCOUNT`: `terraform-admin@<YOUR_UNIQUE_PROJECT_ID_YOU_SELECTED>.iam.gserviceaccount.com`
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: `projects/xxxxxxx/locations/global/workloadIdentityPools/github-pool/providers/github-provider` (The output of the last command)

### Proxmox Setup (API Token & SSH)

For Terraform to create VMs on Proxmox, it needs an API Token with appropriate permissions.

Create Role & User: (Run this in Proxmox Shell or via GUI)

- Create Role `TerraformProv` with permissions: `VM.Allocate`, `VM.Config.All`, `Datastore.AllocateSpace`, `Network.Allocate`.
- Create a new User (e.g., `terraform-user@pve`).

Generate API Token:

- Go to Datacenter -> Permissions -> API Tokens.
- Select User `terraform-user@pve`, uncheck "Privilege Separation".
- Get Token ID and Secret.

Format Secret:

- The value saved to `PROXMOX_STELLAR_DC` usually has the format: `USER@REALM!TOKENID=SECRET`.
- Example: `terraform-user@pve!github-token=1111-2222-3333-4444`.

Ansible needs direct access to the Proxmox host to configure low-level settings (like SDN or storage).

Enable Passwordless Sudo:

- Ensure the user (e.g., root or a user with sudo privileges) can run commands without a password:
- Edit `/etc/sudoers` file: `username ALL=(ALL) NOPASSWD: ALL`.

SSH Key:

- Create a key pair: `ssh-keygen -t ed25519`.
- Copy the content of the `.pub` file to `/root/.ssh/authorized_keys` on the Proxmox server.
- Copy the content of the private key to GitHub Secret `PROXMOX_SSH_KEY`.

## Github Action Secrets

This section describes the secrets required by GitHub Actions so the CI/CD pipeline can access external services (Terraform Cloud, Tailscale, Proxmox) and so Ansible can connect to target servers. Important: store all sensitive values in GitHub repository/organization Secrets or in a secrets manager (e.g., Vault). Do NOT commit secrets into the repository.

- **Terraform Cloud** — used for storing Terraform state and calling the Terraform Cloud API
  - `TF_API_TOKEN`: API token for the Terraform Cloud workspace/organization. Limit the token scope to only the permissions needed (e.g., `run:write`, `state:read/write`).
  - Example: `TF_API_TOKEN=abcd...` (store as a Repository or Organization secret)

- **Tailscale (OAuth)** — used to authenticate CI with Tailscale and manage network access for nodes
  - `TS_OAUTH_CLIENT_ID`: OAuth client ID for the Tailscale application.
  - `TS_OAUTH_SECRET`: OAuth client secret.
  - Use these when the workflow needs to mint auth keys or sign into Tailscale programmatically. Restrict scope and rotate these secrets regularly.

- **SSH info for Ansible** — Ansible connects via SSH public/private keys; password is only for `become` (sudo) verification when necessary
  - `SSH_USERNAME` : Default SSH user on the VM (e.g., `ubuntu` or `ec2-user`).
  - `SSH_PASSWORD`: Password used only for verifying `sudo` if required by playbooks (avoid using passwords for SSH itself).
  - `SSH_PUBLIC_KEY`: Public key content (e.g., `ssh-ed25519 AAAA... user@example.com`) to install on provisioned VMs.
  - `SSH_PRIVATE_KEY`: Private key used by GitHub Actions to run Ansible. Prefer ephemeral keys or keys with limited scope; restrict usage and rotate frequently.

- **Cluster CA (Kubernetes / K3s certificates)** — for static CA-based cluster bootstrap and Ansible distribution
  - `CLUSTER_CA_SERVER_CA`: Server CA certificate PEM (used to sign kube-apiserver/server certificates).
  - `CLUSTER_CA_SERVER_CA_KEY`: Private key PEM for `CLUSTER_CA_SERVER_CA`.
  - `CLUSTER_CA_CLIENT_CA`: Client CA certificate PEM (if server/client CA separation is used).
  - `CLUSTER_CA_CLIENT_CA_KEY`: Private key for client CA.
  - `CLUSTER_CA_REQUEST_HEADER_CA`: Certificate for request-header CA (used with impersonation/request-header auth).
  - `CLUSTER_CA_REQUEST_HEADER_CA_KEY`: Private key for the request-header CA.
  - Note: PEM values are multiline blocks. In GitHub Secrets, store the full PEM block (with \n line breaks). To generate these locally, run `generate-cluster-ca.sh` and upload the resulting PEM contents to the corresponding secrets.

- **Proxmox API** — credentials for Terraform or CI to call the Proxmox API
  - `PROXMOX_STELLAR_DC` : API key + secrets for the promox api in Stellar DC (eg. root@pam!mytoken:1.1.1.1=xxxx-xxxx-xxxx-xxxx-xxxx)
  - `PROXMOX_SSH_USERNAME` : Username for ssh to proxmox server (This user require use sudo without password)
  - `PROXMOX_SSH_KEY` : SSH key for ssh
    to proxmox server

- **Google Cloud**
  - `GCP_PROJECT_ID` :
  - `GCP_WORKLOAD_IDENTITY_PROVIDER`:
  - `GCP_SERVICE_ACCOUNT`:

Short guidance for storing and using secrets in GitHub Actions:

- Store all sensitive values in `Settings -> Secrets` at the repository or organization level.
- Access secrets in workflows using `secrets.<NAME>` (for example `secrets.TF_API_TOKEN`).
- Rotate tokens and keys regularly and revoke any secrets that are no longer needed.

Generating Cluster CA locally: the repository includes `generate-cluster-ca.sh` which can produce the `CLUSTER_CA_*` files. Run that script on a secure machine and then copy the generated PEM blocks into the corresponding GitHub Secrets.
