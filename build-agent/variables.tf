# Variables for Build Agent Infrastructure

variable "name" {
  description = "Base name for resources"
  type        = string
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
  default     = "mcr.microsoft.com/azure-pipelines/vsts-agent"
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
