# Registers the mpv:// link handler for the current user (no admin): copies open.ps1 to
# %LOCALAPPDATA%\mpv-link and points HKCU\Software\Classes\mpv at it. Re-run after editing open.ps1.
# Needs mpv (winget install shinchiro.mpv). Then in Seanime: Settings -> External player link = mpv://{url},
# and the AIOStreams plugin's preferred player = External player link.
$dir = Join-Path $env:LOCALAPPDATA 'mpv-link'
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'open.ps1') $dir -Force

$key = 'HKCU:\Software\Classes\mpv'
New-Item -Force "$key\shell\open\command" | Out-Null
Set-Item $key 'URL:mpv'
New-ItemProperty $key -Name 'URL Protocol' -Value '' -Force | Out-Null
Set-Item "$key\shell\open\command" "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dir\open.ps1`" `"%1`""
"mpv:// handler -> $dir\open.ps1"
