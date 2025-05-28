#!/bin/bash

# Build Agent Deployment Script
# This script deploys the Azure DevOps build agent infrastructure

set -e

echo "🚀 Deploying Azure DevOps Build Agent Infrastructure..."
echo "====================================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    exit 1
fi

if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not logged in. Run 'az login' first${NC}"
    exit 1
fi

# Navigate to build-agent directory
cd "$(dirname "$0")/../build-agent"

echo -e "${GREEN}✅ Prerequisites checked${NC}"
echo ""

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}⚠️  terraform.tfvars not found. Creating from example...${NC}"
    
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        echo -e "${YELLOW}📝 Please edit terraform.tfvars with your specific values:${NC}"
        echo "   - azdo_org_url: Your Azure DevOps organization URL"
        echo "   - name: Base name for resources"
        echo "   - resource_group_name: Resource group for build agents"
        echo "   - location: Azure region"
        echo ""
        echo -e "${YELLOW}⏸️  Pausing for manual configuration. Press Enter when ready to continue...${NC}"
        read
    else
        echo -e "${RED}❌ terraform.tfvars.example not found${NC}"
        exit 1
    fi
fi

# Check if PAT token is set
if [ -z "$TF_VAR_azdo_pat_token" ]; then
    echo -e "${YELLOW}🔑 Azure DevOps PAT token not set as environment variable${NC}"
    echo "Please set your Azure DevOps Personal Access Token:"
    echo -n "PAT Token: "
    read -s PAT_TOKEN
    echo ""
    export TF_VAR_azdo_pat_token="$PAT_TOKEN"
fi

# Set required environment variables
echo -e "${BLUE}📝 Setting required environment variables...${NC}"
export TF_VAR_tenant_id=$(az account show --query tenantId -o tsv)

# Get or create resource group
RESOURCE_GROUP=$(grep "resource_group_name" terraform.tfvars | cut -d'"' -f2)
LOCATION=$(grep "location" terraform.tfvars | cut -d'"' -f2)

echo -e "${BLUE}🏗️  Creating resource group: $RESOURCE_GROUP${NC}"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

export TF_VAR_resource_group_id="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"

echo -e "${GREEN}✅ Environment variables set${NC}"
echo ""

# Initialize Terraform
echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
terraform init

# Validate configuration
echo -e "${BLUE}✔️  Validating Terraform configuration...${NC}"
terraform validate

# Plan deployment
echo -e "${BLUE}📋 Planning deployment...${NC}"
terraform plan -out=tfplan

# Confirm deployment
echo ""
echo -e "${YELLOW}⚠️  Ready to deploy build agent infrastructure.${NC}"
echo "This will create:"
echo "   - Azure Container Instances for DevOps agents"
echo "   - Storage account for agent state"
echo "   - Azure DevOps agent pool registration"
echo ""
echo -n "Continue with deployment? (y/N): "
read -r CONFIRM

if [[ $CONFIRM =~ ^[Yy]$ ]]; then
    # Apply configuration
    echo -e "${BLUE}🚀 Deploying infrastructure...${NC}"
    terraform apply tfplan
    
    echo ""
    echo -e "${GREEN}🎉 Build agent infrastructure deployed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Check Azure DevOps → Project Settings → Agent pools → aks-baseline-agents"
    echo "2. Verify that agents are online and ready"
    echo "3. Continue with the main pipeline setup in the workshop"
    echo ""
    
    # Display outputs
    echo -e "${BLUE}📊 Deployment outputs:${NC}"
    terraform output
    
else
    echo -e "${YELLOW}⏹️  Deployment cancelled${NC}"
    rm -f tfplan
fi
