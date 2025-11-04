#!/usr/bin/env bash
set -euo pipefail

ENV_NAME=${ENV_NAME:-aptos-mi-demo}

echo "==================================================="
echo "Cleanup: Destroying Environment"
echo "==================================================="

# Get RG from environment (if exists)
if [ -d ".azure/$ENV_NAME" ]; then
  RG=$(grep -E '^AZURE_RESOURCE_GROUP=' ".azure/$ENV_NAME/.env" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "")
  
  if [ -n "$RG" ] && [ "$RG" != "null" ]; then
    echo "Deleting resource group: $RG"
    az group delete --name "$RG" --yes --no-wait || true
  else
    echo "No resource group found in environment."
  fi
  
  echo "Removing local environment: .azure/$ENV_NAME"
  rm -rf ".azure/$ENV_NAME"
else
  echo "Environment $ENV_NAME does not exist locally."
fi

echo ""
echo "✓ Cleanup complete"