#Requires -Version 5
#Requires -RunAsAdministrator
[cmdletbinding(DefaultParameterSetName="Silent")]
param(
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

#Test write access
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
if(!$Log){"Downloading ITGlueAPI PowerShell wrapper... " | Out-File -Append -FilePath $Path -NoNewline}
Invoke-WebRequest "https://codeload.github.com/itglue/powershellwrapper/zip/master" -OutFile .\ITGlueAPI.zip
if(!$Log){"Complete!" | Out-File -Append -FilePath $Path}

# Extract
if(!$Log){"Extracting to $PWD\powershellwrapper-master... " | Out-File -Append -FilePath $Path -NoNewline}
Expand-Archive -Path .\ITGlueAPI.zip -DestinationPath .\ -Force
if(!$Log){"Complete!" | Out-File -Append -FilePath $Path}

# Delete old directory
if(!$Log){"Removing $env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI... " | Out-File -Append -FilePath $Path -NoNewline}
Get-ChildItem "$env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI" -Recurse | Remove-Item -Force -Recurse
if(!$Log){"Complete!" | Out-File -Append -FilePath $Path}

# Copy
if(!$Log){"Coping to $env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI... " | Out-File -Append -FilePath $Path -NoNewline}
Copy-Item ".\powershellwrapper-master\ITGlueAPI" "$env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI" -Recurse -Force
if(!$Log){"Complete!" | Out-File -Append -FilePath $Path}

# Delete items
if(!$Log){"Deleting $PWD\ITGlueAPI.zip... " | Out-File -Append -FilePath $Path -NoNewline}
Remove-Item .\ITGlueAPI.zip
if(!$Log){"Complete!" | Out-File -Append -FilePath $Path}

if(!$Log){"Deleting $PWD\powershellwrapper-master... " | Out-File -Append -FilePath $Path -NoNewline}
Remove-Item .\powershellwrapper-master -Recurse
if(!$Log){"Complete!" | Out-File -Append -FilePath $Path}