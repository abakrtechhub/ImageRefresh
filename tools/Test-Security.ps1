param([string]$Revision = 'HEAD', [string]$Base)
$ErrorActionPreference = 'Stop'
function Invoke-GitRead { $result = & git @args; if ($LASTEXITCODE -ne 0) { throw "Git read failed: $args" }; return $result }
$head = Invoke-GitRead rev-parse --verify "$Revision^{commit}"
$commits = @($head)
if ($Base) {
    $baseCommit = Invoke-GitRead rev-parse --verify "$Base^{commit}"
    $commits = @(Invoke-GitRead rev-list "$baseCommit..$head")
}
$seen = @{}
$failures = New-Object 'System.Collections.Generic.List[string]'
$allowed = @('.ps1','.psm1','.psd1','.md','.txt','.json','.csv','.c','.h','.cs','.xaml','.cmd','.yml','.yaml','.sh')
$rules = @(
    'gh[pousr]_[A-Za-z0-9]{30,}',
    'github_pat_[A-Za-z0-9_]{40,}',
    'AKIA[0-9A-Z]{16}',
    '-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----',
    '(?i)(?:password|client_secret|api_key|access_token)\s*[:=]\s*["''][^"''\s]{12,}["'']'
)
foreach ($commit in $commits) {
    foreach ($entry in @(Invoke-GitRead ls-tree -r $commit)) {
        if ($entry -notmatch '^100(?:644|755) blob ([a-f0-9]+)\t(.+)$') { $failures.Add("Unsupported tree entry in $commit"); continue }
        $blob = $Matches[1]; $path = $Matches[2]
        # Quoted paths are rejected rather than decoded ambiguously.
        if ($path.StartsWith('"') -or $path -match '[\r\n]') { $failures.Add('Unsupported path encoding'); continue }
        $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()
        if ($path -match '(^|/)(\.env[^/]*|logs|sessions|workspace|Verification|ReferenceEvidence-[^/]+|node_modules|\.mediarefresh)(/|$)' -or
            ($extension -notin $allowed -and $path -notin @('.gitignore','.gitattributes','.githooks/pre-push','CODEOWNERS'))) {
            $failures.Add("Disallowed public file: $path"); continue
        }
        $size = [long](Invoke-GitRead cat-file -s $blob)
        if ($size -gt 2097152) { $failures.Add("File exceeds source review size limit: $path"); continue }
        if ($seen.ContainsKey($blob)) { continue }; $seen[$blob] = $true
        $content = (Invoke-GitRead cat-file blob $blob) -join "`n"
        foreach ($rule in $rules) {
            if ([regex]::IsMatch($content, $rule)) { $failures.Add("Possible credential/private key: $path (content withheld)"); break }
        }
        if ($extension -in @('.ps1','.psm1','.psd1')) {
            $parseErrors = $null
            [void][Management.Automation.Language.Parser]::ParseInput($content,[ref]$null,[ref]$parseErrors)
            if ($parseErrors.Count) { $failures.Add("PowerShell syntax errors: $path") }
        }
    }
}
if ($failures.Count) { $failures | Sort-Object -Unique | Write-Output; throw 'Security checks failed. Do not bypass; review and fix.' }
Write-Output "Security checks passed for $head ($($commits.Count) commit snapshots; $($seen.Count) unique source blobs). This is not an application security audit."

