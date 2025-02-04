####    Git Commands
function gcl($url) { git clone $url }
function gpr { git pull --rebase }
function gs { git status }
function gss { git status -s }
function ga { git add . }
function gcom { git commit -m $args }

###     PSReadLineOptions
$PSReadLineOptions = @{
    EditMode = 'Windows'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    PredictionSource = 'History'
    PredictionViewStyle = 'ListView'
}

Set-PSReadLineOption @PSReadLineOptions

###     Pimp my terminal

if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck    
}

Import-Module -Name Terminal-Icons

oh-my-posh init pwsh --config $env:USERPROFILE'\AppData\Local\Programs\oh-my-posh\themes\gruvbox.omp.json' | Invoke-Expression