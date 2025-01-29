##################################################################
# SSH Keys
##################################################################
locals {
  master_ssh_private_key = coalesce("${var.cluster_def.nodes_ssh_key_prefix}-master.pem", "master-key.pem")
  master_ssh_public_key  = coalesce("${var.cluster_def.nodes_ssh_key_prefix}-master.pub", "master-key.pub")
  default_username       = "azuser"
}

# Create cluster nodes ssh keys
resource "tls_private_key" "cluster_master_nodes_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Copy private key into a file and store it in your local folder
resource "local_file" "master_ssh_private_key_file" {
  content         = tls_private_key.cluster_master_nodes_key.private_key_pem
  filename        = "${path.module}/${local.master_ssh_private_key}"
  file_permission = "0600"
}

# Copy public key into a file
resource "local_file" "master_ssh_public_key_file" {
  content  = tls_private_key.cluster_master_nodes_key.public_key_openssh
  filename = "${path.module}/${local.master_ssh_public_key}"
}

##################################################################
# Azure public IP
##################################################################
resource "azurerm_public_ip" "k8s_master_nodes" {
  count                   = var.cluster_def.master_count
  name                    = "k8s-master-node-${count.index}-pip"
  location                = data.azurerm_resource_group.default.location
  resource_group_name     = data.azurerm_resource_group.default.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"

  tags = merge(var.default_tags)
}

resource "azurerm_network_interface" "master_nodes_instances_nics" {
  count               = var.cluster_def.master_count
  name                = "master-nic-${count.index}"
  location            = data.azurerm_resource_group.default.location
  resource_group_name = data.azurerm_resource_group.default.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.k8s_vnet.subnets.subnet1.resource_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.k8s_master_nodes[count.index].id
  }
}

##################################################################
# Azure VM
##################################################################
resource "azurerm_linux_virtual_machine" "k8s_master_nodes" {
  count                           = var.cluster_def.master_count
  location                        = data.azurerm_resource_group.default.location
  size                            = var.cluster_def.master_vm_size
  name                            = "k8s-master-${count.index}"
  admin_username                  = local.default_username
  resource_group_name             = data.azurerm_resource_group.default.name
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.master_nodes_instances_nics[count.index].id
  ]

  admin_ssh_key {
    username   = local.default_username
    public_key = local_file.master_ssh_public_key_file.content
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Running remote-exec to make sure that ssh is up and running
  # In this case before running Ansible playbook on local-exec
  provisioner "remote-exec" {
    inline = ["echo 'testing remote-exec connection successful'"]
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = local.default_username
      private_key = <<-EOF
      ${local_file.master_ssh_private_key_file.content}
      EOF
    }
  }

  tags = merge(var.default_tags)
}

# Running node configuration separately
resource "terraform_data" "k8s_masters_config" {
  triggers_replace = [
    var.cluster_def,
    aws_instance.k8s_master_node[*].id
  ]

  provisioner "local-exec" {
    # Pay attention of trailing spaces before and after EOT
    command = <<-EOT
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
      -u ubuntu -i "${join(",", azurerm_linux_virtual_machine.k8s_master_nodes[*].public_ip_address)}," \
      --private-key "${local.master_ssh_private_key}" \
      -e "pub_key=${local.master_ssh_public_key}" \
      -e "k8s_version=${var.cluster_def.k8s_version}" \
      ../../provisioning/playbooks/k8s-master-setup.yml
    EOT
  }
}
