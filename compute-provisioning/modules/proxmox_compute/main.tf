resource "proxmox_virtual_environment_vm" "this" {
  for_each  = var.instances
  name      = each.key
  node_name = each.value.pve_node

  clone {
    vm_id        = each.value.templateId
    datastore_id = each.value.disks["0"].storage
    full         = true
  }

  memory {
    dedicated = each.value.memory
  }

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
  }

  on_boot = true

  agent {
    enabled = true
    trim    = true
  }

  scsi_hardware = "virtio-scsi-single"
  boot_order    = ["scsi0"]

  dynamic "disk" {
    for_each = { for k, v in each.value.disks : k => v if k != "0" }
    content {
      interface    = "scsi${disk.key}"
      datastore_id = disk.value.storage
      size         = disk.value.size

      # Ansible will use serial and tier to identify and mount disks
      serial = disk.value.name

      ssd      = disk.value.enable_ssd_features
      iothread = disk.value.enable_ssd_features
      discard  = disk.value.enable_ssd_features ? "on" : "ignore"
    }
  }

  network_device {
    model  = "virtio"
    bridge = each.value.network.bridge
    mtu    = 1230
  }

  initialization {
    datastore_id = each.value.disks["0"].storage
    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = [trimspace(var.vm_ssh_key)]
    }
    ip_config {
      ipv4 {
        address = each.value.network.ip
        gateway = each.value.network.gateway
      }
    }
  }

  lifecycle {
    ignore_changes = [
      network_device
    ]
  }
}
