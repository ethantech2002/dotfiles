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
    'nano',
    'eza',
    
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

# Install Nerd Fonts (popular monospace fonts with icons)
Write-Host "Installing Nerd Fonts..." -ForegroundColor Cyan
choco install cascadiacode-nerd-font -y
choco install firacode-nerd-font -y
choco install jetbrainsmono-nerd-font -y

# Install WSL2 (Windows Subsystem for Linux)
Write-Host "Installing WSL2..." -ForegroundColor Cyan

# Enable WSL and Virtual Machine Platform features
Write-Host "Enabling WSL features..." -ForegroundColor Yellow
try {
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    Write-Host "WSL features enabled. Installing WSL from Microsoft Store..." -ForegroundColor Yellow
    
    # Try to update WSL first (this fixes the web internal error)
    Write-Host "Updating WSL to latest version..." -ForegroundColor Yellow
    wsl --update --web-download
    
    # Set WSL 2 as default
    wsl --set-default-version 2
    
    # Install Ubuntu (use --web-download to avoid Microsoft Store errors)
    Write-Host "Installing Ubuntu distribution..." -ForegroundColor Yellow
    wsl --install -d Ubuntu --web-download
    
    Write-Host "WSL2 with Ubuntu installation complete!" -ForegroundColor Green
} catch {
    Write-Host "Note: WSL installation may require a restart. You can complete it after restart with:" -ForegroundColor Yellow
    Write-Host "  wsl --install -d Ubuntu --web-download" -ForegroundColor Cyan
}

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

# Don't auto-hide taskbar - keep it visible
# Removed auto-hide setting to keep taskbar on screen

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

# Configure Windows Terminal
Write-Host "Configuring Windows Terminal..." -ForegroundColor Green

$terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $terminalSettingsPath) {
    Write-Host "Updating Windows Terminal settings..." -ForegroundColor Cyan
    
    # Backup existing settings
    Copy-Item $terminalSettingsPath "$terminalSettingsPath.backup" -Force
    
    # Read current settings
    $settings = Get-Content $terminalSettingsPath -Raw | ConvertFrom-Json
    
    # Add custom color scheme
    $customScheme = @{
        "name" = "xcld_tdl"
        "background" = "#0F0F0F"
        "black" = "#000000"
        "blue" = "#2D4F6C"
        "brightBlack" = "#272F2F"
        "brightBlue" = "#5CA8FF"
        "brightCyan" = "#5CA8FF"
        "brightGreen" = "#719F7F"
        "brightPurple" = "#B5A5FF"
        "brightRed" = "#FF6A6A"
        "brightWhite" = "#E5E5E5"
        "brightYellow" = "#6A6AFF"
        "cursorColor" = "#28B9FF"
        "cyan" = "#28B9FF"
        "foreground" = "#FFFFFF"
        "green" = "#719F7F"
        "purple" = "#2B28BF"
        "red" = "#E5A2FF"
        "selectionBackground" = "#FFFFFF"
        "white" = "#E1F1F1"
        "yellow" = "#3D2FAF"
    }
    
    # Initialize schemes array if it doesn't exist
    if (-not $settings.schemes) {
        $settings | Add-Member -MemberType NoteProperty -Name "schemes" -Value @() -Force
    }
    
    # Remove existing xcld_tdl scheme if present
    $settings.schemes = @($settings.schemes | Where-Object { $_.name -ne "xcld_tdl" })
    
    # Add the custom scheme
    $settings.schemes += $customScheme
    
    # Set default profile settings
    if (-not $settings.profiles.defaults) {
        $settings.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value @{} -Force
    }
    
    # Set font to FiraCode Nerd Font Mono
    $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value @{
        "face" = "FiraCode Nerd Font Mono"
        "size" = 11
    } -Force
    
    # Set color scheme to custom xcld_tdl
    $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "colorScheme" -Value "xcld_tdl" -Force
    
    # Set acrylic transparency
    $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "useAcrylic" -Value $true -Force
    $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "acrylicOpacity" -Value 0.9 -Force
    
    # Save updated settings
    $settings | ConvertTo-Json -Depth 100 | Set-Content $terminalSettingsPath -Force
    
    Write-Host "Windows Terminal configured with FiraCode Nerd Font Mono and xcld_tdl color scheme!" -ForegroundColor Green
} else {
    Write-Host "Windows Terminal settings not found. Launch Windows Terminal once, then run this section again." -ForegroundColor Yellow
}

# Force refresh font cache
Write-Host "Refreshing font cache..." -ForegroundColor Cyan
$null = (New-Object -ComObject Shell.Application).Namespace(0x14).Self.Path

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
Write-Host "  - Nerd Fonts (CascadiaCode, FiraCode, JetBrainsMono)" -ForegroundColor White
Write-Host "  - eza (modern ls replacement)" -ForegroundColor White
Write-Host "  - WSL2 with Ubuntu" -ForegroundColor White
Write-Host "  - And many more DevOps tools!" -ForegroundColor White
Write-Host ""
Write-Host "Configurations Applied:" -ForegroundColor Yellow
Write-Host "  ✓ Dark Mode enabled" -ForegroundColor White
Write-Host "  ✓ Mr. Robot wallpaper set" -ForegroundColor White
Write-Host "  ✓ Minimal taskbar (centered, no search, no clock, no notifications)" -ForegroundColor White
Write-Host "  ✓ FiraCode Nerd Font Mono configured" -ForegroundColor White
Write-Host "  ✓ Windows Terminal xcld_tdl color scheme applied" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT NEXT STEPS:" -ForegroundColor Red
Write-Host "  1. Restart your computer for all changes to take effect" -ForegroundColor Yellow
Write-Host "  2. After restart, if WSL didn't complete, run: wsl --install -d Ubuntu --web-download" -ForegroundColor Yellow
Write-Host "  3. Start Docker Desktop after restart" -ForegroundColor Yellow
Write-Host "  4. Configure Git: git config --global user.name 'Your Name'" -ForegroundColor Yellow
Write-Host "  5. Configure Git: git config --global user.email 'your@email.com'" -ForegroundColor Yellow
Write-Host "  6. WSL2 Ubuntu will need initial setup on first launch" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
pause
