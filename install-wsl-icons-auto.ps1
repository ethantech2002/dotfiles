# Windows Terminal WSL Icon Updater v3
# Automatically discovers and applies all icons from GitHub repository
# Repository: https://github.com/ethantech2002/icons-for-wsl

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WSL Icon Updater for Windows Terminal" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# GitHub repository details
$repoOwner = "ethantech2002"
$repoName = "icons-for-wsl"
$repoBranch = "main"
$repoUrl = "https://github.com/$repoOwner/$repoName"

# Define paths
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$iconFolder = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState\icons"

# Check if Windows Terminal is installed
if (-not (Test-Path $settingsPath)) {
    Write-Host "ERROR: Windows Terminal settings file not found!" -ForegroundColor Red
    Write-Host "Expected location: $settingsPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please ensure Windows Terminal is installed and has been run at least once." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Found Windows Terminal settings file" -ForegroundColor Green
Write-Host ""

# Create icon folder if it doesn't exist
if (-not (Test-Path $iconFolder)) {
    Write-Host "Creating icon folder..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $iconFolder -Force | Out-Null
        Write-Host "  Icon folder created: $iconFolder" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to create icon folder!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        pause
        exit 1
    }
} else {
    Write-Host "Icon folder exists: $iconFolder" -ForegroundColor Green
}
Write-Host ""

# Fetch list of icons from GitHub repository
Write-Host "Fetching icon list from GitHub..." -ForegroundColor Yellow
Write-Host "Repository: $repoUrl" -ForegroundColor Gray
Write-Host ""

try {
    $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents?ref=$repoBranch"
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "PowerShell-WSL-Icon-Updater")
    $jsonResponse = $webClient.DownloadString($apiUrl)
    $repoFiles = $jsonResponse | ConvertFrom-Json
    
    # Filter for PNG files only
    $iconFiles = $repoFiles | Where-Object { $_.name -like "*.png" }
    
    if ($iconFiles.Count -eq 0) {
        Write-Host "ERROR: No PNG icon files found in repository!" -ForegroundColor Red
        pause
        exit 1
    }
    
    Write-Host "Found $($iconFiles.Count) icon(s) in repository:" -ForegroundColor Green
    foreach ($icon in $iconFiles) {
        Write-Host "  • $($icon.name)" -ForegroundColor Gray
    }
    Write-Host ""
    
} catch {
    Write-Host "ERROR: Failed to fetch repository contents!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. Your internet connection" -ForegroundColor White
    Write-Host "  2. The repository exists and is accessible" -ForegroundColor White
    Write-Host "  3. GitHub API is accessible" -ForegroundColor White
    pause
    exit 1
}

# Create smart mapping from icon filenames to distribution names
function Get-DistroNameFromIcon {
    param($iconName)
    
    $iconName = $iconName.ToLower() -replace 'icons8-', '' -replace '-24\.png$', '' -replace '\.png$', ''
    
    $mapping = @{
        'ubuntu' = @('Ubuntu', 'ubuntu')
        'fsociety-mask' = @('kali-linux', 'Kali', 'kali')
        'arch-linux' = @('Arch', 'arch', 'arch-linux', 'ArchLinux')
        'debian' = @('Debian', 'debian')
        'powershell' = @('Windows PowerShell', 'PowerShell', 'pwsh')
        'cmd' = @('Command Prompt', 'cmd')
        'azure' = @('Azure Cloud Shell', 'Azure')
    }
    
    foreach ($key in $mapping.Keys) {
        if ($iconName -like "*$key*") {
            return $mapping[$key]
        }
    }
    
    # Fallback: return cleaned icon name
    return @($iconName)
}

# Download all icons from repository
Write-Host "Downloading icons from GitHub..." -ForegroundColor Yellow
Write-Host ""

$downloadedIcons = @{}
$failedDownloads = @()

foreach ($iconFile in $iconFiles) {
    $iconName = $iconFile.name
    $downloadUrl = $iconFile.download_url
    $localPath = Join-Path $iconFolder $iconName
    
    Write-Host "  Downloading: $iconName..." -ForegroundColor White
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $localPath)
        
        # Verify the file was downloaded and has content
        if ((Test-Path $localPath) -and ((Get-Item $localPath).Length -gt 0)) {
            Write-Host "    ✓ Downloaded successfully" -ForegroundColor Green
            
            # Map this icon to potential distribution names
            $distroNames = Get-DistroNameFromIcon $iconName
            foreach ($distroName in $distroNames) {
                $downloadedIcons[$distroName] = @{
                    filename = $iconName
                    path = $localPath
                }
            }
        } else {
            Write-Host "    ✗ Download failed (file empty or not created)" -ForegroundColor Red
            $failedDownloads += $iconName
        }
    } catch {
        Write-Host "    ✗ Download failed: $($_.Exception.Message)" -ForegroundColor Red
        $failedDownloads += $iconName
    }
}

Write-Host ""

# Check if any downloads failed
if ($failedDownloads.Count -gt 0) {
    Write-Host "WARNING: Some icons failed to download:" -ForegroundColor Yellow
    foreach ($icon in $failedDownloads) {
        Write-Host "  • $icon" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($downloadedIcons.Count -eq 0) {
    Write-Host "ERROR: No icons were successfully downloaded!" -ForegroundColor Red
    pause
    exit 1
}

# Backup existing settings
$backupPath = "$settingsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "Creating backup..." -ForegroundColor Yellow
Write-Host "  Location: $backupPath" -ForegroundColor Gray
try {
    Copy-Item $settingsPath $backupPath -ErrorAction Stop
    Write-Host "  Backup created successfully!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: Failed to create backup!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

# Read existing settings
Write-Host "Reading current settings..." -ForegroundColor Yellow
try {
    $settingsContent = Get-Content $settingsPath -Raw -ErrorAction Stop
    $settings = $settingsContent | ConvertFrom-Json -ErrorAction Stop
    Write-Host "  Settings loaded successfully!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: Failed to read or parse settings file!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Your backup is safe at: $backupPath" -ForegroundColor Yellow
    pause
    exit 1
}

# Update icons for matching profiles
Write-Host "Scanning for matching profiles..." -ForegroundColor Yellow
Write-Host ""

$updatedProfiles = @()
$profilesFound = 0

if ($settings.profiles -and $settings.profiles.list) {
    foreach ($profile in $settings.profiles.list) {
        $profileName = $profile.name
        $matched = $false
        
        # Try to match against downloaded icons
        foreach ($distroKey in $downloadedIcons.Keys) {
            # Check if profile name contains the distro key (case insensitive)
            if ($profileName -like "*$distroKey*" -or $profileName -eq $distroKey) {
                $iconInfo = $downloadedIcons[$distroKey]
                
                # Use ms-appdata:/// URI scheme for Windows Terminal
                $iconUri = "ms-appdata:///roaming/icons/$($iconInfo.filename)"
                
                # Update or add the icon property
                $profile | Add-Member -NotePropertyName "icon" -NotePropertyValue $iconUri -Force
                
                # Ensure the profile is not hidden
                if ($profile.PSObject.Properties.Name -contains "hidden") {
                    $profile.hidden = $false
                }
                
                if (-not $matched) {
                    $updatedProfiles += @{
                        name = $profileName
                        icon = $iconInfo.filename
                    }
                    $profilesFound++
                    $matched = $true
                    
                    Write-Host "  ✓ Matched: $profileName" -ForegroundColor Green
                    Write-Host "    Icon: $($iconInfo.filename)" -ForegroundColor Gray
                    Write-Host ""
                }
                
                break
            }
        }
    }
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Update Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($profilesFound -eq 0) {
    Write-Host "⚠ No matching profiles found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Downloaded icons:" -ForegroundColor Cyan
    foreach ($key in $downloadedIcons.Keys | Select-Object -Unique) {
        $icon = $downloadedIcons[$key]
        Write-Host "  - $($icon.filename)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Your current profiles:" -ForegroundColor Cyan
    foreach ($profile in $settings.profiles.list) {
        $profileName = $profile.name
        $source = if ($profile.source) { "[$($profile.source)]" } else { "[Manual]" }
        Write-Host "  - $profileName $source" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Icons were downloaded but no profiles matched." -ForegroundColor Yellow
    Write-Host "You can manually set icons in Windows Terminal settings." -ForegroundColor Gray
    Write-Host ""
    pause
    exit 0
}

Write-Host "Profiles updated: $profilesFound" -ForegroundColor Green
foreach ($profileInfo in $updatedProfiles) {
    Write-Host "  ✓ $($profileInfo.name) → $($profileInfo.icon)" -ForegroundColor Gray
}
Write-Host ""

# Save the updated settings
Write-Host "Saving updated settings..." -ForegroundColor Yellow
try {
    # Convert back to JSON with proper formatting
    $updatedJson = $settings | ConvertTo-Json -Depth 100
    
    # Write to file with UTF-8 encoding (no BOM)
    [System.IO.File]::WriteAllText($settingsPath, $updatedJson, [System.Text.UTF8Encoding]::new($false))
    
    Write-Host "  Settings saved successfully!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: Failed to save settings file!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Restoring from backup..." -ForegroundColor Yellow
    try {
        Copy-Item $backupPath $settingsPath -Force
        Write-Host "  Backup restored successfully!" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to restore backup!" -ForegroundColor Red
        Write-Host "  Manual restore required from: $backupPath" -ForegroundColor Yellow
    }
    Write-Host ""
    pause
    exit 1
}

# Display completion message
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Downloaded $($iconFiles.Count) icons from GitHub" -ForegroundColor Green
Write-Host "✓ Updated $profilesFound profile(s)" -ForegroundColor Green
Write-Host "✓ Icons saved to: $iconFolder" -ForegroundColor Green
Write-Host ""
Write-Host "Repository: $repoUrl" -ForegroundColor Gray
Write-Host ""
Write-Host "Updated profiles:" -ForegroundColor Yellow
foreach ($profileInfo in $updatedProfiles) {
    Write-Host "  • $($profileInfo.name)" -ForegroundColor White
    Write-Host "    → $($profileInfo.icon)" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Close ALL Windows Terminal windows" -ForegroundColor White
Write-Host "  2. Wait 2-3 seconds" -ForegroundColor White
Write-Host "  3. Restart Windows Terminal" -ForegroundColor White
Write-Host "  4. Your custom icons should now appear!" -ForegroundColor White
Write-Host ""
Write-Host "If icons don't appear:" -ForegroundColor Cyan
Write-Host "  • Make sure you completely closed all Terminal windows" -ForegroundColor White
Write-Host "  • Check Task Manager for any remaining Terminal processes" -ForegroundColor White
Write-Host "  • Verify icons are in: $iconFolder" -ForegroundColor White
Write-Host ""
Write-Host "Backup location (if you need to restore):" -ForegroundColor Gray
Write-Host "  $backupPath" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
