terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.9"
    }
  }
}

resource "azurerm_dev_center" "main" {
  name                = "${var.name}-devcenter"
  resource_group_name = var.resource_group_name
  location            = var.location
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

resource "azurerm_storage_account" "terraform_state" {
  name                     = substr(replace(lower("${var.name}tfstate"), "-", ""), 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "production" ? "GRS" : "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }
  network_rules {
    default_action = var.environment == "production" ? "Deny" : "Allow"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ips
  }
  tags = var.tags
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "terraform_state_env" {
  for_each              = toset(["dev", "staging", "production"])
  name                  = "tfstate-${each.key}"
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"
}

resource "azurerm_container_registry" "acr" {
  name                = substr(replace(lower("${var.name}acr"), "-", ""), 0, 50)
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.environment == "production" ? "Premium" : "Basic"
  admin_enabled       = false
  dynamic "network_rule_set" {
    for_each = var.environment == "production" ? [1] : []
    content {
      default_action = "Deny"
      ip_rule {
        action   = "Allow"
        ip_range = var.allowed_ips[0]
      }
    }
  }
  tags = var.tags
}

resource "azurerm_key_vault" "build_agent" {
  name                       = substr("${var.name}-kv", 0, 24)
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  soft_delete_retention_days = 90
  purge_protection_enabled   = var.environment == "production"
  sku_name                   = "standard"
  enable_rbac_authorization = true
  network_acls {
    bypass                     = "AzureServices"
    default_action             = var.environment == "production" ? "Deny" : "Allow"
    ip_rules                   = var.allowed_ips
    virtual_network_subnet_ids = var.subnet_ids
  }
  tags = var.tags
}

resource "azurerm_key_vault_secret" "pat_token" {
  name         = "azdo-pat-token"
  value        = var.azdo_pat_token
  key_vault_id = azurerm_key_vault.build_agent.id
  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_container_group" "build_agent" {
  count               = var.use_container_instances ? var.agent_count : 0
  name                = "${var.name}-agent-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  identity {
    type = "SystemAssigned"
  }
  container {
    name   = "azdo-agent"
    image  = var.agent_container_image
    cpu    = var.agent_cpu
    memory = var.agent_memory
    environment_variables = {
      AZP_URL        = var.azdo_org_url
      AZP_POOL       = var.azdo_pool_name
      AZP_AGENT_NAME = "${var.name}-agent-${count.index}"
    }
    secure_environment_variables = {
      AZP_TOKEN = var.azdo_pat_token
    }
    ports {
      port     = 443
      protocol = "TCP"
    }
  }
  dynamic "subnet_ids" {
    for_each = var.environment == "production" ? [1] : []
    content {
      subnet_ids = var.subnet_ids
    }
  }
  tags = var.tags
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.terraform_state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_dev_center.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = azurerm_key_vault.build_agent.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_dev_center.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "container_instance_contributor" {
  count                = var.use_container_instances ? var.agent_count : 0
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_container_group.build_agent[count.index].identity[0].principal_id
}
