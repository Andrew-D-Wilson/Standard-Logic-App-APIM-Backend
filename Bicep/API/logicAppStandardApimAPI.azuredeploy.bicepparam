using './logicAppStandardApimAPI.azuredeploy.bicep'

param logicAppName = 'ap1devlogic'
param apimInstanceName = 'apidevapim'
param keyVaultName = 'ap1devkv'
param apiName = 'lgsAPI'
param apimAPIPath = '/appapi'
param apimAPIDisplayName = 'ApplicationAPI'
param apimAPIOperations = [
  {
    name: 'w1'
    displayName: 'Workflow1'
    method: 'GET'
    path: '/test1/'
    lgWorkflowName: 'Workflow1'
    lgWorkflowTrigger: 'When_a_HTTP_request_is_received'
  }
  {
    name: 'w2'
    displayName: 'Workflow2'
    method: 'GET'
    path: '/test2/'
    lgWorkflowName: 'Workflow2'
    lgWorkflowTrigger: 'When_a_HTTP_request_is_received'
  }
]

