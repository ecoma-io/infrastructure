variable "vm_user" {
  type      = string
  sensitive = true
}

variable "vm_password" {
  type      = string
  sensitive = true
}

variable "vm_ssh_key" {
  type      = string
  sensitive = true
}

variable "instances" {
  description = "Map of Proxmox VMs to create"
  type = map(object({
    # Proxmox node where VM will be created
    pve_node = string
    region   = string
    zone     = string
    # Template VM ID to clone from
    templateId = number
    # VM specifications
    cores  = number
    memory = number

    network = object({
      ip      = string
      gateway = string
      bridge  = string
    })

    disks = map(
      # Key is disk index (0, 1, 2, ...). Idx 0 is OS disk, others are data disks
      object({
        name                = string # Disk name used as serial and mount by ansible
        tier                = string # swap, hot, warm, cold (disk 0 can't be swap)
        size                = number # size of the disk in GB
        storage             = string # Proxmox storage ID
        enable_ssd_features = bool   # Enable iothread/discard for SSDs for better performance
      })
    )
  }))

  # Validate minimum requirements for each VM
  validation {
    condition = alltrue([
      for vm in var.instances : (
        vm.cores >= 1 &&
        vm.memory >= 1024
      )
    ])
    error_message = "Minimum requirements: 1 core, 1024MB RAM"
  }

  # Validate that each VM has at least disk 0 defined (as OS disk)
  validation {
    condition = alltrue([
      for vm_key, vm in var.instances : contains(keys(vm.disks), "0")
    ])
    error_message = "Every VM instance must have a disk with key '0' defined as the OS disk."
  }

  # Validate that each VM has disk 0 defined and its size is at least 10GB
  validation {
    condition = alltrue([
      for vm_key, vm in var.instances : (
        contains(keys(vm.disks), "0") ? vm.disks["0"].size >= 10 : false
      )
    ])
    error_message = "Every VM instance must have a disk '0' (OS disk) with a minimum size of 10GB."
  }

  # Validation for disks[*].type
  validation {
    condition = alltrue([
      for vm_key, vm in var.instances : alltrue([
        for d_idx, d in vm.disks : (
          contains(["swap", "hot", "warm", "cold"], d.tier) &&
          (d_idx == "0" ? d.tier != "swap" : true)
        )
      ])
    ])
    error_message = "Disk tiers must be 'swap', 'hot', 'warm', 'cold'. Note: Disk 0 (OS) cannot be 'swap'."
  }
  # Validation for disk keys being numeric and within Proxmox SCSI limits
  validation {
    condition = alltrue([
      for vm in var.instances : alltrue([
        for idx, d in vm.disks : can(tonumber(idx)) && tonumber(idx) >= 0 && tonumber(idx) <= 30
      ])
    ])
    error_message = "Disk keys must be numbers between 0 and 30 (Proxmox SCSI limits)."
  }
}

