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
function nano ($File) { bash -c "nano $File" }

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
oh-my-posh init pwsh --config $env:USERPROFILE'\AppData\Local\Programs\oh-my-posh\themes\gruvbox.omp.json' | Invoke-Expression

###    Functions
function Pull-Branch {
    param (
        [string]$rootPath,
        [string]$branch = 'main'
    )
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

# Crate a new function that will clear the branches that are non-existent in the remote repository.
function Clear-NonExistentBranches {
    # Ensure the script stops on errors
    $ErrorActionPreference = "Stop"

    # Function to clean stale branches in a given Git repository
    function Clean-StaleBranches($repoPath) {
        Write-Output "Processing repository at: $repoPath"
        Set-Location $repoPath

        # Fetch latest remote branches and prune deleted ones
        Write-Output "Fetching latest branches from remote..."
        git fetch --prune

        # Get all local branches
        $localBranches = git branch | ForEach-Object { $_.Trim() }

        # Get all remote branches
        $remoteBranches = git branch -r | ForEach-Object { $_.Trim() -replace '^origin/', '' }

        # Identify local branches that no longer exist on remote
        $branchesToDelete = $localBranches | Where-Object { $_ -ne "main" -and $_ -ne "master" -and $_ -notin $remoteBranches }

        if ($branchesToDelete) {
            Write-Output "Deleting the following stale branches:"
            $branchesToDelete | ForEach-Object { Write-Output $_ }

            # Delete each stale branch
            $branchesToDelete | ForEach-Object { git branch -D $_ }
        }
        else {
            Write-Output "No stale branches found in $repoPath."
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

    Write-Output "Cleanup complete!"
}