[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Inputs,
    [Parameter(Mandatory)][string]$ReviewDirectory,
    [string]$Terraform = 'terraform'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$inputPath = (Resolve-Path -LiteralPath $Inputs).Path
$review = [IO.Path]::GetFullPath($ReviewDirectory)
if (Test-Path -LiteralPath $review) { throw 'Use a new private review directory; never overwrite a reviewed plan.' }
if ($env:TF_LOG -or $env:TF_CLI_ARGS -or $env:TF_CLI_ARGS_plan -or $env:TF_CLI_ARGS_init) {
    throw 'Unset Terraform logging and injected CLI arguments before private planning.'
}
$values = Get-Content -LiteralPath $inputPath -Raw | ConvertFrom-Json
if ($values.subscription_id -ne '82073da5-bd6d-4874-947e-73b791054cbc' -or
    $values.tenant_id -ne 'f5654adb-2a4c-4317-9217-09ef32ccdd3a') { throw 'Unexpected development tenant/subscription.' }
$version = & $Terraform version -json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $version.terraform_version -ne '1.16.5') { throw 'Use pinned Terraform 1.16.5.' }
New-Item -ItemType Directory -Path $review | Out-Null
$configuration = Join-Path $review 'configuration'
New-Item -ItemType Directory -Path $configuration | Out-Null
Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.tf' | Copy-Item -Destination $configuration
Copy-Item "$PSScriptRoot/../../.terraform.lock.hcl" (Join-Path $configuration '.terraform.lock.hcl')
Copy-Item $inputPath (Join-Path $review 'inputs.tfvars.json')
$state = (Join-Path $review 'bootstrap.tfstate').Replace('\', '/')
& $Terraform "-chdir=$configuration" init -input=false -lockfile=readonly "-backend-config=path=$state" -no-color *> (Join-Path $review 'init.log')
if ($LASTEXITCODE -ne 0) { throw 'Backend-local initialization failed; inspect the private log.' }
$plan = Join-Path $review 'bootstrap.tfplan'
& $Terraform "-chdir=$configuration" plan -input=false -lock-timeout=60s -no-color "-var-file=$(Join-Path $review 'inputs.tfvars.json')" "-out=$plan" *> (Join-Path $review 'plan.txt')
if ($LASTEXITCODE -ne 0) { throw 'Plan failed; inspect the private log. No apply was attempted.' }
& $Terraform "-chdir=$configuration" show -json $plan > (Join-Path $review 'plan.json')
if ($LASTEXITCODE -ne 0) { throw 'Plan inspection failed.' }
$document = Get-Content (Join-Path $review 'plan.json') -Raw | ConvertFrom-Json
foreach ($change in $document.resource_changes) {
    if (($change.change.actions -join ',') -ne 'create') { throw 'Bootstrap must be create-only; review unexpected ownership/drift.' }
}
$files = @{}
Get-ChildItem -LiteralPath $configuration -File | ForEach-Object { $files[$_.Name] = (Get-FileHash $_.FullName -Algorithm SHA256).Hash }
@{
    createdAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    terraformVersion = $version.terraform_version
    planSha256 = (Get-FileHash $plan -Algorithm SHA256).Hash
    inputsSha256 = (Get-FileHash (Join-Path $review 'inputs.tfvars.json') -Algorithm SHA256).Hash
    configurationSha256 = $files
    operations = @($document.resource_changes | ForEach-Object { @{ address = $_.address; actions = $_.change.actions } })
    statePath = $state
    applyExecuted = $false
} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $review 'manifest.json') -Encoding utf8
Write-Output "Saved create-only bootstrap plan for review. No Azure resources were changed. Manifest: $(Join-Path $review 'manifest.json')"
