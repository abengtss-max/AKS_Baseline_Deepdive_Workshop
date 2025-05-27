terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }
  }
  required_version = ">= 1.3"
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${var.name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  kubernetes_version                = var.kubernetes_version
  dns_prefix                        = var.dns_prefix
  private_cluster_enabled           = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = false
  sku_tier                         = var.sku_tier
  workload_identity_enabled        = true
  oidc_issuer_enabled              = true
  image_cleaner_enabled            = true
  image_cleaner_interval_hours     = 48
  azure_policy_enabled             = true
  http_application_routing_enabled = false
  local_account_disabled           = true
  node_resource_group              = "${var.resource_group_name}-nodes"

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "00:00"
  }

  default_node_pool {
    name                          = var.default_node_pool_name
    vm_size                       = var.default_node_pool_vm_size
    vnet_subnet_id                = var.vnet_subnet_id
    pod_subnet_id                 = var.pod_subnet_id
    zones                         = var.default_node_pool_availability_zones
    node_labels                   = var.default_node_pool_node_labels
    max_pods                      = var.default_node_pool_max_pods
    max_count                     = var.default_node_pool_max_count
    min_count                     = var.default_node_pool_min_count
    node_count                    = var.default_node_pool_node_count
    os_disk_type                  = var.default_node_pool_os_disk_type
    tags                          = var.tags
  }

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  network_profile {
    network_plugin      = "azure"
    network_mode        = "transparent"
    network_policy      = "azure"
    dns_service_ip      = var.network_dns_service_ip
    service_cidr        = var.network_service_cidr
    outbound_type       = "userDefinedRouting"
    load_balancer_sku   = "standard"
    load_balancer_profile {
      managed_outbound_ip_count = 1
      idle_timeout_in_minutes   = 4
    }
  }

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  oms_agent {
    msi_auth_for_monitoring_enabled = true
    log_analytics_workspace_id      = var.log_analytics_workspace_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  storage_profile {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = true
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "least-waste"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "0s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = 0.5
    empty_bulk_delete_max            = 10
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = true
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
      tags
    ]
  }

  depends_on = [
    azurerm_user_assigned_identity.aks_identity
  ]
}

resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.aks_cluster.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enabled_log {
    category = "kube-apiserver"
  }
  enabled_log {
    category = "kube-audit-admin"
  }
  enabled_log {
    category = "kube-controller-manager"
  }
  enabled_log {
    category = "cluster-autoscaler"
  }
  enabled_log {
    category = "cloud-controller-manager"
  }
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_role_assignment" "aks_cluster_admin" {
  for_each             = toset(var.admin_group_object_ids)
  scope                = azurerm_kubernetes_cluster.aks_cluster.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "aks_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}