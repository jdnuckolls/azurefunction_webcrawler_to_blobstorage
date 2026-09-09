param(
    [Parameter(Mandatory = $true)]
    [string] $SearchServiceName,

    [Parameter(Mandatory = $true)]
    [string] $AdminKey,

    [Parameter(Mandatory = $true)]
    [string] $StorageConnectionString,

    [Parameter(Mandatory = $true)]
    [string] $AzureOpenAIEndpoint,

    [Parameter(Mandatory = $true)]
    [string] $AzureOpenAIKey,

    [Parameter(Mandatory = $true)]
    [string] $AzureOpenAIEmbeddingDeployment,

    [string] $ContentContainerName = "content",
    [string] $SearchIndexName = "website-knowledge-chunks",
    [string] $DataSourceName = "website-blob-source",
    [string] $SkillsetName = "website-vectorization-skillset",
    [string] $IndexerName = "website-blob-indexer",
    [string] $ApiVersion = "2024-07-01"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$endpoint = "https://$SearchServiceName.search.windows.net"
$headers = @{
    "Content-Type" = "application/json"
    "api-key" = $AdminKey
}

function Convert-Template {
    param([string] $Path)

    $json = Get-Content -LiteralPath $Path -Raw
    $json = $json.Replace("{{storageConnectionString}}", $StorageConnectionString)
    $json = $json.Replace("{{contentContainerName}}", $ContentContainerName)
    $json = $json.Replace("{{azureOpenAIEndpoint}}", $AzureOpenAIEndpoint)
    $json = $json.Replace("{{azureOpenAIKey}}", $AzureOpenAIKey)
    $json = $json.Replace("{{azureOpenAIEmbeddingDeployment}}", $AzureOpenAIEmbeddingDeployment)
    $json = $json.Replace("{{searchIndexName}}", $SearchIndexName)
    $json = $json.Replace("{{dataSourceName}}", $DataSourceName)
    $json = $json.Replace("{{skillsetName}}", $SkillsetName)
    $json = $json.Replace("{{indexerName}}", $IndexerName)
    return $json
}

$resources = @(
    @{ Path = "index.json"; Route = "indexes/$SearchIndexName" },
    @{ Path = "data-source.json"; Route = "datasources/$DataSourceName" },
    @{ Path = "skillset.json"; Route = "skillsets/$SkillsetName" },
    @{ Path = "indexer.json"; Route = "indexers/$IndexerName" }
)

foreach ($resource in $resources) {
    $body = Convert-Template -Path (Join-Path $root $resource.Path)
    $uri = "$endpoint/$($resource.Route)?api-version=$ApiVersion"
    Invoke-RestMethod -Method Put -Uri $uri -Headers $headers -Body $body | Out-Null
    Write-Host "Deployed $($resource.Route)"
}

Invoke-RestMethod -Method Post -Uri "$endpoint/indexers/$IndexerName/run?api-version=$ApiVersion" -Headers $headers | Out-Null
Write-Host "Started indexer $IndexerName"
