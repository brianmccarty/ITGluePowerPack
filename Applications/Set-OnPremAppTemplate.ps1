#Requires -Modules @{ ModuleName="ITGlueAPI"; ModuleVersion="2.0.0" }
#Requires -Version 3
[cmdletbinding(DefaultParameterSetName="FindAssetId")]
param(
	[Parameter(ParameterSetName="FindConfig",   Position=0, Mandatory=$true)]
	[Parameter(ParameterSetName="FindAssetId",   Position=0, Mandatory=$true)]
	[Parameter(ParameterSetName="RemoveConfig", Position=0, Mandatory=$true)]
	[int64]$OrganizationId,

	[Parameter(ParameterSetName="FindConfig",   Position=1, Mandatory=$true)]
	[Parameter(ParameterSetName="FindAssetId",   Position=1, Mandatory=$true)]
	[Parameter(ParameterSetName="RemoveConfig", Position=1, Mandatory=$true)]
	[int64]$FlexibleAssetTypeId,

	[Parameter(ParameterSetName="FindAssetId",   Mandatory=$true, Position=2)]
	[Parameter(ParameterSetName="RemoveConfig", Mandatory=$true, Position=2)]
	[int64]$ConfigurationId,

	[Parameter(ParameterSetName="AssetId", Position=1, Mandatory=$true)]
	[Parameter(ParameterSetName="RemoveConfig",   Position=1, Mandatory=$true)]
	[int64]$FlexibleAssetId,

	[Parameter(ParameterSetName="FindConfig")]
	[Parameter(ParameterSetName="FindAssetId")]
	[Parameter(ParameterSetName="AssetId")]
	[int64[]]$ApplicationAdminsId,

	[Parameter(ParameterSetName="FindConfig")]
	[Parameter(ParameterSetName="FindAssetId")]
	[Parameter(ParameterSetName="AssetId")]
	[ValidateSet("Yes","No")]
	[String]$ManagedByUs = "Yes",

	[Parameter(ParameterSetName="FindConfig")]
	[Parameter(ParameterSetName="FindAssetId")]
	[Parameter(ParameterSetName="AssetId")]
	[AllowNull()]
	[String]$LicenseKey = "",

	[Parameter(ParameterSetName="FindConfig")]
	[Parameter(ParameterSetName="FindAssetId")]
	[Parameter(ParameterSetName="AssetId")]
	[AllowNull()]
	[String]$LicenseExpireDate = "",

	[Parameter(ParameterSetName="FindConfig")]
	[Parameter(ParameterSetName="FindAssetId")]
	[Parameter(ParameterSetName="AssetId")]
	[int64[]]$FinancialOwnerId,

	[Parameter(ParameterSetName="FindConfig")]
	[Parameter(ParameterSetName="FindAssetId")]
	[Parameter(ParameterSetName="AssetId")]
	[int64[]]$SpecialistsId,
	
	[Parameter(ParameterSetName="FindConfig")]
	[Switch]$FindConfigurationId,

	[Parameter(ParameterSetName="RemoveConfig")]
	[Switch]$RemoveConfiguration
)


# Specify the name of the application here.
# It has to be a valid option in onprem apps.
$ApplicationName = ""

# Below part is used to determind if the application is installed.
# Use HKLM:\SOFTWARE\WOW6432Node for 64-bit appliaction and
# HKLM:\SOFTWARE\ for 32-bit.
# As an example, Office 365 uses
# HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\O365BusinessRetail*
# The star is to catch either "en-us" or other languages.
if(-not $RemoveConfiguration) {
	$applications = @()
	# $registyPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
	# $registyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
	$applications += Get-ItemProperty -Path $registyPath | Select-Object -Property DisplayName, DisplayVersion, Publisher, InstallDate
}


$onPremApp = $null
if(-not $FlexibleAssetId) {
	# Find flexible asset
	$onPremApp = Get-ITGlueFlexibleAssets -filter_organization_id $OrganizationId -filter_flexible_asset_type_id $FlexibleAssetTypeId -filter_name $ApplicationName
} else {
	# Get flexible asset
	$onPremApp = Get-ITGlueFlexibleAssets -id $FlexibleAssetId
}

# If none find
if($onPremApp.meta.'total-count' -eq 0) {
    if($RemoveConfiguration) {
        # Cannot remove when the asset does not exist
        Write-Error "Cannot remove configuration because the asset does not exist."
    } else {
        # Not valid option
		Write-Error "Please create $ApplicationName under OnPrem Apps first."
    }
} elseif($onPremApp.meta.'total-count' -gt 1) {
	# Multiple assets found - use -FlexibleAssetId instead
	Write-Error "Multiple assets found. Please use FlexibleAssetId instead."
}

# If removing configuration from asset
if($RemoveConfiguration) {
	# All current configurations
	[System.Collections.ArrayList]$configs = $onPremApp.data.attributes.traits.'associated-servers-s-or-computer-s'.values.id
	# Remove $ConfigurationId
	$configs.Remove($ConfigurationId)

	# Build same object identical object without $ConfigurationId
	$data = @{
		type = "flexible-assets"
		attributes = @{
			'application-name'											= $onPremApp.data.attributes.traits.'application-name'
			'application-version'										= $onPremApp.data.attributes.traits.'application-version'
			'managed-by-us'												= $onPremApp.data.attributes.traits.'managed-by-us'
			'license-key'												= $onPremApp.data.attributes.traits.'license-key'
			'license-expires'											= $onPremApp.data.attributes.traits.'license-expires'
			'license-volume'											= $onPremApp.data.attributes.traits.'license-volume'
			'contains-personal-data'									= $onPremApp.data.attributes.traits.'contains-personal-data'
			'important-contacts'										= $onPremApp.data.attributes.traits.'important-contacts'
			'application-admin-s-at-the-customer'						= $onPremApp.data.attributes.traits.'application-admin-s-at-the-customer'.values.id
			'financial-application-owner-at-the-customer'				= $onPremApp.data.attributes.traits.'financial-application-owner-at-the-customer'.values.id
			'our-specialist-s'											= $onPremApp.data.attributes.traits.'our-specialist-s'.values.id
			'how-is-this-application-delivered'							= $onPremApp.data.attributes.traits.'how-is-this-application-delivered'
			'associated-servers-s-or-computer-s'						= $configs
			'application-user-interface'								= $onPremApp.data.attributes.traits.'application-user-interface'
			'application-url-if-available'								= $onPremApp.data.attributes.traits.'application-url-if-available'
			'is-there-any-ssl-certificate-s-used-by-this-application'	= $onPremApp.data.attributes.traits.'is-there-any-ssl-certificate-s-used-by-this-application'.values.id
			'client-installation-name'									= $onPremApp.data.attributes.traits.'client-installation-name'
			'rmm-deploy-script'											= $onPremApp.data.attributes.traits.'rmm-deploy-script'
			'password-s'												= $onPremApp.data.attributes.traits.'password-s'.values.id
			'security-groups-or-privileges-required'					= $onPremApp.data.attributes.traits.'security-groups-or-privileges-required'
			'licensed-users'											= $onPremApp.data.attributes.traits.'licensed-users'.values.id
			'upgraded-to-sql'											= $onPremApp.data.attributes.traits.'upgraded-to-sql'
		}
	}

	# Upload and exit
	Set-ITGlueFlexibleAssets -data $data -id $onPremApp.data.id
	return
}

# Find configuration based om computer name
if($FindConfigurationId) {
	$ConfigurationId = (Get-ITGlueConfigurations -organization_id $OrganizationId -filter_name $env:COMPUTERNAME).data.id
}

# Retain if null
if($LicenseKey -eq "") {
	$LicenseKey = $onPremApp.data.attributes.traits.'license-key'
}
# Retain if null
if($LicenseExpireDate -eq "") {
	$LicenseExpireDate = $onPremApp.data.attributes.traits.'license-expires'
}
# Retain if null
if($ApplicationAdminsId = $null) {
	$ApplicationAdminsId = $onPremApp.data.attributes.traits.'application-admin-s-at-the-customer'.values.id
}
# Retain if null
if($FinancialOwnerId = $null) {
	$FinancialOwnerId = $onPremApp.data.attributes.traits.'financial-application-owner-at-the-customer'.values.id
}
# Retain if null
if($SpecialistsId = $null) {
	$SpecialistsId = $onPremApp.data.attributes.traits.'our-specialist-s'.values.id
}

# Get old configurations and add the new one
$configs = $onPremApp.data.attributes.traits.'associated-servers-s-or-computer-s'.values.id
$configs += $ConfigurationId

# Build object
$data = @{
	type = "flexible-assets"
	attributes = @{
		'application-name'											= $onPremApp.data.attributes.traits.'application-name'
		'application-version'										= $onPremApp.data.attributes.traits.'application-version'
		'managed-by-us'												= "Yes"
		'license-key'												= $LicenseKey
		'license-expires'											= $LicenseExpireDate
		'license-volume'											= $onPremApp.data.attributes.traits.'license-volume'
		'contains-personal-data'									= "$onPremApp.data.attributes.traits.'contains-personal-data'"
		'important-contacts'										= $onPremApp.data.attributes.traits.'important-contacts'
		'application-admin-s-at-the-customer'						= $ApplicationAdminsId
		'financial-application-owner-at-the-customer'				= $FinancialOwnerId
		'our-specialist-s'											= $SpecialistsId
		'how-is-this-application-delivered'							= $onPremApp.data.attributes.traits.'how-is-this-application-delivered'
		'associated-servers-s-or-computer-s'						= $configs
		'application-user-interface'								= $onPremApp.data.attributes.traits.'application-user-interface'
		'application-url-if-available'								= $onPremApp.data.attributes.traits.'application-url-if-available'
		'is-there-any-ssl-certificate-s-used-by-this-application'	= $onPremApp.data.attributes.traits.'is-there-any-ssl-certificate-s-used-by-this-application'.values.id
		'client-installation-name'									= $onPremApp.data.attributes.traits.'client-installation-name'
		'rmm-deploy-script'											= $onPremApp.data.attributes.traits.'rmm-deploy-script'
		'password-s'												= $onPremApp.data.attributes.traits.'password-s'.values.id
		'security-groups-or-privileges-required'					= $onPremApp.data.attributes.traits.'security-groups-or-privileges-required'
		'licensed-users'											= $onPremApp.data.attributes.traits.'licensed-users'.values.id
		'upgraded-to-sql'											= $onPremApp.data.attributes.traits.'upgraded-to-sql'
	}
}
# Update ITGlue
Set-ITGlueFlexibleAssets -data $data -id $onPremApp.data.id