
# Local variables
locals {
  # AWS security group ingress rules
  ingress_rules = [
    {
      from        = 22,
      to          = 22,
      proto       = "Tcp",
      cidr        = ["0.0.0.0/0"],
      description = "Incoming ssh rule"
    },
    {
      from        = 0,
      to          = 6443,
      proto       = "Tcp",
      cidr        = ["0.0.0.0/0"],
      description = "Incoming custom K8s https Control node API"
    },
    {
      from        = 0,
      to          = 0,
      proto       = "*",
      cidr        = [var.cluster_def.private_subnets],
      description = "All K8s traffic inside the subnet"
    }
  ]
}

# Create cluster nodes ssh keys
resource "tls_private_key" "cluster_nodes_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Copy private key into a file and store it in your local folder
resource "local_file" "ssh_private_key_file" {
  content         = tls_private_key.cluster_nodes_key.private_key_pem
  filename        = "${path.module}/${var.cluster_def.nodes_ssh_key_name}.pem"
  file_permission = "0600"
}

# Copy public key into a file
resource "local_file" "ssh_public_key_file" {
  content  = tls_private_key.cluster_nodes_key.public_key_openssh
  filename = "${path.module}/${var.cluster_def.nodes_ssh_key_name}.pub"
}


##################################################################
# K8s cluster resource group
##################################################################
# We do not want terraform to manage existing resource group
data "azurerm_resource_group" "default" {
  name     = var.resource_group.name
}

##################################################################
# K8s NAT Gateway
##################################################################
# resource "azurerm_nat_gateway" "this" {
#   location            = data.azurerm_resource_group.default.location
#   name                = "k8s-default-instances-nat-gw"
#   resource_group_name = azurerm_resource_group.default.id
# }

##################################################################
# K8s cluster security group
##################################################################
# resource "azurerm_network_security_group" "k8s_ports" {
#   location            = data.azurerm_resource_group.default.location
#   name                = "k8s-default-instances-sg"
#   resource_group_name = azurerm_resource_group.default.id

#   security_rule = {

#   }
# }

##################################################################
# K8s cluster VNET
##################################################################
module "k8s_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.7.1"

  address_space       = try(var.cluster_def.vnet_address_spaces, [])
  location            = data.azurerm_resource_group.default.location
  name                = "k8s-default-vnet"
  resource_group_name = data.azurerm_resource_group.default.name

  enable_vm_protection = true

  subnets = {
    "subnet1" = {
      name             = "subnet1"
      address_prefixes = try(var.cluster_def.private_subnets, [])
    }
  }
}
