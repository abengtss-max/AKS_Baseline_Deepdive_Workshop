#!/bin/bash

# Script to create Azure DevOps pipeline file
# This script creates the pipeline YAML file that uses container-based agents

set -e

echo "Creating Azure DevOps Pipeline..."

# Create pipelines directory if it doesn't exist
mkdir -p pipelines

# Create Azure DevOps pipeline YAML file
cat > pipelines/azure-infrastructure.yml << 'EOF'
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - terraform/*

variables:
- group: terraform-common

pool:
  name: 'aks-baseline-agents'  # Custom agent pool created by build-agent module

stages:
- stage: Validate
  displayName: 'Terraform Validate'
  jobs:
  - job: Validate
    steps:
    - task: TerraformInstaller@1
      displayName: 'Install Terraform'
      inputs:
        terraformVersion: $(TerraformVersion)
    
    - task: AzureCLI@2
      displayName: 'Terraform Init'
      inputs:
        azureSubscription: $(ServiceConnection)
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          cd terraform
          terraform init -backend-config=backend.conf
    
    - task: AzureCLI@2
      displayName: 'Terraform Validate'
      inputs:
        azureSubscription: $(ServiceConnection)
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          cd terraform
          terraform validate

- stage: Plan
  displayName: 'Terraform Plan'
  dependsOn: Validate
  condition: succeeded()
  jobs:
  - job: Plan
    steps:
    - task: TerraformInstaller@1
      displayName: 'Install Terraform'
      inputs:
        terraformVersion: $(TerraformVersion)
    
    - task: AzureCLI@2
      displayName: 'Terraform Init'
      inputs:
        azureSubscription: $(ServiceConnection)
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          cd terraform
          terraform init -backend-config=backend.conf
    
    - task: AzureCLI@2
      displayName: 'Terraform Plan'
      inputs:
        azureSubscription: $(ServiceConnection)
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          cd terraform
          terraform plan -out=tfplan
    
    - task: PublishPipelineArtifact@1
      displayName: 'Publish Terraform Plan'
      inputs:
        targetPath: 'terraform/tfplan'
        artifact: 'terraform-plan'

- stage: Apply
  displayName: 'Terraform Apply'
  dependsOn: Plan
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: Apply
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: TerraformInstaller@1
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: $(TerraformVersion)
          
          - task: DownloadPipelineArtifact@2
            displayName: 'Download Terraform Plan'
            inputs:
              artifact: 'terraform-plan'
              path: 'terraform'
          
          - task: AzureCLI@2
            displayName: 'Terraform Init'
            inputs:
              azureSubscription: $(ServiceConnection)
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                cd terraform
                terraform init -backend-config=backend.conf
          
          - task: AzureCLI@2
            displayName: 'Terraform Apply'
            inputs:
              azureSubscription: $(ServiceConnection)
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                cd terraform
                terraform apply tfplan
EOF

echo "Pipeline file created at: pipelines/azure-infrastructure.yml"
echo ""
echo "Next steps:"
echo "1. Deploy the build-agent infrastructure first (see Step 0 in documentation)"
echo "2. Import this pipeline in Azure DevOps"
echo "3. Configure the pipeline to use the 'aks-baseline-agents' pool"
