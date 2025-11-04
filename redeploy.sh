#!/usr/bin/env bash
set -euo pipefail

#############################################
# Quick Redeploy Script
# Only pushes app code to existing Web App
#############################################

RG_NAME=${RG_NAME:-rg-aptos-mi-demo}
APP_NAME=${APP_NAME:-aptos-app-demo}

echo "==================================================="
echo "Quick Redeploy to Existing App Service"
echo "==================================================="
echo "Resource Group: $RG_NAME"
echo "Web App:        $APP_NAME"
echo ""

if ! az group exists --name "$RG_NAME" | grep -q true; then
  echo "❌ Resource group $RG_NAME not found. Run ./deploy.sh first."
  exit 1
fi

if ! az webapp show --name "$APP_NAME" --resource-group "$RG_NAME" &>/dev/null; then
  echo "❌ Web App $APP_NAME not found in $RG_NAME. Run ./deploy.sh first."
  exit 1
fi

echo "✓ Environment verified"

echo ""
echo "== Packaging source code =="
pushd src/AptosImageDemo >/dev/null
zip -qr ../../app.zip . -x "bin/*" -x "obj/*" -x "*.user" -x ".vs/*" -x "packages/*"
popd >/dev/null
echo "✓ Source packaged"

echo ""
echo "== Deploying ZIP to Web App =="
az webapp deploy \
  --resource-group "$RG_NAME" \
  --name "$APP_NAME" \
  --src-path app.zip \
  --type zip >/dev/null

echo "Waiting 20 seconds for deployment..."
sleep 20

echo ""
echo "==================================================="
echo "✓ Redeploy Complete"
echo "==================================================="
echo "App URL: https://${APP_NAME}.azurewebsites.net/"
echo ""
echo "Test endpoints:"
echo "  https://${APP_NAME}.azurewebsites.net/"
echo "  https://${APP_NAME}.azurewebsites.net/font-info"
echo "  https://${APP_NAME}.azurewebsites.net/aptos-image?text=Hello&size=72"
echo ""
