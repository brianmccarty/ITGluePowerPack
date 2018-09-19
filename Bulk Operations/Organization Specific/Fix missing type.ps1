[cmdletbinding(DefaultParameterSetName="typeName")]
param(
    [Parameter(ParameterSetName="typeName")]
    [string]$TypeName = "Active",

    [Parameter(ParameterSetName="typeID")]
    [int]$TypeId
)

if($PsCmdlet.ParameterSetName -eq "typeName") {
    $TypeId = ((Get-ITGlueOrganizationStatuses).data | where {$_.attributes.name -eq $TypeName}).id
    if($TypeId.Count -gt 1) {
        #$TypeId = $TypeId[1]
        Write-Error "More than one type ID was found. Please specify the ID to use."
        $validIds = @()
        (Get-ITGlueOrganizationStatuses).data | where {$_.attributes.name -eq $TypeName} | ForEach-Object {
            Write-Output "$($_.id) - $($_.attributes.name) - Synced: $($_.attributes.synced)"
            $validIds += $_.id
        }
        while(-not $validIds.Contains($TypeId)) {
            $TypeId = Read-Host -Prompt "ID"
            if(-not $validIds.Contains($TypeId)) {
                Write-Output "Please enter a valid ID."
            }
        }
    }
}

$organizations = (Get-ITGlueOrganizations -page_size ((Get-ITGlueOrganizations).meta.'total-count')).data
$organizationsToUpdate = @()

$organizations | ForEach-Object {
    if(-not $_.attributes.'organization-type-id') {
        $organizationsToUpdate += @{
            type = "organizations"
            attributes = @{
                id = $_.id
                organization_type_id = $TypeId
            }
        }
    }
}

$body = @{
    data = @(
        $organizationsToUpdate
    )
}

Set-ITGlueOrganizations -data $body