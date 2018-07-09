[cmdletbinding(DefaultParameterSetName="ManualMode")]
param (
    [Parameter(Mandatory=$true)]
    [String]$organisationid,


    [Parameter(ParameterSetName="Credentials")]
    [string]$Path = "$env:USERPROFILE\UpstreamPowerPack",

    [Parameter(ParameterSetName="NoCredentials", Mandatory=$true)]
    [string]$Username,

    [Parameter(ParameterSetName="NoCredentials", Mandatory=$true)]
    [string]$Password,

    [Parameter(ParameterSetName="NoCredentials")]
    [switch]$Savecreds,

    [Parameter(ParameterSetName="ManualMode")]
    [switch]$ManualMode,

    [switch]$Log,
    [String]$LogFile = "$Path\Encrypt.ps1_$(Get-Date -Format "yyyy-MM-dd").log",
    [String]$Unlicensed,
    [String]$Duplicates
)


if($PSBoundParameters.Verbose) {
    $verbose = $true
}
Function Write-Message {
    [CmdletBinding()]
    Param ($Message, [switch]$Warning)

    if($Log) {
        Out-File -InputObject "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $($Message)" -FilePath $LogFile -Append
    }
    if($Warning) {
        Microsoft.PowerShell.Utility\Write-Verbose -Message "$Message"
    } elseif($verbose) {
        Microsoft.PowerShell.Utility\Write-Warning -Message "$Message"
    }
}

if($Path.EndsWith("\")) {
    $Path = $Path.Remove($Path.Length -1, 1)
}

if(-not (Get-Module -ListAvailable -Name AzureAD)) {
    Write-Message -Message "Please run the Office 365 install script first or manually install the AzureAD module." -Warning
    exit
}

if($PSCmdlet.ParameterSetName -eq "Credentials") {
    if(-not (Test-Path -path $Path\o365credentials.xml)) {
        Write-Message -Message "$Path\o365credentials.xml does not exist." -Warning
        Write-Message -Message "Please run script with -username and -password parameter instead. Use -savecreds to save them for later use." -Warning
        exit
    } else {
        try {
            Connect-AzureAD -Credential $credential > $null
        } catch [Exception]{
            Write-Message -Message "Login error: $($_)" -Warning
            exit
        }
    }
}

if($PSCmdlet.ParameterSetName -eq "NoCredentials") {
    try {
        $credential = New-Object System.Management.Automation.PSCredential ($Username, (ConvertTo-SecureString $Password  -AsPlainText -Force))
        Connect-AzureAD -Credential $credential > $null

        if($Savecreds) {
            $credentials | Export-Clixml -Path $Path\o365credentials.xml
        }
    } catch [Exception]{
        Write-Message -Message "Login error: $($_)"
        exit
    }
}

if($ManualMode) {
    $doNext = "find org"
    :FindOrganization
    while($true) {
        switch ($doNext) {
            "find org" {
                $organizationName = Read-Host "Organisation name in ITGlue"
                $foundOrgs = New-Object System.Collections.ArrayList

                (Get-ITGlueOrganizations -page_size ((Get-ITGlueOrganizations).meta.'total-count')).data | ForEach-Object {
                    if($_.attributes.name -like "*$organizationName*") {
                            $foundOrgs.Add($_) > $null
                    }
                }

                if(-not $foundOrgs) {
                    Write-Host "No organisation found."
                    $doNext = "find org"
                } elseif ($foundOrgs.Count -eq 1) {
                    $organizationName = $foundOrgs
                    $doNext = "confirm org"
                } elseif ($foundOrgs.Count -gt 1) {
                    $doNext = "multi hit handling"
                }
            }

            "multi hit handling" {
                $foundOrgsSorted = New-Object System.Collections.ArrayList
                $foundOrgs.attributes.name | Sort-Object | ForEach-Object {
                    $currentName = $_
                    $foundOrgsSorted.Add(($foundOrgs | Where-Object {$_.attributes.name -eq $currentName})) > $null
                }

                $count=1
                foreach($org in $foundOrgsSorted) {
                    Write-Host "$($count) $($org.attributes.name)"
                    $count++
                }

                # Remove one because we always add one more at the end.
                $count--

                Write-Host ""
                Write-Host "Found more than organisation was found."
                # Force a valid input
                do {
                    $userInput = Read-Host "Enter the number corresponding to your org or 0 to enter name again"
                    $value = $userInput -as [Double]
                    # Null if failed to convert
                    if($value -eq $null) {
                        Write-Host ""
                        Write-Host "You must enter a numeric value"
                    # Cannot be out of array index
                    } elseif ($value -gt $count -or $value -lt 0) {
                        Write-Host ""
                        Write-Host "You must enter a number from 1 to $count."
                    }
                }
                until (($value -ne $null) -and ($value -le $count))

                Write-Host ""
                if ($value -eq 0) {
                    $doNext = "find org"
                } else {
                    $organizationName = $foundOrgsSorted[$value - 1]
                    $doNext = "confirm org"
                }
            }

            "confirm org" {
                $userInput = Read-Host "Do you want to import into $($organizationName.attributes.name)? (y/n)"
                if("yes" -match $userInput) {
                    break FindOrganization
                } else {
                    $doNext = "find org"
                }
            }

        }
    }

    $organisationid = $organizationName.id
}

# Get all contacts from ITGlue
$ITGlueContacts = ((Get-ITGlueContacts -page_size ((Get-ITGlueContacts).meta.'total-count')).data | Where-Object {$_.attributes.'organization-id' -eq $organisationid})


Get-AzureADUser -All $true | ForEach-Object {
    $currentUser = $_

    # Clean up name
    if($currentUser.DisplayName.Split().Count -gt 1) {
        $firstname = $currentUser.DisplayName.Replace($currentUser.DisplayName.Split()[$currentUser.DisplayName.Split().Count - 1], "")
        $lastname = $currentUser.DisplayName.Split()[-1]
        if($firstname.EndsWith(" ")) {
            $firstname = $firstname.Substring(0, $firstname.Length - 1)
        }
    } else {
        $firstname = $currentUser.DisplayName
        $lastname = ""
    }

    if($_.AssignedLicenses.skuid -eq $null -and -not $Unlicensed) {
        # Skip unlicensed users.
        Write-Message -Message "Skipping unlicensed user: $($_.UserPrincipalName)"
        return
    } elseif((-not $Duplicates) -and (($ITGlueContacts.attributes.'contact-emails'.value -contains $_.UserPrincipalName) -or ($ITGlueContacts.attributes.'first-name' -eq $firstname -and $ITGlueContacts.attributes.'last-name' -eq $lastname))) {
        # Skip existing emails and names
        Write-Message -Message "Skipping existing user: $($_.UserPrincipalName)"
        return
    }


    $body = @{
        organization_id = $organisationid
        data = @{
            type = 'contacts'
            attributes = @{
                first_name = $firstname
                last_name = $lastname
                notes = "Office 365 user"
                contact_emails = @(
                    @{
                        value = $currentUser.UserPrincipalName
                        label_name = "Work"
                        primary = $true
                    }
                )
            }
        }
    }

    New-ITGlueContacts -data $body
}