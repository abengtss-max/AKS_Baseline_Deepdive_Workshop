output "storage_account_name" {
  value = module.build_agent.storage_account_name
}

output "container_registry_login_server" {
  value = module.build_agent.container_registry_login_server
}

output "key_vault_uri" {
  value = module.build_agent.key_vault_uri
}
