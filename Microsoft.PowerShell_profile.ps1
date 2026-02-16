# Aliases
Set-Alias -Name bash -Value "C:\Program Files\Git\bin\bash.exe"

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
}

Set-PSReadLineOption @PSReadLineOptions

###     Pimp my terminal
oh-my-posh init pwsh --config $env:USERPROFILE'\AppData\Local\Programs\oh-my-posh\themes\honukai.omp.json' | Invoke-Expression

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

function tail {
    param (
        [string]$path,
        [string]$lines = 10
    )
    Get-Content -Path $path -Tail $lines
}

function me() {
    if (Test-Path -Path "c:\repo") { Set-Location "C:\repo" } 
    elseif (Test-Path -Path "c:\code") { Set-Location "c:\code" }
}