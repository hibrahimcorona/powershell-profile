####
#### Most of the commands were taken from the following file: https://github.com/ChrisTitusTech/powershell-profile/blob/main/setup.ps1
####
####


$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "Not running as Admin. Requesting elevation..."

    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = $MyInvocation.BoundParameters

    Start-Process pwsh -ArgumentList "-File `"$scriptPath`"" -Verb RunAs
}
Write-Host "Success! You are running PowerShell 7 as Administrator." -ForegroundColor Green

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $testConnection = Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

try {
    $fallbackPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "winget is available in PATH." -ForegroundColor Green
        $wingetCmd = "winget"
    }
    elseif (Test-Path $fallbackPath) {
        Write-Host "winget not found in PATH, but found at fallback path." -ForegroundColor Yellow
        $wingetCmd = $fallbackPath
    }
    else {
        Write-Error "winget is not installed or could not be found."
        return
    }

    & $wingetCmd install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
    & $wingetCmd install -e --id Fastfetch-cli.Fastfetch
}
catch {
    Write-Error "Failed to install Oh My Posh or Starship. Error: $_"
}

if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}

if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}

if (-not (Get-Module -ListAvailable -Name z)) {
    Install-Module -Name z -Scope CurrentUser -Force -SkipPublisherCheck
}

if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}


function Install-NerdFonts {
    param (
        [string]$FontName = "CascadiaCode",
        [string]$FontDisplayName = "CaskaydiaCove NF",
        [string]$Version = "3.3.0"
    )

    try {
        Write-Host "Installing ${FontDisplayName} font"
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        if ($fontFamilies -notcontains "${FontDisplayName}" -or $fontFamilies -notcontains "${FontDisplayName}") {
            Write-Host "Font name is $FontName"
            $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
            $zipFilePath = "$env:TEMP\${FontName}.zip"
            $extractPath = "$env:TEMP\${FontName}"

            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFileAsync((New-Object System.Uri($fontZipUrl)), $zipFilePath)

            while ($webClient.IsBusy) {
                Start-Sleep -Seconds 2
            }

            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
            Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            Remove-Item -Path $extractPath -Recurse -Force
            Remove-Item -Path $zipFilePath -Force
            Write-Host "Font ${FontDisplayName} installed successfully"
        }
        else {
            Write-Host "Font ${FontDisplayName} already installed"
        }
    }
    catch {
        Write-Error "Failed to download or install ${FontDisplayName} font. Error: $_"
    }
}
$fontVersion = "3.3.0"
Install-NerdFonts "CascadiaCode" "CaskaydiaCove NF" "$fontVersion"
Install-NerdFonts "FiraCode" "FiraCode Nerd Font"  "$fontVersion"
Install-NerdFonts "JetBrainsMono" "JetBrainsMono NF" "$fontVersion"

# Profile creation or update
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect Version of PowerShell & Create Profile directories if they do not exist.
        $profilePath = ""
        if ($PSVersionTable.PSEdition -eq "Core") {
            $profilePath = "$env:userprofile\Documents\Powershell"
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
        }

        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType "directory"
        }

        Invoke-RestMethod https://raw.githubusercontent.com/hibrahimcorona/powershell-profile/refs/heads/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
        Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {
        Get-Item -Path $PROFILE | Move-Item -Destination "oldprofile.ps1" -Force
        Invoke-RestMethod https://raw.githubusercontent.com/hibrahimcorona/powershell-profile/refs/heads/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
        Write-Host "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to backup and update the profile. Error: $_"
    }
}

### Creation of config folder for vscode and symbolic links to customization of VSCode.
$folderPath = "C:\.config"
$sourceDir = "$HOME\Documents\Powershell\Customization"

# Ensure the destination folder exists
if (-not (Test-Path -Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory | Out-Null
    Write-Host "Created directory: $folderPath"
}

if (-not (Test-Path -Path "$folderPath\vscode")) {
    New-Item -Path "$folderPath\vscode" -ItemType Directory | Out-Null
    Write-Host "Created directory: $folderPath\vscode"
}

if (-not (Test-Path -Path "$folderPath\ohmyposh")) {
    New-Item -Path "$folderPath\ohmyposh" -ItemType Directory | Out-Null
    Write-Host "Created directory: $folderPath\ohmyposh"
}

# Define the links to manage: LinkPath => TargetPath
$links = @{
    "$folderPath\vscode\custom.css"                  = "$sourceDir\vscode\custom.css"
    "$folderPath\vscode\custom.js"                   = "$sourceDir\vscode\custom.js"
    "$folderPath\ohmyposh\catpuccino-mocha.omp.json" = "$sourceDir\ohmyposh\catpuccino-mocha.omp.json"
}

# Create links only if they do not already exist
foreach ($link in $links.GetEnumerator()) {
    if (-not (Test-Path -Path $link.Key)) {
        New-Item -ItemType SymbolicLink -Path $link.Key -Value $link.Value | Out-Null
        Write-Host "Created symbolic link for: $($link.Name)"
    }
    else {
        Write-Host "Symbolic link already exists: $($link.Name)"
    }
}
