#!/usr/bin/env bash
set -euo pipefail

#############################################
# Azure App Service Managed Instance Deploy
# Location: West Central US
# Author: msangapu-msft
# Updated: 2025-11-04
#############################################

ENV_NAME=${ENV_NAME:-aptos-mi-demo}
LOCATION=${LOCATION:-westcentralus}

# Fixed resource names
RG_NAME=${RG_NAME:-rg-aptos-mi-demo}
PLAN_NAME=${PLAN_NAME:-mi-plan-demo}
APP_NAME=${APP_NAME:-aptos-app-demo}

echo "==================================================="
echo "Azure App Service Managed Instance Deployment"
echo "==================================================="
echo "Environment:        $ENV_NAME"
echo "Location:           $LOCATION"
echo "Resource Group:     $RG_NAME"
echo "App Service Plan:   $PLAN_NAME"
echo "Web App:            $APP_NAME"
echo ""

# Create or reuse resource group
if az group exists --name "$RG_NAME" | grep -q true; then
  echo "✓ Resource group already exists: $RG_NAME"
else
  echo "== Creating resource group =="
  az group create --name "$RG_NAME" --location "$LOCATION" >/dev/null
fi

# Optional: reset environment if RESET_ENV=1
if [ "${RESET_ENV:-0}" = "1" ]; then
  echo "RESET_ENV=1 → Removing existing azd environment directory .azure/$ENV_NAME"
  rm -rf ".azure/$ENV_NAME"
fi

# Create azd environment if missing
if [ ! -d ".azure/$ENV_NAME" ]; then
  echo "== Creating azd environment =="
  azd env new "$ENV_NAME" --location "$LOCATION" --no-prompt
else
  echo "✓ azd environment already exists (.azure/$ENV_NAME)"
fi

echo "== Setting environment variables =="
azd env set "AZURE_LOCATION=$LOCATION"
azd env set "AZURE_RESOURCE_GROUP=$RG_NAME"

echo ""
echo "== Building font installation package =="
bash scripts/prepare-install.sh

FONT_COUNT=$(unzip -l install-scripts.zip 2>/dev/null | grep -ic '\.ttf' || echo "0")
if [ "$FONT_COUNT" -eq 0 ]; then
  echo "ERROR: No fonts found in install-scripts.zip"
  exit 1
fi
echo "✓ $FONT_COUNT font files packaged"

echo ""
echo "== Provisioning base infrastructure (identity + storage) =="
azd provision

# Gather provisioned values
VALUES=$(azd env get-values --output json)
RG=$(echo "$VALUES" | jq -r .AZURE_RESOURCE_GROUP)
STORAGE=$(echo "$VALUES" | jq -r .STORAGE_ACCOUNT_NAME)
CONTAINER=$(echo "$VALUES" | jq -r .STORAGE_CONTAINER_NAME)
IDENTITY_ID=$(echo "$VALUES" | jq -r .MANAGED_IDENTITY_ID)

echo ""
echo "Provisioned Resources:"
echo "  Resource Group:      $RG"
echo "  Storage Account:     $STORAGE"
echo "  Container:           $CONTAINER"
echo "  Managed Identity ID: $IDENTITY_ID"

echo ""
echo "== Uploading font package to storage =="
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Current user ObjectId: $USER_OBJECT_ID"

echo "Granting Storage Blob Data Contributor (if not already assigned)..."
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "$USER_OBJECT_ID" \
  --assignee-principal-type User \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE" \
  --only-show-errors 2>/dev/null || echo "  (Role assignment may already exist)"

echo "Waiting 15 seconds for role propagation..."
sleep 15

echo "Uploading install-scripts.zip..."
az storage blob upload \
  --account-name "$STORAGE" \
  --container-name "$CONTAINER" \
  --name install-scripts.zip \
  --file install-scripts.zip \
  --auth-mode login \
  --overwrite >/dev/null
echo "✓ Font package uploaded"

SCRIPT_URI="https://${STORAGE}.blob.core.windows.net/${CONTAINER}/install-scripts.zip"

echo ""
echo "== Ensuring App Service Managed Instance Plan =="
if az resource show --resource-group "$RG" --resource-type Microsoft.Web/serverfarms --name "$PLAN_NAME" &>/dev/null; then
  echo "✓ Plan already exists: $PLAN_NAME"
else
  echo "Creating Managed Instance Plan: $PLAN_NAME"
  az deployment group create \
    --resource-group "$RG" \
    --template-file infra/app-service-plan-managed-instance.json \
    --parameters \
      location="$LOCATION" \
      appServicePlanName="$PLAN_NAME" \
      userAssignedIdentityResourceId="$IDENTITY_ID" \
      installScriptSourceUri="$SCRIPT_URI" \
      skuName=P1V4 \
      skuCapacity=1 >/dev/null
fi

echo ""
echo "== Verifying Managed Instance properties =="
IS_CUSTOM=$(az resource show \
  --resource-group "$RG" \
  --resource-type Microsoft.Web/serverfarms \
  --name "$PLAN_NAME" \
  --api-version 2024-11-01 \
  --query "properties.isCustomMode" -o tsv 2>/dev/null || echo "unknown")

if [ "$IS_CUSTOM" = "true" ]; then
  echo "✓ Managed Instance plan confirmed (isCustomMode=true)"
else
  echo "⚠️ isCustomMode=$IS_CUSTOM (region may not support full MI features; scripts/fonts may not auto-install)"
fi

echo ""
echo "== Ensuring Web App =="
if az webapp show --name "$APP_NAME" --resource-group "$RG" &>/dev/null; then
  echo "✓ Web App already exists: $APP_NAME"
else
  echo "Creating Web App: $APP_NAME"
  az webapp create \
    --name "$APP_NAME" \
    --resource-group "$RG" \
    --plan "$PLAN_NAME" \
    --runtime "ASPNET|V4.8" >/dev/null
fi

echo ""
echo "== Assigning managed identity to Web App (if available) =="
if [ -n "$IDENTITY_ID" ] && [ "$IDENTITY_ID" != "null" ]; then
  az webapp identity assign \
    --name "$APP_NAME" \
    --resource-group "$RG" \
    --identities "$IDENTITY_ID" >/dev/null || echo "⚠️ Failed to assign managed identity"
else
  echo "⚠️ No managed identity ID found; skipping assignment"
fi

echo ""
echo "== Packaging source code for deployment =="
pushd src/AptosImageDemo >/dev/null
zip -qr ../../app.zip . -x "bin/*" -x "obj/*" -x "*.user" -x ".vs/*" -x "packages/*"
popd >/dev/null
echo "✓ Source packaged"

echo ""
echo "== Deploying application code =="
az webapp deploy \
  --resource-group "$RG" \
  --name "$APP_NAME" \
  --src-path app.zip \
  --type zip >/dev/null

echo "Waiting 30 seconds for Azure to process deployment..."
sleep 30

echo ""
echo "==================================================="
echo "✓ Deployment Complete"
echo "==================================================="
echo "Resource Group:  $RG"
echo "Plan:            $PLAN_NAME"
echo "Web App:         $APP_NAME"
echo "App URL:         https://${APP_NAME}.azurewebsites.net/"
echo ""
echo "Test endpoints:"
echo "  https://${APP_NAME}.azurewebsites.net/"
echo "  https://${APP_NAME}.azurewebsites.net/font-info"
echo "  https://${APP_NAME}.azurewebsites.net/aptos-image?text=Hello&size=72"
echo ""
