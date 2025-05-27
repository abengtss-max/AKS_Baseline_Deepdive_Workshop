output "storage_account_name" {
  description = "Storage account name for Terraform state"
  value       = azurerm_storage_account.terraform_state.name
}

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.terraform_state.id
}

output "storage_primary_access_key" {
  description = "Storage account primary access key"
  value       = azurerm_storage_account.terraform_state.primary_access_key
  sensitive   = true
}

output "storage_primary_connection_string" {
  description = "Storage account primary connection string"
  value       = azurerm_storage_account.terraform_state.primary_connection_string
  sensitive   = true
}

output "container_registry_login_server" {
  description = "ACR login server"
  value       = azurerm_container_registry.acr.login_server
}

output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.build_agent.id
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.build_agent.vault_uri
}

output "dev_center_id" {
  description = "Dev Center ID"
  value       = azurerm_dev_center.main.id
}

output "container_instance_ids" {
  description = "Container instance IDs"
  value       = var.use_container_instances ? azurerm_container_group.build_agent[*].id : []
}
