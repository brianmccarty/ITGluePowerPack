$applications = @()
$applications += Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object -Property DisplayName, DisplayVersion, Publisher, InstallDate
$applications += Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object -Property DisplayName, DisplayVersion, Publisher, InstallDate

# foreach($app in $applications) {
#     if($app.Publisher -eq "Microsoft Corporation"){$publisher = "Microsoft"} else {$publisher = $app.Publisher}
#     $data = @{
#         type = "flexible_assets"
#         attributes = @{
#             organization_id = 2504761
#             flexible_asset_type_id = 89651
#             traits = @{
#                 manufacturer = $publisher
# 	            name = $app.DisplayName
# 	            version = $app.DisplayVersion
#             }
#         }
#     }
#     $app.Publisher
#     #New-ITGlueFlexibleAssets -data $data
# }

$applications | ?{$_.displayname -like "Microsoft Office 365*"}