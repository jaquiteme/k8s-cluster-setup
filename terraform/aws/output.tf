
output "k8s_master_node_ips" {
  value = {
    for node in aws_instance.k8s_master_node :
    node.tags.Name => node.public_ip
  }
  description = "K8s master nodes IP addresses"
}

output "k8s_worker_node_ips" {
  value = {
    for node in aws_instance.k8s_worker_node :
    node.tags.Name => node.public_ip
  }
  description = "K8s worker nodes IP addresses"
}
