<#
.SYNOPSIS
    Imports Office 365 users as contacts to ITGlue.
.DESCRIPTION
    Visit https://github.com/UpstreamAB/ITGluePowerPack/wiki/Office-365 for help on how to use this script.
.NOTES
    Author:  Emile Priller
    Date:    18/07/2018
#>
[cmdletbinding(DefaultParameterSetName="ManualMode")]
param (
    [Parameter(ParameterSetName="Credentials", Mandatory=$true)]
    [Parameter(ParameterSetName="NoCredentials", Mandatory=$true)]
    [String]$OrganisationId,

    [Parameter(ParameterSetName="Credentials")]
    [Switch]$CredFile,

    [Parameter(ParameterSetName="Credentials")]
    [String]$Path = "$env:USERPROFILE\UpstreamPowerPack",

    [Parameter(ParameterSetName="NoCredentials", Mandatory=$true)]
    [String]$Usernam,

    [Parameter(ParameterSetName="NoCredentials", Mandatory=$true)]
    [String]$Password,

    [Parameter(ParameterSetName="NoCredentials")]
    [Switch]$Savecreds,

    [Parameter(ParameterSetName="ManualMode")]
    [Switch]$ManualMode = $true,

    [Switch]$Log,
    [String]$LogFile = "$Path\Encrypt.ps1_$(Get-Date -Format "yyyy-MM-dd").log",
    [String]$Unlicensed,
    [String]$Duplicates
)

if($PSBoundParameters.Verbose) {
    $verbose = $true
}
Function Write-Message {
    [CmdletBinding()]
    Param ($Message, [switch]$Warning, [switch]$Throw)

    if($Log) {
        Out-File -InputObject "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $($Message)" -FilePath $LogFile -Append
    }
    if($Warning) {
        Microsoft.PowerShell.Utility\Write-Verbose -Message "$Message"
    } elseif($Throw) {
        throw $Message
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
        $credential = New-Object System.Management.Automation.PSCredential ($Username, (ConvertTo-SecureString $Password -AsPlainText -Force))
        Connect-AzureAD -Credential $credential > $null

        if($Savecreds) {
            $credentials | Export-Clixml -Path $Path\o365credentials.xml
        }
    } catch [Exception]{
        Write-Message -Message "Login error: $($_)"
        exit
    }
}

if($PSCmdlet.ParameterSetName -eq "ManualMode") {
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
                    $userInput = Read-Host "Enter the number corresponding to your org or 0 to enter name agai"
                    $value = $userInput -as [Doubl]
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
                $userInput = Read-Host "Do you want to import into $($organizationName.attributes.name) ($($organizationName.id))? (y/n)"
                if("yes" -match $userInput){
                    break FindOrganization
                } else {
                    $doNext = "find org"
                }
            }

        }
    }

    $organisationid = $organizationName.id
    $importData = New-Object System.Collections.ArrayList

    while($true) {
        try {
            $Username = Read-Host "Office 365 usernam"
            $Password = Read-Host "Office 365 password" -AsSecureString
            $credential = New-Object System.Management.Automation.PSCredential($Username, $Passwor)
            Connect-AzureAD -Credential $credential > $null
            break
        } catch {
            Write-Output "Login failed, try again."
        }
    }
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
        Write-Message -Message "Skipping unlicensed user: $($_.UserPrincipalName)" -Warning
        return
    } elseif((-not $Duplicates) -and (($ITGlueContacts.attributes.'contact-emails'.value -contains $_.UserPrincipalName) -or ($ITGlueContacts.attributes.'first-name' -eq $firstname -and $ITGlueContacts.attributes.'last-name' -eq $lastname))) {
        # Skip existing emails and names
        Write-Message -Message "Skipping existing user: $($_.UserPrincipalName)" -Warning
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

    if($PSCmdlet.ParameterSetName -eq "ManualMode") {
       $importData.Add($body) > $null
    } else {
        New-ITGlueContacts -data $body
    }
}

if($PSCmdlet.ParameterSetName -eq "ManualMode") {
    $doNext = "output data"

    :import
    while($true) {
        switch ($doNext){
            "output data" {
                Write-Output "The following data will be imported:"
                for($i = 0; $i -lt $importData.Count; $i++) {
                    Write-Output "$($i+1)`: $($importData[$i].data.attributes.first_name) $($importData[$i].data.attributes.last_name) ($($importData[$i].data.attributes.contact_emails.value))"
                }

                $doNext = "confirm"
            }
            "confirm" {
                Write-Output ""
                $userInput = Read-Host "Import (y) or remove contact (n)"
                if("yes" -match $userInput){
                    $doNext = "import"
                } elseif("no" -match $userInput) {
                    $doNext = "remove contacts"
                }
            }
            "remove contacts" {
                $contactNr = Read-Host "Enter number of contact to remove"
                $importData.RemoveAt($contactNr - 1)
                $doNext = "output data"
            }
            "import" {
                foreach($body in $importData) {
                    New-ITGlueContacts -data $body
                }
                break import
            }
        }
    }
}