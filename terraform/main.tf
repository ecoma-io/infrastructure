terraform {
  required_version = ">= 1.0.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.90.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
    gcp = {
      source  = "hashicorp/google"
      version = "~> 7.4.0"
    }
  }

  cloud {
    organization = "ecoma-io"
    workspaces {
      name = "main"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_user}=${var.proxmox_password}"
  insecure  = true
}


module "proxmox_infrastructure" {
  source = "./modules/proxmox_compute"

  ## Common VM Credentials
  vm_user     = var.vm_user
  vm_password = var.vm_password
  vm_ssh_key  = var.vm_ssh_key

  ## Proxmox VMs Configuration
  instances = var.proxmox_vms

}


# provider "aws" {
#   region     = var.aws_region
#   access_key = var.aws_access_key
#   secret_key = var.aws_secret_key
# }


# module "aws_infrastructure" {
#   source = "./modules/aws_compute"

#   ## Common VM Credentials
#   vm_user     = var.vm_user
#   vm_password = var.vm_password
#   vm_ssh_key  = var.vm_ssh_key

#   instances = var.aws_vms
# }

# module "gcp_infrastructure" {
#   source = "./modules/gcp_compute"

#   ## Common VM Credentials
#   vm_user     = var.vm_user
#   vm_password = var.vm_password
#   vm_ssh_key  = var.vm_ssh_key

#   instances = var.gcp_vms
# }

# provider "gcp" {
#   project    = var.gcp_project
#   region     = var.gcp_region
#   credentials = var.gcp_secret_key
# }