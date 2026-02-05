# PowerShell script to set Windows Terminal tab colors
# This script modifies the settings.json file for Windows Terminal

$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Check if Windows Terminal settings file exists
if (-not (Test-Path $settingsPath)) {
    Write-Host "Windows Terminal settings file not found at: $settingsPath" -ForegroundColor Red
    Write-Host "Please make sure Windows Terminal is installed." -ForegroundColor Yellow
    exit 1
}

Write-Host "Found Windows Terminal settings file" -ForegroundColor Green

# Read the current settings
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

# Define the tab colors for each profile
$profileColors = @{
    "archlinux"      = "#00F6FF"
    "kalilinux"      = "#005CFF"
    "ubuntulinux"    = "#FF00F6"
    "azure"          = "#7A00FF"
    "command prompt" = "#7A00FF"
    "powershell"     = "#005CFF"
}

# Backup the original settings
$backupPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json.backup"
Copy-Item $settingsPath $backupPath -Force
Write-Host "Backup created at: $backupPath" -ForegroundColor Cyan

# Update each profile's tab color
$updatedCount = 0
foreach ($profile in $settings.profiles.list) {
    $profileName = $profile.name.ToLower()
    
    foreach ($key in $profileColors.Keys) {
        if ($profileName -match $key) {
            $profile | Add-Member -MemberType NoteProperty -Name "tabColor" -Value $profileColors[$key] -Force
            Write-Host "Updated '$($profile.name)' with color $($profileColors[$key])" -ForegroundColor Green
            $updatedCount++
            break
        }
    }
}

# Save the updated settings
$settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath -Encoding UTF8

Write-Host "`nSuccessfully updated $updatedCount profile(s)" -ForegroundColor Green
Write-Host "Please restart Windows Terminal to see the changes" -ForegroundColor Yellow
