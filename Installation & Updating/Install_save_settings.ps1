param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    $API_Key,
    [Parameter(ValueFromPipeline=$true)]
    $Data_Center
)

# Preperations
if (-not ((Get-PackageProvider).name -contains "NuGet")) {
    Install-PackageProvider -Name "NuGet" -Force
}
if (-not ((Get-PSRepository).name -contains "PSGallery")) {
    Register-PSRepository -Default
}
if((Get-PSRepository -Name PSGallery).InstallationPolicy -eq "Untrusted") {
    Set-PSRepository -InstallationPolicy Trusted -Name PSGallery
}

# Installation
Install-Module ITGlueAPI -Force

# Settings

# Save settings