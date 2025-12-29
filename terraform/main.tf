resource "proxmox_virtual_environment_vm" "vms" {
  for_each    = var.vms
  name        = each.key
  node_name   = each.value.pve_node
  vm_id       = each.value.id
  tags        = [split("-", each.key)[0]] 
  clone {
    vm_id = each.value.template
    full  = true
  }

  memory {
    dedicated = each.value.memory
  }

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
  }
  scsi_hardware = "virtio-scsi-single"
  boot_order = ["scsi0"]
  on_boot = true
  
  agent {
    enabled = true
    trim    = true 
  }

  disk {
    datastore_id = each.value.os_disk.storage
    interface    = "scsi0"
    size         = each.value.os_disk.size
    ssd          = each.value.os_disk.enable_ssd_features ? true : false
    iothread     = each.value.os_disk.enable_ssd_features ? true : false
    discard      = each.value.os_disk.enable_ssd_features ? "on" : "ignore"
  }

  dynamic "disk" {
    for_each = each.value.data_disks
    content {
      datastore_id = disk.value.storage
      interface    = "scsi${disk.key + 1}"
      size         = disk.value.size   
      iothread     = disk.value.enable_ssd_features ? true : false
      discard      = disk.value.enable_ssd_features ? "on" : "ignore"   
    }
  }

  network_device {
    model  = "virtio"
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = each.value.os_disk.storage
    user_account {
      username = var.vm_user
      password = var.vm_password
      keys = [trimspace(var.vm_ssh_key)]
    }
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = each.value.gateway
      }
    }
  }

  lifecycle {
    ignore_changes = [
      network_device
    ]
  }
}