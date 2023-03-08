
resource "aws_instance" "k8s_worker_node" {
  count                       = var.cluster_node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.k8s_cluster_public.id
  vpc_security_group_ids      = [aws_security_group.k8s_cluster_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "k8s-node-${count.index}"
  }
}

