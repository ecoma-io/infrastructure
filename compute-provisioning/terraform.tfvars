# proxmox_vms = {
#   "cpl-1" = {
#     templateId = 9000
#     pve_node   = "stellar"
#     region     = "vn-hn"
#     zone       = "vn-hn-1"
#     cores      = 2
#     memory     = 3072
#     network = {
#       ip      = "10.41.1.11/24"
#       gateway = "10.41.1.1"
#       bridge  = "vnet"
#     },
#     disks = {
#       "0" = {
#         name                = "os"
#         tier                = "hot"
#         size                = 20
#         storage             = "nvme"
#         enable_ssd_features = true
#       }
#     }
#   },
#   "cpl-2" = {
#     templateId = 9000
#     pve_node   = "stellar"
#     region     = "vn-hn"
#     zone       = "vn-hn-1"
#     cores      = 2
#     memory     = 3072
#     network = {
#       ip      = "10.41.1.12/24"
#       gateway = "10.41.1.1"
#       bridge  = "vnet"
#     },
#     disks = {
#       "0" = {
#         name                = "os"
#         tier                = "hot"
#         size                = 20
#         storage             = "nvme"
#         enable_ssd_features = true
#       }
#     }
#   },
#   "cpl-3" = {
#     templateId = 9000
#     pve_node   = "stellar"
#     region     = "vn-hn"
#     zone       = "vn-hn-1"
#     cores      = 2
#     memory     = 3072
#     network = {
#       ip      = "10.41.1.13/24"
#       gateway = "10.41.1.1"
#       bridge  = "vnet"
#     },
#     disks = {
#       "0" = {
#         name                = "os"
#         tier                = "hot"
#         size                = 20
#         storage             = "nvme"
#         enable_ssd_features = true
#       }
#     }
#   }

#   # "ops-1" = {
#   #   id         = 200
#   #   templateId = 9000
#   #   pve_node   = "stellar"
#   #   cores      = 4
#   #   memory     = 8192
#   #   ip         = "192.168.31.104/24"
#   #   gateway    = "192.168.31.1"
#   #   disks = {
#   #     "0" = {
#   #       name                = "os"
#   #       tier                = "warm"
#   #       size                = 120
#   #       storage             = "ssd"
#   #       enable_ssd_features = true
#   #     }
#   #     "1" = {
#   #       name                = "data-0"
#   #       tier                = "swap"
#   #       size                = 8
#   #       storage             = "nvme"
#   #       enable_ssd_features = true
#   #     }
#   #   }
#   # },

#   # "sts-1" = {
#   #   id         = 300
#   #   templateId = 9000
#   #   pve_node   = "stellar"
#   #   cores      = 4
#   #   memory     = 12288
#   #   ip         = "192.168.31.105/24"
#   #   gateway    = "192.168.31.1"
#   #   disks = {
#   #     "0" = {
#   #       name                = "os"
#   #       tier                = "hot"
#   #       size                = 500
#   #       storage             = "nvme"
#   #       enable_ssd_features = true
#   #     }
#   #     "1" = {
#   #       name                = "data-0"
#   #       tier                = "cold"
#   #       size                = 2000
#   #       storage             = "hdd"
#   #       enable_ssd_features = false
#   #     }
#   #   }
#   # },

#   # "wkr-1" = {
#   #   id         = 400
#   #   templateId = 9000
#   #   pve_node   = "stellar"
#   #   cores      = 4
#   #   memory     = 4096
#   #   ip         = "192.168.31.106/24"
#   #   gateway    = "192.168.31.1"
#   #   disks = {
#   #     "0" = {
#   #       name                = "os"
#   #       tier                = "warm"
#   #       size                = 60
#   #       storage             = "nvme"
#   #       enable_ssd_features = true
#   #     }
#   #   }
#   # }
# }
