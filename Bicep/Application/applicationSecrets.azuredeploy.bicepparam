using './applicationSecrets.azuredeploy.bicep'

param applicationLogicAppName = 'ap1devlogic'
param keyVaultName = 'ap1devkv'
param workflows = [
  {
    workflowName: 'Workflow1'
    workflowTrigger: 'When_a_HTTP_request_is_received'
  }
  {
    workflowName: 'Workflow2'
    workflowTrigger: 'When_a_HTTP_request_is_received'
  }
]

