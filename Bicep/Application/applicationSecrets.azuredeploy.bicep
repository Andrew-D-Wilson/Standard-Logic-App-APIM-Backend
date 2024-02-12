/*****************************************
Bicep Template: Application Secrets Deploy
        Author: Andrew Wilson
*****************************************/

targetScope = 'resourceGroup'

// ** User Defined Types **
// ************************

@description('Object type used to identify a Workflow and Trigger')
@metadata({
  workflowName: 'The name of the workflow within your Standard Logic App.'
  workflowTrigger: 'The HTTP trigger name within the workflow'
})
@sealed()
type workflow = {
  workflowName: string
  workflowTrigger: string
}

@description('Array of Standard Logic App Workflows')
@minLength(1)
type workflowArray = workflow[]

// ** Parameters **
// ****************

@description('Name of the Logic App to place workflow(s) sig into KeyVault')
param applicationLogicAppName string

@description('Name of the Key Vault to place secrets into')
param keyVaultName string

@description('Array of Workflows to obtain sigs from.')
param workflows workflowArray

// ** Variables **
// ***************

// ** Resources **
// ***************

@description('Retrieve the existing Logic App')
resource logicApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: applicationLogicAppName
}

@description('Retrieve the existing Key Vault instance to store secrets')
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

@description('Vault the Logic App workflow sig as a secret - Deployment principle requires RBAC permissions to do this')
resource vaultLogicAppKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for workflow in workflows: {
  name: '${logicApp.name}-${workflow.workflowName}-sig'
  parent: keyVault
  tags: {
    ResourceType: 'LogicAppStandard'
    ResourceName: logicApp.name
  }
  properties: {
    contentType: 'string'
    value: listCallbackUrl(resourceId('Microsoft.Web/sites/hostruntime/webhooks/api/workflows/triggers', logicApp.name, 'runtime', 'workflow', 'management', workflow.workflowName, workflow.workflowTrigger), '2022-09-01').queries.sig
  }
}]

// ** Outputs **
// *************
