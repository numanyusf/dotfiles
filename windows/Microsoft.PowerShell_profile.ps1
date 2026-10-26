# PowerShell 7 profile -> Documents\PowerShell\Microsoft.PowerShell_profile.ps1 (copied, not symlinked)
# Windows counterpart of ~/.dotfiles/bashrc: oh-my-posh prompt, prefix history search, gh completion.

# Generated init scripts (oh-my-posh, gh) are cached here so the profile doesn't launch the exes on every start.
$profileCache = "$env:LOCALAPPDATA\pwsh-profile-cache"
if (-not (Test-Path $profileCache)) { New-Item -ItemType Directory $profileCache | Out-Null }

# --- prompt: oh-my-posh (emodipt-extend), same theme as Linux ---
# `init` prints one line pointing at oh-my-posh's own cached script; reuse it with a fresh session id.
# Refreshed daily, when the theme changes, or when oh-my-posh drops that script (e.g. after an upgrade).
$ompConfig = "$HOME\.config\oh-my-posh\emodipt-extend.omp.json"
$ompCache = "$profileCache\omp-init.ps1"
$ompInit = if (Test-Path $ompCache) { Get-Content -Raw $ompCache }
$ompStale = -not $ompInit -or
    (Get-Item $ompCache).LastWriteTime -lt (Get-Date).AddDays(-1) -or
    (Get-Item $ompConfig).LastWriteTime -gt (Get-Item $ompCache).LastWriteTime -or
    -not ($ompInit -match "& '([^']+)'" -and (Test-Path $Matches[1]))
if ($ompStale -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    $ompInit = oh-my-posh init pwsh --config $ompConfig | Out-String
    Set-Content $ompCache $ompInit -NoNewline
}
if ($ompInit) {
    $ompInit -replace '(POSH_SESSION_ID = ")[^"]+', "`${1}$([guid]::NewGuid())" | Invoke-Expression
}

# --- history prefix search on Up/Down, suggestions from history as a dropdown list ---
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -HistoryNoDuplicates  # F2 toggles inline/list

# --- gh completion (cached; regenerated when gh is updated) ---
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    $ghCache = "$profileCache\gh-completion.ps1"
    if (-not (Test-Path $ghCache) -or (Get-Item $gh.Source).LastWriteTime -gt (Get-Item $ghCache).LastWriteTime) {
        gh completion -s powershell | Out-String | Set-Content $ghCache
    }
    . $ghCache
}
