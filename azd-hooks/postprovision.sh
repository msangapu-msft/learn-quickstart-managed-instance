#!/bin/bash
set -e

echo "=================================================="
echo "Uploading configuration package to storage..."
echo "=================================================="

# Get environment values from azd
STORAGE_ACCOUNT=$(azd env get-values --output json | jq -r .STORAGE_ACCOUNT_NAME)
CONTAINER_NAME=$(azd env get-values --output json | jq -r .STORAGE_CONTAINER_NAME)
RESOURCE_GROUP=$(azd env get-values --output json | jq -r .AZURE_RESOURCE_GROUP)

# Check if zip exists
if [ ! -f "scripts.zip" ]; then
    echo "❌ Error: scripts.zip not found!"
    exit 1
fi

echo "Storage Account: $STORAGE_ACCOUNT"
echo "Container: $CONTAINER_NAME"
echo "Resource Group: $RESOURCE_GROUP"
echo ""

# Get current user's object ID and subscription ID
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Grant current user Storage Blob Data Contributor role
echo "Granting Storage Blob Data Contributor role to current user..."
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "$USER_OBJECT_ID" \
  --assignee-principal-type User \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT" \
  --only-show-errors 2>/dev/null || echo "  (Role assignment may already exist)"

# Wait for role propagation
echo "Waiting 20 seconds for role assignment to propagate..."
sleep 20

echo ""
echo "Uploading scripts.zip to $STORAGE_ACCOUNT/$CONTAINER_NAME..."

# Upload using Azure CLI
az storage blob upload \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$CONTAINER_NAME" \
    --name "scripts.zip" \
    --file "scripts.zip" \
    --auth-mode login \
    --overwrite

# Verify upload
echo "Verifying upload..."
BLOB_EXISTS=$(az storage blob exists \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$CONTAINER_NAME" \
    --name "scripts.zip" \
    --auth-mode login \
    --query exists \
    --output tsv)

if [ "$BLOB_EXISTS" = "true" ]; then
    echo "✓ scripts.zip successfully uploaded to blob storage"
else
    echo "❌ Error: Failed to verify blob upload"
    exit 1
fi

# Get the web app URI for display (if it exists)
WEB_URI=$(azd env get-values --output json 2>/dev/null | jq -r '.SERVICE_WEB_URI // ""' 2>/dev/null || echo "")

echo ""
echo "=================================================="
echo "Post-Provision Complete!"
echo "=================================================="
if [ -n "$WEB_URI" ] && [ "$WEB_URI" != "null" ]; then
    echo "Web App URL: $WEB_URI"
fi

echo "\n=== Deployment Complete ==="
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container Name: $STORAGE_CONTAINER_NAME"
echo "Managed Identity Client ID: $MANAGED_IDENTITY_CLIENT_ID"
echo "Resource Group: $AZURE_RESOURCE_GROUP"
echo ""