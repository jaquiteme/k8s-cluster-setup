variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "cluster_def" {
  type = object({
    k8s_version = optional(string, "1.28.0-00")
    master_count = optional(number, 1)
    worker_count = optional(number, 2)
    nodes_ssh_key_name = optional(string, "k8s-cluster-key")
    vpc_cidr = optional(string, "172.16.0.0/16")
    private_subnet_cidr = optional(string, "172.16.1.0/24")
  })
  default = {}
  description = "K8s simple cluster definition"
}

