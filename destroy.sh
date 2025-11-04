#!/usr/bin/env bash
set -euo pipefail

#############################################
# Environment Cleanup Script
#############################################

ENV_NAME=${ENV_NAME:-aptos-mi-demo}
FALLBACK_RG=${FALLBACK_RG:-rg-aptos-mi-demo}

echo "==================================================="
echo "Cleanup: Destroying Environment"
echo "==================================================="

RG=""

if [ -d ".azure/$ENV_NAME" ]; then
  RG=$(grep -E '^AZURE_RESOURCE_GROUP=' ".azure/$ENV_NAME/.env" 2>/dev/null | cut -d= -f2 | tr -d '\"' || echo "")
  if [ -n "$RG" ] && [ "$RG" != "null" ]; then
    echo "✓ Found resource group in azd env: $RG"
  else
    echo "⚠️ No RG recorded in environment, using fallback: $FALLBACK_RG"
    RG="$FALLBACK_RG"
  fi
else
  echo "⚠️ No azd environment folder (.azure/$ENV_NAME). Using fallback RG: $FALLBACK_RG"
  RG="$FALLBACK_RG"
fi

if az group exists --name "$RG" | grep -q true; then
  echo "Deleting resource group: $RG"
  az group delete --name "$RG" --yes --no-wait || echo "⚠️ Failed to queue deletion"
else
  echo "Resource group $RG not found (already deleted or name mismatch)."
fi

if [ -d ".azure/$ENV_NAME" ]; then
  echo "Removing local environment directory: .azure/$ENV_NAME"
  rm -rf ".azure/$ENV_NAME"
fi

echo ""
echo "✓ Cleanup complete"
