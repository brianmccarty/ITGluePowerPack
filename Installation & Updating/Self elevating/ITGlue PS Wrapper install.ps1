[cmdletbinding(DefaultParameterSetName="Loud")]
param(
	[Parameter(ParameterSetName="Loud","Silent")]
    [String]$APIKey = "",

	[Parameter(ParameterSetName="Loud","Silent")]
    [Switch]$ExportAPIKey,

	[Parameter(ParameterSetName="Loud","Silent")]
    [Alias('locale','dc')]
    [ValidateSet( 'US', 'EU')]
    [String]$DataCenter = '',

	[Parameter(ParameterSetName="Loud","Silent")]
    [Switch]$SaveSettings,

    [Parameter(ParameterSetName="Silent")]
    [Switch]$Silent
)

# Code from http://www.expta.com/2017/03/how-to-self-elevate-powershell-script.html
# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

Try {
	[io.file]::OpenWrite("$env:ProgramFiles\WindowsPowerShell\Modules\test.file").close()
	Remove-Item "$env:ProgramFiles\WindowsPowerShell\Modules\test.file"
} Catch {
	Write-Warning "Unable to update."
	Write-Warning "You do not have access to $env:ProgramFiles\WindowsPowerShell\Modules\."
	exit
}

# Download required software
if(!$Silent) {Write-Host 'Downloading ITGlueAPI PowerShell wrapper... ' -NoNewline}
Invoke-WebRequest "https://codeload.github.com/itglue/powershellwrapper/zip/master" -OutFile .\ITGlueAPI.zip
if(!$Silent) {Write-Host 'Complete!'}

# Extract
if(!$Silent) {Write-Host "Extracting to $($PWDp)owershellwrapper-master... " -NoNewline}
Expand-Archive -Path .\ITGlueAPI.zip -DestinationPath .\ -Force
if(!$Silent) {Write-Host "Complete!"}

# Copy
if(!$Silent) {Write-Host "Coping to $env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI... " -NoNewline}
Copy-Item ".\powershellwrapper-master\ITGlueAPI" "$env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI" -Recurse -Force
if(!$Silent) {Write-Host "Complete!"}

# Delete items
if(!$Silent) {Write-Host "Deleting $($PWD)ITGlueAPI.zip... " -NoNewline}
Remove-Item .\ITGlueAPI.zip
if(!$Silent) {Write-Host "Complete!"}
Remove-Item .\powershellwrapper-master -Recurse
if(!$Silent) {Write-Host "Deleting $($PWD)powershellwrapper-master... " -NoNewline}
if(!$Silent) {Write-Host "Complete!"}
if(!$Silent) {Write-Host ""}

# Import ITGlue API
if(!$Silent) {Write-Host "Importing module..."}
Import-Module ITGlueAPI

# Add Base URI for the API
if($APIKey -ne "") {
if(!$Silent) {Write-Host "Adding your API key"}
	Add-ITGlueAPIKey -Api_Key $APIKey
}

if($DataCenter -ne "") {
	if(!$Silent) {Write-Host "Setting up base URI, datacenter: $DataCenter"}
	Add-ITGlueBaseURI -data_center $DataCenter
} else {
	if(!$Silent) {Write-Host "Setting up base URI, datacenter: US"}
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