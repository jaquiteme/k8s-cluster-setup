
output "k8s_control_node_ips" {
  value = {
    for node in aws_instance.k8s_control_node :
    node.tags.Name => node.public_ip
  }
  description = "K8s control nodes IP addresses"
}

output "k8s_worker_node_ips" {
  value = {
    for node in aws_instance.k8s_worker_node :
    node.tags.Name => node.public_ip
  }
  description = "K8s worker nodes IP addresses"
}
