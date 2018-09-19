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