# ============================================================
# TerminalWP - PowerShell profile
# ============================================================

# --- Wallpaper folder ---
$TerminalWP = "$env:USERPROFILE\TerminalWP"
if (-not (Test-Path $TerminalWP)) { New-Item -ItemType Directory -Path $TerminalWP -Force | Out-Null }

# --- Local IP for oh-my-posh right panel ---
$env:TERMINAL_LOCAL_IP = 'N/A'
try {
    $cfg = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1
    if ($cfg -and $cfg.IPv4Address) { $env:TERMINAL_LOCAL_IP = $cfg.IPv4Address.IPAddress }
} catch {}

# --- Modules ---
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module PSReadLine -ErrorAction SilentlyContinue

# --- PSReadLine ---
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    Set-PSReadLineOption -Colors @{
        Command   = 'Cyan'
        Parameter = 'Gray'
        Operator  = 'Magenta'
        Variable  = 'Green'
        String    = 'Yellow'
        Number    = 'Blue'
        Type      = 'DarkCyan'
        Comment   = 'DarkGray'
    } -ErrorAction SilentlyContinue
}

# --- oh-my-posh prompt ---
$shell = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }
$theme = "$env:USERPROFILE\.config\oh-my-posh\theme.omp.json"
if (Test-Path $theme) {
    oh-my-posh init $shell --config $theme | Invoke-Expression
}

# --- System information banner ---
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

# --- Helpers ---
Set-Alias ll Get-ChildItem -ErrorAction SilentlyContinue
function la { Get-ChildItem -Force }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function touch { param($p) New-Item -ItemType File -Path $p -Force | Out-Null }
function which { param($c) (Get-Command $c -ErrorAction SilentlyContinue).Source }
