/********************************************************
Bicep Template: Logic App Standard APIM API With Swagger
        Author: Andrew Wilson
********************************************************/

targetScope = 'resourceGroup'

// ** User Defined Types **
// ************************

@description('Configuration properties for setting up a LG App stnd APIM API Operation')
@metadata({
  name: 'Name of the API Operation'
  lgWorkflowName: 'Name of the Standard Logic App Workflow to use for the Operation Backend'
  lgWorkflowTrigger: 'Name of the Workflow HTTP Trigger'
})
@sealed()
type apimAPIOperation = {
  name: string
  lgWorkflowName: string
  lgWorkflowTrigger: string
}

@description('One or more APIM API Operations to configure')
@minLength(1)
type apimAPIOperationArray = apimAPIOperation[]

// ** Parameters **
// ****************

@description('Name of the Logic App to add as a backend')
param logicAppName string

@description('Name of the APIM instance')
param apimInstanceName string

@description('Name of the Key Vault instance')
param keyVaultName string

@description('Name of the API to create in APIM')
param apiName string

@description('APIM API path')
param apimAPIPath string

@description('APIM API display name')
param apimAPIDisplayName string

@description('Array of API operations')
param apimAPIOperations apimAPIOperationArray

// ** Variables **
// ***************

// Logic App Base URL
var lgBaseUrl = 'https://${logicApp.properties.defaultHostName}/api'

// Key Vault Read Access
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

// All Operations Policy
var apimAPIPolicyRaw = loadTextContent('./APIM-Policies/APIMAllOperationsPolicy.xml')
var apimAPIPolicy = replace(apimAPIPolicyRaw, '__apiName__', apiName)

// Operation Policy Template
var apimOperationPolicyRaw = loadTextContent('./APIM-Policies/APIMOperationPolicy.xml')

// Load Swagger Definition
// TODO: Specify your own path to the GeneratedSpec.json
var swaggerDefinition = loadTextContent('../../SwaggerGenerator/GeneratedSpec.json')

// ** Resources **
// ***************

@description('Retrieve the existing APIM Instance, will add APIs and Policies to this resource')
resource apimInstance 'Microsoft.ApiManagement/service@2022-08-01' existing = {
  name: apimInstanceName
}

@description('Create the Logic App API in APIM - Loading in Swagger Definition')
resource logicAppAPI 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  name: apiName
  parent: apimInstance
  properties: {
    displayName: apimAPIDisplayName
    subscriptionRequired: true
    path: apimAPIPath
    protocols: [
      'https'
    ]
    format: 'swagger-json'
    value: swaggerDefinition
  }
}

@description('Retrieve the existing Logic App for linking as a backend')
resource logicApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: logicAppName
}

@description('Retrieve the existing application Key Vault instance')
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

@description('Retrieve the existing logicapp workflow sig secret')
resource vaultLogicAppKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = [for operation in apimAPIOperations: {
  name: '${logicAppName}-${operation.lgWorkflowName}-sig'
  parent: keyVault
}]

@description('Grant APIM Key Vault Reader for the logic app API key secret')
resource grantAPIMPermissionsToSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (operation, index) in apimAPIOperations: {
  name: guid(keyVaultSecretsUserRoleDefinitionId, keyVault.id, operation.lgWorkflowName)
  scope: vaultLogicAppKey[index]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleDefinitionId)
    principalId: apimInstance.identity.principalId
    principalType: 'ServicePrincipal'
  }
}]

@description('Create the named values for the logic app API sigs')
resource logicAppBackendNamedValues 'Microsoft.ApiManagement/service/namedValues@2022-08-01' = [for (operation, index) in apimAPIOperations: {
  name: '${apiName}-${operation.name}-sig'
  parent: apimInstance
  properties: {
    displayName: '${apiName}-${operation.name}-sig'
    tags: [
      'sig'
      'logicApp'
      '${apiName}'
      '${operation.name}'
    ]
    secret: true
    keyVault: {
      identityClientId: null
      secretIdentifier: '${keyVault.properties.vaultUri}secrets/${vaultLogicAppKey[index].name}'
    }
  }
  dependsOn: [
    grantAPIMPermissionsToSecret
  ]
}]

@description('Create the backend for the Logic App API')
resource logicAppBackend 'Microsoft.ApiManagement/service/backends@2022-08-01' = {
  name: apiName
  parent: apimInstance
  properties: {
    protocol: 'http'
    url: lgBaseUrl
    resourceId: uri(environment().resourceManager, logicApp.id)
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

@description('Create a policy for the logic App API and all its operations - linking the logic app backend')
resource logicAppAPIAllOperationsPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' = {
  name: 'policy'
  parent: logicAppAPI
  properties: {
    value: apimAPIPolicy
    format: 'xml'
  }
  dependsOn: [
    logicAppBackend
  ]
}

@description('Add query strings via policy')
module operationPolicy './Modules/apimOperationPolicy.azuredeploy.bicep' = [for (operation, index) in apimAPIOperations: {
  name: 'operationPolicy-${operation.name}'
  params: {
    parentStructureForName: '${apimInstance.name}/${logicAppAPI.name}/${operation.name}'
    rawPolicy: apimOperationPolicyRaw
    apiVersion: listCallbackUrl(resourceId('Microsoft.Web/sites/hostruntime/webhooks/api/workflows/triggers', logicAppName, 'runtime', 'workflow', 'management', operation.lgWorkflowName, operation.lgWorkflowTrigger), '2022-09-01').queries['api-version']
    sp: listCallbackUrl(resourceId('Microsoft.Web/sites/hostruntime/webhooks/api/workflows/triggers', logicAppName, 'runtime', 'workflow', 'management', operation.lgWorkflowName, operation.lgWorkflowTrigger), '2022-09-01').queries.sp
    sv: listCallbackUrl(resourceId('Microsoft.Web/sites/hostruntime/webhooks/api/workflows/triggers', logicAppName, 'runtime', 'workflow', 'management', operation.lgWorkflowName, operation.lgWorkflowTrigger), '2022-09-01').queries.sv
    sig: '{{${apiName}-${operation.name}-sig}}'
  }
}]

// ** Outputs **
// *************
