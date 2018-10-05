# Get all organizations..
$data = Get-ITGlueOrganizations -page_size 1000
# ..as array..
$organizations = New-Object System.Collections.ArrayList
# ..and add them to array
foreach($item in $data.data) {
    $organizations.Add($item)
}
# Check for more pages. Get the rest of the data if there is.
$page = 1
while($data.meta.'total-pages' -gt $page) {
    $page++
    Get-ITGlueOrganizations -page_number $page | Select-Object -ExpandProperty data | ForEach-Object {
        $organizations.add($_)
    }
}


# Get all locations.
$data = Get-ITGlueLocations -page_size 1000
# ..as array..
$locations = New-Object System.Collections.ArrayList
# ..and add them to array
foreach($item in $data.data) {
    $locations.Add($item)
}
# Check for more pages. Get the rest of the data if there is.
$page = 1
while($data.meta.'total-pages' -gt $page) {
    $page++
    Get-ITGlueLocations -page_number $page | Select-Object -ExpandProperty data | ForEach-Object {
        $locations.add($_)
    }
}
$locationsToUpdate = New-Object System.Collections.ArrayList



# Loop through all organizations
$organizations | ForEach-Object {
    # Placeholder for org id
    $currentOrgId = $_.id
    # Count all primary locations
    if((($locations | Where {$_.attributes.'organization-id' -eq $currentOrgId}).attributes | Where Primary -eq $true | Measure-Object | Select -expand count) -eq 0) {
        # Filter out organization again if primary count equal 0
        $locations | Where {$_.attributes.'organization-id' -eq $currentOrgId} | ForEach-Object {
            # Find $currentOrgId has already been added
            if($locationsToUpdate) {
                if( -not (($locationsToUpdate.attributes.'organization_id').Contains($currentOrgId)) ) {
                    # Add location if it has not
                    $locationsToUpdate.Add(@{
                        type = "locations"
                        attributes = @{
                            id = $_.id
                            primary = 1
                            organization_id = $currentOrgId
                        }
                    })
                }
            } else {
                # Add location if it has not
                # AND it is the first one to add (i.e. variable is null)
                $locationsToUpdate.Add(@{
                    type = "locations"
                    attributes = @{
                        id = $_.id
                        primary = 1
                        organization_id = $currentOrgId
                    }
                })
            }
        }
    }
}

$body =  @($locationsToUpdate)
Set-ITGlueLocations -data $body