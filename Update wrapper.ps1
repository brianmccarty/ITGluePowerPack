[cmdletbinding(DefaultParameterSetName="Silent")]
param(
    [Parameter(ParameterSetName="Silent")]
    [Switch]$Silent
)

#Test write access
Try {
	[io.file]::OpenWrite("$env:ProgramFiles\WindowsPowerShell\Modules\test.file").close()
	Remove-Item "$env:ProgramFiles\WindowsPowerShell\Modules\test.file"
} Catch {
	Write-Warning "Unable to update."
	Write-Warning "You do not have access to $env:ProgramFiles\WindowsPowerShell\Modules\."
	exit
}

# Download required software
if(!$Silent){Write-Host "Downloading ITGlueAPI PowerShell wrapper... " -NoNewline}
Invoke-WebRequest "https://codeload.github.com/itglue/powershellwrapper/zip/master" -OutFile .\ITGlueAPI.zip
if(!$Silent){Write-Host "Complete!"}

# Extract
if(!$Silent){Write-Host "Extracting to $PWD\powershellwrapper-master... " -NoNewline}
Expand-Archive -Path .\ITGlueAPI.zip -DestinationPath .\ -Force
if(!$Silent){Write-Host "Complete!"}

# Delete old directory
if(!$Silent){Write-Host "Removing $env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI... " -NoNewline}
Get-ChildItem "$env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI" -Recurse | Remove-Item -Force -Recurse
if(!$Silent){Write-Host "Complete!"}

# Copy
if(!$Silent){Write-Host "Coping to $env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI... " -NoNewline}
Copy-Item ".\powershellwrapper-master\ITGlueAPI" "$env:ProgramFiles\WindowsPowerShell\Modules\ITGlueAPI" -Recurse -Force
if(!$Silent){Write-Host "Complete!"}

# Delete items
if(!$Silent){Write-Host "Deleting $PWD\ITGlueAPI.zip... " -NoNewline}
Remove-Item .\ITGlueAPI.zip
if(!$Silent){Write-Host "Complete!"}
Remove-Item .\powershellwrapper-master -Recurse
if(!$Silent){Write-Host "Deleting $PWD\powershellwrapper-master... " -NoNewline}
if(!$Silent){Write-Host "Complete!"}
if(!$Silent){Write-Host ""}
