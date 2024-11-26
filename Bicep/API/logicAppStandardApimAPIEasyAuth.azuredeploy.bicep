/****************************************************
Bicep Template: Logic App Standard APIM API Easy Auth 
        Author: Andrew Wilson
*****************************************************/

targetScope = 'resourceGroup'

// ** User Defined Types **
// ************************

@description('Configuration properties for setting up a LG App stnd APIM API Operation')
@metadata({
  name: 'Name of the API Operation'
  displayName: 'User friendly name of the API Operation'
  method: 'The API Operations HTTP method'
  path: 'APIM API Operation path that will be replaced with backend implementation through policy. Relative Paths included and matching Logic App.'
  lgWorkflowName: 'Name of the Standard Logic App Workflow to use for the Operation Backend'
  lgWorkflowTrigger: 'Name of the Workflow HTTP Trigger'
})
@sealed()
type apimAPIOperation = {
  name: string
  displayName: string
  method: 'GET' | 'PUT' | 'POST' | 'PATCH' | 'DELETE'
  path: string
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

@description('Name of the API to create in APIM')
param apiName string

@description('APIM API path')
param apimAPIPath string

@description('APIM API display name')
param apimAPIDisplayName string

@description('Array of API operations')
param apimAPIOperations apimAPIOperationArray

@description('Logic App Easy Auth Client Id')
param logicAppEasyAuthClientId string

// ** Variables **
// ***************

// Logic App Base URL
var lgBaseUrl = 'https://${logicApp.properties.defaultHostName}/api'

// All Operations Policy
var apimAPIPolicyRaw = loadTextContent('./APIM-Policies/EasyAuth/APIMAllOperationsPolicy.xml')
var apimAPIPolicy = replace(apimAPIPolicyRaw, '__apiName__', apiName)

// Operation Policy Template
var apimOperationPolicyRaw = loadTextContent('./APIM-Policies/EasyAuth/APIMOperationPolicy.xml')

// APIM Managed Identity Authentication Policy Fragment Template
var apimMIAuthFragPolicy = loadTextContent('./APIM-Policies/EasyAuth/APIMManagedIdentityAuthentication.PolicyFragment.xml')

// ** Resources **
// ***************

@description('Retrieve the existing APIM Instance, will add APIs and Policies to this resource')
resource apimInstance 'Microsoft.ApiManagement/service@2022-08-01' existing = {
  name: apimInstanceName
}

@description('Create the Logic App API in APIM')
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
  }
}

@description('Retrieve the existing Logic App for linking as a backend')
resource logicApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: logicAppName
}

@description('Apply AuthSettingsV2 Easy Auth for Logic App')
module logicAppEasyAuthConfig 'Modules/applicationSecurityConfig.azuredeploy.bicep' = {
  name: 'logicAppEasyAuthConfig'
  params: {
    apimInstanceName: apimInstance.name
    applicationLogicAppName: logicApp.name
    logicAppEasyAuthClientId: logicAppEasyAuthClientId
  }
}

@description('Deploy logic App API operation')
module logicAppAPIOperation 'Modules/apimOperation.azuredeploy.bicep' = [for operation in apimAPIOperations: {
  name: '${operation.name}-deploy'
  params: {
    parentName: '${apimInstance.name}/${logicAppAPI.name}'
    lgCallBackObject: listCallbackUrl(resourceId('Microsoft.Web/sites/hostruntime/webhooks/api/workflows/triggers', logicAppName, 'runtime', 'workflow', 'management', operation.lgWorkflowName, operation.lgWorkflowTrigger), '2022-09-01')
    operationDisplayName: operation.displayName
    operationMethod: operation.method
    operationPath: operation.path
    operationName: operation.name
  }
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

@description('APIM System Assigned Managed Identity Authentication Policy Fragment')
resource apimMIAuthPolicyFragment 'Microsoft.ApiManagement/service/policyFragments@2022-08-01' = {
  name: 'MIAuthFrag'
  parent: apimInstance
  properties: {
    value: apimMIAuthFragPolicy
    description: 'APIM System Assigned Managed Identity Authentication Policy Fragment'
    format: 'xml'
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
    apimMIAuthPolicyFragment
  ]
}

@description('Add query strings and workflow endpoint via policy')
module operationPolicy './Modules/apimOperationPolicy.azuredeploy.bicep' = [for (operation, index) in apimAPIOperations: {
  name: 'operationPolicy-${operation.name}'
  params: {
    parentStructureForName: '${apimInstance.name}/${logicAppAPI.name}/${operation.name}'
    rawPolicy: apimOperationPolicyRaw
    lgCallBackObject: listCallbackUrl(resourceId('Microsoft.Web/sites/hostruntime/webhooks/api/workflows/triggers', logicAppName, 'runtime', 'workflow', 'management', operation.lgWorkflowName, operation.lgWorkflowTrigger), '2022-09-01')
  }
  dependsOn: [
    logicAppAPIOperation
  ]
}]

// ** Outputs **
// *************
