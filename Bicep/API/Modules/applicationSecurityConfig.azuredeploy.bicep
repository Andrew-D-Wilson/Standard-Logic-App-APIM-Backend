/******************************************************
Bicep Template: Application Security Config (Easy Auth)
        Author: Andrew Wilson
*******************************************************/

targetScope = 'resourceGroup'

// ** User Defined Types **
// ************************

// ** Parameters **
// ****************

@description('Name of the Logic App to Retrieve')
param applicationLogicAppName string

@description('Name of the APIM instance')
param apimInstanceName string

@description('Logic App Easy Auth Client Id')
param logicAppEasyAuthClientId string

// ** Variables **
// ***************

// ** Resources **
// ***************

@description('Retrieve Existing Standard Logic App')
resource applicationLogicAppStandardDeploy 'Microsoft.Web/sites@2024-04-01' existing = {
  name: applicationLogicAppName
}

@description('Retrieve the existing APIM Instance')
resource apimInstance 'Microsoft.ApiManagement/service@2022-08-01' existing = {
  name: apimInstanceName
}

@description('Setup the Easy Auth config settings for the Standard Logic App')
resource applicationAuthSettings 'Microsoft.Web/sites/config@2024-04-01' = {
  name: 'authsettingsV2'
  parent: applicationLogicAppStandardDeploy
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'AllowAnonymous'
    }
    httpSettings: {
      requireHttps: true
      routes: {
        apiPrefix: '/.auth'
      }
      forwardProxy: {
        convention: 'NoProxy'
      }
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          openIdIssuer: uri('https://sts.windows.net/', tenant().tenantId)
          clientId: logicAppEasyAuthClientId
          clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
        }
        validation: {
          allowedAudiences: environment().authentication.audiences
          defaultAuthorizationPolicy: {
            allowedPrincipals: {
              identities: [
                apimInstance.identity.principalId
              ]
            }
          }
        }
      }
    }
    platform: {
      enabled: true
      runtimeVersion: '~1'
    }
  }
}

// ** Outputs **
// *************
