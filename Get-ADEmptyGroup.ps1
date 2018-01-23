Function Get-ADEmptyGroup
{
    #Requires -Modules ActiveDirectory
    <#
    .SYNOPSIS
    Finds empty groups in Active Directory. An empty group is one in which
    there are no members.

    .DESCRIPTION
    Finds empty groups in Active Directory. An empty group is one in  which
    there are no members.
    
    .PARAMETER IncludeBuiltIn
    Includs built in Groups

    .PARAMETER ExcludeExchangeRoleGroups
    Excludes Exchange Built-In Role Groups

    .EXAMPLE
    Get-ADEmptyGroup
    Returns Active Directory groups with no members.

    .EXAMPLE
    Get-ADEmptyGroup -IncludesBuiltIn
    Returns Active Directory groups, including built-in groups, which have no members.
    
    .OUTPUTS
    Microsoft.ActiveDirectory.Management.ADGroup

    .NOTES
    Raymond Jette

    #>
    [OutputType([Microsoft.ActiveDirectory.Management.ADGroup])]
    [CmdletBinding()]
    param(
        # Include buit-in groups in the results
        [Switch]$IncludeBuiltIn,

        # Excludes Exchange built-in role groups
        [Switch]$ExcludeExchangeRoleGroups,

        # Exchanges SQL Server built-in groups
        [Switch]$ExcludeSqlServerBuiltIn
    )

    try {
        # Exchange Role Groups
        $ExchangeRoleGroups = @(
            'Organization Management'
            'View-Only Organization Management'
            'Recipient Management'
            'UM Management'
            'Help Desk'
            'Hygiene Management'
            'Compliance Management'
            'Records Management'
            'Discovery Management'
            'Public Folder Management'
            'Server Management'
            'Delegated Setup'
            'Exchange All Hosted Organizations'
            'ExchangeLegacyInterop'
        )

        # Parameters for the Get-ADGoup cmdlet
        $GetADGroupParam = @{
            Filter = '*'
            ErrorAction = 'Stop'
            ErrorVariable = 'ErrGetADGroup'
        }
        # Get all Active Directory Groups
        Write-Verbose -Message 'Getting all Active Directory groups...'
        #$ADGroups = Get-ADGroup -Filter *
        $ADGroups = Get-ADGroup @GetADGroupParam 

        # If we are not including built-in gorups
        if (-not $IncludeBuiltIn) {
            Write-Verbose -Message 'Built-in groups will not be included in the results.'
            $ADGroups = $ADGroups | Where-Object {$_.DistinguishedName -NotLike "*BuiltIn*"} 
        }

        # If we are not including Exchange built-in role groups
        if ($ExcludeExchangeRoleGroups) {
            Write-Verbose -Message 'Excluding built-in Exchange role groups.'

            $ADGroups = $ADGroups | Where-Object {$ExchangeRoleGroups -NotContains $_.Name}
        }
    
        # If we are excluding built-in SQL Groups
        if ($ExcludeSqlServerBuiltIn) {
            Write-Verbose -Message 'Excluding built-in SQL groups.'
            $ADGroups = $ADGroups | Where-Object {
                ($_.Name -NotLike "SQLServerMSSQLServerADHelperUser$*") -and
                ($_.Name -NotLike "SQLServer2005SQLBrowserUser$*") -and 
                ($_.Name -NotLike "SQLServer2005MSSQLUser$*") -and
                ($_.Name -NotLike "SQLServer2005MSFTEUser$*")
            }   
        }

        If ($ADGroups) {
            Write-Verbose -Message 'Looping through groups looking for duplicates...'
            ForEach ($Group in $ADGroups) {
                # The groups does not contain any memebers
                If (-Not ($Group | Get-ADGroupMember)) {
                    Write-Verbose -Message "[$($Group.Name)] is empty"
                    $Group
                }
            }
        }
        # No Groups have been returned
        Else {
            if ($ErrGetADGroup) {Write-Error 'Failed to run Get-ADGroup.'}
            Write-Error -Message 'No groups have been returned.'
        }
    } catch {$_.exception.message}
}