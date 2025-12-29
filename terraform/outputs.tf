locals {
  all_vms = merge(
    module.proxmox_infrastructure.vm_info
  )
}

output "ansible_inventory" {
  description = "Inventory data including common credentials and VM list grouped by role"
  sensitive   = true
  value = {
    username = var.vm_user
    password = var.vm_password
    vms = {
      for role in distinct([for k, v in local.all_vms : split("-", k)[0]]) :
      role => [
        for k, v in local.all_vms : {
          hostname = v.hostname
          ip       = split("/", v.ip)[0]
          provider = v.provider
          disks = [
            for disk in v.disks : {
              name = disk.name
              tier = disk.tier
            }
          ]
        }
        if split("-", k)[0] == role
      ]
    }
  }
}
