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
resource "azurerm_public_ip" "k8s_master_nodes" {
  name                    = "k8s-master-nodes-pip"
  location                = azurerm_resource_group.default.location
  resource_group_name     = azurerm_resource_group.default.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = merge(var.default_tags)
}

##################################################################
# Azure scale set
##################################################################
resource "azurerm_linux_virtual_machine_scale_set" "k8s_master_nodes" {
  instances           = var.cluster_def.master_count
  location            = azurerm_resource_group.default.location
  sku                 = "Standard_F2"
  name                = "k8s-masters"
  admin_username      = local.default_username
  resource_group_name = "k8s-default-rg"

  network_interface {
    name    = "private"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = module.avm-res-network-virtualnetwork.subnets[0].id
    }
  }

  network_interface {
    name    = "public"
    primary = false

    ip_configuration {
      name      = "external"
      subnet_id = azurerm_public_ip.k8s_master_nodes.id
    }
  }

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
  provisioner "remote-exec" {
    inline = ["echo 'Hello from the node'"]
    connection {
      host        = self.network_interface[1].ip_configuration[0].public_ip_address
      type        = "ssh"
      user        = local.default_username
      private_key = <<-EOF
      ${local_file.ssh_private_key_file.content}
      EOF
    }
  }

  tags = merge(var.default_tags)
}