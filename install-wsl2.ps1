#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs WSL2 and multiple Linux distributions (Kali Linux, Arch Linux, Ubuntu 22.04)

.DESCRIPTION
    This script automates the installation of WSL2 and three popular Linux distributions.
    It checks prerequisites, enables required Windows features, sets WSL2 as default,
    and installs the specified distributions.

.NOTES
    - Requires Windows 10 version 2004 or higher, or Windows 11
    - Must be run as Administrator
    - May require system restart
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WSL2 Multi-Distribution Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to check Windows version
function Test-WindowsVersion {
    $version = [System.Environment]::OSVersion.Version
    if ($version.Major -eq 10 -and $version.Build -ge 19041) {
        return $true
    }
    return $false
}

# Verify administrator privileges
if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Check Windows version
if (-not (Test-WindowsVersion)) {
    Write-Host "ERROR: Windows 10 version 2004 (Build 19041) or higher is required!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Administrator privileges confirmed" -ForegroundColor Green
Write-Host "✓ Windows version compatible" -ForegroundColor Green
Write-Host ""

# Step 1: Enable WSL and Virtual Machine Platform features
Write-Host "[1/5] Enabling WSL and Virtual Machine Platform..." -ForegroundColor Yellow

$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
$vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

$needsRestart = $false

if ($wslFeature.State -ne "Enabled") {
    Write-Host "  → Enabling WSL feature..." -ForegroundColor Cyan
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    $needsRestart = $true
} else {
    Write-Host "  ✓ WSL feature already enabled" -ForegroundColor Green
}

if ($vmFeature.State -ne "Enabled") {
    Write-Host "  → Enabling Virtual Machine Platform..." -ForegroundColor Cyan
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    $needsRestart = $true
} else {
    Write-Host "  ✓ Virtual Machine Platform already enabled" -ForegroundColor Green
}

if ($needsRestart) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  RESTART REQUIRED" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Windows features have been enabled, but a system restart is required." -ForegroundColor Yellow
    Write-Host "After restarting, please run this script again to complete the installation." -ForegroundColor Yellow
    Write-Host ""
    $restart = Read-Host "Would you like to restart now? (Y/N)"
    if ($restart -eq "Y" -or $restart -eq "y") {
        Restart-Computer -Force
    } else {
        Write-Host "Please restart your computer manually and run this script again." -ForegroundColor Cyan
        exit 0
    }
}

# Step 2: Update WSL
Write-Host "[2/5] Updating WSL to latest version..." -ForegroundColor Yellow
try {
    wsl --update
    Write-Host "  ✓ WSL updated successfully" -ForegroundColor Green
} catch {
    Write-Host "  ! WSL update encountered an issue (may already be latest version)" -ForegroundColor Yellow
}

# Step 3: Set WSL2 as default version
Write-Host "[3/5] Setting WSL2 as default version..." -ForegroundColor Yellow
wsl --set-default-version 2
Write-Host "  ✓ WSL2 set as default" -ForegroundColor Green

# Step 4: Install distributions
Write-Host "[4/5] Installing Linux distributions..." -ForegroundColor Yellow
Write-Host ""

$distributions = @(
    @{Name="Ubuntu-22.04"; DisplayName="Ubuntu 22.04 LTS"},
    @{Name="kali-linux"; DisplayName="Kali Linux"},
    @{Name="Arch"; DisplayName="Arch Linux"}
)

foreach ($distro in $distributions) {
    Write-Host "  → Installing $($distro.DisplayName)..." -ForegroundColor Cyan
    
    # Check if already installed
    $installed = wsl --list --quiet | Where-Object { $_ -match $distro.Name }
    
    if ($installed) {
        Write-Host "    ✓ $($distro.DisplayName) is already installed" -ForegroundColor Green
    } else {
        try {
            wsl --install --distribution $distro.Name --no-launch
            Write-Host "    ✓ $($distro.DisplayName) installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "    ✗ Failed to install $($distro.DisplayName)" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Step 5: Ensure all distributions are running WSL2
Write-Host "[5/5] Ensuring all distributions use WSL2..." -ForegroundColor Yellow

$installedDistros = wsl --list --verbose | Select-Object -Skip 1 | ForEach-Object {
    if ($_ -match '^\s*[\*\s]\s*(.+?)\s+(Stopped|Running)\s+(\d+)') {
        [PSCustomObject]@{
            Name = $matches[1].Trim()
            State = $matches[2]
            Version = $matches[3]
        }
    }
}

foreach ($distro in $installedDistros) {
    if ($distro.Version -eq "1") {
        Write-Host "  → Converting $($distro.Name) to WSL2..." -ForegroundColor Cyan
        wsl --set-version $distro.Name 2
        Write-Host "    ✓ $($distro.Name) converted to WSL2" -ForegroundColor Green
    } else {
        Write-Host "  ✓ $($distro.Name) is already running WSL2" -ForegroundColor Green
    }
}

# Final summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed distributions:" -ForegroundColor Green
wsl --list --verbose
Write-Host ""
Write-Host "To launch a distribution, use:" -ForegroundColor Cyan
Write-Host "  wsl -d Ubuntu-22.04" -ForegroundColor White
Write-Host "  wsl -d kali-linux" -ForegroundColor White
Write-Host "  wsl -d Arch" -ForegroundColor White
Write-Host ""
Write-Host "First-time setup:" -ForegroundColor Cyan
Write-Host "  When you first launch each distribution, you'll be prompted to" -ForegroundColor White
Write-Host "  create a username and password." -ForegroundColor White
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "  wsl --list --verbose    # List all installed distributions" -ForegroundColor White
Write-Host "  wsl --set-default <name> # Set default distribution" -ForegroundColor White
Write-Host "  wsl --shutdown          # Shutdown all distributions" -ForegroundColor White
Write-Host ""
