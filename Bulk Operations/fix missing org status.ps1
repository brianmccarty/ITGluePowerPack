[cmdletbinding(DefaultParameterSetName="statusName")]
param(
    [Parameter(ParameterSetName="statusName")]
    [string]$StatusName = "Active",

    [Parameter(ParameterSetName="statusID")]
    [int]$StatusId
)

if($PsCmdlet.ParameterSetName -eq "statusName") {
    $StatusId = ((Get-ITGlueOrganizationStatuses).data | where {$_.attributes.name -eq $StatusName}).id
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
$organizationsToUpdate = @()

$organizations | ForEach-Object {
    if(-not $_.attributes.'organization-status-id') {
        $organizationsToUpdate += @{
            type = "organizations"
            attributes = @{
                id = $_.id
                organization_status_id = $StatusId
            }
        }
    }
}

$body = @{
    data = @(
        $organizationsToUpdate
    )
}
