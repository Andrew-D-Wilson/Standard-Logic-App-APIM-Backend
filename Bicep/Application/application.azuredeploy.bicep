/**********************************
Bicep Template: Application Deploy
        Author: Andrew Wilson
***********************************/

targetScope = 'resourceGroup'

// ** Parameters **
// ****************

@description('A prefix used to identify the application resources')
param applicationPrefixName string

@description('The name of the application used for tags')
param applicationName string

@description('The location that the resources will be deployed to - defaulting to the resource group location')
param location string = resourceGroup().location

@description('The environment that the resources are being deployed to')
@allowed([
  'dev'
  'test'
  'prod'
])
param env string = 'dev'

// ** Variables **
// ***************

var applicationKeyVaultName = '${applicationPrefixName}${env}kv'
var lgApplicationAppServicePlanName = '${applicationPrefixName}${env}asp'
var lgStorageAccountName = '${applicationPrefixName}${env}st'
var applicationLogicAppName = '${applicationPrefixName}${env}logic'

var isProduction = env == 'prod'

// ** Resources **
// ***************

@description('Deploy the Application Specific Key Vault')
resource applicationKeyVaultDeploy 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: applicationKeyVaultName
  location: location
  tags: {
    Application: applicationName
    Environment: env
    Version: deployment().properties.template.contentVersion
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: isProduction
  }
}

@description('Deploy the App Service Plan used for Logic App Standard')
resource lgAppServicePlanDeploy 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: lgApplicationAppServicePlanName
  location: location
  tags: {
    Application: applicationName
    Environment: env
    Version: deployment().properties.template.contentVersion
  }
  kind: 'elastic'
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
    size: 'WS1'
    family: 'WS'
    capacity: 1
  }
}

@description('Deploy the Storage Account used for Logic App Standard')
resource lgStorageAccountDeploy 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: lgStorageAccountName
  location: location
  tags: {
    Application: applicationName
    Environment: env
    Version: deployment().properties.template.contentVersion
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    defaultToOAuthAuthentication: true
  }
}

@description('Deploy the Application Standard Logic App')
resource applicationLogicAppStandardDeploy 'Microsoft.Web/sites@2022-09-01' = {
  name: applicationLogicAppName
  location: location
  tags: {
    Application: applicationName
    Environment: env
    Version: deployment().properties.template.contentVersion
  }
  kind: 'functionapp,workflowapp'
  properties: {
    serverFarmId: lgAppServicePlanDeploy.id
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
  }
  resource config 'config@2022-09-01' = {
    name: 'appsettings'
    properties: {
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'node'
      WEBSITE_NODE_DEFAULT_VERSION: '~18'
      AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${lgStorageAccountDeploy.name};AccountKey=${listKeys(lgStorageAccountDeploy.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${lgStorageAccountDeploy.name};AccountKey=${listKeys(lgStorageAccountDeploy.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
      WEBSITE_CONTENTSHARE: lgStorageAccountDeploy.name
      AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
      AzureFunctionsJobHost__extensionBundle__version: '${'[1.*,'}${' 2.0.0)'}'
      APP_KIND: 'workflowApp'
    }
  }
}

// ** Outputs **
// *************

output keyVaultName string = applicationKeyVaultName
output applicationLogicAppName string  = applicationLogicAppName
