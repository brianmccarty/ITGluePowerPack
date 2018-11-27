[cmdletbinding(DefaultParameterSet="DontSaveSettings")]
param(
    [Parameter(ParameterSetName="SaveSettings",ValueFromPipeline=$true)]
    $API_Key,

    [Parameter(ParameterSetName="SaveSettings")]
    [ValidateSet("EU","US")]
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

if($PSCmdlet.ParameterSetName -eq "SaveSettings") {
	# Settings
	Add-ITGlueAPIKey -ApiKey $API_Key
	if($Data_Center) {Add-ITGlueBaseURI -data_center $Data_Center}

	# Save settings
	Export-ITGlueModuleSettings
}