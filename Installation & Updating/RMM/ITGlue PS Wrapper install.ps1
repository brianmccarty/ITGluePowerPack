#Requires -Version 5
[cmdletbinding(DefaultParameterSetName="Silent")]
param(
	[Parameter(ParameterSetName="Loud")]
    [Parameter(ParameterSetName="Silent")]
    [String]$APIKey = "",

    [Parameter(ParameterSetName="Loud")]
    [Parameter(ParameterSetName="Silent")]
    [Alias('locale','dc')]
    [ValidateSet( 'US', 'EU')]
    [String]$DataCenter = '',

    [Parameter(ParameterSetName="Loud")]
    [Parameter(ParameterSetName="Silent")]
    [Switch]$SaveSettings,

    [Parameter(ParameterSetName="Log")]
    [Switch]$Log,

    [Parameter(
    	ParameterSetName="Log",
    	Mandatory=$true)]
    [String]$Path,

    [Parameter(
    	ParameterSetName="Log",
    	Mandatory=$true)]
    [String]$LogFile
)

if($Path.EndsWith("\")) {
	$Path.Remove($Path.Length -1)
}
if($LogFile.EndsWith("\")) {
	$LogFile.Remove($LogFile.Length -1)
}

Try {
	[io.file]::OpenWrite("$env:ProgramFiles\WindowsPowerShell\Modules\test.file").close()
	[io.file]::OpenWrite("$Path\$LogFile").close()
	Remove-Item "$env:ProgramFiles\WindowsPowerShell\Modules\test.file"
} Catch {
	"Unable to update." | Out-File -Append -FilePath $Path
	"You do not have access to $env:ProgramFiles\WindowsPowerShell\Modules\." | Out-File -Append -FilePath $Path
	exit
}

# Download required software
if($Log) {"$(Get-Date) Downloading ITGlueAPI PowerShell wrapper..." | Out-File -Append -FilePath $Path -NoNewline}
Invoke-WebRequest "https://codeload.github.com/itglue/powershellwrapper/zip/master" -OutFile .\ITGlueAPI.zip
if($Log) {"$(Get-Date) Complete!" | Out-File -Append -FilePath $Path}

# Extract
if($Log) {"$(Get-Date) Extracting to $($PWDp)owershellwrapper-master..." | Out-File -Append -FilePath $Path -NoNewline}
Expand-Archive -Path .\ITGlueAPI.zip -DestinationPath .\ -Force
if($Log) {"$(Get-Date) Complete!" | Out-File -Append -FilePath $Path}

# Copy
if($Log) {"$(Get-Date) Coping to $env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI..." | Out-File -Append -FilePath $Path -NoNewline}
Copy-Item ".\powershellwrapper-master\ITGlueAPI" "$env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI" -Recurse -Force
if($Log) {"$(Get-Date) Complete!" | Out-File -Append -FilePath $Path}

# Delete items
if($Log) {"$(Get-Date) Deleting $($PWD)ITGlueAPI.zip..." | Out-File -Append -FilePath $Path -NoNewline}
Remove-Item .\ITGlueAPI.zip
if($Log) {"$(Get-Date) Complete!" | Out-File -Append -FilePath $Path}
Remove-Item .\powershellwrapper-master -Recurse
if($Log) {"$(Get-Date) Deleting $($PWD)powershellwrapper-master..." | Out-File -Append -FilePath $Path -NoNewline}
if($Log) {"$(Get-Date) Complete!" | Out-File -Append -FilePath $Path}
if($Log) {"$(Get-Date) " | Out-File -Append -FilePath $Path}

# Import ITGlue API
if($Log) {"$(Get-Date) Importing ITGlueAPI module" | Out-File -Append -FilePath $Path}
Import-Module ITGlueAPI

# Add Base URI for the API
if($APIKey -ne "") {
	if($Log) {"$(Get-Date) Adding ITGlue API key" | Out-File -Append -FilePath $Path}
	Add-ITGlueAPIKey -Api_Key $APIKey
}

if($DataCenter -ne "") {
	if($Log) {"$(Get-Date) Adding base URI, datacenter: $DataCenter" | Out-File -Append -FilePath $Path}
	Add-ITGlueBaseURI -data_center $DataCenter
} else {
	if($Log) {"$(Get-Date) Default is base URI is https://api.itglue.com" | Out-File -Append -FilePath $Path}
}

# Save API key for user
if($SaveSettings) {
	if($Log) {"$(Get-Date) Exporting settings..." | Out-File -Append -FilePath $Path -NoNewline}
	Export-ITGlueModuleSettings
	if($Log) {"$(Get-Date) Complete!" | Out-File -Append -FilePath $Path}
}

## Commented out because change on ITGlue's side. Does not work.
# $utf8fix = @'
# $ITGlue_Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
# $ITGlue_Headers.Add("Content-Type", 'application/vnd.api+json; charset=utf-8')

# Set-Variable -Name "ITGlue_Headers"  -Value $ITGlue_Headers -Scope global


# Import-ITGlueModuleSettings
# '@
# $utf8fix > "$env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI\ITGlueAPI.psm1"