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

@description('The named value name for the workflow sig')
param sig string = ''

@description('Logic App Call Back object containing URL and other details')
param lgCallBackObject object

// ** Variables **
// ***************

var operationUrlBase = split(split(lgCallBackObject.value, '?')[0], '/api')[1]
var hasRelativePath = lgCallBackObject.?relativePath != null ? true : false
var RelativePathHasBeginingSlash = hasRelativePath ? first(lgCallBackObject.relativePath) == '/' : false
var operationUrl = hasRelativePath && RelativePathHasBeginingSlash ? '${operationUrlBase}${lgCallBackObject.relativePath}' : hasRelativePath && !RelativePathHasBeginingSlash ? '${operationUrlBase}/${lgCallBackObject.relativePath}' : operationUrlBase

var policyURI = replace(rawPolicy, '__uri__', operationUrl)
var policyApiVersion = replace(policyURI, '__api-version__', lgCallBackObject.queries['api-version'])
var policySP = replace(policyApiVersion, '__sp__', lgCallBackObject.queries.sp)
var policySV = replace(policySP, '__sv__', lgCallBackObject.queries.sv)
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
