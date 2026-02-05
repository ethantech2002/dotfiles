#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs WSL2 with Ubuntu, Arch Linux, and Kali Linux
.DESCRIPTION
    This script enables WSL2 and installs three Linux distributions.
    After reboot, you'll be prompted to set username and password for each distro.
#>

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "WSL2 Multi-Distro Installer" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Function to check if reboot is needed
function Test-RebootRequired {
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    
    if ($wslFeature.State -eq "Enabled" -and $vmFeature.State -eq "Enabled") {
        return $false
    }
    return $true
}

# Step 1: Enable WSL and Virtual Machine Platform
Write-Host "[1/5] Checking WSL features..." -ForegroundColor Yellow

$wslEnabled = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq "Enabled"
$vmEnabled = (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -eq "Enabled"

if (-not $wslEnabled) {
    Write-Host "Enabling WSL feature..." -ForegroundColor Green
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
}

if (-not $vmEnabled) {
    Write-Host "Enabling Virtual Machine Platform..." -ForegroundColor Green
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
}

# Check if reboot is needed
if (Test-RebootRequired) {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Yellow
    Write-Host "REBOOT REQUIRED" -ForegroundColor Yellow
    Write-Host "=====================================" -ForegroundColor Yellow
    Write-Host "WSL features have been enabled." -ForegroundColor Green
    Write-Host "After reboot, run this script again to complete installation." -ForegroundColor Cyan
    Write-Host ""
    
    $reboot = Read-Host "Reboot now? (Y/N)"
    if ($reboot -eq "Y" -or $reboot -eq "y") {
        Restart-Computer -Force
    } else {
        Write-Host "Please reboot manually and run this script again." -ForegroundColor Yellow
        exit 0
    }
}

# Step 2: Set WSL2 as default
Write-Host "[2/5] Setting WSL2 as default version..." -ForegroundColor Yellow
wsl --set-default-version 2

# Step 3: Update WSL
Write-Host "[3/5] Updating WSL..." -ForegroundColor Yellow
wsl --update

# Step 4: Install distributions
Write-Host "[4/5] Installing Linux distributions..." -ForegroundColor Yellow
Write-Host ""

# Install Ubuntu
Write-Host "Installing Ubuntu..." -ForegroundColor Green
wsl --install -d Ubuntu --no-launch

# Install Arch Linux
Write-Host "Installing Arch Linux..." -ForegroundColor Green
wsl --install -d Arch --no-launch

# Install Kali Linux
Write-Host "Installing Kali Linux..." -ForegroundColor Green
wsl --install -d kali-linux --no-launch

# Step 5: Instructions
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Three distributions have been installed:" -ForegroundColor White
Write-Host "  1. Ubuntu" -ForegroundColor Yellow
Write-Host "  2. Arch" -ForegroundColor Yellow
Write-Host "  3. kali-linux" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "To set up each distribution, run these commands:" -ForegroundColor White
Write-Host ""
Write-Host "  wsl -d Ubuntu" -ForegroundColor Yellow
Write-Host "  (Set username and password for Ubuntu)" -ForegroundColor Gray
Write-Host ""
Write-Host "  wsl -d Arch" -ForegroundColor Yellow
Write-Host "  (Set username and password for Arch)" -ForegroundColor Gray
Write-Host ""
Write-Host "  wsl -d kali-linux" -ForegroundColor Yellow
Write-Host "  (Set username and password for Kali)" -ForegroundColor Gray
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  wsl --list --verbose       (List all installed distros)" -ForegroundColor Gray
Write-Host "  wsl --set-default <name>   (Set default distro)" -ForegroundColor Gray
Write-Host "  wsl --terminate <name>     (Stop a running distro)" -ForegroundColor Gray
Write-Host "  wsl --unregister <name>    (Remove a distro)" -ForegroundColor Gray
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
