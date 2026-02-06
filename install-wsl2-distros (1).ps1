#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs WSL2 with Ubuntu, Arch Linux, and Kali Linux
.DESCRIPTION
    This script enables WSL2 and installs three Linux distributions.
    After installation and first launch, profiles will appear in Windows Terminal.
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
Write-Host "Checking available distributions..." -ForegroundColor Cyan
$availableDistros = wsl --list --online
Write-Host $availableDistros
Write-Host ""

# Install Ubuntu
Write-Host "Installing Ubuntu..." -ForegroundColor Green
try {
    wsl --install -d Ubuntu-22.04 --no-launch 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Ubuntu 22.04 LTS installed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ! Ubuntu installation completed with warnings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Ubuntu installation failed: $_" -ForegroundColor Red
}

# Install Arch Linux - using the exact name from wsl --list --online
Write-Host "Installing Arch Linux..." -ForegroundColor Green
try {
    # Try "Arch" first (the actual name in wsl --list --online)
    wsl --install -d Arch --no-launch 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Arch Linux installed successfully" -ForegroundColor Green
        $archInstalled = $true
    } else {
        Write-Host "  ! Arch Linux installation completed with warnings" -ForegroundColor Yellow
        $archInstalled = $true
    }
} catch {
    Write-Host "  ✗ Arch Linux installation failed: $_" -ForegroundColor Red
    $archInstalled = $false
}

# Install Kali Linux
Write-Host "Installing Kali Linux..." -ForegroundColor Green
try {
    wsl --install -d kali-linux --no-launch 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Kali Linux installed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ! Kali installation completed with warnings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Kali installation failed: $_" -ForegroundColor Red
}

# Step 5: Verify and show instructions
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Installation Status" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Currently installed WSL distributions:" -ForegroundColor Yellow
wsl --list --verbose
Write-Host ""

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "IMPORTANT: First Launch Required!" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Windows Terminal profiles appear ONLY AFTER first launch!" -ForegroundColor White
Write-Host "You must complete user setup for each distro first." -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "------------" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Set up Ubuntu:" -ForegroundColor White
Write-Host "   Run: wsl -d Ubuntu-22.04" -ForegroundColor Yellow
Write-Host "   Create username and password when prompted" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Set up Arch Linux:" -ForegroundColor White
Write-Host "   Run: wsl -d Arch" -ForegroundColor Yellow
Write-Host "   Create username and password when prompted" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Set up Kali Linux:" -ForegroundColor White
Write-Host "   Run: wsl -d kali-linux" -ForegroundColor Yellow
Write-Host "   Create username and password when prompted" -ForegroundColor Gray
Write-Host ""

Write-Host "After completing user setup for each distro:" -ForegroundColor Cyan
Write-Host "  • Open Windows Terminal (Win+X, then T)" -ForegroundColor Gray
Write-Host "  • Click the dropdown (v) next to the + button" -ForegroundColor Gray
Write-Host "  • You'll see Ubuntu, Arch, and Kali-Linux profiles!" -ForegroundColor Gray
Write-Host ""

Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  wsl --list --verbose           (List all distros)" -ForegroundColor Gray
Write-Host "  wsl -d <name>                  (Launch specific distro)" -ForegroundColor Gray
Write-Host "  wsl --set-default <name>       (Set default distro)" -ForegroundColor Gray
Write-Host "  wsl --terminate <name>         (Stop a running distro)" -ForegroundColor Gray
Write-Host "  wsl --shutdown                 (Stop all distros)" -ForegroundColor Gray
Write-Host "  wsl --unregister <name>        (Remove a distro)" -ForegroundColor Gray
Write-Host ""

Write-Host "Troubleshooting:" -ForegroundColor Cyan
Write-Host "  If a distro doesn't appear in Windows Terminal:" -ForegroundColor Gray
Write-Host "  1. Make sure you launched it and completed user setup" -ForegroundColor Gray
Write-Host "  2. Close and reopen Windows Terminal" -ForegroundColor Gray
Write-Host "  3. Run 'wsl --list' to verify it's installed" -ForegroundColor Gray
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
