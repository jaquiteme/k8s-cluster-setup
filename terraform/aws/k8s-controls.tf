locals {
  ssh_private_key = "${var.key_name}.pem"
  ssh_public_key = "${var.key_name}.pub"
}

resource "aws_instance" "k8s_control_node" {
  count                       = var.cluster_master_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.k8s_cluster_private.id
  vpc_security_group_ids      = [aws_security_group.k8s_cluster_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "k8s-control-${count.index}"
  }

  # Running remote-exec to make sure that ssh is up and running
  # In this case before running Ansible playbook on local-exec
  provisioner "remote-exec" {
   inline = ["echo 'Hello from the node'"]
   connection {
     host        = self.public_ip
     type        = "ssh"
     user        = "ubuntu"
     private_key = file(local.ssh_private_key)
   }
  }

  # Local exec run commands immediately when the machine is provisioned
  # Not wait for the end of boot up
  provisioner "local-exec" {
   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${local.ssh_private_key} -e 'pub_key=${local.ssh_public_key}' ../provision/k8s-master-setup.yml"
  }
}

