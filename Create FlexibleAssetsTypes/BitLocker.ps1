$body = @{
    data = @{
        type = 'flexible_asset_types'
        attributes = @{
            name = 'Bitlocker'
            description = 'Bitlocker encryption information and keys.'
            icon = 'lock'
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
                            name = 'Computer'
                            kind = 'Tag'
                            hint = 'Which computer is the drive on?'
                            tag_type = 'Configurations'
                            required = $true
                            show_in_list = $true
                            use_for_title = $true
                        }
                    },
                    @{
                        type = 'flexible_asset_fields'
                        attributes = @{
                            order = 2
                            name = 'Drive'
                            kind = 'Select'
                            hint = 'Which drive was encrypted?'
                            required = $true
                            show_in_list = $true
                            use_for_title = $true
                        }
                    },
                    @{
                        type = 'flexible_asset_fields'
                        attributes = @{
                            order = 3
                            name = 'Capacity'
                            kind = 'Text'
                            hint = 'Size of the harddrive.'
                            required = $false
                            show_in_list = $true
                            use_for_title = $true
                        }
                    },
                    @{
                        type = 'flexible_asset_fields'
                        attributes = @{
                            order = 4
                            name = 'KeyProtectorType'
                            kind = 'Tag'
                            hint = ''
                            tag_type = 'Configurations'
                            required = $true
                            show_in_list = $false
                            use_for_title = $false
                        }
                    },
                    @{
                        type = 'flexible_asset_fields'
                        attributes = @{
                            order = 5
                            name = 'KeyProtectorType'
                            kind = 'Text'
                            hint = ''
                            required = $true
                            show_in_list = $false
                            use_for_title = $false
                        }
                    },
                    @{
                        type = 'flexible_asset_fields'
                        attributes = @{
                            order = 6
                            name = 'RecoveryPassword'
                            kind = 'Text'
                            hint = ''
                            required = $true
                            show_in_list = $false
                            use_for_title = $false
                        }
                    }
                )
            }
        }
    }
}
New-ITGlueFlexibleAssetTypes -data $body