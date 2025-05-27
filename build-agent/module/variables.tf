variable "name" {
  description = "Base name for resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,24}$", var.name))
    error_message = "Name must be lowercase alphanumeric with hyphens, max 24 chars."
  }
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "azdo_org_url" {
  description = "Azure DevOps organization URL"
  type        = string
}

variable "azdo_pat_token" {
  description = "Azure DevOps Personal Access Token"
  type        = string
  sensitive   = true
}

variable "azdo_pool_name" {
  description = "Azure DevOps agent pool name"
  type        = string
  default     = "Default"
}

variable "allowed_ips" {
  description = "Allowed IP addresses for storage account and key vault"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet IDs for network integration"
  type        = list(string)
  default     = []
}

variable "use_container_instances" {
  description = "Use Azure Container Instances for agents"
  type        = bool
  default     = true
}

variable "agent_count" {
  description = "Number of build agents"
  type        = number
  default     = 2
}

variable "agent_container_image" {
  description = "Container image for build agent"
  type        = string
  default     = "mcr.microsoft.com/azure-pipelines/vsts-agent:ubuntu-20.04"
}

variable "agent_cpu" {
  description = "CPU cores for agent container"
  type        = number
  default     = 2
}

variable "agent_memory" {
  description = "Memory in GB for agent container"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
