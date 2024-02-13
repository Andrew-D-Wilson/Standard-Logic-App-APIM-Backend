using './logicAppStandardApimAPIWithSwagger.azuredeploy.bicep'

param logicAppName = 'ap1devlogic'
param apimInstanceName = 'apidevapim'
param keyVaultName = 'ap1devkv'
param apiName = 'lgsAPI2'
param apimAPIPath = '/appapi2'
param apimAPIDisplayName = 'ApplicationAPI2'
param apimAPIOperations = [
  {
    name: 'Workflow1Op'
    path: '/test1/{customerId}'
    lgWorkflowName: 'Workflow1'
    lgWorkflowTrigger: 'When_a_HTTP_request_is_received'
  }
  {
    name: 'Workflow2Op'
    path: '/test2/'
    lgWorkflowName: 'Workflow2'
    lgWorkflowTrigger: 'When_a_HTTP_request_is_received'
  }
]

