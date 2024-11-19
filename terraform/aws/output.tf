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

resource "terraform_data" "k8s_ansible_inventory" {
  triggers_replace = [
    aws_instance.k8s_master_node[*].id,
    aws_instance.k8s_worker_node[*].id
  ]

  provisioner "local-exec" {
    command = "echo [masters] > inventory"
  }

  provisioner "local-exec" {
    command = "echo '${join("\n", aws_instance.k8s_master_node[*].public_ip)}' >> inventory"
  }

  provisioner "local-exec" {
    command = "echo [nodes] >> inventory"
  }

  provisioner "local-exec" {
    command = "echo '${join("\n", aws_instance.k8s_worker_node[*].public_ip)}' >> inventory"
  }
}
