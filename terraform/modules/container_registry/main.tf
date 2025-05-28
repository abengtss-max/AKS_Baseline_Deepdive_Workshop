terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
 
  required_version = ">= 0.14.9"
}


resource "azurerm_container_registry" "acr" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.sku  
  admin_enabled            = var.admin_enabled
  tags                     = var.tags

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.acr_identity.id
    ]
  }

  dynamic "georeplications" {
    for_each = var.georeplication_locations

    content {
      location = georeplications.value
      tags     = var.tags
    }
  }

  lifecycle {
      ignore_changes = [
          tags
      ]
  }
}

resource "azurerm_user_assigned_identity" "acr_identity" {
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  name = "${var.name}Identity"
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}