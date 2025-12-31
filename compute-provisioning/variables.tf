
# variable "compute_instances" {
#   type = map(object({
#     # Specs
#     insntance_type = string
#     cpu            = number
#     memory        = number
    
#     # Network
#     ip      = string
#     subnet  = string 

#     # Storage (Dùng cho Ansible mount)
#     storage = map(object({
#       tier    = string
#       size_gb = number
#       mount   = string
#     }))

#     # Chỉ chứa những thứ KHÔNG THỂ suy luận từ Key
#     # Ví dụ: template_id, storage_pool
#     metadata = map(string)
#   }))
# }