variable "proxmox_api_url" {
  type      = string
  sensitive = true
}

variable "proxmox_user" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "vm_user" {
  type    = string
  sensitive = true
}

variable "vm_password" {
  type    = string
  sensitive = true
}

variable "vm_ssh_key" {
  type      = string
  sensitive = true
}

variable "vms" {
  type = map(object({
    id        = number
    pve_node  = string
    cores     = number
    memory    = number
    template  = number
    ip        = string
    gateway   = string
    os_disk   = object({
      size    = number
      storage = string
      enable_ssd_features  = bool
    })
    data_disks = list(object({
      size    = number
      storage = string
      enable_ssd_features  = bool
    }))
  }))
}