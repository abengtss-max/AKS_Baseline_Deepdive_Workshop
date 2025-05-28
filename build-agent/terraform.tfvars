# Build Agent Terraform Variables
# Customize these values for your environment

# Basic Configuration
name                = "aks-baseline"
resource_group_name = "rg-aks-baseline-agents"
resource_group_id   = "/subscriptions/e217cd2f-1a4f-44a8-b5ce-7ed01cb0dd4a/resourceGroups/rg-aks-baseline-agents"
location           = "westeurope"
environment        = "production"
tenant_id          = "2d3522cb-b8b3-4f1e-9311-000f54e5c96f"

# Azure DevOps Configuration
azdo_org_url       = "https://dev.azure.com/alibengtsson"
azdo_pool_name     = "aks-baseline-agents"
# azdo_pat_token is set via environment variable TF_VAR_azdo_pat_token for security

# Agent Configuration
use_container_instances = true
agent_count            = 2
agent_cpu              = 2
agent_memory           = 4

# Network Security (Optional)
# allowed_ips = ["YOUR_PUBLIC_IP/32"]  # Add your public IP for secure access

# Tags
tags = {
  Environment = "production"
  Project     = "aks-baseline"
  Purpose     = "build-agents"
}
