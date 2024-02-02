<#
    .SYNOPSIS
	Creates a Swagger definition for a select Standard Logic App and its specified Workflows.

    .DESCRIPTION
	Uses a series of parameters to derive the Standard Logic App and the Workflows to include in the base Swagger definition template. 

    .PARAMETER SubscriptionId
    The ID of the Subscription that the Standard Logic App is Hosted in.

    .PARAMETER ResourceGroupName
    The Resource Group Name that the Standard Logic App is Hosted in.

    .PARAMETER LogicAppName
    The Name of the Standard Logic App to use for the Swagger Definition.

    .PARAMETER APITitle
    API Name used to define the set of operations.

    .PARAMETER APIDescription
    Description of the API and its set of operations.

    .PARAMETER APIVersion
    None-Mandatory - Specified version of the API. Default is 1.0.0.0

    .PARAMETER SpecTemplatePath
    None-Mandatory - Base path to the swagger definition template, doesn't include the name of the file.

    .PARAMETER ControlFile
    None-Mandatory - Base path to the json control file used to identify the set of Workflows to extract as operations for the swagger definition, doesn't include the name of the file.

	.PARAMETER InteractiveMode
	If specified will request the user to interactively login into Azure for az tooling.

	.NOTES 
	Author: Andrew Wilson
    #>
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string]$SubscriptionId,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string]$ResourceGroupName,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string]$LogicAppName,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string]$APITitle,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string]$APIDescription,

	[ValidateScript( { $_ -match '\d.\d.\d.\d' })]
	[string]$APIVersion = '1.0.0.0',

	[ValidateScript( { Test-Path $_ })]
	[ValidateNotNullOrEmpty()]
	[string]$SpecTemplatePath = $PSScriptRoot,

	[ValidateScript( { Test-Path $_ })]
	[ValidateNotNullOrEmpty()]
	[string]$ControlFile = $PSScriptRoot,

	[switch]$InteractiveMode
)

# Setup strict mode and stop on error
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

Write-Host '--| Starting LG Standard Swagger Generation |--'

$logicAppWorkflowBase = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Web/sites/{2}' -f $SubscriptionId, $ResourceGroupName, $LogicAppName
Write-Debug ('logicAppWorkflowBase: {0}' -f $logicAppWorkflowBase)

# 0 relative path
# 1 triggerMethod
# 2 OperationName
# 3 BodyDescription
$apiPath = '"{0}": {{
	"{1}": {{
	  "deprecated": false,
	  "description": "Trigger a run of the logic app.",
	  "operationId": "{2}",
	  "parameters": [
	{3}
	  ],
	  "responses": {{
		"default": {{
		  "description": "The Logic App Response.",
		  "schema": {{
			"type": "object"
		  }}
		}}
	  }}
	}}
  }}'

# Import the json control file
$controlFilePath = Join-Path -Path $ControlFile -ChildPath 'ControlFile.json'
Write-Debug ('controlFilePath: {0}' -f $controlFilePath)
if (!(Test-Path $controlFilePath)) {
	# the file doesn't exist
	throw "ControlFile provided does not exist"
}
else {
	try {
		Write-Verbose 'Importing Control File'
		$controlData = Get-Content $controlFilePath -Encoding UTF8 -Raw | ConvertFrom-Json
	}
	catch {
		$ErrorMessage = $_
		Write-Error $ErrorMessage
	}
}

Write-Debug '--| Control File |--'
Write-Debug ($controlData | Out-String)
Write-Debug '---------------------'

# az login and set subscription scope
Write-Debug ('InteractiveMode: {0}' -f $InteractiveMode)
if ($InteractiveMode) {
	Write-Verbose 'Running as interactive.'
	try {
		az login
	}
	catch {
		$ErrorMessage = $_
		Write-Error $ErrorMessage
	}
}

try {
	Write-Verbose 'Setting Subscription Scope'
	Write-Debug ('SubscriptionId: {0}' -f $SubscriptionId)
	$response = az account set --subscription $SubscriptionId 2>&1
	Write-Debug ('response: {0}' -f $response)
	if ($response -like "*ERROR*") {
		throw $response
	}
}
catch {
	$ErrorMessage = $_
	Write-Error $ErrorMessage
}

$specTempPath = Join-Path -Path $SpecTemplatePath -ChildPath 'SpecTemplate.txt'
Write-Debug ('SpecTemplatePath: {0}' -f $specTempPath)
if (!(Test-Path $specTempPath)) {
	# the file doesn't exist
	throw "specTemplate provided does not exist"
}
else {
	try {
		Write-Verbose 'Importing specTemplate'
		$specDocument = Get-Content -Path $specTempPath
	}
	catch {
		$ErrorMessage = $_
		Write-Error $ErrorMessage
	}
}

# Generate swagger info
Write-Verbose 'Generate swagger info'
$specDocument = $specDocument.Replace('__APITitle__', $APITitle)
$specDocument = $specDocument.Replace('__APIDescription__', $APIDescription)
$specDocument = $specDocument.Replace('__APIVersion__', $APIVersion)

Write-Verbose 'Loop through workflows'
$apiPaths = @()
$schemaDefinitions = @()
foreach ($workflow in $controlData) {
	# Get LG Schema
	Write-Verbose ('Retrieve Workflow {0} Schema' -f $workflow.WorkflowDefinitionName)
	$logicAppSchemaUrl = '{0}/hostruntime/runtime/webhooks/workflow/api/management/workflows/{1}/triggers/{2}/schemas/json?api-version=2022-03-01' -f $logicAppWorkflowBase, $workflow.WorkflowDefinitionName, $workflow.HTTPTriggerName
	Write-Debug ('logicAppSchemaUrl: {0}' -f $logicAppSchemaUrl)
	
	$schema = az rest -m GET -u $logicAppSchemaUrl | Out-String
	Write-Debug ('schema: {0}' -f $schema)

	# Get workflow definition
	Write-Verbose ('Get workflow {0} definition' -f $workflow.WorkflowDefinitionName)
	$logicAppWorkflowUrl = "{0}/workflows/{1}?api-version=2020-12-01" -f $logicAppWorkflowBase, $workflow.WorkflowDefinitionName
	Write-Debug ('logicAppWorkflowUrl: {0}' -f $logicAppWorkflowUrl)
	$logicAppWorkflow = (az rest -m GET -u $logicAppWorkflowUrl) | ConvertFrom-Json
	Write-Debug ('logicAppWorkflow: {0}' -f ($logicAppWorkflow))

	$triggerMethod = 'get'
	$relativePath = ''
	$relativePathBase = "/{0}/triggers/{1}/invoke/" -f $workflow.WorkflowDefinitionName, $workflow.HTTPTriggerName
	$bodyDescription = ''
	$pathParametersArray = @()
	try {
		$logicAppWorkflow = $logicAppWorkflow.properties.files.'workflow.json'.definition.triggers."$($workflow.HTTPTriggerName)".inputs
		Write-Debug ($logicAppWorkflow)
	
		try {
			$triggerMethod = $logicAppWorkflow.method
		}
		catch {
			Write-Verbose 'No Method stated'
		}

		Write-Debug ('triggerMethod: {0}' -f $triggerMethod)
	
		try {
			$relativePath = $logicAppWorkflow.relativePath
		}
		catch {
			Write-Verbose 'No relative path'
		}

		Write-Debug ('relativePath: {0}' -f $relativePath)

		if (($triggerMethod -ne 'get') -and (![string]::IsNullOrEmpty($schema))) {
			$schemaDefinition = '"{0}request-manual": {1}' -f $workflow.WorkflowDefinitionName, $schema
			$bodyDescription = '{{
			  "description": "The request body.",
			  "in": "body",
			  "name": "body",
			  "required": false,
			  "schema": {{
				"$ref": "#/definitions/{0}request-manual"
			  }}
			}}' -f $workflow.WorkflowDefinitionName

			Write-Debug ('schemaDefinition: {0}' -f $schemaDefinition)
			$schemaDefinitions += $schemaDefinition
			Write-Debug ('bodyDescription: {0}' -f $bodyDescription)
			$pathParametersArray += $bodyDescription
		}
	}
	catch {
		Write-Verbose 'No inputs found'
	}

	if (![string]::IsNullOrEmpty($relativePath)) {
		$pathParameters = Select-String '({[A-Za-z0-9]+})' -input $relativePath -AllMatches | ForEach-Object { $_.matches } | ForEach-Object { $_.groups[1].value.Replace('{','').Replace('}','')}
		Write-Debug ('pathParameters: {0}' -f $pathParameters)

		foreach ($parameter in $pathParameters) {
			if (![string]::IsNullOrEmpty($parameter)) {
				$parameterString = '{{
				"description": "Path Parameter {0}",
				"in": "path",
				"name": "{1}",
				"required": true,
				"type": "string"
			  }}' -f $parameter, $parameter

				$pathParametersArray += $parameterString
			}
		}
		$relativePath = (Join-Path -Path $relativePathBase -ChildPath $relativePath).Replace('\', '/')
	}
	else {
		$relativePath = $relativePathBase
	}
	
	$parameters = $pathParametersArray -join ","

	$populatedApiPath = $apiPath -f $relativePath, $triggerMethod.ToLower(), $workflow.OperationName, $parameters
	$apiPaths += $populatedApiPath

}

$apiPathsString = $apiPaths -join ","
Write-Debug $apiPathsString
$schemasDefinitionsString = $schemaDefinitions -join ","
Write-Debug $schemasDefinitionsString

$specDocument = $specDocument.Replace('__paths__', $apiPathsString)
$specDocument = $specDocument.Replace('__SchemaDefinitions__', $schemasDefinitionsString)

$ouputFilePath = Join-Path -Path $SpecTemplatePath -ChildPath 'GeneratedSpec.json'
Write-Host '--| Finished LG Standard Swagger Generation |--'
Write-Debug ($specDocument | Out-String)
$specDocument | Out-File -FilePath $ouputFilePath -Encoding utf8