locals {
  ssh_private_key  = "${var.cluster_def.nodes_ssh_key_name}.pem"
  ssh_public_key   = "${var.cluster_def.nodes_ssh_key_name}.pub"
  default_username = "azuser"
}

##################################################################
# Azure security group
##################################################################

##################################################################
# Azure public IP
##################################################################
# resource "azurerm_public_ip" "k8s_master_nodes" {
#   name                    = "k8s-master-nodes-pip"
#   location                = data.azurerm_resource_group.default.location
#   resource_group_name     = data.azurerm_resource_group.default.name
#   allocation_method       = "Static"
#   idle_timeout_in_minutes = 30

#   tags = merge(var.default_tags)
# }

resource "azurerm_network_interface" "master_nodes_instances_nics" {
  count               = var.cluster_def.master_count
  name                = "master-nic-${count.index}"
  location            = data.azurerm_resource_group.default.location
  resource_group_name = data.azurerm_resource_group.default.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.k8s_vnet.subnets.subnet1.resource_id
    private_ip_address_allocation = "Dynamic"
  }
}

##################################################################
# Azure VM
##################################################################
resource "azurerm_linux_virtual_machine" "k8s_master_nodes" {
  count               = var.cluster_def.master_count
  location            = data.azurerm_resource_group.default.location
  size                = "Standard_F2"
  name                = "k8s-masters"
  admin_username      = local.default_username
  resource_group_name = "k8s-default-rg"

  network_interface_ids = [
    azurerm_network_interface.master_nodes_instances_nics[count.index].id
  ]

  admin_ssh_key {
    username   = local.default_username
    public_key = local_file.ssh_public_key_file.content
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
  # provisioner "remote-exec" {
  #   inline = ["echo 'Hello from the node'"]
  #   connection {
  #     host        = self.network_interface[1].ip_configuration[0].public_ip_address
  #     type        = "ssh"
  #     user        = local.default_username
  #     private_key = <<-EOF
  #     ${local_file.ssh_private_key_file.content}
  #     EOF
  #   }
  # }

  tags = merge(var.default_tags)
}
