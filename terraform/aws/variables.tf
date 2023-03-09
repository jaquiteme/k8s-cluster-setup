variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "k8s_vpc_cidr" {
  type        = string
  default     = "172.16.0.0/16"
  description = "K8s vpc cidr"
}

variable "k8s_private_subnet_cidr" {
  type        = string
  default     = "172.16.1.0/24"
  description = "K8s private subnet cidr"
}

variable "cluster_master_count" {
  type        = number
  default     = 1
  description = "K8s cluster control nodes count"
}

variable "cluster_worker_count" {
  type        = number
  default     = 2
  description = l
}

variable "key_name" {
  type        = string
  default     = "k8s-cluster-key"
  description = "K8s cluster key"
}
