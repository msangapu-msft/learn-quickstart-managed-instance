param name string
param location string
param tags object = {}
param appServicePlanId string
param managedIdentityId string = ''
param appSettings object = {}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,windows'
  identity: empty(managedIdentityId) ? null : {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
<<<<<<< HEAD
      windowsFxVersion: isWindows ? 'v4.8' : ''
=======
      windowsFxVersion: 'v4.8'
>>>>>>> db3b45b (Fix: Update azd template for .NET Framework 4.8)
      appSettings: [
        for setting in items(appSettings): {
          name: setting.key
          value: setting.value
        }
      ]
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      http20Enabled: true
    }
    httpsOnly: true
  }
}

output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'