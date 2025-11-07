targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the resource group')
param resourceGroupName string = 'rg-managed-instance'

@minLength(1)
@description('Primary location for all resources')
param location string = 'westcentralus'

param environmentName string
param location string
param storageAccountName string = ''
param managedIdentityName string = ''

var tags = {
  'azd-env-name': environmentName
}

var token = toLower(uniqueString(subscription().subscriptionId, environmentName, location))
var abbrs = loadJsonContent('./abbreviations.json')

var idName  = empty(managedIdentityName) ? '${abbrs.managedIdentityUserAssignedIdentities}${token}' : managedIdentityName
var stgName = empty(storageAccountName) ? '${abbrs.storageStorageAccounts}${token}' : storageAccountName

module managedIdentity 'managed-identity.bicep' = {
  name: 'managed-identity'
  params: {
    name: idName
    location: location
    tags: tags
  }
}

module storage 'storage.bicep' = {
  name: 'storage'
  params: {
    name: stgName
    location: location
    tags: tags
    principalId: managedIdentity.outputs.principalId
  }
}

output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = resourceGroup().name
output STORAGE_ACCOUNT_NAME string = storage.outputs.name
output STORAGE_CONTAINER_NAME string = storage.outputs.containerName
output MANAGED_IDENTITY_ID string = managedIdentity.outputs.id
output MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.outputs.clientId
