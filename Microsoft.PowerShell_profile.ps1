#################################
######### CUSTOMIZATION #########
#################################

$ENV:STARSHIP_CONFIG = "$HOME/.config/starship.toml"

if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    #fastfetch -c "$HOME/.config/fastfetch/config.jsonc"
    fastfetch --logo "$env:USERPROFILE\.config\fastfetch\koala.txt"
}

# Oh-My-Posh
#oh-my-posh init pwsh --config $env:USERPROFILE'\AppData\Local\Programs\oh-my-posh\themes\honukai.omp.json' | Invoke-Expression
# Starship
Invoke-Expression (&starship init powershell)


# Aliases
Set-Alias -Name bash -Value "C:\Program Files\Git\bin\bash.exe"

$nvimPath = "C:\Program Files\Neovim\bin\nvim.exe"
$codePath = "$env:USERPROFILE\AppData\Local\Programs\Microsoft VS Code\"

if ([System.IO.File]::Exists($nvimPath)) {
    $env:EDITOR = $nvimPath
}
elseif ([System.IO.File]::Exists($codePath)) {
    $env:EDITOR = "$codePath\Code.exe"
}
else {
    $env:EDITOR = 'notepad.exe'
}

####    Git Commands
function gcl($url) { git clone $url }
function gpr { git pull --rebase }
function gs { git status }
function gss { git status -s }
function ga { git add . }
function gcom { git commit -m $args }
function glog { git log --oneline }
function gbs { git branch }
function gc-b { git checkout -B }

###     PSReadLineOptions
$PSReadLineOptions = @{
    EditMode                      = 'Windows'
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    PredictionSource              = 'History'
    PredictionViewStyle           = 'ListView'
    BellStyle                    = 'None'
    Colors                          = @{
        InlinePrediction = "`e[38;5;238m"
    }
}

Set-PSReadLineOption @PSReadLineOptions

#################################
######### GIT FUNCTIONS #########
#################################

function Pull-Branch {
    param (
        [string]$rootPath,
        [string]$branch = 'main'
    )
    Write-Host "Pulling $branch" -ForegroundColor Yellow
    git pull origin $branch
    Write-Host "Pulling subdirectories." -ForegroundColor Yellow

    Get-ChildItem -Path $rootPath -Directory -Recurse | ForEach-Object {
        if (Test-Path "$($_.FullName)\.git") {
            Write-Host "Pulling $branch branch in $($_.FullName)" -ForegroundColor Yellow

            Push-Location $_.FullName
            git pull origin $branch
            Pop-Location
        }
    }
}

function Clear-NonExistentBranches {
    # Ensure the script stops on errors
    $ErrorActionPreference = "Stop"

    # Function to clean stale branches in a given Git repository
    function Clean-StaleBranches($repoPath) {
        Write-Host "Processing repository at: $repoPath"
        Set-Location $repoPath

        # Fetch latest remote branches and prune deleted ones
        Write-Host "Fetching latest branches from remote..."
        git fetch --prune

        # Get all local branches
        $localBranches = git branch | ForEach-Object { $_.Trim() }

        # Get all remote branches
        $remoteBranches = git branch -r | ForEach-Object { $_.Trim() -replace '^origin/', '' }

        # Identify local branches that no longer exist on remote
        $branchesToDelete = $localBranches | Where-Object { $_ -ne "main" -and $_ -ne "master" -and $_ -notin $remoteBranches }

        if ($branchesToDelete) {
            Write-Host "Deleting the following stale branches:"
            $branchesToDelete | ForEach-Object { Write-Host $_ }

            # Delete each stale branch
            $branchesToDelete | ForEach-Object { git branch -D $_ }
        }
        else {
            Write-Host "No stale branches found in $repoPath."
        }

        # Return to the original directory
        Set-Location - 
    }

    # Get the root Git repository
    $rootRepo = Get-Location

    # Process the main repository
    Clean-StaleBranches $rootRepo

    # Detect submodules and nested repositories
    $gitDirs = Get-ChildItem -Recurse -Directory -Force | Where-Object { Test-Path "$($_.FullName)\.git" }

    # Process each detected submodule or nested repository
    foreach ($dir in $gitDirs) {
        Clean-StaleBranches $dir.FullName
    }

    Write-Host "Cleanup complete!"
}

function Show-Branches {
    # Ensure the script stops on errors
    $ErrorActionPreference = "Stop"

    # Get the root Git repository
    $rootRepo = Get-Location
    Write-Host "Checking main repository:" -ForegroundColor Yellow
    Get-CurrentBranch $rootRepo

    # Detect submodules and nested repositories
    $gitDirs = Get-ChildItem -Recurse -Directory -Force | Where-Object { Test-Path "$($_.FullName)\.git" }

    # Process each detected submodule or nested repository
    if ($gitDirs) {
        Write-Host "Checking submodules and nested repositories:" -ForegroundColor Yellow
        foreach ($dir in $gitDirs) {
            Get-CurrentBranch $dir.FullName
        }
    }
    else {
        Write-Host "No submodules or nested repositories found." -ForegroundColor Red
    }

    Write-Host "Done!" -ForegroundColor Yellow

}

function Get-CurrentBranch($repoPath) {
    Set-Location $repoPath
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($branch) {
        Write-Host "[$branch] - $repoPath"
    }
    else {
        Write-Host "Not a valid Git repository: $repoPath" -ForegroundColor Red
    }
    Set-Location - # Return to the original directory
}

#####################################
######### WINDOWS FUNCTIONS #########
#####################################

function Rename {
    param (
        [string]$path,
        [string]$newPath
    )
    Rename-Item -Path $path -NewName $newPath
}

function head {
    param(
        [string]$path,
        [string]$lines = 10
    )
    Get-Content -Path $path -Head $lines
}

function tail {
    param (
        [string]$path,
        [string]$lines = 10
    )
    Get-Content -Path $path -Tail $lines
}

function touch($file) { "" | Out-File $file -Encoding ASCII }

function ff($name) { 
    Get-ChildItem -recurse -filter "*$name*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.directory)\$($_)"
    }
}

function reload() {
    . $PROFILE
}

function me {
    if (Test-Path -Path "d:\code") { Set-Location "d:\code" } 
    elseif (Test-Path -Path "c:\repo") { Set-Location "C:\repo" } 
    elseif (Test-Path -Path "c:\code") { Set-Location "c:\code" }
}

function ll { Get-ChildItem -Path . -Force }

function Update-PowerShell {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (Get-Command -Name 'Update-PowerShell_Override' -ErrorAction SilentlyContinue) {
        Update-PowerShell_Override @PSBoundParameters
        return
    }

    if (-not (Test-Command winget)) {
        Write-Warning 'winget is required to update PowerShell automatically.'
        return
    }

    try {
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' -ErrorAction Stop
        $currentVersion = [version]$PSVersionTable.PSVersion
        $latestVersion = [version]($release.tag_name -replace '^v', '')

        if ($currentVersion -ge $latestVersion) {
            Write-Host "PowerShell $currentVersion is up to date." -ForegroundColor Green
            return
        }

        if ($PSCmdlet.ShouldProcess("PowerShell $currentVersion", "Upgrade to $latestVersion")) {
            winget upgrade --id Microsoft.PowerShell --exact --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0) {
                Write-Error "winget failed to update PowerShell. Exit code: $LASTEXITCODE"
                return
            }
            Write-Host 'PowerShell has been updated. Restart your shell to use the new version.' -ForegroundColor Magenta
        }
    } catch {
        Write-Error "Failed to update PowerShell. Error: $_"
    }
}


function Test-Command {
    param([Parameter(Mandatory)][string]$Name)
    $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

# Dotnet Aliases
Set-Alias -Name d -Value dotnet
function dw { dotnet watch run }
function dt { dotnet test }
function db { dotnet build }
function d-ef { dotnet ef }
function dcb { dotnet clean && dotnet build }

# Clean all bin and obj folders recursively (crucial for .NET troubleshooting)
function Clear-DotNetArtifacts {
    Write-Host "Cleaning bin and obj folders..." -ForegroundColor Yellow
    Get-ChildItem -Path . -Include bin, obj -Recurse -Directory | Remove-Item -Recurse -Force
    Write-Host "Cleanup complete!" -ForegroundColor Green
}