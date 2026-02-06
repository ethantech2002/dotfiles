# Starship PowerShell Installation Script
# This script installs Starship, Hack Nerd Font, and configures your PowerShell profile

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starship Installation for PowerShell  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  This script requires Administrator privileges to install fonts." -ForegroundColor Yellow
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

# Install Starship using winget
Write-Host "📦 Installing Starship..." -ForegroundColor Green
try {
    winget install --id Starship.Starship -e --silent --accept-source-agreements --accept-package-agreements
    Write-Host "✅ Starship installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install Starship. Error: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# Download and Install Hack Nerd Font
Write-Host "📦 Installing Hack Nerd Font..." -ForegroundColor Green

$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
$tempFolder = "$env:TEMP\HackNerdFont"
$zipFile = "$tempFolder\Hack.zip"

# Create temp directory
New-Item -ItemType Directory -Force -Path $tempFolder | Out-Null

# Download font
try {
    Write-Host "   Downloading Hack Nerd Font..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $fontUrl -OutFile $zipFile -UseBasicParsing
    
    # Extract zip
    Write-Host "   Extracting font files..." -ForegroundColor Cyan
    Expand-Archive -Path $zipFile -DestinationPath $tempFolder -Force
    
    # Install fonts
    Write-Host "   Installing fonts..." -ForegroundColor Cyan
    $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
    $fontFiles = Get-ChildItem -Path $tempFolder -Include "*.ttf", "*.otf" -Recurse
    
    foreach ($fontFile in $fontFiles) {
        $fontsFolder.CopyHere($fontFile.FullName, 0x10)
    }
    
    Write-Host "✅ Hack Nerd Font installed successfully!" -ForegroundColor Green
    
    # Clean up
    Remove-Item -Path $tempFolder -Recurse -Force
} catch {
    Write-Host "❌ Failed to install Hack Nerd Font. Error: $_" -ForegroundColor Red
    Write-Host "   You can manually download from: https://github.com/ryanoasis/nerd-fonts/releases" -ForegroundColor Yellow
}

Write-Host ""

# Create .starship directory if it doesn't exist
$starshipDir = "$HOME\.starship"
if (-not (Test-Path $starshipDir)) {
    Write-Host "📁 Creating .starship directory..." -ForegroundColor Green
    New-Item -ItemType Directory -Path $starshipDir | Out-Null
}

# Prompt for custom starship config repo
Write-Host "📥 Do you want to clone your custom Starship config repository?" -ForegroundColor Cyan
Write-Host "   If yes, please enter the Git repository URL (or press Enter to skip):" -ForegroundColor Cyan
$repoUrl = Read-Host "   Repository URL"

if ($repoUrl -and $repoUrl.Trim() -ne "") {
    Write-Host "   Cloning repository..." -ForegroundColor Cyan
    try {
        # Check if git is installed
        $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitInstalled) {
            Write-Host "   ⚠️  Git is not installed. Installing git..." -ForegroundColor Yellow
            winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
            # Refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        }
        
        # Clone the repo
        $tempRepoPath = "$env:TEMP\starship-config"
        if (Test-Path $tempRepoPath) {
            Remove-Item -Path $tempRepoPath -Recurse -Force
        }
        
        git clone $repoUrl $tempRepoPath
        
        # Copy starship.toml if it exists
        if (Test-Path "$tempRepoPath\starship.toml") {
            Copy-Item "$tempRepoPath\starship.toml" "$starshipDir\starship.toml" -Force
            Write-Host "✅ Custom starship.toml copied successfully!" -ForegroundColor Green
        } elseif (Test-Path "$tempRepoPath\.config\starship.toml") {
            Copy-Item "$tempRepoPath\.config\starship.toml" "$starshipDir\starship.toml" -Force
            Write-Host "✅ Custom starship.toml copied successfully!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  No starship.toml found in repository." -ForegroundColor Yellow
            Write-Host "   Please manually copy your config to: $starshipDir\starship.toml" -ForegroundColor Yellow
        }
        
        # Clean up
        Remove-Item -Path $tempRepoPath -Recurse -Force
    } catch {
        Write-Host "❌ Failed to clone repository. Error: $_" -ForegroundColor Red
        Write-Host "   You can manually download your config and place it at: $starshipDir\starship.toml" -ForegroundColor Yellow
    }
}

Write-Host ""

# Configure PowerShell Profile
Write-Host "⚙️  Configuring PowerShell profile..." -ForegroundColor Green

$profilePath = $PROFILE

# Create profile if it doesn't exist
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

# Read current profile content
$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

# Check if Starship is already configured
if ($profileContent -notmatch "starship init powershell") {
    # Add Starship configuration
    $starshipConfig = @"

# Starship Configuration
`$ENV:STARSHIP_CONFIG = `$HOME\.starship\starship.toml
`$ENV:STARSHIP_DISTRO = " ⎈ xcad"
Invoke-Expression (&starship init powershell)
"@
    
    Add-Content -Path $profilePath -Value $starshipConfig
    Write-Host "✅ PowerShell profile configured!" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Starship already configured in PowerShell profile." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✨ Installation Complete! ✨" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Configure Windows Terminal to use 'Hack Nerd Font Mono'" -ForegroundColor White
Write-Host "   Settings → Profiles → Defaults → Appearance → Font face → 'Hack Nerd Font Mono'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Restart your PowerShell terminal or run:" -ForegroundColor White
Write-Host "   . `$PROFILE" -ForegroundColor Gray
Write-Host ""
Write-Host "3. If you haven't cloned your config yet, place your starship.toml at:" -ForegroundColor White
Write-Host "   $starshipDir\starship.toml" -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to exit"
