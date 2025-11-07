targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the resource group')
param resourceGroupName string = 'rg-managed-instance'

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the environment')
param environmentName string = 'rg-mi'

param storageAccountName string = ''
param managedIdentityName string = ''

var tags = {
  'azd-env-name': environmentName
}

var token = toLower(uniqueString(subscription().subscriptionId, environmentName, location))
var abbrs = loadJsonContent('./abbreviations.json')

var idName  = empty(managedIdentityName) ? '${abbrs.managedIdentityUserAssignedIdentities}${token}' : managedIdentityName
var rawStgName = empty(storageAccountName) ? '${abbrs.storageStorageAccounts}${token}' : storageAccountName
var stgName = take(rawStgName, 24)

// Create the resource group - ENSURE location is set
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location  // This MUST be specified
  tags: tags
}

// Deploy managed identity into the resource group
module managedIdentity 'managed-identity.bicep' = {
  name: 'managed-identity'
  scope: rg
  params: {
    name: idName
    location: location
    tags: tags
  }
}

// Deploy storage account into the resource group
module storage 'storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: stgName
    location: location
    tags: tags
    principalId: managedIdentity.outputs.principalId
  }
}

output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name
output STORAGE_ACCOUNT_NAME string = storage.outputs.name
output STORAGE_CONTAINER_NAME string = storage.outputs.containerName
output MANAGED_IDENTITY_ID string = managedIdentity.outputs.id
output MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.outputs.clientId
