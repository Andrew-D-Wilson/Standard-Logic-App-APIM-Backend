/********************************************
Bicep Template: APIM LG API Operation Policy
        Author: Andrew Wilson
********************************************/

targetScope = 'resourceGroup'

// ** Parameters **
// ****************

@description('The Parent naming structure for the Policy')
param parentStructureForName string

@description('The raw policy document template')
param rawPolicy string

@description('The Logic App service API version')
param apiVersion string

@description('The Logic App workflow permissions')
param sp string

@description('The Logic App workflow version number of the query parameters')
param sv string

@description('The named value name for the workflow sig')
param sig string

// ** Variables **
// ***************

var policyApiVersion = replace(rawPolicy, '__api-version__', apiVersion)
var policySP = replace(policyApiVersion, '__sp__', sp)
var policySV = replace(policySP, '__sv__', sv)
var policySIG = replace(policySV, '__sig__', sig)


// ** Resources **
// ***************

@description('Add query strings via policy')
resource operationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2022-08-01' = {
  name: '${parentStructureForName}/policy'
  properties: {
    value: policySIG
    format: 'xml'
  }
}

// ** Outputs **
// *************
