[cmdletbinding(DefaultParameterSetName="statusName")]
param(
    [Parameter(ParameterSetName="statusName")]
    [string]$StatusName = "Active",

    [Parameter(ParameterSetName="statusID")]
    [int]$StatusId
)

if($PsCmdlet.ParameterSetName -eq "statusName") {
    $StatusId = ((Get-ITGlueOrganizationStatuses).data | where {$_.attributes.name -eq "Active"}).id
    if($StatusId.Count -gt 1) {
        #$statusId = $StatusId[1]
        Write-Error "More than one status ID was found. Please specify the ID to use."
        $validIds = @()
        (Get-ITGlueOrganizationStatuses).data | where {$_.attributes.name -eq "Active"} | ForEach-Object {
            Write-Output "$($_.id) - $($_.attributes.name) - Synced: $($_.attributes.synced)"
            $validIds += $_.id
        }
        while(-not $validIds.Contains($statusId)) {
            $StatusId = Read-Host -Prompt "ID"
            if(-not $validIds.Contains($statusId)) {
                Write-Output "Please enter a valid ID."
            }
        }
    }
}

$organizations = (Get-ITGlueOrganizations -page_size ((Get-ITGlueOrganizations).meta.'total-count')).data
$locations = (Get-ITGlueLocations -page_size ((Get-ITGlueLocations).meta.'total-count')).data
$locationsToUpdate = @()

$organizations | ForEach-Object {
    $currentOrgId = $_.id
    if(-not (($locations | where {$_.attributes.'organization-id' -eq $currentOrgId}).attributes.primary | where {$_ -eq $True}) ) {
        $locations | where {$_.attributes.'organization-id' -eq $currentOrgId} | ForEach-Object {
            if($locationsToUpdate) {
                if(-not ( ($locationsToUpdate.attributes.'organization_id').Contains($currentOrgId) ) ) {
                    $locationsToUpdate += @{
                        type = "locations"
                        attributes = @{
                            id = $_.id
                            primary = 1
                            organization_id = $currentOrgId
                        }
                    }
                }
            } else {
                $locationsToUpdate += @{
                    type = "locations"
                    attributes = @{
                        id = $_.id
                        primary = 1
                        organization_id = $currentOrgId
                    }
                }
            }
        }
    }
}

$body = @{
    data = @(
        $locationsToUpdate
    )
}

Set-ITGlueLocations -data $body