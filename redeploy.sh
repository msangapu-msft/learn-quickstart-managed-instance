cd ~/azd-managed-instance
cat > redeploy.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

#############################################
# Quick Redeploy Script
# Redeploys code to existing App Service
# without recreating infrastructure
#############################################

# Fixed resource names
RG_NAME="rg-aptos-mi-demo"
APP_NAME="aptos-app-demo"

echo "==================================================="
echo "Quick Redeploy to Existing App Service"
echo "==================================================="
echo "Resource Group: $RG_NAME"
echo "App Name: $APP_NAME"
echo ""

# Check if resource group exists
if ! az group exists --name "$RG_NAME" | grep -q "true"; then
  echo "❌ Error: Resource group $RG_NAME does not exist"
  echo "   Run ./deploy.sh first to create infrastructure"
  exit 1
fi

# Check if app exists
if ! az webapp show --name "$APP_NAME" --resource-group "$RG_NAME" &>/dev/null; then
  echo "❌ Error: Web app $APP_NAME does not exist"
  echo "   Run ./deploy.sh first to create infrastructure"
  exit 1
fi

echo "✓ Found existing resources"
echo ""

# Package source code
echo "== Packaging source code =="
pushd src/AptosImageDemo >/dev/null
zip -qr ../../app.zip . -x "bin/*" -x "obj/*" -x "*.user" -x ".vs/*" -x "packages/*"
popd >/dev/null
echo "✓ Source code packaged"

echo ""
echo "== Deploying to Azure App Service =="
az webapp deploy \
  --resource-group "$RG_NAME" \
  --name "$APP_NAME" \
  --src-path app.zip \
  --type zip

echo ""
echo "Waiting for Azure to build and deploy..."
sleep 30
echo ""
echo "==================================================="
echo "✓ Redeploy Complete!"
echo "==================================================="
echo ""
echo "App URL: https://${APP_NAME}.azurewebsites.net/"
echo ""
echo "Test endpoints:"
echo "  https://${APP_NAME}.azurewebsites.net/"
echo "  https://${APP_NAME}.azurewebsites.net/font-info"
echo "  https://${APP_NAME}.azurewebsites.net/aptos-image?text=Hello&size=72"
echo ""
EOF

chmod +x redeploy.sh
git add redeploy.sh
git commit -m "Add redeploy.sh for quick code updates"
git push origin default