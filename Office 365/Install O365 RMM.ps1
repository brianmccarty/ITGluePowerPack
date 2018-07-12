<#
.SYNOPSIS
    Installs the AzureAD module in order to connect to Office 365. Requires eleveted shell.
.DESCRIPTION
    This script saves your username and password in -path\o365credentials.xml. $Path\ is by default "$env:USERPROFILE\UpstreamPowerPack" unless specified with the -path parameter.
.PARAMETER Username
    Your Office 365 username. This will be saved in -path\o365credentials.xml unless specifed not to.
.PARAMETER Password
    Your Office 365 password. This will be saved in -path\o365credentials.xml unless specifed not to.
.PARAMETER Path
    Default $env:USERPROFILE\UpstreamPowerPack. Set this parameter if you want to store your credentials somewhere else.
.EXAMPLE
    C:\PS> '.\Install O365 Automated version.ps1' -Username "user@example.com" -Password "weakpassword" -SaveCredentials
    Installs AzureAD module and exports your credentials to %userprofile%\UpstreamPowerPack\o365credentials.xml.
.EXAMPLE
    C:\PS> '.\Install O365 Automated version.ps1' -Username "user@example.com" -Password "weakpassword" -path "C:\Office\API" -SaveCredentials
    Installs AzureAD module and exports your credentials to C:\Office\API\o365credentials.xml.
.EXAMPLE
    C:\PS> '.\Install O365 Automated version.ps1'
    Only installs AzureAD module.
.NOTES
    Author:  Emile Priller
    Date:    08/05/2018
    Updated: 09/07/2018
#>
[CmdletBinding(DefaultParameterSetName="ManualMode")]
param(
    [Parameter(ParameterSetName="ManualMode")]
    [Switch]$ManualMode = $true,

    [Parameter(ParameterSetName="RMM")]
    [Switch]$RMM,

    [Parameter(ParameterSetName="ManualMode")]
    [Parameter(ParameterSetName="RMM")]
    [string]$Username,

    [Parameter(ParameterSetName="ManualMode")]
    [Parameter(ParameterSetName="RMM")]
    [string]$Password,

    [Parameter(ParameterSetName="ManualMode")]
    [Parameter(ParameterSetName="RMM")]
    [string]$Path = "$env:USERPROFILE\UpstreamPowerPack",

    [Parameter(ParameterSetName="ManualMode")]
    [Parameter(ParameterSetName="RMM")]
    [Switch]$SaveCredentials
)

Function Write-Message {
    [CmdletBinding()]
    Param ($Message, [switch]$Warning, [switch]$Throw)

    if($Log) {
        Out-File -InputObject "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $($Message)" -FilePath $LogFile -Append
    }
    if($Warning) {
        Microsoft.PowerShell.Utility\Write-Verbose -Message "$Message"
    } elseif($Throw) {
        throw $Message
    } elseif($verbose) {
        Microsoft.PowerShell.Utility\Write-Warning -Message "$Message"
    }
}

Function Save-Credentials {
    Param(
        [Switch]$save,
        [String]$uname,
        [String]$pw,
        [String]$path
    )

    if($save) {
        $securePassword = ConvertTo-SecureString $pw -AsPlainText -Force
        $credentials = Get-Credential -Credential (New-Object -TypeName PSCredential -ArgumentList $uname,$securePassword)
        $credentials | Export-Clixml -Path $path\o365credentials.xml
        Write-Output -Message "Credentials saved to $path\o365credentials.xml."
    }
}

if(![bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")) {
    Write-Message -Message "Please run this script again as admin." -Throw
}

if($Path.EndsWith("\")) {
    $Path = $Path.Remove($Path.Length -1, 1)
}

if(-not (Test-Path -path $Path)) {
    try {
        New-Item $Path -ItemType Directory | %{$_.Attributes = "hidden"}
    } catch [Exception]{
        Write-Message -Message $_ -Throw
    }
}

if($ManualMode) {
    Install-Module AzureAD -Force

    if(SaveCredentials) {
        if($Username -ne "" -and $Password -ne "") {
            Save-Credentials -path $Path -uname $Username -pw $Password -save
        } else {
            Write-Output -Message "Not saving credentials because username or password was not provided."
        }
    }

    Write-Output "Press any key to exit."
    $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') > $null
} else {
    try {
        if(-not (Get-Module -name "AzureAD")) {
            if (-not ((Get-PackageProvider).name -contains "NuGet")) {
                Install-PackageProvider -Name "NuGet" -Force
            }

            if (-not ((Get-PSRepository).name -contains "PSGallery")) {
                Register-PSRepository -Default
            }

            if((Get-PSRepository -Name PSGallery).InstallationPolicy -eq "Untrusted") {
                Set-PSRepository -InstallationPolicy Trusted -Name PSGallery
            }

            Install-Module AzureAD -Force
        }
    } catch [Exception]{
        Write-Message -Message $_ -Warning
        Write-Message -Message "Exiting." -Warning
    }

    if(SaveCredentials) {
        if($Username -ne "" -and $Password -ne "") {
            Save-Credentials -path $Path -uname $Username -pw $Password -save
        } else {
            Write-Message -Message "Not saving credentials because username or password was not provided." -Warning
        }
    }
}