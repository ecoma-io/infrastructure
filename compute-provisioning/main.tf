terraform {
  required_version = ">= 1.0.0"

  cloud {
    organization = "ecoma-io"
    workspaces {
      name = "main"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.90.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.4.0"
    }
  }
  
}


variable "vm_user" {
  type      = string
  sensitive = true
}

variable "vm_password" {
  type      = string
  sensitive = true
}

variable "vm_ssh_key" {
  type      = string
  sensitive = true
}

variable "proxmox_ssh_username" {
  type      = string
  sensitive = true
}

variable "proxmox_ssh_key" {
  type      = string
  sensitive = true
}

variable "proxmox_stellar_dc" {
  type      = string
  sensitive = true
}

locals {  
  stellar_parsed = regex("^(?P<token_id>[^:]+):(?P<ip>[^=]+)=(?P<secret>.+)$", var.proxmox_stellar_dc)
}

provider "proxmox" {
  alias     = "stellar"
  endpoint  = "https://${local.stellar_parsed.ip}:8006/api2/json"
  api_token = "${local.stellar_parsed.token_id}=${local.stellar_parsed.secret}"
  insecure  = true
}

provider "google" {
  alias   = "us_region"
  project = "my-project-id"
  region  = "asia-southeast1"
}



# module "proxmox_infrastructure" {
#   source = "./modules/proxmox_compute"

#   ## Common VM Credentials
#   vm_user     = var.vm_user
#   vm_password = var.vm_password
#   vm_ssh_key  = var.vm_ssh_key

#   ## Proxmox VMs Configuration
#   instances = var.proxmox_vms

# }


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