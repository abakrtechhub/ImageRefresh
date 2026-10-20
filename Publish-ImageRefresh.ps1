param()
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$remote = & git remote get-url origin
if ($LASTEXITCODE -ne 0 -or $remote -ne 'https://github.com/abakrtechhub/ImageRefresh.git') { throw 'Unexpected remote.' }
$branch = (& git branch --show-current).Trim()
$head = (& git rev-parse HEAD).Trim()
if (& git status --porcelain) { throw 'Working tree/index is not clean. Review and commit only the intended changes first.' }
& "$PSScriptRoot/tools/Test-Push.ps1" -Commit $head -Branch "refs/heads/$branch"
& git push --set-upstream origin "HEAD:refs/heads/$branch"
if ($LASTEXITCODE -ne 0) { throw 'Push failed; local commit retained.' }
$remoteHead = & git ls-remote origin "refs/heads/$branch"
if ($LASTEXITCODE -ne 0 -or ($remoteHead -split '\s+')[0] -ne $head) { throw 'Remote verification failed.' }
Write-Output "Verified review branch: $branch at $head. Open/update its pull request; do not merge automatically."
