# Build Agent Infrastructure
# This Terraform root module deploys the Azure DevOps build agent infrastructure independently.

terraform {
  required_version = ">= 1.3"
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

provider "azurerm" {
  features {}
}

provider "azuredevops" {
  org_service_url       = var.azdo_org_url
  personal_access_token = var.azdo_pat_token
}

module "build_agent" {
  source = "./module"

  name                = var.name
  resource_group_name = var.resource_group_name
  resource_group_id   = var.resource_group_id
  location            = var.location
  environment         = var.environment
  tenant_id           = var.tenant_id
  azdo_org_url        = var.azdo_org_url
  azdo_pat_token      = var.azdo_pat_token
  azdo_pool_name      = var.azdo_pool_name
  allowed_ips         = var.allowed_ips
  subnet_ids          = var.subnet_ids
  use_container_instances = var.use_container_instances
  agent_count         = var.agent_count
  agent_container_image = var.agent_container_image
  agent_cpu           = var.agent_cpu
  agent_memory        = var.agent_memory
  tags                = var.tags
}
