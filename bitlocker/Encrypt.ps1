<#
.SYNOPSIS
    Encrypt hard drive with Bitlock and upload keys to ITGlue.
.DESCRIPTION
    This script uses Enable-Bitlocker to encrypt a hard drive with Recovery Password. For each drive encrypted a new asset will be created in ITGlue.
.PARAMETER OrganizationId
    ID of organization in ITGlue to upload keys to.
.PARAMETER OrganizationName
    Name of organization in ITGlue to upload keys to. Has to be exact match.
.PARAMETER FindConfiguration
    Indicates that the script will look for the configuration in ITGlue. Specify name with -ConfigurationName.
.PARAMETER CreateConfiguration
    Indicates that the script will create a new configuration if no configuration was found or no configuration ID was given.
.PARAMETER ConfigurationId
    ID of configuration in ITGlue.
.PARAMETER ConfigurationName
    Name of configuration in ITGlue. Default is $env:COMPUTERNAME (name of computer).
.PARAMETER ConfigurationType
    Which type of configuration. Default is desktop.
.PARAMETER FlexibleAssetId
    ID of flexible asset in ITGlue.
.PARAMETER MountPoint
    Which hard drive(s) to encrypt. If several drives are given multiple assets will be created in ITGlue.
.PARAMETER EnableLoggning
    Outputs everything to a file. Change location with -Path.
.PARAMETER Path
    Specifies the location of the log file. Default us $env:USERPROFILE\UpstreamPowerPack. The folder will be created if it does not exist.
.EXAMPLE
    .\Encrypt.ps1 -OrganizationId 2504761 -FlexibleAssetId 90253 -MountPoint c
    Encrypt drive C and upload to organization with ID 2504761.
.EXAMPLE
    .\Encrypt.ps1 -OrganizationName "Happy Dog" -FlexibleAssetId 90253 -MountPoint c
    Encrypt drive C and upload to organization Happy Dog.
.EXAMPLE
    .\Encrypt.ps1 -OrganizationId 2504761 -FlexibleAssetId 90253 -MountPoint c,d
    Encrypt drive C and D.
.EXAMPLE
    .\Encrypt.ps1 -OrganizationId 2504761 -FlexibleAssetId 90253 -MountPoint c -EnableLoggning
    Encrypt drive C with loggning enabled.
.EXAMPLE
    .\Encrypt.ps1 -OrganizationId 2504761 -FlexibleAssetId 90253 -MountPoint c -EnableLoggning -Path "D:\example\logs"
    Encrypt drive C with loggning enabled and path changed to D:\example\logs.
.EXAMPLE
    .\Encrypt.ps1 -OrganizationId 2504761 -FlexibleAssetId 90253 -MountPoint c -FindConfiguration
    Encrypt drive C and find configuration ID with name $env:COMPUTERNAME.
.EXAMPLE
    .\Encrypt.ps1 -OrganizationId 2504761 -FlexibleAssetId 90253 -MountPoint c -FindConfiguration -ConfigurationName "SESOL01SRV01"
    Encrypt drive C and find configuration ID with name "SESOL01SRV01".
.EXAMPLE
    .\Encrypt.ps1 -OrganizationId 2504761 -FlexibleAssetId 90253 -MountPoint c -FindConfiguration -CreateConfiguration
    Encrypt drive C and find configuration ID with name $env:COMPUTERNAME and create a new configuration if none was found.
.EXAMPLE
    .\Encrypt.ps1 -OrganizationId 2504761 -FlexibleAssetId 90253 -MountPoint c -FindConfiguration -ConfigurationName "SESOL01SRV01" -CreateConfiguration
    reEncrypt drive C and find configuration ID with name "SESOL01SRV01" and create a new configuration if none was found with name "SESOL01SRV01"
.EXAMPLE
    .\Encrypt.ps1 -OrganizationId 2504761 -FlexibleAssetId 90253 -MountPoint c -ConfigurationId 14424920
    Encrypt drive C and and match it to configuration ID 14424920.
.NOTES
    Author: Emile Priller
    Date:   2018-06-20
#>

[cmdletbinding(DefaultParameterSetName="ccwoid")]
param(
    [Parameter(ParameterSetName="ccwoid", Mandatory=$true)]
    [Parameter(ParameterSetName="fccwoid", Mandatory=$true)]
    [Parameter(ParameterSetName="cidwoid", Mandatory=$true)]
    [int]$OrganizationId,

    [Parameter(ParameterSetName="ccwon", Mandatory=$true)]
    [Parameter(ParameterSetName="fccwon", Mandatory=$true)]
    [Parameter(ParameterSetName="cidwon", Mandatory=$true)]
    [String]$OrganizationName,

    [Parameter(ParameterSetName="fccwoid")]
    [Parameter(ParameterSetName="fccwon")]
    [Switch]$FindConfiguration,

    [Parameter(ParameterSetName="ccwoid")]
    [Parameter(ParameterSetName="ccwon")]
    [Parameter(ParameterSetName="fccwoid")]
    [Parameter(ParameterSetName="fccwon")]
    [Switch]$CreateConfiguration,

    [Parameter(ParameterSetName="cidwoid", Mandatory=$true)]
    [Parameter(ParameterSetName="cidwon", Mandatory=$true)]
    [int]$ConfigurationId,

    [Parameter(ParameterSetName="ccwoid")]
    [Parameter(ParameterSetName="ccwon")]
    [Parameter(ParameterSetName="fccwoid")]
    [Parameter(ParameterSetName="fccwon")]
    [String]$ConfigurationName=$env:ComputerName,

    [Parameter(ParameterSetName="ccwoid")]
    [Parameter(ParameterSetName="ccwon")]
    [Parameter(ParameterSetName="fccwoid")]
    [Parameter(ParameterSetName="fccwon")]
    [String]$ConfigurationType = "Desktop",


    [Parameter(Mandatory=$true)]
    [String]$FlexibleAssetId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("A:","B:","C:","D:","E:","F:","G:","H:","I:","J:","K:","L:","M:","N:","O:","P:","Q:","R:","S:","T:","U:","V:","W:","X:","Y:","Z:","a:","b:","c:","d:","e:","f:","g:","h:","i:","j:","k:","l:","m:","n:","o:","p:","q:","r:","s:","t:","u:","v:","w:","x:","y:","z:","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")]
    [String[]]$MountPoint,

    [Alias("Log", "ErrorLog")]
    [Switch]$EnableLoggning,

    [String]$Path = "$env:USERPROFILE\UpstreamPowerPack",
    [String]$LogFile = "$Path\Encrypt.ps1_$(Get-Date -Format "yyyy-MM-dd").log"
)


if($Path.EndsWith("\")) {
    $Path = $Path.Remove($Path.Length -1, 1)
}

if($PSBoundParameters.Verbose) {
    $verbose = $true
}
Function Write-Verbose {
    [CmdletBinding()]
    Param ($Message)

    if($EnableLoggning) {
        Out-File -InputObject "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $($Message)" -FilePath $LogFile -Append
    }
    if($verbose) {
        Microsoft.PowerShell.Utility\Write-Verbose -Message "$Message"
    }
}

Function New-Configuration {
    Write-Verbose "Creating new configuration."
    # Get or create IDs if not existing

    # Manufacturers
    Write-Verbose "Searching for manufacturer in ITGlue..."
    if($manufacturer = (Get-ITGlueManufacturers -filter_name (Get-WmiObject Win32_BIOS).Manufacturer)) {
        Write-Verbose "Manufacturer found: $($manufacturer.data.id), '$($manufacturer.data.attributes.name)'."
    } elseif($manufacturer = New-ITGlueManufacturers -data (@{data = @{type = "manufacturers";attributes = @{name = (Get-WmiObject Win32_BIOS).Manufacturer}}})) {
        Write-Verbose "Manufacturer not found, created: $($manufacturer.data.id), '$($manufacturer.data.attributes.name)'."
    }


    # Model ID
    # Look for model in ITGlue
    Write-Verbose "Searching for model in ITGlue..."
    if($model = (Get-ITGlueModels -manufacturer_id $manufacturer.data.id).data) {
        Write-Verbose "Model found: $($model.attributes)."
    # If not found, create new.
    } elseif($model = New-ITGlueModels -data (@{data = @{type = "models";attributes = @{manufacturer_id = $manufacturer.data.id;name = (Get-WmiObject Win32_Computersystem).Model}}})) {
        Write-Verbose "Model not found, created: $($model.attributes)."
    }

    # Windows version
    $itGlueOS = Get-ITGlueOperatingSystems

    foreach ($os in $itGlueOS.data) {
        if(([WmiClass]"\\localhost\root\default:stdRegProv").GetStringValue(2147483650, "SOFTWARE\Microsoft\Windows NT\CurrentVersion", "ProductName").sValue -like "$($os.attributes.name)*") {
            $windowsVersion = $os.id
        }
    }

    # Network interfaces
    Write-Verbose "Searching for network interfaces..."
    $interfaceArray = @();
    # Mark first as primary.
    $firstAsPrimary = $true
    Get-NetAdapter | ForEach-Object {
        Write-Verbose "Found interface: $($_.InterfaceAlias), $((Get-NetIPConfiguration -InterfaceIndex $_.InterfaceIndex).IPv4Address.IPAddress), primary: $($firstAsPrimary)"
        $interfaceArray += @{
            type = "configuration_interfaces"
            attributes = @{
                ip_address = (Get-NetIPConfiguration -InterfaceIndex $_.InterfaceIndex).IPv4Address.IPAddress
                name = $_.InterfaceIndex
                primary = if($firstAsPrimary) {$firstAsPrimary = $false;$true} else {$false}
                notes = $_.InterfaceAlias
            }
        }
    }

    # New config
    $configuration = @{
        data = @{
            type = "configurations"
            attributes = @{
                organization_id = $OrganizationId
                configuration_type_id = (Get-ITGlueConfigurationTypes -filter_name $ConfigurationType).data.id
                configuration_status_id = (Get-ITGlueConfigurationStatuses -filter_name "Active").data.id
                manufacturer_id = $manufacturer.data.id
                model_id = $model.data.id
                Name = $ConfigurationName
                serial_number = (Get-WmiObject Win32_BIOS).SerialNumber

                hostname = $ConfigurationName
                primary_ip = $interfaceArray[0].Values."ip_address"
                mac_address = (Get-CimInstance win32_networkadapterconfiguration | Where {$_.ipaddress -eq $interfaceArray[0].Values."ip_address"}).MACAddress
                default_gateway = ((Get-CimInstance win32_networkadapterconfiguration | Where {$_.ipaddress -eq $interfaceArray[0].Values."ip_address"})).DefaultIPGateway
                operating_system_id = $windowsVersion
            }
            relationships = @{
                configuration_interfaces = @{
                    data = @(
                        $interfaceArray
                    )
                }
            }
        }
    }
    Write-Verbose "Configuration ready for upload:"
    Write-Verbose "$($configuration | ConvertTo-Json -Depth 100)"

    # Try to upload to ITGlue.
    try {
        Write-Verbose "Uploading configuration to ITGlue..."
        $thisConfiguration = New-ITGlueConfigurations -data $configuration
        Write-Verbose "URL: (your_company).itglue.com/$($OrganizationId)/configurations/$($thisConfiguration.data.id)"

    } catch {
        Write-Error "Error when uploading: $_"

    }
}


Write-Verbose "Being Encrypt.ps1 $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
Write-Verbose "PARAMETERS"
Write-Verbose "OrganizationId:      $($OrganizationId)"
Write-Verbose "OrganizationName:    $($OrganizationName)"
Write-Verbose "MountPoint:          $($MountPoint)"
Write-Verbose "ConfigurationName:        $($ConfigurationName)"
Write-Verbose "CreateConfiguration: $($CreateConfiguration)"
Write-Verbose "Path:                $($Path)"
Write-Verbose "ErrorLog:            $($EnableLoggning)"
Write-Verbose "LogFile:             $($LogFile)"
Write-Verbose "---"

if($OrganizationName) {
    Write-Verbose "Finding organization_id..."
    $OrganizationId = (Get-ITGlueOrganizations -filter_name $OrganizationName).data.id

    if(-not $OrganizationId) {
        Write-Verbose "No Organization Name found."
        Write-Verbose "Exiting."
        exit
    } elseif ($OrganizationId.Lenght -gt 1) {
        Write-Verbose "More than one Organization found."
        Write-Verbose "Please specify more specific."
        Write-Verbose "Exiting."
        exit
    } else {
        Write-Verbose "Organization ID: $OrganizationId"
    }
}


if($FindConfiguration) {
    Write-Verbose "Finding configuration..."
    $configuration = Get-ITGlueConfigurations -organization_id $OrganizationId | Where {$_.attributes.name -like "*$ConfigurationName*"}

    if(-not $configuration) {
        Write-Verbose "No configuration was found."

        if($CreateConfiguration) {
            New-Configuration
        } else {
            Write-Verbose "CreateConfiguration parameter not specified, exiting."
            exit
        }
    }
} elseif($CreateConfiguration) {
    New-Configuration
} elseif($ConfigurationId) {
    try {
        $configuration = Get-ITGlueConfigurations -id $ConfigurationId
    } catch [Exception]{
        Write-Verbose " -- BEGIN ERROR -- "
        Write-Verbose "$($_.Exception)"
        Write-Verbose " -- END ERROR -- "
        exit
    }
}

foreach ($drive in $MountPoint) {
    if(-not $drive.EndsWith(":")) {
        $drive = $drive + ":"
    }

    try {
        Write-Verbose "--"
        Write-Verbose "ENCRYPTING -- $drive"
        $encryption = Enable-BitLocker -MountPoint $drive -RecoveryPasswordProtector -SkipHardwareTest
        Write-Verbose "AutoUnlockEnabled: $($encryption.AutoUnlockEnabled)" -Verbose
        Write-Verbose "CapacityGB: $($encryption.CapacityGB)" -Verbose
        Write-Verbose "ConfigurationName: $($encryption.ComputerName)" -Verbose
        Write-Verbose "EncryptionMethod: $($encryption.EncryptionMethod)" -Verbose
        Write-Verbose "KeyProtector: $($encryption.KeyProtector)" -Verbose
        Write-Verbose "LockStatus: $($encryption.LockStatus)" -Verbose
        Write-Verbose "MountPoint: $($encryption.MountPoint)" -Verbose

        $body = @{
            data = @{
                type = "flexible_assets"
                attributes = @{
                    organization_id = $OrganizationId
                    flexible_asset_type_id = $FlexibleAssetId
                    traits = @{
                        computer = $configuration.id
                        drive = $drive
                        capacity = "$($encryption.CapacityGB) GB"
                        "encryption-method" = $encryption.EncryptionMethod.ToString()
                        keyprotectorid = $encryption.KeyProtector.KeyProtectorId
                        keyprotectortype = $encryption.KeyProtector.KeyProtectorType.ToString()
                        recoverypassword = $encryption.KeyProtector.RecoveryPassword
                    }
                }
            }
        }

        try {
            Write-Verbose "Uploading information to ITGlue.."
            New-ITGlueFlexibleAssets -data $body
            Write-Verbose "Upload successful."
        } catch [Exception]{
            Write-Verbose " -- BEGIN ERROR -- "
            Write-Verbose "$($_.Exception)"
            Write-Verbose " -- END ERROR -- "
        }

    } catch [Exception]{
        Write-Verbose " -- BEGIN ERROR -- "
        Write-Verbose "$($_.Exception)"
        Write-Verbose " -- END ERROR -- "
    }
}