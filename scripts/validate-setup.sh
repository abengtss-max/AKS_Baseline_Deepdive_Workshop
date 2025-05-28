#!/bin/bash

# Azure DevOps Pipeline Validation Script
# This script validates that all prerequisites are met before running the pipeline

set -e

echo "🔍 Validating Azure DevOps Pipeline Prerequisites..."
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VALIDATION_PASSED=true

# Function to check status
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        VALIDATION_PASSED=false
    fi
}

# Function to check warning
check_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo ""
echo "1. Checking Azure CLI..."
if command -v az &> /dev/null; then
    check_status 0 "Azure CLI is installed"
    
    # Check if logged in
    if az account show &> /dev/null; then
        check_status 0 "Azure CLI is logged in"
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
        SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
        echo "   📋 Current subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
    else
        check_status 1 "Azure CLI is not logged in - run 'az login'"
    fi
else
    check_status 1 "Azure CLI is not installed"
fi

echo ""
echo "2. Checking Terraform..."
if command -v terraform &> /dev/null; then
    check_status 0 "Terraform is installed"
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    echo "   📋 Terraform version: $TERRAFORM_VERSION"
else
    check_status 1 "Terraform is not installed"
fi

echo ""
echo "3. Checking repository structure..."

# Check critical files
CRITICAL_FILES=(
    "terraform/main.tf"
    "terraform/variables.tf"
    "terraform/backend.conf"
    "build-agent/main.tf"
    "build-agent/terraform.tfvars.example"
    "pipelines/azure-infrastructure.yml"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_status 0 "File exists: $file"
    else
        check_status 1 "Missing file: $file"
    fi
done

echo ""
echo "4. Checking build-agent configuration..."

if [ -f "build-agent/terraform.tfvars" ]; then
    check_status 0 "build-agent/terraform.tfvars exists"
    
    # Check if critical variables are set
    if grep -q "azdo_org_url" build-agent/terraform.tfvars; then
        check_status 0 "Azure DevOps org URL is configured"
    else
        check_status 1 "Azure DevOps org URL is not configured in terraform.tfvars"
    fi
    
    if grep -q "azdo_pool_name" build-agent/terraform.tfvars; then
        POOL_NAME=$(grep "azdo_pool_name" build-agent/terraform.tfvars | cut -d'"' -f2)
        check_status 0 "Agent pool name is configured: $POOL_NAME"
    else
        check_status 1 "Agent pool name is not configured in terraform.tfvars"
    fi
else
    check_status 1 "build-agent/terraform.tfvars not found - copy from terraform.tfvars.example"
fi

# Check if PAT token is set
if [ -n "$TF_VAR_azdo_pat_token" ]; then
    check_status 0 "Azure DevOps PAT token is set as environment variable"
else
    check_warning "Azure DevOps PAT token not set as TF_VAR_azdo_pat_token environment variable"
fi

echo ""
echo "5. Checking Terraform backend configuration..."

if [ -f "terraform/backend.conf" ]; then
    check_status 0 "Terraform backend.conf exists"
    
    # Validate backend.conf content
    if grep -q "resource_group_name" terraform/backend.conf && \
       grep -q "storage_account_name" terraform/backend.conf && \
       grep -q "container_name" terraform/backend.conf; then
        check_status 0 "Backend configuration appears complete"
    else
        check_status 1 "Backend configuration is incomplete"
    fi
else
    check_status 1 "terraform/backend.conf not found"
fi

echo ""
echo "6. Validating pipeline YAML syntax..."

if command -v python3 &> /dev/null && python3 -c "import yaml" &> /dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('pipelines/azure-infrastructure.yml', 'r'))" &> /dev/null; then
        check_status 0 "Pipeline YAML syntax is valid"
    else
        check_status 1 "Pipeline YAML syntax is invalid"
    fi
else
    check_warning "Python3 with PyYAML not available - skipping YAML syntax validation"
fi

echo ""
echo "7. Checking pipeline pool configuration..."

if grep -q "name: 'aks-baseline-agents'" pipelines/azure-infrastructure.yml; then
    check_status 0 "Pipeline uses correct agent pool name"
else
    check_status 1 "Pipeline does not use the correct agent pool name"
fi

echo ""
echo "=================================================="
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}🎉 All critical validations passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Deploy build-agent infrastructure: cd build-agent && terraform apply"
    echo "2. Verify agents are online in Azure DevOps"
    echo "3. Create service connection and variable groups in Azure DevOps"
    echo "4. Import the pipeline and run it"
    exit 0
else
    echo -e "${RED}❌ Some validations failed. Please fix the issues above before proceeding.${NC}"
    exit 1
fi
