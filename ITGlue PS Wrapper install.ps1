[cmdletbinding(DefaultParameterSetName="Loud")]
param(
	[Parameter(ParameterSetName="Loud")]
	[Parameter(ParameterSetName="SilentInstall")]
    [String]$APIKey = "",

    [Parameter(ParameterSetName="Loud")]
	[Parameter(ParameterSetName="SilentInstall")]
    [Switch]$ExportAPIKey,

    [Parameter(ParameterSetName="Loud")]
	[Parameter(ParameterSetName="SilentInstall")]
    [Alias('locale','dc')]
    [ValidateSet( 'US', 'EU')]
    [String]$DataCenter = '',

    [Parameter(ParameterSetName="Loud")]
	[Parameter(ParameterSetName="SilentInstall")]
    [Switch]$SaveSettings,

    [Parameter(ParameterSetName="SilentInstall")]
    [Switch]$Silent
)


# Download required software
if(!$Silent) {Write-Host 'Downloading ITGlueAPI PowerShell wrapper... ' -NoNewline}
Invoke-WebRequest 'https://codeload.github.com/itglue/powershellwrapper/zip/master' -OutFile .\ITGlueAPI.zip
if(!$Silent) {Write-Host 'Complete!'}

# Extract
if(!$Silent) {Write-Host 'Extracting to $PWD\powershellwrapper-master... ' -NoNewline}
Expand-Archive -Path .\ITGlueAPI.zip -DestinationPath .\ -Force
if(!$Silent) {Write-Host 'Complete!'}

# Copy
if(!$Silent) {Write-Host 'Coping to $env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI... ' -NoNewline}
Copy-Item '.\powershellwrapper-master\ITGlueAPI' "$env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI" -Recurse -Force
if(!$Silent) {Write-Host 'Complete!'}

# Delete items
if(!$Silent) {Write-Host 'Deleting $PWD\ITGlueAPI.zip... ' -NoNewline}
Remove-Item .\ITGlueAPI.zip
if(!$Silent) {Write-Host 'Complete!'}
Remove-Item .\powershellwrapper-master -Recurse
if(!$Silent) {Write-Host 'Deleting $PWD\powershellwrapper-master... ' -NoNewline}
if(!$Silent) {Write-Host 'Complete!'}
if(!$Silent) {Write-Host ''}

# Import ITGlue API
Import-Module ITGlueAPI

# Add Base URI for the API
if($APIKey -ne "") {
	Add-ITGlueAPIKey -Api_Key $APIKey
}

if($DataCenter -ne "") {
	Add-ITGlueBaseURI -data_center $DataCenter
} else {
	Add-ITGlueBaseURI
}

# Save API key for user
if($SaveSettings) {
	if(!$Silent) {Write-Host 'Exporting settings... ' -NoNewline}
	Export-ITGlueModuleSettings
	if(!$Silent) {Write-Host 'Complete!'}
}

## Commented out because change on ITGlue's side. Does not work.
# $utf8fix = @'
# $ITGlue_Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
# $ITGlue_Headers.Add("Content-Type", 'application/vnd.api+json; charset=utf-8')

# Set-Variable -Name "ITGlue_Headers"  -Value $ITGlue_Headers -Scope global


# Import-ITGlueModuleSettings
# '@
# $utf8fix > "$env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI\ITGlueAPI.psm1"