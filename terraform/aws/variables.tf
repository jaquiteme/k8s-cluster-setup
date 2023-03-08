variable "region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region"
}

variable "cluster_control_count" {
  type        = number
  default     = 1
  description = "K8s cluster control nodes count"
}

variable "cluster_node_count" {
  type        = number
  default     = 2
  description = "K8s cluster nodes count"
}

variable "key_name" {
  type        = string
  default     = "k8s-cluster-key"
  description = "K8s cluster key"
}
