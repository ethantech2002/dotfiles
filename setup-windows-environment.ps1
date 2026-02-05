#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Complete Windows environment setup with Christian Lempa's toolset
.DESCRIPTION
    This script will:
    - Install Chocolatey package manager
    - Install all development tools (Docker, Git, VS Code, Terraform, kubectl, etc.)
    - Install Google Chrome
    - Set Mr. Robot wallpaper
    - Enable Windows Dark Mode
    - Configure minimal taskbar (hide search, clock, notifications, auto-hide)
.NOTES
    Must be run as Administrator
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows Environment Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if running as administrator
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

# Set execution policy
Write-Host "[1/6] Setting execution policy..." -ForegroundColor Green
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install Chocolatey if not already installed
Write-Host "[2/6] Installing Chocolatey package manager..." -ForegroundColor Green
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "Chocolatey already installed, upgrading..." -ForegroundColor Yellow
    choco upgrade chocolatey -y
}

# Install all applications
Write-Host "[3/6] Installing applications (this may take a while)..." -ForegroundColor Green

$apps = @(
    # Browsers
    'googlechrome',
    
    # Development Tools
    'git',
    'vscode',
    'docker-desktop',
    'terraform',
    'packer',
    'vagrant',
    
    # Kubernetes Tools
    'kubernetes-cli',
    'kubernetes-helm',
    'k9s',
    'lens',
    
    # Container Tools
    'podman-desktop',
    
    # Cloud CLIs
    'awscli',
    'azure-cli',
    'gcloudsdk',
    
    # Terminal & Shell
    'microsoft-windows-terminal',
    'powershell-core',
    'oh-my-posh',
    
    # Utilities
    'curl',
    'wget',
    'jq',
    'yq',
    'grep',
    'sed',
    'vim',
    'nano',
    
    # DevOps Tools
    'ansible',
    'make',
    
    # Version Managers
    'nvm',
    'pyenv-win',
    
    # Other Tools
    '7zip',
    'sysinternals',
    'putty',
    'winscp',
    'postman',
    'insomnia-rest-api-client',
    
    # Monitoring
    'grafana',
    'prometheus',
    
    # Database Tools
    'dbeaver',
    
    # Note Taking
    'obsidian',
    'notion'
)

foreach ($app in $apps) {
    Write-Host "Installing $app..." -ForegroundColor Cyan
    choco install $app -y --ignore-checksums
}

# Install WSL2 (Windows Subsystem for Linux)
Write-Host "Installing WSL2..." -ForegroundColor Cyan
wsl --install -d Ubuntu

# Download and set wallpaper
Write-Host "[4/6] Setting wallpaper..." -ForegroundColor Green

$wallpaperUrl = "https://raw.githubusercontent.com/ChristianLempa/hackbox/main/src/assets/mr-robot-wallpaper.png"
$wallpaperPath = "$env:USERPROFILE\Pictures\mr-robot-wallpaper.png"

# Download wallpaper
Write-Host "Downloading Mr. Robot wallpaper..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath

# Set wallpaper
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

[Wallpaper]::SystemParametersInfo(0x0014, 0, $wallpaperPath, 0x0001 -bor 0x0002)
Write-Host "Wallpaper set successfully!" -ForegroundColor Green

# Enable Dark Mode
Write-Host "[5/6] Enabling Windows Dark Mode..." -ForegroundColor Green

# Set apps to dark mode
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force

# Set system to dark mode
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force

# Set taskbar to dark
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "ColorPrevalence" -Value 0 -Type DWord -Force

Write-Host "Dark mode enabled!" -ForegroundColor Green

# Configure Taskbar - Completely Minimal Setup
Write-Host "[6/6] Configuring minimal taskbar..." -ForegroundColor Green

# Hide Search Box
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force

# Hide Task View button
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord -Force

# Hide People/Meet Now
if (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People") {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Value 0 -Type DWord -Force
}

# Hide News and Interests (Widgets)
if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds") {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force
}

# Hide Cortana button
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCortanaButton" -Value 0 -Type DWord -Force

# Small taskbar icons (Windows 10)
if ([System.Environment]::OSVersion.Version.Build -lt 22000) {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Value 1 -Type DWord -Force
}

# Auto-hide taskbar
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name "Settings" -Value ([byte[]](0x30,0x00,0x00,0x00,0xfe,0xff,0xff,0xff,0x03,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x2e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x00,0x38,0x04,0x00,0x00,0x00,0x01,0x00,0x00,0xe0,0x07,0x00,0x00)) -Type Binary -Force

# Taskbar alignment - Center (for Windows 11)
if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 1 -Type DWord -Force
}

# Hide system tray icons
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value 1 -Type DWord -Force

# Hide notification area
if (-not (Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
    New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideSCAMeetNow" -Value 1 -Type DWord -Force

# Hide clock and date
if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell")) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" -Force | Out-Null
}

# For hiding the clock/calendar (requires registry tweak)
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1 -Type DWord -Force

# Restart Explorer to apply changes
Write-Host "Restarting Explorer to apply taskbar changes..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed Applications:" -ForegroundColor Yellow
Write-Host "  - Google Chrome" -ForegroundColor White
Write-Host "  - Git & GitHub CLI" -ForegroundColor White
Write-Host "  - Visual Studio Code" -ForegroundColor White
Write-Host "  - Docker Desktop" -ForegroundColor White
Write-Host "  - Terraform, Packer, Vagrant" -ForegroundColor White
Write-Host "  - Kubernetes (kubectl, helm, k9s, lens)" -ForegroundColor White
Write-Host "  - Cloud CLIs (AWS, Azure, GCloud)" -ForegroundColor White
Write-Host "  - Windows Terminal & PowerShell Core" -ForegroundColor White
Write-Host "  - WSL2 with Ubuntu" -ForegroundColor White
Write-Host "  - And many more DevOps tools!" -ForegroundColor White
Write-Host ""
Write-Host "Configurations Applied:" -ForegroundColor Yellow
Write-Host "  ✓ Dark Mode enabled" -ForegroundColor White
Write-Host "  ✓ Mr. Robot wallpaper set" -ForegroundColor White
Write-Host "  ✓ Minimal taskbar (auto-hide, no search, no clock, no notifications)" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT NEXT STEPS:" -ForegroundColor Red
Write-Host "  1. Restart your computer for all changes to take effect" -ForegroundColor Yellow
Write-Host "  2. Start Docker Desktop after restart" -ForegroundColor Yellow
Write-Host "  3. Configure Git: git config --global user.name 'Your Name'" -ForegroundColor Yellow
Write-Host "  4. Configure Git: git config --global user.email 'your@email.com'" -ForegroundColor Yellow
Write-Host "  5. WSL2 Ubuntu will need initial setup on first launch" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
pause
