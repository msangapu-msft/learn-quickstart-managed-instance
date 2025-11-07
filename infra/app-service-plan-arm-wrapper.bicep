param location string
param appServicePlanName string
param userAssignedIdentityResourceId string
param storageAccountName string
param containerName string
param tags object = {}
param skuName string = 'P1V4'
param skuCapacity int = 1

// Use environment suffix for sovereign clouds
var installScriptBlobUri = 'https://${storageAccountName}.blob.${environment().suffixes.storage}/${containerName}/configuration-scripts.zip'

resource nestedDeployment 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'managedInstancePlanDeployment'
  properties: {
    mode: 'Incremental'
    template: loadJsonContent('./app-service-plan-managed-instance.json')
    parameters: {
      location: { value: location }
      appServicePlanName: { value: appServicePlanName }
      userAssignedIdentityResourceId: { value: userAssignedIdentityResourceId }
      installScriptSourceUri: { value: installScriptBlobUri }
      tags: { value: tags }
      skuName: { value: skuName }
      skuCapacity: { value: skuCapacity }
    }
  }
}

output id string = nestedDeployment.properties.outputs.id.value
output name string = nestedDeployment.properties.outputs.name.value
