vms = {
  "cdb-1" = {
    id = 102, template = 9000, pve_node = "proxmox1"
    cores = 2, memory = 1792
    ip = "192.168.31.102/24", gateway = "192.168.31.1"
    os_disk = { 
      size = 15
      storage = "ssd"
      enable_ssd_features = true
    }
    data_disks = [
      { 
        size = 15
        storage = "nvme"
        enable_ssd_features = true
      }
    ]
  },
  "cpl-1" = {
    id = 103
    template = 9000
    pve_node = "proxmox1"
    cores = 2
    memory = 4096
    ip = "192.168.31.103/24"
    gateway = "192.168.31.1"
    os_disk = {
      size = 20
      storage = "ssd"
      enable_ssd_features = true
    }
    data_disks = [
      {
        size = 4
        storage = "nvme"
        enable_ssd_features = true
      }
    ]
  },

  "ops-1" = {
    id = 104
    template = 9000
    pve_node = "proxmox1"
    cores = 4
    memory = 8192
    ip = "192.168.31.104/24"
    gateway = "192.168.31.1"
    os_disk = {
      size = 120
      storage = "ssd"
      enable_ssd_features = true
    }
    data_disks = [
      {
        size = 8
        storage = "nvme"
        enable_ssd_features = true
      }
    ]
  },

  "sts-1" = {
    id = 105
    template = 9000
    pve_node = "proxmox1"
    cores = 4
    memory = 12288
    ip = "192.168.31.105/24"
    gateway = "192.168.31.1"
    os_disk = {
      size = 900
      storage = "nvme"
      enable_ssd_features = true
    }
    data_disks = [
      {
        size = 6000
        storage = "hdd"
        enable_ssd_features = false
      }
    ]
  },

  "wkr-1" = {
    id = 106
    template = 9000
    pve_node = "proxmox1"
    cores = 4
    memory = 4096
    ip = "192.168.31.106/24"
    gateway = "192.168.31.1"
    os_disk = {
      size = 60
      storage = "nvme"
      enable_ssd_features = true
    }
    data_disks = []
  }
}
