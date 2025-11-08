#!/usr/bin/env bash
set -euo pipefail

#############################################
# Azure App Service Managed Instance Deploy
# Location: West Central US
# Author: msangapu-msft
# Date: 2025-11-04
#############################################

ENV_NAME=${ENV_NAME:-aptos-mi-demo}
LOCATION=${LOCATION:-westcentralus}

echo "==================================================="
echo "Azure App Service Managed Instance Deployment"
echo "==================================================="
echo "Environment: $ENV_NAME"
echo "Location: $LOCATION"
echo ""

# Generate random hash suffix for resource group
RANDOM_HASH=$(openssl rand -hex 4)
RG_NAME="rg-aptos-mi-demo-${RANDOM_HASH}"

echo "Resource Group: $RG_NAME"
echo ""

# Clean old environment (if exists)
echo "== Cleaning old environment =="
rm -rf .azure/$ENV_NAME

# Create resource group
echo "== Creating resource group =="
az group create --name "$RG_NAME" --location "$LOCATION"

# Create azd environment
echo "== Creating azd environment =="
azd env new "$ENV_NAME" --location "$LOCATION" --no-prompt

# Set environment variables using key=value syntax
echo "== Setting environment variables =="
azd env set "AZURE_LOCATION=$LOCATION"
azd env set "AZURE_RESOURCE_GROUP=$RG_NAME"

# Build font package
echo ""
echo "== Building font installation package =="
bash scripts/prepare-install.sh

# Verify fonts are packaged
FONT_COUNT=$(unzip -l install-scripts.zip 2>/dev/null | grep -ic '\.ttf' || echo "0")
if [ "$FONT_COUNT" -eq 0 ]; then
  echo "ERROR: No fonts found in install-scripts.zip"
  exit 1
fi
echo "✓ $FONT_COUNT font files packaged"

# Provision base infrastructure (identity + storage)
echo ""
echo "== Provisioning base infrastructure =="
azd provision

# Get provisioned resource values
VALUES=$(azd env get-values --output json)
RG=$(echo "$VALUES" | jq -r .AZURE_RESOURCE_GROUP)
STORAGE=$(echo "$VALUES" | jq -r .STORAGE_ACCOUNT_NAME)
CONTAINER=$(echo "$VALUES" | jq -r .STORAGE_CONTAINER_NAME)
IDENTITY_ID=$(echo "$VALUES" | jq -r .MANAGED_IDENTITY_ID)

echo ""
echo "Provisioned Resources:"
echo "  Resource Group: $RG"
echo "  Storage Account: $STORAGE"
echo "  Container: $CONTAINER"
echo "  Identity: $IDENTITY_ID"

# Upload font package to blob storage
echo ""
echo "== Uploading font package to storage =="

# Get current user's object ID
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Current user: msangapu-msft (ObjectId: $USER_OBJECT_ID)"

# Grant current user Storage Blob Data Contributor role
echo "Granting Storage Blob Data Contributor role to current user..."
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "$USER_OBJECT_ID" \
  --assignee-principal-type User \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE" \
  --only-show-errors 2>/dev/null || echo "  (Role assignment may already exist)"

# Wait for role propagation
echo "Waiting 20 seconds for role assignment to propagate..."
sleep 20

# Upload the ZIP
echo "Uploading install-scripts.zip..."
az storage blob upload \
  --account-name "$STORAGE" \
  --container-name "$CONTAINER" \
  --name install-scripts.zip \
  --file install-scripts.zip \
  --auth-mode login \
  --overwrite

echo "✓ Font package uploaded"

# Deploy App Service Managed Instance Plan
PLAN_NAME="mi-plan-$(date +%H%M%S)"
SCRIPT_URI="https://${STORAGE}.blob.core.windows.net/${CONTAINER}/install-scripts.zip"

echo ""
echo "== Deploying Managed Instance Plan =="
echo "Plan Name: $PLAN_NAME"
echo "Install Script URI: $SCRIPT_URI"

az deployment group create \
  --resource-group "$RG" \
  --template-file infra/app-service-plan-managed-instance.json \
  --parameters \
    location="$LOCATION" \
    appServicePlanName="$PLAN_NAME" \
    userAssignedIdentityResourceId="$IDENTITY_ID" \
    installScriptSourceUri="$SCRIPT_URI" \
    skuName=P1V4 \
    skuCapacity=1

# Verify Managed Instance properties
echo ""
echo "== Verifying Managed Instance properties =="
IS_CUSTOM=$(az resource show \
  --resource-group "$RG" \
  --resource-type Microsoft.Web/serverfarms \
  --name "$PLAN_NAME" \
  --api-version 2024-11-01 \
  --query "properties.isCustomMode" -o tsv)

if [ "$IS_CUSTOM" = "true" ]; then
  echo "✓ Managed Instance plan created successfully (isCustomMode=true)"
else
  echo "⚠️  Warning: isCustomMode=$IS_CUSTOM"
  echo "   This region (westcentralus) may not support true Managed Instance."
  echo "   Fonts may not auto-install via installScripts."
fi

# Create Web App
APP_NAME="aptos-app-$(date +%H%M%S)"

echo ""
echo "== Creating Web App =="
echo "App Name: $APP_NAME"

az webapp create \
  --name "$APP_NAME" \
  --resource-group "$RG" \
  --plan "$PLAN_NAME" \
  --runtime "DOTNET|9"

# Assign managed identity to web app
echo "Assigning managed identity to web app..."
az webapp identity assign \
  --name "$APP_NAME" \
  --resource-group "$RG" \
  --identities "$IDENTITY_ID"

# Build and deploy application
echo ""
echo "== Building .NET application =="
pushd src/AptosImageDemo >/dev/null
dotnet publish -c Release -o publish
cd publish
zip -qr ../../../app.zip .
cd ..
popd >/dev/null
echo "✓ Application packaged"

echo ""
echo "== Deploying application code =="
az webapp deployment source config-zip \
  --resource-group "$RG" \
  --name "$APP_NAME" \
  --src app.zip

# Summary
echo ""
echo "==================================================="
echo "✓ Deployment Complete!"
echo "==================================================="
echo ""
echo "Resource Group:  $RG"
echo "Plan:            $PLAN_NAME"
echo "Web App:         $APP_NAME"
echo ""
echo "App URL:         https://${APP_NAME}.azurewebsites.net/"
echo ""
echo "Test endpoints:"
echo "  https://${APP_NAME}.azurewebsites.net/"
echo "  https://${APP_NAME}.azurewebsites.net/aptos-image?text=Hello&size=72"
echo ""
