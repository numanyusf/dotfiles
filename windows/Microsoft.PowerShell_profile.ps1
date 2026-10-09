# PowerShell 7 profile -> Documents\PowerShell\Microsoft.PowerShell_profile.ps1 (copied, not symlinked)
# Windows counterpart of ~/.dotfiles/bashrc: oh-my-posh prompt, eza, fzf, prefix history search, gh completion.

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

# --- LS_COLORS from vivid (one-dark, dirs gold), read by eza ---
$lsColors = "$HOME\.config\ls_colors"
if (Test-Path $lsColors) { $env:LS_COLORS = (Get-Content -Raw $lsColors).Trim() }

# --- ls -> eza with Nerd Font icons ---
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --icons=auto --group-directories-first @args }
    function ll { eza -l --icons=auto --group-directories-first --git @args }
    function la { eza -la --icons=auto --group-directories-first --git @args }
    function l  { eza --icons=auto --group-directories-first @args }
    function lt { eza --tree --level=2 --icons=auto --group-directories-first @args }
}

# --- history prefix search on Up/Down, suggestions from history as a dropdown list ---
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -HistoryNoDuplicates  # F2 toggles inline/list

# --- fzf: Ctrl-R history, Ctrl-T files, Alt-C cd (PSFzf module) ---
# PSFzf takes ~0.3 s to import, so it loads on the first keypress instead of at startup.
function Import-PSFzfOnce {
    if (-not (Get-Module PSFzf)) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        Set-PSReadLineKeyHandler -Key 'Alt+c' -ScriptBlock { Invoke-FuzzySetLocation }
    }
}
# Only bind when fzf and PSFzf are installed; checks module dirs directly since Get-Module -ListAvailable is slow.
$hasPSFzf = $env:PSModulePath -split [IO.Path]::PathSeparator | Where-Object { Test-Path "$_\PSFzf" } | Select-Object -First 1
if ($hasPSFzf -and (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Set-PSReadLineKeyHandler -Key 'Ctrl+r' -ScriptBlock { Import-PSFzfOnce; Invoke-FzfPsReadlineHandlerHistory }
    Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock { Import-PSFzfOnce; Invoke-FzfPsReadlineHandlerProvider }
    Set-PSReadLineKeyHandler -Key 'Alt+c' -ScriptBlock { Import-PSFzfOnce; Invoke-FuzzySetLocation }
}

# --- gh completion (cached; regenerated when gh is updated) ---
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    $ghCache = "$profileCache\gh-completion.ps1"
    if (-not (Test-Path $ghCache) -or (Get-Item $gh.Source).LastWriteTime -gt (Get-Item $ghCache).LastWriteTime) {
        gh completion -s powershell | Out-String | Set-Content $ghCache
    }
    . $ghCache
}

# --- bat: cat with syntax highlighting ---
$env:BAT_THEME = "OneHalfDark"
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
    function cat { bat --paging=never --style=plain @args }
}

# --- fzf: fd as the file source, One Dark colours (same as bashrc) ---
if (Get-Command fd -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git'
    $env:FZF_CTRL_T_COMMAND = $env:FZF_DEFAULT_COMMAND
    $env:FZF_ALT_C_COMMAND = 'fd --type d --hidden --exclude .git'
}
$env:FZF_DEFAULT_OPTS = '--height 40% --layout reverse --border ' +
    '--color fg:#D6D2C4,hl:#E5C07B,fg+:#FFFEFE,bg+:#2C313A,hl+:#E5C07B ' +
    '--color info:#98C379,prompt:#E06C75,pointer:#E06C75,marker:#98C379,spinner:#C678DD,header:#56B6C2,border:#5C6370'

# --- zoxide last: `z foo` jumps, `zi` picks with fzf ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
