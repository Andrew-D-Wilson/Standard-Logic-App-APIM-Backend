# Logic App (Standard) APIM Backend

[![GitHub Issues][badge_issues]][link_issues]
[![GitHub Stars][badge_repo_stars]][link_repo]
[![Repo Language][badge_language]][link_repo]
[![Repo License][badge_license]][link_repo]

[badge_issues]: https://img.shields.io/github/issues/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend?style=for-the-badge
[link_issues]: https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/issues
[badge_repo_stars]: https://img.shields.io/github/stars/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend?logo=github&style=for-the-badge
[badge_language]: https://img.shields.io/badge/language-Bicep/PowerShell-blue?style=for-the-badge
[badge_license]: https://img.shields.io/github/license/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend?style=for-the-badge
[link_repo]: https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend

This repository contains configurable and secure methods in setting up the front-to-backend routing in APIM for Logic Apps Standard. 

I have specified three approaches with the same overall aim but with varying degrees of configurability and security:
1. Using Logic App SAS Sig Key and Configuration through Bicep ONLY.
   - See Blog Post for more details: [Azure API Management | Logic App (Standard) Backend](https://andrewilson.co.uk/post/2024/01/standard-logic-app-apim-backend/)
2. Using Logic App SAS Sig Key and Configuration through Swagger Generation and Bicep.
   - See Blog Post for more details: [Azure API Management | Logic App (Standard) Backend Using a Swagger Definition](https://andrewilson.co.uk/post/2024/02/standard-logic-app-apim-backend-swagger/)
3. Using Logic App Easy Auth and Configuration through Bicep ONLY.
   - See Blog Post for more details: [Easy Auth | Standard Logic App with Azure API Management](https://andrewilson.co.uk/post/2024/02/standard-logic-app-easy-auth-apim/)

## Getting started
Depending on the configuration approach that you would like to take, the steps involved will differ slightly.

In all cases you will need to deploy the Application first and then the API.

### Getting started: SAS Sig Key and Bicep Only Configuration
1. Application Deployment
   1. Deploy the Application Services into Azure
      1. Update the [Application Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/application.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/application.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/application.azuredeploy.bicepparam).
      3. Deploy the Application Template to Azure.
   2. Deploy the demo [Standard Logic App](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/tree/main/Application) to the Standard Logic App you deployed into Azure in step 1.
   3. Deploy Application Secrets to KeyVault
      1.  Update the [Application Secrets Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/applicationSecrets.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/applicationSecrets.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/applicationSecrets.azuredeploy.bicepparam).
      3. Deploy the Application Secrets Template to Azure.
2. APIM and API Deployment
   1. Deploy an APIM Instance into Azure
      1. Update the [APIM Instance Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/apimInstance.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/apimInstance.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/apimInstance.azuredeploy.bicepparam).
      3. Deploy the APIM Instance Template to Azure.
   2. Deploy the APIM API with the recently deployed Logic App as the Backend.
      1. Update the [Logic App APIM API Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/logicAppStandardApimAPI.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/logicAppStandardApimAPI.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/logicAppStandardApimAPI.azuredeploy.bicepparam).
      3. Deploy the Logic App APIM API Template to Azure.

You will now be in a position to call your APIM API which will be using the Standard Logic App as its backend.

### Getting started: SAS Sig Key and Swagger Definition

As a prerequisite to running the swagger generator, you will need to have installed the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).

1. Application Deployment
   1. Deploy the Application Services into Azure
      1. Update the [Application Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/application.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/application.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/application.azuredeploy.bicepparam).
      3. Deploy the Application Template to Azure.
   2. Deploy the demo [Standard Logic App](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/tree/main/Application) to the Standard Logic App you deployed into Azure in step 1.
   3. Deploy Application Secrets to KeyVault
      1.  Update the [Application Secrets Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/applicationSecrets.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/applicationSecrets.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/applicationSecrets.azuredeploy.bicepparam).
      3. Deploy the Application Secrets Template to Azure.
   4. Generate Swagger Definition
      1. Update the [ControlFile](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/SwaggerGenerator/ControlFile.json) to represent the Logic App and its workflows that you have deployed into Azure.
      2. Run the [SpecCreator.ps1](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/SwaggerGenerator/SpecCreator.ps1) script providing the respective parameters. Use the interactive parameter switch to conduct an interactive login with the az tooling.
      3. After a successful run, you will find a "GeneratedSpec.json" file in the same folder location as the SpecCreator script.
2. APIM and API Deployment
   1. Deploy an APIM Instance into Azure
      1. Update the [APIM Instance Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/apimInstance.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/apimInstance.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/apimInstance.azuredeploy.bicepparam).
      3. Deploy the APIM Instance Template to Azure.
   2. Deploy the APIM API with the recently deployed Logic App as the Backend (Using the created Swagger Definition).
      1. Update the [Logic App APIM API with Swagger Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/logicAppStandardApimAPIWithSwagger.azuredeploy.bicepparam)
      2. **If** you moved the generated swagger file, you will need to update the [Bicep Template (line 56)](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/d968591f6716341e6302ae91e518ed0dc594ff63/Bicep/API/logicAppStandardApimAPIWithSwagger.azuredeploy.bicep#L56) to point to the new location.
      3. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/logicAppStandardApimAPIWithSwagger.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/logicAppStandardApimAPIWithSwagger.azuredeploy.bicepparam).
      4. Deploy the Logic App APIM API Template to Azure.

You will now be in a position to call your APIM API which will be using the Standard Logic App as its backend.

### Getting started: Using Logic App Easy Auth and Configuration through Bicep ONLY.
1. Application Deployment
   1. Deploy the Application Services into Azure
      1. Update the [Application Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/application.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/application.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/Application/application.azuredeploy.bicepparam).
      3. Deploy the Application Template to Azure.
   2. Deploy the demo [Standard Logic App](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/tree/main/Application) to the Standard Logic App you deployed into Azure in step 1.
2. APIM and API Deployment
   1. Deploy an APIM Instance into Azure
      1. Update the [APIM Instance Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/apimInstance.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/apimInstance.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/apimInstance.azuredeploy.bicepparam).
      3. Deploy the APIM Instance Template to Azure.
   2. Deploy the APIM API with the recently deployed Logic App as the Backend.
      1. Update the [Logic App APIM API Bicep Parameters from their defaults](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/logicAppStandardApimAPIEasyAuth.azuredeploy.bicepparam)
      2. Build both the [Bicep Template](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/logicAppStandardApimAPIEasyAuth.azuredeploy.bicep) and [Bicep Parameter File](https://github.com/Andrew-D-Wilson/Standard-Logic-App-APIM-Backend/blob/main/Bicep/API/logicAppStandardApimAPIEasyAuth.azuredeploy.bicepparam).
      3. Deploy the Logic App APIM API Template to Azure.

You will now be in a position to call your APIM API which will be using the Standard Logic App as its backend.

## Author
👤 Andrew Wilson

[![Website][badge_blog]][link_blog]
[![LinkedIn][badge_linkedin]][link_linkedin]

[![Twitter][badge_twitter]][link_twitter]
[![BlueSky][badge_bluesky]][link_bluesky]


## License
The Standard Logic App APIM Backend is made available under the terms and conditions of the [MIT license](LICENSE).

[badge_blog]: https://img.shields.io/badge/blog-andrewilson.co.uk-blue?style=for-the-badge
[link_blog]: https://andrewilson.co.uk/

[badge_linkedin]: https://img.shields.io/badge/LinkedIn-Andrew%20Wilson-blue?style=for-the-badge&logo=linkedin
[link_linkedin]: https://www.linkedin.com/in/andrew-wilson-792345106

[badge_twitter]: https://img.shields.io/badge/follow-%40Andrew__DWilson-blue?logo=twitter&style=for-the-badge&logoColor=white
[link_twitter]: https://twitter.com/Andrew_DWilson

[badge_bluesky]: https://img.shields.io/badge/Bluesky-%40andrewilson.co.uk-blue?logo=bluesky&style=for-the-badge&logoColor=white
[link_bluesky]: https://bsky.app/profile/andrewilson.co.uk
