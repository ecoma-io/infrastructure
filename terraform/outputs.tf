output "ansible_inventory" {
  description = "Inventory data including common credentials and VM list grouped by role"
  sensitive   = true
  value = {
    username = var.vm_user
    password = var.vm_password
    vms = {
      for role in distinct([for vm in proxmox_virtual_environment_vm.vms : split("-", vm.name)[0]]) :
      role => [
        for vm in proxmox_virtual_environment_vm.vms :
        (split("-", vm.name)[0]) == role ? {
          hostname = vm.name
          ip       = split("/", var.vms[vm.name].ip)[0]
        } : null
        if (split("-", vm.name)[0]) == role
      ]
    }
  }
}
