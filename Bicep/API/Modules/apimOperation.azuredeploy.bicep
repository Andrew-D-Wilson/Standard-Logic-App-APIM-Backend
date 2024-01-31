/**********************************
Bicep Template: API Operation Deploy
        Author: Andrew Wilson
***********************************/

targetScope = 'resourceGroup'

// ** Parameters **
// ****************

@description('API Management Service API Name Path')
param parentName string

@description('Name of the API Operation')
param operationName string

@description('Display name for the API operation')
param operationDisplayName string

@description('API Operation Method e.g. GET')
param operationMethod string

@description('Logic App Call Back object containing URL and other details')
param lgCallBackObject object

// ** Variables **
// ***************

var operationUrlBase = split(split(lgCallBackObject.value, '?')[0], '/api')[1]
var hasRelativePath = lgCallBackObject.?relativePath != null ? true : false
var pathParametersList = hasRelativePath ? lgCallBackObject.relativePathParameters : []
var pathParameters = [for pathParameter in pathParametersList: {
    name: pathParameter
    type: 'string'
}]
var RelativePathHasBeginingSlash = hasRelativePath ? first(lgCallBackObject.relativePath) == '/' : false
var operationUrl = hasRelativePath && RelativePathHasBeginingSlash ? '${operationUrlBase}${lgCallBackObject.relativePath}' : hasRelativePath && !RelativePathHasBeginingSlash ? '${operationUrlBase}/${lgCallBackObject.relativePath}' : operationUrlBase

// ** Resources **
// ***************

@description('Deploy logic App API operation')
resource logicAppAPIGetOperation 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  name: '${parentName}/${operationName}'
  properties: {
    displayName: operationDisplayName
    method: operationMethod
    urlTemplate: operationUrl
    templateParameters: hasRelativePath ? pathParameters : null
  }
}

// ** Outputs **
// *************
