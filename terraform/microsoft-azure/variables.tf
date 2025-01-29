variable "azure_resource_group" {
  type        = string
  description = "Azure resource group name"
}

variable "resource_group" {
  type = object({
    name              = optional(string, "k8s-default-rg")
    delete_on_destroy = optional(bool, false)
  })
  default     = {}
  description = "Microsoft resource group"
}

variable "default_tags" {
  type = object({})
  default = {
    environment = "dev"
    project     = "k8s-learning"
  }
}

variable "cluster_def" {
  type = object({
    k8s_version          = optional(string, "1.28.0-00")
    master_count         = optional(number, 1)
    master_vm_size        = optional(string, "Standard_D2s_v3")
    worker_count         = optional(number, 2)
    worker_vm_size        = optional(string, "Standard_D2s_v3")
    nodes_ssh_key_prefix = optional(string, "k8s-cluster-key")
    vnet_address_spaces  = optional(list(string), ["172.16.0.0/16"])
    private_subnets      = optional(list(string), ["172.16.1.0/24"])
  })
  default     = {}
  description = "K8s simple cluster definition"
}

