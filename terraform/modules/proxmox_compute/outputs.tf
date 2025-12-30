output "vm_info" {
  value = {
    for k, v in proxmox_virtual_environment_vm.this : k => {
      hostname = v.name
      ip       = split("/", var.instances[k].network.ip)[0]
      provider = "proxmox"
      zone     = var.instances[k].zone
      region   = var.instances[k].region
      disks = [
        for idx, disk in var.instances[k].disks : {
          name = disk.name
          tier = disk.tier
        }
      ]
    }
  }
}
