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
if($model = (Get-ITGlueModels -manufacturer_id $manufacturerId).data) {
    Write-Verbose "Model found: $($model.attributes)."
# If not found, create new.
} elseif($model = New-ITGlueModels -data (@{data = @{type = "models";attributes = @{manufacturer_id = $manufacturerId;name = (Get-WmiObject Win32_Computersystem).Model}}})) {
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
Write-Verbose "Creating configuration..."
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

            hostname = $ComputerName
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