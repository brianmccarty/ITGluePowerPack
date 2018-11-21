#Requires -Modules @{ ModuleName="ITGlueAPI"; ModuleVersion="2.0.0" }
#Requires -Version 3
[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [int64]$OrganizationId,

    [Parameter(Mandatory=$true)]
    [int64]$FlexibleAssetTypeId,

    [int64[]]$ApplicationAdminsId,

    [ValidateSet("Yes","No")]
    [String]$ManagedByUs = "Yes",

    [AllowNull()]
    [String]$License = "",

    [AllowNull()]
    [String]$LicenseExpireDate = "",

    [int64[]]$FinancialOwnerId,

    [int64[]]$SpecialistsId,
    
    [Switch]$TagConfiguration
)

$application = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\O365BusinessRetail*" -ErrorAction Stop

if($TagConfiguration) {
    $ComputerId = (Get-ITGlueConfigurations -organization_id $OrganizationId -filter_name $env:COMPUTERNAME).data.id
} else {
	$ComputerId = $null
}

$data = @{
	type = "flexible_assets"
	attributes = @{
		organization_id = $OrganizationId
		flexible_asset_type_id = $FlexibleAssetTypeId
		traits = @{
			"application-name"                            = "Microsoft Office 365"
			"application-version"                         = "$($application.DisplayVersion) - $($application.PSChildName)"
			"managed-by-us"                               = $ManagedByUs
			"license-key"                                 = $License
			"license-expires"                             = $LicenseExpireDate
			"license-volume"                              = 1
			"contains-personal-data"                      = "Yes"
			"application-admin-s-at-the-customer"         = $ApplicationAdminsId
			"financial-application-owner-at-the-customer" = $FinancialOwnerId
			"our-specialist-s"                            = $SpecialistsId
			"how-is-this-application-delivered"           = "Locally from a computer"
            "associated-servers-s-or-computer-s"          = $ComputerId 
			"application-user-interface"                  = "Browser, client software and mobile App"
            "application-url-if-available"                = "http://login.microsoftonline.com/"

		}
	}
}

$resp = New-ITGlueFlexibleAssets -data $data
return $resp.data.id