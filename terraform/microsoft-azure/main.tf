
# Local variables
locals {
  # Ssecurity group ingress rules
  security_rules = [
    {
      name                         = "AllowInboundSSH",
      priority                     = 100,
      access                       = "Allow",
      direction                    = "Inbound",
      source_port_range            = "*",
      destination_port_range       = 22,
      protocol                     = "Tcp",
      source_address_prefix        = "*",
      source_address_prefixes      = null,
      destination_address_prefixes = try(var.cluster_def.private_subnets, ["*"]),
      description                  = "Incoming ssh rule"
    },
    {
      name                         = "AllowInboundK8sApiServer",
      priority                     = 110,
      access                       = "Allow",
      direction                    = "Inbound",
      source_port_range            = "*",
      destination_port_range       = 6443,
      protocol                     = "Tcp",
      source_address_prefix        = "*",
      source_address_prefixes      = null,
      destination_address_prefixes = try(var.cluster_def.private_subnets, ["*"]),
      description                  = "Incoming custom K8s https Control node API"
    },
    {
      name                         = "AllowInternalK8sTraffic",
      priority                     = 120,
      access                       = "Allow",
      direction                    = "Inbound",
      source_port_range            = "*",
      destination_port_range       = "*",
      protocol                     = "*",
      source_address_prefix        = null,
      source_address_prefixes      = try(var.cluster_def.private_subnets, []),
      destination_address_prefixes = try(var.cluster_def.private_subnets, []),
      description                  = "All K8s traffic inside the subnet"
    }
  ]
}


##################################################################
# K8s cluster resource group
##################################################################
# We do not want terraform to manage existing resource group
data "azurerm_resource_group" "default" {
  name = var.resource_group.name
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
# K8s Network Security Group
##################################################################
resource "azurerm_network_security_group" "k8s_subnet_nsg" {
  location            = var.location
  name                = "k8s-default-nsg"
  resource_group_name = data.azurerm_resource_group.default.name

  dynamic "security_rule" {
    for_each = local.security_rules

    content {
      name                         = security_rule.value.name
      priority                     = security_rule.value.priority
      access                       = security_rule.value.access
      direction                    = security_rule.value.direction
      source_port_range            = security_rule.value.source_port_range
      destination_port_range       = security_rule.value.destination_port_range
      protocol                     = security_rule.value.protocol
      source_address_prefix        = (security_rule.value.source_address_prefix != null ? security_rule.value.source_address_prefix : null)
      source_address_prefixes      = (security_rule.value.source_address_prefixes != null ? security_rule.value.source_address_prefixes : null)
      destination_address_prefixes = security_rule.value.destination_address_prefixes
      description                  = security_rule.value.description
    }
  }

  tags = merge(var.default_tags)
}

##################################################################
# K8s cluster VNET
##################################################################
module "k8s_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.7.1"

  address_space       = try(var.cluster_def.vnet_address_spaces, [])
  location            = var.location
  name                = "k8s-default-vnet"
  resource_group_name = data.azurerm_resource_group.default.name

  enable_vm_protection = true

  subnets = {
    "subnet1" = {
      name             = "subnet1"
      address_prefixes = try(var.cluster_def.private_subnets, [])

      network_security_group = {
        id = azurerm_network_security_group.k8s_subnet_nsg.id
      }
    }
  }

  tags = merge(var.default_tags)
}
