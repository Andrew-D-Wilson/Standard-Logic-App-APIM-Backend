# Logic App (Standard) APIM Backend

## Overview
This repository contains my approach to a configurable and secure method in setting up the front-to-backend routing in APIM for Logic Apps Standard. 

I have specified two approaches with the same overall aim but with varying degrees of configurability:
1. Configuration through Bicep ONLY.
2. Configuration through Swagger Generation and Bicep.

The high level architecture diagram is shown below:

![Architecture-Overview](https://andrewilson.co.uk/images/posts/2024/01/Overview.png)

The overall design aims to abstract the backend from the api operations, i.e. the backend points to the Logic App and the individual operations point to the respective workflows. The design also specifies granular access to the workflow Shared-Access-Signature (sig) held in the applications specific KeyVault (to see further details on this, see Azure RBAC Key Vault | Role Assignment for Specific Secret). Furthermore, the additional required parameters that are necessary to call a workflow have been implemented through APIM policies to remove the need for callers to understand backend implementation.

I have opted for Infrastructure as Code (IaC) as my method of implementation, specifically Bicep. I have broken down the implementation of the diagram above into two parts, Application Deployment, and API Deployment.

### Application Architecture and Steps (Bicep Only)
![Application-Overview](https://andrewilson.co.uk/images/posts/2024/01/Application-Deployment.png)

### API Architecture and Steps (Bicep Only)
![API-Overivew](https://andrewilson.co.uk/images/posts/2024/01/API-Deployment.png)

### Application Architecture and Steps (With Swagger Generation)
![Application-Overview](https://andrewilson.co.uk/images/posts/2024/01/Application-Deployment-Swagger.png)

### API Architecture and Steps (With Swagger Definition)
![API-Overivew](https://andrewilson.co.uk/images/posts/2024/01/API-Deployment-with-Swagger.png)

## Getting started

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
