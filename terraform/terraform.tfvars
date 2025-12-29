proxmox_vms = {
  "cdb-1" = {
    id         = 102
    templateId = 9000
    pve_node   = "proxmox1"
    cores      = 2
    memory     = 1792
    ip         = "192.168.31.102/24"
    gateway    = "192.168.31.1"
    disks = {
      "0" = {
        name                = "os"
        tier                = "warm"
        size                = 15
        storage             = "ssd"
        enable_ssd_features = true
      }
      "1" = {
        name                = "data-0"
        tier                = "swap"
        size                = 3
        storage             = "nvme"
        enable_ssd_features = true
      }
      "2" = {
        name                = "data-1"
        tier                = "hot"
        size                = 6
        storage             = "nvme"
        enable_ssd_features = true
      }
    }
  },
  "cpl-1" = {
    id         = 103
    templateId = 9000
    pve_node   = "proxmox1"
    cores      = 2
    memory     = 4096
    ip         = "192.168.31.103/24"
    gateway    = "192.168.31.1"
    disks = {
      "0" = {
        name                = "os"
        tier                = "warm"
        size                = 20
        storage             = "ssd"
        enable_ssd_features = true
      }
      "1" = {
        name                = "data-0"
        tier                = "swap"
        size                = 4
        storage             = "nvme"
        enable_ssd_features = true
      }
    }
  },

  "ops-1" = {
    id         = 104
    templateId = 9000
    pve_node   = "proxmox1"
    cores      = 4
    memory     = 8192
    ip         = "192.168.31.104/24"
    gateway    = "192.168.31.1"
    disks = {
      "0" = {
        name                = "os"
        tier                = "warm"
        size                = 120
        storage             = "ssd"
        enable_ssd_features = true
      }
      "1" = {
        name                = "data-0"
        tier                = "swap"
        size                = 8
        storage             = "nvme"
        enable_ssd_features = true
      }
    }
  },

  "sts-1" = {
    id         = 105
    templateId = 9000
    pve_node   = "proxmox1"
    cores      = 4
    memory     = 12288
    ip         = "192.168.31.105/24"
    gateway    = "192.168.31.1"
    disks = {
      "0" = {
        name                = "os"
        tier                = "hot"
        size                = 900
        storage             = "nvme"
        enable_ssd_features = true
      }
      "1" = {
        name                = "data-0"
        tier                = "cold"
        size                = 2000
        storage             = "hdd"
        enable_ssd_features = false
      }
    }
  },

  "wkr-1" = {
    id         = 106
    templateId = 9000
    pve_node   = "proxmox1"
    cores      = 4
    memory     = 4096
    ip         = "192.168.31.106/24"
    gateway    = "192.168.31.1"
    disks = {
      "0" = {
        name                = "os"
        tier                = "warm"
        size                = 60
        storage             = "nvme"
        enable_ssd_features = true
      }
    }
  }
}