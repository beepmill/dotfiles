function Install-DotFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Source,
        [Parameter(Mandatory = $true)]
        $Destination,
        [switch]$Force # Create the destination path if it does not exist.
    )

    if (Test-Path $Source) {
        $src = Get-Item $Source
    }
    else {
        throw "Failed to access source path!`n$_"
    }

    if (-not (Test-Path $Destination)) {
        if ($Force) {
            try {
                Write-Verbose "Creating '$Destination'"
                $dest = New-Item -Path $Destination -ItemType Directory -Force
            }
            catch {
                throw "Unable to create path!`n$_"
            }
        }
            else {
                throw "Destination path '$Destination' does not exist!"
            }
    }
    else {
        $dest = Get-Item $Destination
    }

    Push-Location $src
    Get-ChildItem . -File -Recurse | ForEach-Object {
        # Make sure that the full path exists
        $rel_parent = Resolve-Path -Relative $_.FullName | Split-Path
        if (!($dest_parent = Join-Path $dest $rel_parent -Resolve)) {
            Write-Verbose "Creating '$(Join-Path $dest $rel_parent)'"
            New-Item -Path (Join-Path $dest $rel_parent) -ItemType Directory -Force
            $dest_parent = Join-Path $dest $rel_parent -Resolve
        }
        if (!($existing = Get-Item (Join-Path $dest_parent $_.Name) -ErrorAction SilentlyContinue)) {
            Write-Verbose "Linking ($($_.FullName)) -> ($(Join-Path $dest_parent $_.Name))"
            New-Item -ItemType HardLink -Path $dest_parent -Name $_.Name -Value $_.FullName
        }
        else {
            if ($existing.LinkType -eq 'HardLink') {
                Write-Warning "Link '$existing' already exists! -> ($($existing.Target[0]))"
            }
            else {
                Write-Warning "File '$existing' already exists!"
            }
        }
    }
    Pop-Location
}

# Install providers
if (!(Get-PackageProvider -Name NuGet)) {
    Install-PackageProvider -Name NuGet -Scope CurrentUser -Force
}
if (!(Get-PackageProvider -Name Chocolatey)) {
    Install-PackageProvider -Name Chocolatey -Scope CurrentUser -Force
    Import-PackageProvider -Name Chocolatey
}

# Install packages
('git.install',
 'tortoisegit',
 'meld') | ForEach-Object {
    if (!(Get-Package -Name $_ -ProviderName Chocolatey -ErrorAction SilentlyContinue)) {
        Install-Package -ProviderName Chocolatey -Name $_ -Force
    }
}

# Install modules
('posh-git',
 'PSReadline',
 'PSScriptAnalyzer') | ForEach-Object {
    if (!(Get-InstalledModule -Name $_ -ErrorAction SilentlyContinue)) {
        Install-Module $_ -Scope CurrentUser -Repository PSGallery -Force
    }
}

# Install dotfiles
Push-Location $PSScriptRoot
Install-DotFiles -Source .\userprofile -Destination $env:USERPROFILE -Verbose