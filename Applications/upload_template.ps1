[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [int64]$organization_id,

    [Parameter(Mandatory=$true)]
    [int64]$flexible_asset_type_id
)


$applications = @()
$applications += Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object -Property DisplayName, DisplayVersion, Publisher, InstallDate
$applications += Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object -Property DisplayName, DisplayVersion, Publisher, InstallDate

$applications | Where {$_.displayname -like "Application Name"} | ForEach {
	$data = @{
		type = "flexible_assets"
		attributes = @{
			organization_id = 2504761
			flexible_asset_type_id = 89651
			traits = @{
				manufacturer = $app.Publisher
				name = $app.DisplayName
				version = $app.DisplayVersion
			}
		}
	}
	New-ITGlueFlexibleAssets -data $data
}