# Azure DevOps Automation Setup

This directory contains the automated deployment setup for the AKS Baseline infrastructure using Azure DevOps pipelines with container-based agents.

## Quick Start

### 1. Prerequisites
- Azure subscription with Owner/Contributor access
- Azure DevOps organization with Project Administrator permissions
- Azure CLI (2.50.0+)
- Terraform (1.3+)
- Git client

### 2. Validate Setup
```bash
# Run validation script
chmod +x scripts/validate-setup.sh
./scripts/validate-setup.sh
```

### 3. Deploy Build Agents
```bash
# Deploy container-based build agents
chmod +x scripts/deploy-build-agents.sh
./scripts/deploy-build-agents.sh
```

### 4. Follow Workshop Guide
Continue with `09-automation.md` for complete setup instructions.

## Files Overview

### Scripts
- `scripts/validate-setup.sh` - Validates all prerequisites
- `scripts/deploy-build-agents.sh` - Deploys Azure DevOps build agents
- `scripts/create-pipeline.sh` - Creates pipeline YAML file

### Build Agent Infrastructure
- `build-agent/` - Terraform module for Azure Container Instance agents
- `build-agent/terraform.tfvars.example` - Configuration template

### Pipeline Configuration
- `pipelines/azure-infrastructure.yml` - Azure DevOps pipeline YAML
- `terraform/backend.conf` - Terraform state backend configuration

## Architecture

```
Azure DevOps Pipeline
├── Container-based Agents (Azure Container Instances)
├── Service Principal + Workload Identity Federation
├── Terraform State (Azure Storage)
└── Azure Resources Deployment
```

## Deployment Flow

1. **Build Agent Setup** (Step 0)
   - Deploy Azure Container Instances
   - Register agents with Azure DevOps
   - Create agent pool: `aks-baseline-agents`

2. **Azure Resources Setup** (Steps 1-8)
   - Create resource groups and storage backend
   - Configure Service Principal with Workload Identity Federation
   - Set up Key Vault and variable groups

3. **Pipeline Configuration** (Steps 9-10)
   - Import pipeline YAML
   - Configure production environment
   - Run infrastructure deployment

## Troubleshooting

### Build Agents Not Showing
```bash
# Check container instances
az container list --resource-group rg-aks-baseline-agents --output table

# Check agent logs
az container logs --resource-group rg-aks-baseline-agents --name aks-baseline-agent-1
```

### Pipeline Failures
```bash
# Validate Terraform locally
cd terraform
terraform init -backend-config=backend.conf
terraform validate
terraform plan
```

### Service Connection Issues
```bash
# Check role assignments
az role assignment list --assignee <SERVICE_PRINCIPAL_ID> --output table
```

## Security Features

- **No stored secrets**: Workload Identity Federation uses OIDC tokens
- **Least privilege**: Service Principal has minimal required RBAC roles
- **Encrypted state**: Terraform state stored in Azure Storage with encryption
- **Container isolation**: Build agents run in isolated Azure Container Instances
- **Key Vault integration**: Secrets managed through Azure Key Vault

## Support

For issues or questions:
1. Check the troubleshooting section in `09-automation.md`
2. Validate setup using `scripts/validate-setup.sh`
3. Review Azure DevOps agent pool status
4. Check Azure resource deployment logs
