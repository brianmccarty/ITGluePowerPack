[cmdletbinding(DefaultParameterSetName='ID')]
param(
    [Parameter(ParameterSetName='ID', Mandatory=$true)]
    [int]$OrganizationId,

    [Parameter(ParameterSetName='Name', Mandatory=$true)]
    [String]$OrganizationName,

    [Parameter(Mandatory=$true)]
    [String[]]$MountPoint,

    [Alias("Log", "ErrorLog")]
    [Switch]$EnableLoggning,
    [Switch]$CreateConfiguration,

    [String]$Path = "$env:USERPROFILE\UpstreamPowerPack",
    [String]$LogFile = "$Path\Encrypt.ps1_$(Get-Date -Format "yyyy-MM-dd").log",
    [String]$ComputerName=$env:COMPUTERNAME,
    [String]$ConfigurationType = "Desktop"
)


Begin {
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
    Write-Verbose "Being Encrypt.ps1 $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
    Write-Verbose "PARAMETERS"
    Write-Verbose "OrganizationId:      $($OrganizationId)"
    Write-Verbose "OrganizationName:    $($OrganizationName)"
    Write-Verbose "MountPoint:          $($MountPoint)"
    Write-Verbose "ComputerName:        $($ComputerName)"
    Write-Verbose "CreateConfiguration: $($CreateConfiguration)"
    Write-Verbose "Path:                $($Path)"
    Write-Verbose "ErrorLog:            $($EnableLoggning)"
    Write-Verbose "LogFile:             $($LogFile)"
    Write-Verbose "---"

    if($PSCmdlet.ParameterSetName -eq "Name") {
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
        }
    }

    if($OrganizationId) {
        Write-Verbose "Finding configuration..."
        $configuration = Get-ITGlueConfigurations -organization_id $OrganizationId | Where {$_.attributes.name -like "*$ComputerName*"}

        if(-not $configuration) {
            Write-Verbose "No configuration was found."
            if($CreateConfiguration) {
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
                Write-Verbose "Creating configuration..."
                $configuration = @{
                    data = @{
                        type = "configurations"
                        attributes = @{
                            organization_id = $OrganizationId
                            configuration_type_id = (Get-ITGlueConfigurationTypes -filter_name "Desktop").data.id
                            configuration_status_id = (Get-ITGlueConfigurationStatuses -filter_name "Active").data.id
                            manufacturer_id = $manufacturer.data.id
                            model_id = $model.data.id
                            Name = $ComputerName
                            serial_number = (Get-WmiObject Win32_BIOS).SerialNumber

                            hostname = $ComputerName
                            primary_ip = $interfaceArray[0].Values."ip_address"
                            mac_address = (Get-CimInstance win32_networkadapterconfiguration | Where {$_.ipaddress -eq $interfaceArray[0].Values."ip_address"}).MACAddress
                            default_gateway = ((Get-CimInstance win32_networkadapterconfiguration | Where {$_.ipaddress -eq $interfaceArray[0].Values."ip_address"})).DefaultIPGateway
                            operating_system_id = 111
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
                Write-Verbose "Configuration created."
                Write-Verbose "$($configuration | ConvertTo-Json -Depth 100)"

                # Try to upload to ITGlue.
                try {
                    Write-Verbose "Uploading configuration to ITGlue..."
                    $thisConfiguration = New-ITGlueConfigurations -data $configuration

                } catch {
                    Write-Error "Error when uploading: $_"

                } finally {
                    if($thisConfiguration) {
                        Write-Verbose "URL: (your_company).itglue.com/$($OrganizationId)/configurations/$($thisConfiguration.data.id)"
                    }
                }
            } else {
                Write-Verbose "Not creating configuration."
                Write-Verbose "Exiting"
                exit
            }
        } else {
            Write-Verbose "Result: $($configuration)"
        }
    } else {
        Write-Verbose "No OrganizationId, exiting."
        exit
    }
}
Process {
    Write-Verbose "ENCRYPTING -- $MountPoint"
    $encryption = Enable-BitLocker -MountPoint $MountPoint -RecoveryPasswordProtector -SkipHardwareTest
    Write-Verbose "Status $encryption"

    $body = @{
        data = @{
            type = "flexible_assets"
            attributes = @{
                organization_id = $OrganizationId
                traits = @{
                    computer = $configuration
                    keyprotectorid = $encryption.KeyProtector.KeyProtectorId
                    keyprotectortype = $encryption.KeyProtector.KeyProtectorType
                    recoverypassword = $encryption.KeyProtector.RecoveryPassword
                }
            }
        }
    }

    $result = New-ITGlueFlexibleAssets -data $body
    $result
}