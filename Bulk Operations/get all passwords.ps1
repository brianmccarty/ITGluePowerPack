$ITGlue_Headers = @{
    "x-api-key" = "ITG.fbf096c8a7b26f3f1b4bee8c4f46650c.lZcIZI-sO2R-n5Gvmr_62rpub4POGNHqLQ55qvs7M3bdGbolCnS2B0egeQwkeu0B"
    "Content-Type" = "application/vnd.api+json; charset=utf-8"
}

$body = @{'page[size]' = (Invoke-RestMethod -method 'GET' -uri ("http://api.itglue.com/organizations") -headers $ITGlue_Headers).meta.'total-count'}
$orgs = (Invoke-RestMethod -method 'GET' -uri ("http://api.itglue.com/organizations") -headers $ITGlue_Headers -body $body).data


$body = @{'page[size]' = (Invoke-RestMethod -method 'GET' -uri ("http://api.itglue.com/passwords") -headers $ITGlue_Headers).meta.'total-count'}
$passwords = (Invoke-RestMethod -method 'GET' -uri ("http://api.itglue.com/passwords") -headers $ITGlue_Headers -body $body).data


$creds = @{}

foreach($org in $orgs) {
    $passwords | where {$_.attributes.'organization-id' -eq $org.id} | % {
        $response = Invoke-RestMethod -method 'GET' -uri ("http://api.itglue.com/organizations/$($org.id)/relationships/passwords/$($_.id)") -headers $ITGlue_Headers

        $response.data.attributes.username #USERNAME
        $response.data.attributes.password #PASSWORD
    }
}
