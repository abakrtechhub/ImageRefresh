param([Parameter(Mandatory=$true)][string]$Commit, [Parameter(Mandatory=$true)][string]$Branch)
$ErrorActionPreference = 'Stop'
$bootstrap = $Branch -eq 'refs/heads/main'
if (-not $bootstrap -and $Branch -notmatch '^refs/heads/review/[a-z0-9][a-z0-9-]*$') { throw 'Only review/* branches may be pushed from this working tree.' }
$expected = (& git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $Commit -ne $expected) { throw 'Only the checked-out, reviewed HEAD may be pushed.' }
$gitDir = (& git rev-parse --absolute-git-dir).Trim()
$reportPath = Join-Path $gitDir 'imagerefresh-security-review.json'
if (-not (Test-Path -LiteralPath $reportPath)) { throw 'No security review recorded for this push.' }
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
if ($report.Commit -ne $Commit -or $report.Decision -ne 'pass' -or $report.OpenFindings -ne 0 -or
    [string]::IsNullOrWhiteSpace($report.Summary) -or [string]::IsNullOrWhiteSpace($report.Tests) -or
    [string]::IsNullOrWhiteSpace($report.Reviewer)) { throw 'Security review is incomplete or belongs to a different commit.' }
$remoteMain = & git ls-remote origin refs/heads/main
if ($LASTEXITCODE -ne 0) { throw 'Cannot verify remote main.' }
$mainSha = (($remoteMain -split '\s+')[0])
if ($bootstrap) {
    if ($remoteMain -or $report.Base -ne 'EMPTY') { throw 'Direct main pushes are blocked after initial setup.' }
    if ((& git rev-list --count $Commit) -ne '1') { throw 'Bootstrap must be a single root commit.' }
    $setupOnly = @('.gitattributes','.gitignore','.githooks/pre-push','.github/workflows/security.yml','README.md','SECURITY.md','Publish-ImageRefresh.ps1','tools/Test-Security.ps1','tools/Test-Push.ps1','tools/Record-SecurityReview.ps1')
    foreach ($path in @(& git ls-tree -r --name-only $Commit)) { if ($path -notin $setupOnly) { throw 'Bootstrap may contain only the reviewed workflow setup files.' } }
    & "$PSScriptRoot/Test-Security.ps1" -Revision $Commit
    return
}
if ([string]::IsNullOrWhiteSpace($mainSha) -or $report.Base -ne $mainSha) { throw 'Review base does not match current main. Fetch and repeat review.' }
& git merge-base --is-ancestor $mainSha $Commit
if ($LASTEXITCODE -ne 0) { throw 'Review branch must include current main.' }
& "$PSScriptRoot/Test-Security.ps1" -Revision $Commit -Base $mainSha
