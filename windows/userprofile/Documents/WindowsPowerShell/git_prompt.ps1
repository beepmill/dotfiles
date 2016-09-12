# Add aliases
if (!(Get-Command -Name 'git' -ErrorAction SilentlyContinue)) {
    if (Test-Path "$($env:ProgramFiles)\Git\bin\git.exe" -ErrorAction SilentlyContinue) {
        Set-Alias -Name git -Value "$($env:ProgramFiles)\Git\bin\git.exe"
    } elseif (Test-Path "$(${env:ProgramFiles(x86)})\Git\bin\git.exe" -ErrorAction SilentlyContinue) {
        Set-Alias -Name git -Value "$(${env:ProgramFiles(x86)})\Git\bin\git.exe"
    }
}

Import-Module posh-git


# Set up a simple prompt, adding the git prompt parts inside git repos
function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    Write-Host($pwd.ProviderPath) -nonewline

    Write-VcsStatus

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}