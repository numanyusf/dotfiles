# Opens mpv:// links (from Seanime's "external player link") in mpv.
# Only http(s) URLs are accepted, and they are passed after "--" so they can never be read as mpv options.
param([string]$Link)
$log = Join-Path $PSScriptRoot 'last.log'
"$(Get-Date -Format s) received: $Link" | Set-Content $log
$u = $Link -replace '^mpv:(//)?', ''
if ($u -notmatch '^https?:') { $u = [uri]::UnescapeDataString($u) }
$u = $u -replace '^(https?):?/*', '$1://'   # browsers sometimes mangle "https://" after a custom scheme
# file names in the link may contain spaces/brackets: encode spaces, refuse quotes and line breaks (argument injection)
if ($u -notmatch '^https?://[^"\r\n]+$') { "rejected: $u" | Add-Content $log; exit 1 }
$u = $u -replace ' ', '%20'
"launching: $u" | Add-Content $log
Start-Process -FilePath 'C:\Program Files\MPV Player\mpv.exe' -ArgumentList @('--force-window=immediate', '--', "`"$u`"")
