# PowerShell 7 profile -> Documents\PowerShell\Microsoft.PowerShell_profile.ps1 (copied, not symlinked)
# Windows counterpart of ~/.dotfiles/bashrc: oh-my-posh prompt, eza, fzf, prefix history search, gh completion.

# --- prompt: oh-my-posh (emodipt-extend), same theme as Linux ---
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\emodipt-extend.omp.json" | Invoke-Expression
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

# --- history prefix search on Up/Down, inline suggestions from history ---
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -PredictionSource History -HistoryNoDuplicates

# --- fzf: Ctrl-R history, Ctrl-T files, Alt-C cd (PSFzf module) ---
if ((Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Module -ListAvailable PSFzf)) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PSReadLineKeyHandler -Key 'Alt+c' -ScriptBlock { Invoke-FuzzySetLocation }
}

# --- gh completion ---
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh completion -s powershell | Out-String | Invoke-Expression
}
