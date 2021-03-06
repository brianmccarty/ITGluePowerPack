$data = @{
    type = 'flexible_asset_types'
    attributes = @{
        name = 'Cloud Apps'
        description = "This flexible asset is designed specifically for Cloud applications. This is part of Upstream's IT Glue customer on-boarding procedure."
        icon = 'cloud'
        show_in_menu = $true
        enabled = $true
    }
    relationships = @{
        flexible_asset_fields = @{
            data = @(
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 1
                        name = 'Application name'
                        kind = 'Select'
                        hint = 'The name of the application like Office 365 Business Premium, Salesforce, Drobpbox etc.'
                        default_value =   "Kaseya VSA`r`n" `
                                        + "Kaseya BMS`r`n" `
                                        + "Kaseya Authanvil`r`n" `
                                        + "IT Glue`r`n" `
                                        + "Audit Guru for GDPR`r`n" `
                                        + "Auvik`r`n" `
                                        + "Webroot`r`n" `
                                        + "MySelfServicePortal.com`r`n" `
                                        + "--------------------------------`r`n" `
                                        + "Office 365 Business`r`n" `
                                        + "Office 365 Business Premium`r`n" `
                                        + "Office 365 Business Essentials`r`n" `
                                        + "Dropbox`r`n" `
                                        + "Salesforce`r`n" `
                                        + "Fortnox`r`n" `
                                        + "Hogia`r`n" `
                                        + "Visma Administration`r`n" `
                                        + "Visma Lön`r`n" `
                                        + "Visma Tid`r`n" `
                                        + "Hogia Smart Ekonomi`r`n" `
                                        + "Navision`r`n" `
                                        + "Mailchimp`r`n" `
                                        + "Zoom Meeting"
                        required = $false
                        show_in_list = $true
                        use_for_title = $true
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 2
                        name = 'Licensed Users'
                        kind = 'Tag'
                        hint = 'Tag the specific contacts using this application'
                        tag_type = 'Contacts'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 3
                        name = 'Application URL '
                        kind = 'Text'
                        hint = 'What is the URL for this application?'
                        default_value = ''
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 4
                        name = 'Application user interface'
                        kind = 'Select'
                        hint = 'Is this a web browser based application or does it require a software installation?'
                        default_value = "Browser based only`r`n" `
                                    + "Local software only`r`n" `
                                    + "Mobile App only`r`n" `
                                    + "Browser and Mobile App`r`n" `
                                    + "Browser and local software`r`n" `
                                    + "Browser, local software and mobile App`r`n"
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 5
                        name = 'Subscription period (contract period)'
                        kind = 'Select'
                        hint = 'What is the agreed subscription (contract) period for this application?'
                        default_value = "Monthly`r`n" `
                                    + "Yearly`r`n" `
                                    + "2 years`r`n" `
                                    + "3 years`r`n" `
                                    + "Other`r`n"
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 6
                        name = 'Subscription expires'
                        kind = 'Date'
                        hint = 'When do the Cloud software subscription agreement expire?'
                        required = $false
                        show_in_list = $true
                        expiration = $true
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 7
                        name = 'Important contacts'
                        kind = 'Header'
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 8
                        name = 'Financial application owner at the customer'
                        kind = 'Tag'
                        hint = 'Who pays the bills? Can be the same as the application administrator.'
                        tag_type = 'Contacts'
                        required = $false
                        show_in_list = $true
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 9
                        name = 'Application admin(s) at the customer'
                        kind = 'Tag'
                        hint = 'Do the customer have specific application administrator(s) for this application?'
                        tag_type = 'Contacts'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 10
                        name = 'Our application specialist(s)'
                        kind = 'Tag'
                        hint = 'Here you can tag our application specialist(s) for this application?'
                        tag_type = 'AccountsUsers'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 11
                        name = 'Passwords and security'
                        kind = 'Header'
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 12
                        name = 'Passwords'
                        kind = 'Tag'
                        hint = 'Tag the password(s) associated with this app for administration purposes.'
                        tag_type = 'Passwords'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 13
                        name = 'RMM Deployment Agent Procedure'
                        kind = 'Text'
                        hint = 'Can this application be deployed with a Agent Procedure? What is the name?'
                        default_value = 'Type the name of the Kaseya Agent Procedure here.'
                        required = $false
                        show_in_list = $false
                    }
                },
                 @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 14
                        name = 'Requires 2factor authentication'
                        kind = 'Select'
                        hint = 'Does this application requires any 2factor verification.'
                        default_value = "Yes`r`n" `
                                      + "No"
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 15
                        name = '2factor solution used'
                        kind = 'Select'
                        hint = 'If yes on requires 2factor authentication, what solution do the customer use?'
                        default_value = "Authanvil`r`n" `
                                    + "OneLogin`r`n" `
                                    + "Octa`r`n" `
                                    + "DUO`r`n" `
                                    + "Google Authenticator`r`n" `
                                    + "Macosoft Authenticator`r`n" `
                                    + "Other (take note)"
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 16
                        name = 'GDPR Related Information'
                        kind = 'Header'
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 17
                        name = 'Contains Personal Data'
                        kind = 'Select'
                        hint = 'Do this application fall under GDPR restrictions and regulations?'
                        default_value = "Yes`r`n" `
                                      + "No"
                        required = $true
                        show_in_list = $true
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 18
                        name = 'Vendor'
                        kind = 'Tag'
                        hint = 'Tag vendor'
                        tag_type  = "FlexibleAssetType: $((Get-ITGlueFlexibleAssetTypes -filter_name Vendors).data.id)"
                        required = $false
                        show_in_list = $true
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 19
                        name = 'Notes'
                        kind = 'Text'
                        hint = 'Any addition notes?'
                        required = $false
                        show_in_list = $false
                    }
                }
            )
        }
    }
}
New-ITGlueFlexibleAssetTypes -data $data
