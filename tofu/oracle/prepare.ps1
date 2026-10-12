#Requires -Version 7.5
<#
.SYNOPSIS
Decrypt OCI input values into the gitignored secrets.auto.tfvars.json file.
.DESCRIPTION
The resource definitions are ordinary .tf files. This script only decrypts values;
it never generates HCL, calls OCI, imports state, or applies infrastructure changes.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
if (-not $env:SOPS_AGE_KEY_FILE -and -not $env:SOPS_AGE_KEY -and -not $env:SOPS_AGE_KEY_CMD) {
    $identity = Join-Path $env:USERPROFILE '.config/sops/age/keys.txt'
    if (Test-Path -LiteralPath $identity) { $env:SOPS_AGE_KEY_FILE = $identity }
}
$destination = Join-Path $PSScriptRoot 'secrets.auto.tfvars.json'
& git -C $PSScriptRoot check-ignore -q -- $destination
if ($LASTEXITCODE -ne 0) { throw 'Decrypted inputs must be gitignored.' }
$plaintext = (& sops decrypt (Join-Path $PSScriptRoot 'secrets.sops.json') | Out-String)
$values = $plaintext | ConvertFrom-Json -AsHashtable -DateKind String
if (-not $values.tenancy_ocid -or $values.import_ids -isnot [System.Collections.IDictionary]) {
    throw 'Unexpected OCI input file: expected tenancy_ocid and import_ids inputs.'
}
if (Test-Path -LiteralPath $destination) {
    # Compare data, not formatting. Preserve any differing local edits.
    $existing = Get-Content -LiteralPath $destination -Raw | ConvertFrom-Json -AsHashtable -DateKind String
    function CanonicalJson($value) {
        if ($value -is [System.Collections.IDictionary]) {
            $ordered = [ordered]@{}
            foreach ($key in @($value.Keys | Sort-Object)) { $ordered[$key] = CanonicalJson $value[$key] }
            return $ordered
        }
        if ($value -is [array]) { return ,@($value | ForEach-Object { CanonicalJson $_ }) }
        return $value
    }
    $before = CanonicalJson $existing | ConvertTo-Json -Depth 100 -Compress
    $after = CanonicalJson $values | ConvertTo-Json -Depth 100 -Compress
    if ($before -cne $after) { throw 'secrets.auto.tfvars.json has local edits. Preserve them before decrypting updated inputs.' }
} else {
    [IO.File]::WriteAllText($destination, $plaintext, [Text.UTF8Encoding]::new($false))
}
Write-Output 'Decrypted OCI inputs are ready. Resource definitions remain in the .tf files.'
