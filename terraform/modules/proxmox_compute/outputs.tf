output "vm_info" {
  value = {
    for k, v in proxmox_virtual_environment_vm.this : k => {
      hostname = v.name
      ip       = var.instances[k].ip
      provider = "proxmox"
      disks = [
        for idx, disk in var.instances[k].disks : {
          name = disk.name
          tier = disk.tier
        }
      ]
    }
  }
}
