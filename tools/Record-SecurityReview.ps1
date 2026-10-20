param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Summary,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Tests,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Reviewer,
    [switch]$Bootstrap
)
$ErrorActionPreference = 'Stop'
# Run only AFTER an actual review. This records its result; it does not perform AI review.
$head = (& git rev-parse HEAD).Trim()
if ($Bootstrap) {
    $remoteMain = & git ls-remote origin refs/heads/main
    if ($LASTEXITCODE -ne 0 -or $remoteMain) { throw 'Bootstrap requires a verified empty remote main.' }
    $base = 'EMPTY'
    & "$PSScriptRoot/Test-Security.ps1" -Revision $head
} else {
    & git fetch origin main
    if ($LASTEXITCODE -ne 0) { throw 'Fetch failed.' }
    $base = (& git rev-parse origin/main).Trim()
    & git merge-base --is-ancestor $base $head
    if ($LASTEXITCODE -ne 0) { throw 'Include current main and review again.' }
    & "$PSScriptRoot/Test-Security.ps1" -Revision $head -Base $base
}
$gitDir = (& git rev-parse --absolute-git-dir).Trim()
$report = [ordered]@{ Commit=$head; Base=$base; Decision='pass'; OpenFindings=0; Reviewer=$Reviewer; Summary=$Summary; Tests=$Tests; RecordedUtc=[DateTime]::UtcNow.ToString('o') }
$report | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $gitDir 'imagerefresh-security-review.json') -Encoding UTF8
Write-Output 'Review recorded for this exact commit. Any new commit requires another review.'
