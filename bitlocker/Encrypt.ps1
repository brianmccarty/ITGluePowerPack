[cmdletbinding(DefaultParameterSetName='ID')]
param(
	[Parameter(ParameterSetName='ID', Mandatory=$true)]
	[int]$OrganizationId,

	[Parameter(ParameterSetName='Name', Mandatory=$true)]
	[String]$OrganizationName,

	[String[]]$MountPoint="G:",
	[String]$ComputerName=$env:COMPUTERNAME,
	[Switch]$CreateConfiguration,
	[String]$ConfigurationType = "Desktop",
	[String]$Path = "$env:USERPROFILE\UpstreamPowerPack",
	[Switch]$ErrorLog,
	[String]$LogFile = "$Path\Encrypt.ps1_$(Get-Date -Format "yyyy-MM-dd HH:mm:ss").log"
)


Begin {
	if($ErrorLog) {
		Write-Verbose "Error loggning is enabled."
		Write-Verbose "Location: $LogFile"
		Write-Verbose ""
	} else {
		Write-Verbose "Error loggning is disabled."
		Write-Verbose ""
	}

	Write-Verbose "PARAMETERS"
	Write-Verbose "OrganizationId:      $($OrganizationId)"
	Write-Verbose "OrganizationName:    $($OrganizationName)"
	Write-Verbose "MountPoint:          $($MountPoint)"
	Write-Verbose "ComputerName:        $($ComputerName)"
	Write-Verbose "CreateConfiguration: $($CreateConfiguration)"
	Write-Verbose "Path:                $($Path)"
	Write-Verbose "ErrorLog:            $($ErrorLog)"
	Write-Verbose "LogFile:             $($LogFile)"
	Write-Verbose ""

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
		Write-Verbose "Result: $($configuration)"
		Write-Verbose ""

		if(-not $configuration) {
			Write-Verbose "No configuration was found."
			if($CreateConfiguration) {
				# Get or create IDs if not existing

				# Manufacturers
				Write-Verbose "Creating new configuration."
				if($manufacturer = ((Get-ITGlueManufacturers -filter_name (Get-WmiObject Win32_BIOS).Manufacturer))) {
					Write-Verbose "Manufacturer found: $($manufacturer.data.id), '$($manufacturer.data.attributes.name)'."
				} elseif($manufacturer = New-ITGlueManufacturers -data (@{data = @{type = "manufacturers";attributes = @{name = (Get-WmiObject Win32_BIOS).Manufacturer}}})) {
					Write-Verbose "Manufacturer created: $($manufacturer.data.id), '$($manufacturer.data.attributes.name)'."
				}

				# Model ID
				if($model = (Get-ITGlueModels -manufacturer_id $manufacturerId).data) {
					Write-Verbose "Model found: $($model.data.attributes)."
				} elseif($model = New-ITGlueModels -data (@{data = @{type = "models";attributes = @{manufacturer_id = $manufacturerId;name = (Get-WmiObject Win32_Computersystem).Model}}})) {
					Write-Verbose "Model created: $($model.data.attributes)."
				}

				# Network interfaces
				Write-Verbose "Looking for network interfaces..."
				$interfaceArray = @();
				$first = $true
				Get-NetAdapter | ForEach-Object {
					$interfaceArray += @{
						type = "configuration_interfaces"
						attributes = @{
							ip_address = (Get-NetIPConfiguration -InterfaceIndex $_.InterfaceIndex).IPv4Address.IPAddress
							name = $_.InterfaceIndex
							primary = if($first) {$first = $false;$true} else {$false}
							notes = $_.InterfaceAlias
						}
					}
				}
				Write-Verbose "Network interfaces found: $($interfaceArray | ConvertTo-Json)"
				#new config
				$configuration = @{
					data = @{
						type = "configurations"
						attributes = @{
							organization_id = $OrganizationId
							configuration_type_id = (Get-ITGlueConfigurationTypes -filter_name "Desktop").data.id
							configuration_status_id = (Get-ITGlueConfigurationStatuses -filter_name "Active").data.id
							manufacturer_id = $manufacturerId
							model_id = $model.data.id
							Name = $ComputerName
							serial_number = (Get-WmiObject Win32_BIOS).SerialNumber
							primary_ip = $interfaceArray[0].Values."ip_address"
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

				$thisConfiguration = New-ITGlueConfigurations -data $configuration
			} else {
				Write-Verbose "Not creating configuration."
				Write-Verbose "Exiting"
				exit
			}
		}
	} else {
		Write-Verbose "No OrganizationId, exiting."
		exit
	}
}
Process {
	Write-Verbose "Encrypting $MountPoint"
	$encryption = Enable-BitLocker -MountPoint $MountPoint -RecoveryPasswordProtector -SkipHardwareTest
	Write-Verbose "Status $encryption"

	$body = {
		data = @(
			"awd" = "awd"
		)
	}
	# $encryption.KeyProtector.KeyProtectorId
	# $encryption.KeyProtector.KeyProtectorType
	# $encryption.KeyProtector.RecoveryPassword
}