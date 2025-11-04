@description('Location for the Managed Instance App Service Plan.')
param location string

@description('Name of the Managed Instance plan.')
param appServicePlanName string

@description('Resource ID of the user-assigned managed identity.')
param userAssignedIdentityResourceId string

@description('Storage account name containing install-scripts.zip.')
param storageAccountName string

@description('Blob container name containing install-scripts.zip.')
param containerName string

@description('Tags to apply.')
param tags object = {}

@description('SKU name (e.g. P1V4).')
param skuName string = 'P1V4'

@description('SKU capacity (instance count).')
param skuCapacity int = 1

// Construct blob URI using environment suffix (no hard-coded core.windows.net)
var installScriptBlobUri = 'https://${storageAccountName}.blob.${environment().suffixes.storage}/${containerName}/install-scripts.zip'

resource miPlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    reserved: false          // Windows
    isCustomMode: true       // Required for Managed Instance
    installScripts: [
      {
        name: 'FontInstaller'
        source: {
          type: 'RemoteAzureBlob'
          sourceUri: installScriptBlobUri
        }
      }
    ]
    planDefaultIdentity: {
      identityType: 'UserAssigned'
      userAssignedIdentityResourceId: userAssignedIdentityResourceId
    }
  }
}

output id string = miPlan.id
output name string = miPlan.name
