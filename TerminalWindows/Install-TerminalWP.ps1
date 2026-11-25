# =====================================================================
# TerminalWP - Installer (run: .\Install-TerminalWP.ps1)
# =====================================================================
param(
    [string]$WallpaperFolder = "$env:USERPROFILE\TerminalWP",
    [switch]$SkipTerminalSettings
)
$ErrorActionPreference = 'Continue'
Write-Host "`n=== TerminalWP installer ===" -ForegroundColor Cyan

# 1. Wallpaper folder
if (-not (Test-Path $WallpaperFolder)) {
    New-Item -ItemType Directory -Path $WallpaperFolder -Force | Out-Null
    Write-Host "[+] Created wallpaper folder: $WallpaperFolder" -ForegroundColor Green
} else {
    Write-Host "[=] Wallpaper folder exists: $WallpaperFolder" -ForegroundColor Yellow
}

# 2. Download wallpaper
$wpFile = Join-Path $WallpaperFolder 'wallpaper.jpg'
if (-not (Test-Path $wpFile)) {
    Write-Host "[*] Downloading wallpaper..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri 'https://images.unsplash.com/photo-1477346611705-65d1883cee1e?q=80&w=1170&auto=format&fit=crop' -OutFile $wpFile
        Write-Host "[+] Wallpaper saved: $wpFile" -ForegroundColor Green
    } catch {
        Write-Host "[!] Could not download wallpaper: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[=] Wallpaper already present." -ForegroundColor Yellow
}

# 3. Modules
Write-Host "[*] Ensuring PowerShell modules..." -ForegroundColor Cyan
try {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    if (-not (Get-Module -ListAvailable Terminal-Icons)) {
        Install-Module Terminal-Icons -Scope CurrentUser -Force -AllowClobber
    }
    Write-Host "[+] Modules ready." -ForegroundColor Green
} catch {
    Write-Host "[!] Module install issue: $_" -ForegroundColor Red
}

# 4. oh-my-posh theme
$themeDir = "$env:USERPROFILE\.config\oh-my-posh"
if (-not (Test-Path $themeDir)) { New-Item -ItemType Directory -Path $themeDir -Force | Out-Null }
$themeFile = Join-Path $themeDir 'theme.omp.json'
$themeJson = '{"$schema":"https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json","version":3,"final_space":true,"console_title_template":"{{ .Shell }} in {{ .Folder }}","blocks":[{"type":"prompt","alignment":"left","segments":[{"type":"os","style":"diamond","foreground":"#ffffff","background":"#1f1f2e","template":" {{ if .WSL }}WSL {{ end }}{{ .Icon }} "},{"type":"session","style":"diamond","foreground":"#e0def4","background":"#2a2a3c","template":" {{ .UserName }} "},{"type":"path","style":"powerline","powerline_symbol":"\ue0b0","foreground":"#e0def4","background":"#31748f","template":" \ue5ff {{ path .Path .Location }} ","properties":{"style":"folder"}},{"type":"git","style":"powerline","powerline_symbol":"\ue0b0","foreground":"#191724","background":"#ebbcba","template":" {{ .HEAD }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }} ","properties":{"fetch_status":true}}]},{"type":"prompt","alignment":"right","segments":[{"type":"time","style":"diamond","foreground":"#f6c177","background":"transparent","template":" \uf017 {{ .CurrentDate | date .Format }} ","properties":{"time_format":"2006-01-02 15:04:05"}},{"type":"sysinfo","style":"diamond","foreground":"#9ccfd8","background":"transparent","template":" \uf2db {{ round .PhysicalPercentUsed .Precision }}% RAM ","properties":{"precision":1}},{"type":"text","style":"diamond","foreground":"#c4a7e7","background":"transparent","template":" \uf0ac {{ .Env.TERMINAL_LOCAL_IP }} "},{"type":"ipify","style":"diamond","foreground":"#eb6f92","background":"transparent","template":" \uf0e8 {{ .IP }} ","properties":{"http_timeout":1000,"cache_duration":"1h"}}]},{"type":"prompt","alignment":"left","newline":true,"segments":[{"type":"text","style":"plain","foreground":"#908caa","template":"\u276f "}]}]}'
Set-Content -Path $themeFile -Value $themeJson -Encoding UTF8
Write-Host "[+] oh-my-posh theme written: $themeFile" -ForegroundColor Green

# 5. Profiles
$profileContent = @'
# TerminalWP profile
$TerminalWP = "$env:USERPROFILE\TerminalWP"
if (-not (Test-Path $TerminalWP)) { New-Item -ItemType Directory -Path $TerminalWP -Force | Out-Null }

$env:TERMINAL_LOCAL_IP = 'N/A'
try {
    $cfg = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1
    if ($cfg -and $cfg.IPv4Address) { $env:TERMINAL_LOCAL_IP = $cfg.IPv4Address.IPAddress }
} catch {}

Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module PSReadLine -ErrorAction SilentlyContinue
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    Set-PSReadLineOption -Colors @{ Command='Cyan'; Parameter='Gray'; Operator='Magenta'; Variable='Green'; String='Yellow'; Number='Blue'; Type='DarkCyan'; Comment='DarkGray' } -ErrorAction SilentlyContinue
}

$shell = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }
$theme = "$env:USERPROFILE\.config\oh-my-posh\theme.omp.json"
if (Test-Path $theme) { oh-my-posh init $shell --config $theme | Invoke-Expression }

function Show-TerminalBanner {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
        $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $ramFree  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $ramUsed  = [math]::Round($ramTotal - $ramFree, 2)
        $up = (Get-Date) - $os.LastBootUpTime
        $localIP = $env:TERMINAL_LOCAL_IP
        $publicIP = 'N/A'
        try { $publicIP = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 3).Trim() } catch {}
        Write-Host ''
        Write-Host '  +--------------------------------------------------------------+' -ForegroundColor DarkCyan
        Write-Host '  |               TerminalWP - System Information                |' -ForegroundColor Cyan
        Write-Host '  +--------------------------------------------------------------+' -ForegroundColor DarkCyan
        Write-Host ("  |  OS       : {0}" -f $os.Caption) -ForegroundColor White
        Write-Host ("  |  CPU      : {0}" -f $cpu) -ForegroundColor White
        Write-Host ("  |  RAM      : {0} GB used / {1} GB total" -f $ramUsed, $ramTotal) -ForegroundColor White
        Write-Host ("  |  Uptime   : {0}d {1}h {2}m" -f $up.Days, $up.Hours, $up.Minutes) -ForegroundColor White
        Write-Host ("  |  Local IP : {0}" -f $localIP) -ForegroundColor Magenta
        Write-Host ("  |  Public IP: {0}" -f $publicIP) -ForegroundColor Yellow
        Write-Host ("  |  Time     : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Green
        Write-Host '  +--------------------------------------------------------------+' -ForegroundColor DarkCyan
        Write-Host ''
    } catch {}
}
Show-TerminalBanner

Set-Alias ll Get-ChildItem -ErrorAction SilentlyContinue
function la { Get-ChildItem -Force }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
'@

$profilePaths = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
    "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
)
foreach ($pp in $profilePaths) {
    $d = Split-Path $pp
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Set-Content -Path $pp -Value $profileContent -Encoding UTF8
    Write-Host "[+] Profile written: $pp" -ForegroundColor Green
}

# 6. Windows Terminal settings (optional)
if (-not $SkipTerminalSettings) {
    $wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $wtSettings) {
        Copy-Item $wtSettings "$wtSettings.bak" -Force
        Write-Host "[+] Backed up Windows Terminal settings to settings.json.bak" -ForegroundColor Yellow
        Write-Host "[i] Apply wallpaper/opacity/font/colorScheme in settings.json manually if desired." -ForegroundColor Yellow
    }
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Install Nerd Font:  oh-my-posh font install CascadiaCode" -ForegroundColor White
Write-Host "  2. Set Windows Terminal font to 'CaskaydiaCove Nerd Font'" -ForegroundColor White
Write-Host "  3. Restart Windows Terminal" -ForegroundColor White
